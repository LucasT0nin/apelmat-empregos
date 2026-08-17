import uuid

from django.contrib.auth.models import AbstractUser
from django.db import models

from .managers import UserManager


class User(AbstractUser):
    class AccountType(models.TextChoices):
        PROFESSIONAL = "professional", "Profissional"
        CONTRACTOR = "contractor", "Contratante"
        BOTH = "both", "Ambos"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = None
    email = models.EmailField(unique=True)
    display_name = models.CharField(max_length=120)
    phone = models.CharField(max_length=30, blank=True)
    account_type = models.CharField(
        max_length=20,
        choices=AccountType.choices,
        default=AccountType.PROFESSIONAL,
    )
    is_verified = models.BooleanField(default=False)
    accepted_terms_at = models.DateTimeField(null=True, blank=True)
    accepted_privacy_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["display_name"]

    objects = UserManager()

    class Meta:
        verbose_name = "01. Usuario"
        verbose_name_plural = "01. Usuarios"

    def __str__(self):
        return f"{self.display_name} <{self.email}>"


class ProfessionalProfile(models.Model):
    class WorkArea(models.TextChoices):
        OPERATOR = "operador", "Operador"
        ADMINISTRATIVE = "administrativo", "Administrativo"
        LOGISTICS = "logistica", "Logistica"
        MAINTENANCE = "manutencao", "Manutencao"
        ELECTRICAL = "eletrica", "Eletrica"
        MECHANIC = "mecanica", "Mecanica"
        TRANSPORT = "transporte", "Transporte"
        CLEANING = "limpeza", "Limpeza"
        PRODUCTION = "producao", "Producao"
        SAFETY = "seguranca", "Seguranca"
        OTHER = "outros", "Outros"

    class Availability(models.TextChoices):
        AVAILABLE = "available", "Disponivel"
        BUSY = "busy", "Ocupado"
        UNAVAILABLE = "unavailable", "Indisponivel"

    class CatalogStatus(models.TextChoices):
        DRAFT = "draft", "Rascunho"
        REVIEW = "review", "Em analise"
        PUBLISHED = "published", "Publicado"
        PAUSED = "paused", "Pausado"
        REJECTED = "rejected", "Recusado"

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="professional_profile",
    )
    headline = models.CharField(max_length=140, blank=True)
    bio = models.TextField(blank=True)
    area = models.CharField(
        max_length=30,
        choices=WorkArea.choices,
        blank=True,
    )
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=2, blank=True)
    availability = models.CharField(
        max_length=20,
        choices=Availability.choices,
        default=Availability.AVAILABLE,
    )
    years_of_experience = models.PositiveSmallIntegerField(default=0)
    resume = models.FileField(upload_to="resumes/%Y/%m/", blank=True)
    profile_visible = models.BooleanField(default=True)
    catalog_status = models.CharField(
        max_length=20,
        choices=CatalogStatus.choices,
        default=CatalogStatus.DRAFT,
    )
    verified_by_apelmat = models.BooleanField(default=False)
    review_notes = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        "User",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reviewed_professional_profiles",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Perfil profissional de {self.user.display_name}"

    class Meta:
        verbose_name = "02. Curriculo profissional"
        verbose_name_plural = "02. Curriculos profissionais"


class ContractorProfile(models.Model):
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="contractor_profile",
    )
    company_name = models.CharField(max_length=160, blank=True)
    document = models.CharField(max_length=30, blank=True)
    city = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=2, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.company_name or self.user.display_name

    class Meta:
        verbose_name = "03. Empresa"
        verbose_name_plural = "03. Empresas"
