from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from accounts.models import ContractorProfile, ProfessionalProfile, User

from .models import ContactRequest, Notification, ProfessionalObjective


class ControlledCatalogFlowTests(APITestCase):
    def setUp(self):
        self.admin = User.objects.create_user(
            email="admin@example.com",
            display_name="Admin",
            phone="+5511999999999",
            account_type=User.AccountType.PROFESSIONAL,
            is_staff=True,
            password="senha-segura-123",
        )
        self.contractor = User.objects.create_user(
            email="contratante@example.com",
            display_name="Contratante",
            phone="+5511999999998",
            account_type=User.AccountType.CONTRACTOR,
            password="senha-segura-123",
        )
        ContractorProfile.objects.create(
            user=self.contractor,
            company_name="Empresa Teste",
            city="Sao Paulo",
            state="SP",
        )
        self.professional = User.objects.create_user(
            email="profissional@example.com",
            display_name="Profissional",
            phone="+5511888888888",
            account_type=User.AccountType.PROFESSIONAL,
            password="senha-segura-123",
        )
        ProfessionalProfile.objects.create(
            user=self.professional,
            headline="Operador experiente",
            bio="Experiencia em equipamentos e rotinas de obra.",
            city="Sao Paulo",
            state="SP",
            years_of_experience=6,
            profile_visible=True,
            catalog_status=ProfessionalProfile.CatalogStatus.PUBLISHED,
            verified_by_apelmat=True,
            reviewed_at=timezone.now(),
        )
        self.objective = ProfessionalObjective.objects.create(
            professional=self.professional,
            role=ProfessionalObjective.Role.OPERATOR,
            summary="Operador de maquinas com foco em seguranca.",
            salary_expectation="A combinar",
            availability="Disponivel para conversa",
            answers={"equipamentos": "Retroescavadeira e pa carregadeira"},
            status=ProfessionalObjective.Status.PUBLISHED,
            reviewed_at=timezone.now(),
        )

    def test_contractor_sees_catalog_without_contact_data(self):
        self.client.force_authenticate(self.contractor)

        response = self.client.get("/api/accounts/professionals/")

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        item = response.data["results"][0]
        self.assertEqual(item["display_name"], self.professional.display_name)
        self.assertIsNone(item["email"])
        self.assertIsNone(item["phone"])
        self.assertIsNone(item["resume_download_url"])
        self.assertTrue(item["verified_by_apelmat"])
        self.assertEqual(item["objectives"][0]["role"], "operador")

    def test_contractor_requests_contact_with_one_click(self):
        self.client.force_authenticate(self.contractor)

        response = self.client.post(
            "/api/marketplace/contact-requests/",
            {
                "professional": str(self.professional.id),
                "objective": str(self.objective.id),
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["status"], ContactRequest.Status.PENDING)
        self.assertEqual(ContactRequest.objects.count(), 1)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.admin,
                kind=Notification.Kind.CONTACT_REQUEST,
            ).exists()
        )

    def test_approved_request_releases_contact_data(self):
        ContactRequest.objects.create(
            company=self.contractor,
            professional=self.professional,
            objective=self.objective,
            status=ContactRequest.Status.APPROVED,
            decided_by=self.admin,
            decided_at=timezone.now(),
        )
        self.client.force_authenticate(self.contractor)

        response = self.client.get("/api/accounts/professionals/")

        item = response.data["results"][0]
        self.assertEqual(item["email"], self.professional.email)
        self.assertEqual(item["phone"], self.professional.phone)
        self.assertEqual(item["contact_request_status"], "approved")

    def test_professional_can_register_up_to_three_objectives(self):
        self.client.force_authenticate(self.professional)
        for role in (
            ProfessionalObjective.Role.TRUCK_DRIVER,
            ProfessionalObjective.Role.FOREMAN,
        ):
            response = self.client.post(
                "/api/marketplace/professional-objectives/",
                {
                    "role": role,
                    "summary": "Resumo profissional completo.",
                    "salary_expectation": "A combinar",
                    "availability": "Imediata",
                    "answers": {"experiencia": "Boa experiencia"},
                },
                format="json",
            )
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        response = self.client.post(
            "/api/marketplace/professional-objectives/",
            {
                "role": ProfessionalObjective.Role.ENGINEER,
                "summary": "Resumo profissional completo.",
                "salary_expectation": "A combinar",
                "availability": "Imediata",
                "answers": {"experiencia": "Boa experiencia"},
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_professional_cannot_consult_catalog(self):
        self.client.force_authenticate(self.professional)

        response = self.client.get("/api/accounts/professionals/")

        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_old_opportunity_endpoint_is_not_available(self):
        self.client.force_authenticate(self.contractor)

        response = self.client.post(
            "/api/marketplace/opportunities/",
            {
                "title": "Vaga operacional",
                "description": "Empresa tentando publicar direto.",
                "city": "Sao Paulo",
                "state": "SP",
                "status": "published",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_contact_request_cannot_be_deleted_by_company(self):
        contact_request = ContactRequest.objects.create(
            company=self.contractor,
            professional=self.professional,
            objective=self.objective,
            status=ContactRequest.Status.PENDING,
        )
        self.client.force_authenticate(self.contractor)

        response = self.client.delete(
            f"/api/marketplace/contact-requests/{contact_request.id}/"
        )

        self.assertEqual(response.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)
        self.assertTrue(ContactRequest.objects.filter(id=contact_request.id).exists())

    def test_health_endpoint_checks_database_without_authentication(self):
        self.client.logout()

        response = self.client.get("/api/health/")
        payload = response.json()

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(payload["status"], "ok")
        self.assertEqual(payload["database"], "ok")

    def test_admin_publishes_professional_objective_from_app_api(self):
        self.objective.status = ProfessionalObjective.Status.REVIEW
        self.objective.save(update_fields=("status",))
        self.client.force_authenticate(self.admin)

        response = self.client.post(
            f"/api/marketplace/professional-objectives/{self.objective.id}/publish/"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], ProfessionalObjective.Status.PUBLISHED)
        self.assertEqual(response.data["professional_name"], self.professional.display_name)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.professional,
                kind=Notification.Kind.PROFILE_REVIEW,
            ).exists()
        )

    def test_admin_approves_contact_request_from_app_api(self):
        contact_request = ContactRequest.objects.create(
            company=self.contractor,
            professional=self.professional,
            objective=self.objective,
            status=ContactRequest.Status.PENDING,
        )
        self.client.force_authenticate(self.admin)

        response = self.client.post(
            f"/api/marketplace/contact-requests/{contact_request.id}/approve/"
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["status"], ContactRequest.Status.APPROVED)
        self.assertEqual(response.data["professional_phone"], self.professional.phone)
        self.assertEqual(response.data["company_phone"], self.contractor.phone)
        self.assertTrue(
            Notification.objects.filter(
                recipient=self.contractor,
                kind=Notification.Kind.CONTACT_RELEASED,
            ).exists()
        )
