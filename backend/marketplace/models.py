import uuid

from django.conf import settings
from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models


class ServiceCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=120, unique=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ("name",)
        verbose_name_plural = "service categories"

    def __str__(self):
        return self.name


class Skill(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, unique=True)
    category = models.ForeignKey(
        ServiceCategory,
        on_delete=models.PROTECT,
        related_name="skills",
    )

    class Meta:
        ordering = ("name",)

    def __str__(self):
        return self.name


class ProfessionalSkill(models.Model):
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="professional_skills",
    )
    skill = models.ForeignKey(
        Skill,
        on_delete=models.CASCADE,
        related_name="professionals",
    )
    years = models.PositiveSmallIntegerField(
        default=0,
        validators=[MaxValueValidator(80)],
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=("professional", "skill"),
                name="unique_professional_skill",
            )
        ]


class ProfessionalObjective(models.Model):
    class Role(models.TextChoices):
        OPERATOR = "operador", "Operador"
        TRUCK_DRIVER = "motorista_caminhao", "Motorista de caminhao"
        FOREMAN = "encarregado", "Encarregado"
        ENGINEER = "engenheiro", "Engenheiro"
        OTHER = "outros", "Outros"

    class Status(models.TextChoices):
        DRAFT = "draft", "Rascunho"
        REVIEW = "review", "Em analise"
        PUBLISHED = "published", "Publicado"
        PAUSED = "paused", "Pausado"
        REJECTED = "rejected", "Recusado"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="professional_objectives",
    )
    role = models.CharField(max_length=30, choices=Role.choices)
    summary = models.CharField(max_length=180, blank=True)
    salary_expectation = models.CharField(max_length=80, blank=True)
    availability = models.CharField(max_length=120, blank=True)
    answers = models.JSONField(default=dict, blank=True)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.REVIEW,
    )
    admin_notes = models.TextField(blank=True)
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reviewed_professional_objectives",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("role",)
        verbose_name = "01. Area profissional"
        verbose_name_plural = "01. Areas profissionais"
        constraints = [
            models.UniqueConstraint(
                fields=("professional", "role"),
                name="unique_professional_objective_role",
            )
        ]
        indexes = [
            models.Index(fields=("role", "status")),
            models.Index(fields=("professional", "status")),
        ]

    def __str__(self):
        return f"{self.professional} - {self.get_role_display()}"


class Opportunity(models.Model):
    class ListingType(models.TextChoices):
        WORK_OFFER = "work_offer", "Profissional oferecendo trabalho"
        HIRING = "hiring", "Contratante buscando profissional"

    class Kind(models.TextChoices):
        JOB = "job", "Emprego"
        SERVICE = "service", "Servico"

    class Status(models.TextChoices):
        DRAFT = "draft", "Rascunho"
        PUBLISHED = "published", "Publicada"
        CLOSED = "closed", "Encerrada"
        CANCELLED = "cancelled", "Cancelada"

    class BudgetType(models.TextChoices):
        FIXED = "fixed", "Valor fechado"
        HOURLY = "hourly", "Por hora"
        NEGOTIABLE = "negotiable", "A combinar"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="opportunities",
    )
    category = models.ForeignKey(
        ServiceCategory,
        on_delete=models.PROTECT,
        related_name="opportunities",
    )
    listing_type = models.CharField(
        max_length=20,
        choices=ListingType.choices,
        default=ListingType.HIRING,
    )
    kind = models.CharField(
        max_length=20,
        choices=Kind.choices,
        default=Kind.SERVICE,
    )
    title = models.CharField(max_length=140)
    description = models.TextField()
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=2)
    budget_type = models.CharField(
        max_length=20,
        choices=BudgetType.choices,
        default=BudgetType.NEGOTIABLE,
    )
    budget_min = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
    )
    budget_max = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.DRAFT,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    published_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-created_at",)
        indexes = [
            models.Index(fields=("status", "state", "city")),
            models.Index(fields=("category", "status")),
            models.Index(fields=("listing_type", "status")),
        ]

    def __str__(self):
        return self.title


class Application(models.Model):
    class Status(models.TextChoices):
        SUBMITTED = "submitted", "Enviada"
        REVIEWING = "reviewing", "Em analise"
        ACCEPTED = "accepted", "Aceita"
        REJECTED = "rejected", "Recusada"
        WITHDRAWN = "withdrawn", "Retirada"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    opportunity = models.ForeignKey(
        Opportunity,
        on_delete=models.CASCADE,
        related_name="applications",
    )
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="applications",
    )
    cover_letter = models.TextField(blank=True)
    proposed_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.SUBMITTED,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-created_at",)
        constraints = [
            models.UniqueConstraint(
                fields=("opportunity", "professional"),
                name="unique_application_per_professional",
            )
        ]

    def __str__(self):
        return f"{self.professional} -> {self.opportunity}"


class ContactRequest(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Em analise"
        APPROVED = "approved", "Contato liberado"
        REJECTED = "rejected", "Recusado"
        CANCELLED = "cancelled", "Cancelado"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    company = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="contact_requests_made",
    )
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="contact_requests_received",
    )
    objective = models.ForeignKey(
        ProfessionalObjective,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="contact_requests",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )
    admin_notes = models.TextField(blank=True)
    release_notes = models.TextField(blank=True)
    decided_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="contact_requests_decided",
    )
    decided_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-created_at",)
        verbose_name = "02. Solicitacao de contato"
        verbose_name_plural = "02. Solicitacoes de contato"
        indexes = [
            models.Index(fields=("company", "status", "-created_at")),
            models.Index(fields=("professional", "status", "-created_at")),
        ]

    def __str__(self):
        return (
            f"{self.company} solicitou contato de "
            f"{self.professional} ({self.get_status_display()})"
        )


class Notification(models.Model):
    class Kind(models.TextChoices):
        NEW_RESUME = "new_resume", "Novo curriculo"
        NEW_OPPORTUNITY = "new_opportunity", "Nova oportunidade"
        APPLICATION = "application", "Candidatura"
        APPLICATION_STATUS = "application_status", "Status da candidatura"
        PROFILE_REVIEW = "profile_review", "Analise de curriculo"
        CONTACT_REQUEST = "contact_request", "Solicitacao de contato"
        CONTACT_RELEASED = "contact_released", "Contato liberado"
        CONTACT_REJECTED = "contact_rejected", "Contato recusado"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    kind = models.CharField(max_length=30, choices=Kind.choices)
    title = models.CharField(max_length=160)
    body = models.TextField()
    opportunity = models.ForeignKey(
        Opportunity,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    professional = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="professional_notifications",
    )
    contact_request = models.ForeignKey(
        "marketplace.ContactRequest",
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ("-created_at",)
        verbose_name = "03. Aviso"
        verbose_name_plural = "03. Avisos"
        indexes = [
            models.Index(fields=("recipient", "is_read", "-created_at")),
        ]

    def __str__(self):
        return f"{self.recipient}: {self.title}"
