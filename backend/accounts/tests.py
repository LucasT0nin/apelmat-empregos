import tempfile

from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework import status
from rest_framework.test import APITestCase

from marketplace.models import ContactRequest, ProfessionalObjective

from .models import ContractorProfile, ProfessionalProfile, User


class RegistrationTests(APITestCase):
    def test_registers_user_and_profiles(self):
        response = self.client.post(
            "/api/accounts/register/",
            {
                "email": "profissional@example.com",
                "display_name": "Maria Silva",
                "phone": "(11) 99999-9999",
                "account_type": "professional",
                "accept_terms": True,
                "password": "uma-senha-forte-123",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="profissional@example.com")
        self.assertTrue(hasattr(user, "professional_profile"))
        self.assertTrue(hasattr(user, "contractor_profile"))
        self.assertEqual(user.phone, "+5511999999999")
        self.assertIsNotNone(user.accepted_terms_at)

    def test_public_registration_rejects_contractor_accounts(self):
        response = self.client.post(
            "/api/accounts/register/",
            {
                "email": "empresa@example.com",
                "display_name": "Empresa",
                "phone": "(11) 99999-9999",
                "account_type": "contractor",
                "accept_terms": True,
                "password": "uma-senha-forte-123",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(email="empresa@example.com").exists())

    def test_user_cannot_change_account_type_from_profile_api(self):
        user = User.objects.create_user(
            email="profissional@example.com",
            display_name="Profissional",
            phone="+5511999999999",
            account_type=User.AccountType.PROFESSIONAL,
            password="senha-segura-123",
        )
        self.client.force_authenticate(user)

        response = self.client.patch(
            "/api/accounts/me/",
            {"account_type": "contractor"},
            format="json",
        )
        user.refresh_from_db()

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(user.account_type, User.AccountType.PROFESSIONAL)
        self.assertEqual(response.data["account_type"], User.AccountType.PROFESSIONAL)

    def test_admin_creates_contractor_account(self):
        admin = User.objects.create_user(
            email="admin@example.com",
            display_name="Admin",
            phone="+5511777777777",
            account_type=User.AccountType.PROFESSIONAL,
            is_staff=True,
            password="senha-segura-123",
        )
        self.client.force_authenticate(admin)

        response = self.client.post(
            "/api/accounts/contractors/",
            {
                "email": "contratante@example.com",
                "display_name": "Responsavel Empresa",
                "phone": "(11) 98888-7777",
                "company_name": "Empresa Nova",
                "city": "Sao Paulo",
                "state": "sp",
                "password": "uma-senha-forte-123",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        user = User.objects.get(email="contratante@example.com")
        self.assertEqual(user.account_type, User.AccountType.CONTRACTOR)
        self.assertEqual(user.contractor_profile.company_name, "Empresa Nova")
        self.assertEqual(user.contractor_profile.state, "SP")

    def test_profiles_are_restricted_by_account_type(self):
        professional = User.objects.create_user(
            email="profissional@example.com",
            display_name="Profissional",
            phone="+5511999999999",
            account_type=User.AccountType.PROFESSIONAL,
            password="senha-segura-123",
        )
        contractor = User.objects.create_user(
            email="contratante@example.com",
            display_name="Contratante",
            phone="+5511888888888",
            account_type=User.AccountType.CONTRACTOR,
            password="senha-segura-123",
        )
        ProfessionalProfile.objects.create(user=professional)
        ContractorProfile.objects.create(user=contractor, company_name="Empresa")

        self.client.force_authenticate(professional)
        contractor_profile_response = self.client.get("/api/accounts/me/contractor/")
        self.client.force_authenticate(contractor)
        professional_profile_response = self.client.get("/api/accounts/me/professional/")

        self.assertEqual(
            contractor_profile_response.status_code,
            status.HTTP_403_FORBIDDEN,
        )
        self.assertEqual(
            professional_profile_response.status_code,
            status.HTTP_403_FORBIDDEN,
        )

    def test_admin_account_cannot_be_deleted_from_app_api(self):
        admin = User.objects.create_user(
            email="admin@example.com",
            display_name="Admin",
            phone="+5511777777777",
            account_type=User.AccountType.PROFESSIONAL,
            is_staff=True,
            password="senha-segura-123",
        )
        self.client.force_authenticate(admin)

        response = self.client.delete("/api/accounts/me/delete/")

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(User.objects.filter(id=admin.id).exists())


class ProfessionalDirectoryTests(APITestCase):
    def setUp(self):
        self.temp_media = tempfile.TemporaryDirectory()
        self.media_override = self.settings(MEDIA_ROOT=self.temp_media.name)
        self.media_override.enable()
        self.contractor = User.objects.create_user(
            email="empresa@example.com",
            display_name="Empresa",
            phone="+5511999999999",
            account_type=User.AccountType.CONTRACTOR,
            password="senha-segura-123",
        )
        self.professional = User.objects.create_user(
            email="pessoa@example.com",
            display_name="Pessoa Profissional",
            phone="+5511888888888",
            account_type=User.AccountType.PROFESSIONAL,
            password="senha-segura-123",
        )
        self.profile = ProfessionalProfile.objects.create(
            user=self.professional,
            city="Sao Paulo",
            state="SP",
            profile_visible=True,
            catalog_status=ProfessionalProfile.CatalogStatus.PUBLISHED,
            verified_by_apelmat=True,
            resume=SimpleUploadedFile(
                "curriculo.pdf",
                b"%PDF-1.4\nconteudo de teste",
                content_type="application/pdf",
            ),
        )
        self.objective = ProfessionalObjective.objects.create(
            professional=self.professional,
            role=ProfessionalObjective.Role.OPERATOR,
            summary="Operador de maquinas",
            availability="Imediata",
            answers={"equipamentos": "Retroescavadeira"},
            status=ProfessionalObjective.Status.PUBLISHED,
        )

    def tearDown(self):
        self.media_override.disable()
        self.temp_media.cleanup()

    def test_contractor_lists_resume_without_downloading_before_release(self):
        self.client.force_authenticate(self.contractor)

        list_response = self.client.get("/api/accounts/professionals/")
        download_response = self.client.get(
            f"/api/accounts/professionals/{self.professional.id}/resume/"
        )

        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data["count"], 1)
        self.assertIsNone(list_response.data["results"][0]["email"])
        self.assertIsNone(list_response.data["results"][0]["resume_download_url"])
        self.assertEqual(download_response.status_code, status.HTTP_403_FORBIDDEN)

    def test_contractor_downloads_resume_after_contact_release(self):
        ContactRequest.objects.create(
            company=self.contractor,
            professional=self.professional,
            objective=self.objective,
            status=ContactRequest.Status.APPROVED,
        )
        self.client.force_authenticate(self.contractor)

        download_response = self.client.get(
            f"/api/accounts/professionals/{self.professional.id}/resume/"
        )
        downloaded_content = b"".join(download_response.streaming_content)
        download_response.close()

        self.assertEqual(download_response.status_code, status.HTTP_200_OK)
        self.assertIn(
            "attachment",
            download_response["Content-Disposition"],
        )
        self.assertTrue(downloaded_content.startswith(b"%PDF"))

    def test_professional_cannot_list_other_resumes(self):
        self.client.force_authenticate(self.professional)

        response = self.client.get("/api/accounts/professionals/")

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_lists_and_publishes_review_profiles(self):
        admin = User.objects.create_user(
            email="admin@example.com",
            display_name="Admin",
            phone="+5511777777777",
            account_type=User.AccountType.PROFESSIONAL,
            is_staff=True,
            password="senha-segura-123",
        )
        self.profile.catalog_status = ProfessionalProfile.CatalogStatus.REVIEW
        self.profile.verified_by_apelmat = False
        self.profile.profile_visible = True
        self.profile.save()
        self.client.force_authenticate(admin)

        list_response = self.client.get("/api/accounts/professionals/")
        publish_response = self.client.post(
            f"/api/accounts/professionals/{self.professional.id}/publish/"
        )

        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data["count"], 1)
        self.assertEqual(
            list_response.data["results"][0]["catalog_status"],
            ProfessionalProfile.CatalogStatus.REVIEW,
        )
        self.assertEqual(publish_response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            publish_response.data["catalog_status"],
            ProfessionalProfile.CatalogStatus.PUBLISHED,
        )
        self.assertTrue(publish_response.data["verified_by_apelmat"])

    def test_admin_profile_never_enters_professional_directory(self):
        admin = User.objects.create_user(
            email="admin@example.com",
            display_name="Admin",
            phone="+5511777777777",
            account_type=User.AccountType.PROFESSIONAL,
            is_staff=True,
            password="senha-segura-123",
        )
        ProfessionalProfile.objects.create(
            user=admin,
            city="Sao Paulo",
            state="SP",
            profile_visible=True,
            catalog_status=ProfessionalProfile.CatalogStatus.PUBLISHED,
            verified_by_apelmat=True,
        )
        self.client.force_authenticate(admin)

        response = self.client.get("/api/accounts/professionals/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["count"], 1)
        self.assertEqual(response.data["results"][0]["display_name"], "Pessoa Profissional")
