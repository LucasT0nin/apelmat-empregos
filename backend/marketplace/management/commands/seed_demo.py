from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from accounts.models import ContractorProfile, ProfessionalProfile
from marketplace.models import ProfessionalObjective


DEMO_PASSWORD = "Teste12345!"


class Command(BaseCommand):
    help = "Cria contas e dados de demonstracao para testar o app."

    @transaction.atomic
    def handle(self, *args, **options):
        user_model = get_user_model()

        admin = self._user(
            user_model,
            email="admin@apelmat.com",
            display_name="Admin Apelmat",
            account_type="professional",
            is_staff=True,
            is_superuser=True,
        )
        contractor = self._user(
            user_model,
            email="contratante@apelmat.com",
            display_name="Contratante Teste",
            account_type="contractor",
        )
        professional = self._user(
            user_model,
            email="profissional@apelmat.com",
            display_name="Profissional Teste",
            account_type="professional",
        )
        self._disable_legacy_user(user_model, "teste@apelmat.com")

        self._profiles(admin, "Curitiba", "PR")
        self._profiles(contractor, "Curitiba", "PR")
        self._profiles(professional, "Curitiba", "PR")
        self._objective(
            professional,
            ProfessionalObjective.Role.OPERATOR,
            "Operador com experiencia em equipamentos e rotina de obra.",
        )
        self._objective(
            professional,
            ProfessionalObjective.Role.TRUCK_DRIVER,
            "Motorista de caminhao com disponibilidade para viagens curtas.",
        )

        self.stdout.write(self.style.SUCCESS("Contas de teste criadas."))
        self.stdout.write(f"Senha para todas as contas: {DEMO_PASSWORD}")

    def _user(
        self,
        user_model,
        *,
        email,
        display_name,
        account_type,
        is_staff=False,
        is_superuser=False,
    ):
        user, created = user_model.objects.get_or_create(
            email=email,
            defaults={
                "display_name": display_name,
                "account_type": account_type,
                "is_staff": is_staff,
                "is_superuser": is_superuser,
                "is_active": True,
            },
        )
        user.display_name = display_name
        user.account_type = account_type
        user.is_staff = is_staff
        user.is_superuser = is_superuser
        user.is_active = True
        user.phone = "+5511933398386"
        user.set_password(DEMO_PASSWORD)
        user.save()
        return user

    def _disable_legacy_user(self, user_model, email):
        updated = user_model.objects.filter(email=email).update(is_active=False)
        if updated:
            self.stdout.write(
                self.style.WARNING(
                    f"Conta legada {email} desativada para evitar quarto perfil."
                )
            )

    def _profiles(self, user, city, state):
        professional, _ = ProfessionalProfile.objects.get_or_create(user=user)
        professional.headline = "Profissional de apoio operacional"
        professional.bio = (
            "Perfil criado para demonstracao do aplicativo Apelmat Empregos."
        )
        professional.city = city
        professional.state = state
        professional.area = "eletrica"
        professional.years_of_experience = 5
        professional.profile_visible = (
            not user.is_staff and user.account_type == "professional"
        )
        if professional.profile_visible:
            professional.catalog_status = ProfessionalProfile.CatalogStatus.PUBLISHED
            professional.verified_by_apelmat = True
            professional.reviewed_at = timezone.now()
        else:
            professional.catalog_status = ProfessionalProfile.CatalogStatus.DRAFT
            professional.verified_by_apelmat = False
            professional.reviewed_at = None
        professional.save()

        contractor, _ = ContractorProfile.objects.get_or_create(user=user)
        contractor.company_name = "Empresa Teste Apelmat"
        contractor.city = city
        contractor.state = state
        contractor.save()

    def _objective(self, user, role, summary):
        objective, _ = ProfessionalObjective.objects.get_or_create(
            professional=user,
            role=role,
            defaults={
                "summary": summary,
                "salary_expectation": "A combinar",
                "availability": "Disponibilidade para conversar esta semana",
                "answers": self._answers(role),
                "status": ProfessionalObjective.Status.PUBLISHED,
                "reviewed_at": timezone.now(),
            },
        )
        objective.summary = summary
        objective.salary_expectation = "A combinar"
        objective.availability = "Disponibilidade para conversar esta semana"
        objective.answers = self._answers(role)
        objective.status = ProfessionalObjective.Status.PUBLISHED
        objective.reviewed_at = objective.reviewed_at or timezone.now()
        objective.save()

    def _answers(self, role):
        if role == ProfessionalObjective.Role.OPERATOR:
            return {
                "equipamentos": "Retroescavadeira, pa carregadeira e empilhadeira",
                "seguranca": "Faz checklist diario e comunica manutencao antes de operar",
                "experiencia": "5 anos em operacao e apoio de obra",
            }
        if role == ProfessionalObjective.Role.TRUCK_DRIVER:
            return {
                "cnh": "Categoria D com EAR",
                "veiculos": "Caminhao truck e toco",
                "rotina": "Entregas regionais, conferencia de carga e checklist",
            }
        if role == ProfessionalObjective.Role.FOREMAN:
            return {
                "equipe": "Ja liderou equipes de 8 a 12 pessoas",
                "rotina": "Organizacao de escala, DDS e acompanhamento de producao",
                "relatorios": "Controle diario por planilha e WhatsApp",
            }
        return {
            "crea": "Informado pelo profissional",
            "obras": "Acompanhamento tecnico e cronograma",
            "ferramentas": "Planilhas, leitura de projeto e relatorios",
        }
