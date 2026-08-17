from django.contrib import admin
from django.utils import timezone
from django.utils.html import format_html
from urllib.parse import quote

from .models import (
    ContactRequest,
    Notification,
    ProfessionalObjective,
)


@admin.register(ProfessionalObjective)
class ProfessionalObjectiveAdmin(admin.ModelAdmin):
    list_display = (
        "professional",
        "role",
        "status",
        "salary_expectation",
        "availability",
        "updated_at",
    )
    list_filter = ("role", "status", "updated_at")
    search_fields = (
        "professional__display_name",
        "professional__email",
        "summary",
    )
    readonly_fields = ("reviewed_by", "reviewed_at", "created_at", "updated_at")
    actions = ("publish_objectives", "reject_objectives", "send_to_review")

    @admin.action(description="Publicar areas selecionadas")
    def publish_objectives(self, request, queryset):
        now = timezone.now()
        updated = queryset.update(
            status=ProfessionalObjective.Status.PUBLISHED,
            reviewed_by=request.user,
            reviewed_at=now,
        )
        for objective in queryset.select_related("professional"):
            Notification.objects.create(
                recipient=objective.professional,
                kind=Notification.Kind.PROFILE_REVIEW,
                professional=objective.professional,
                title="Area profissional publicada",
                body=(
                    f"Sua area {objective.get_role_display()} foi aprovada "
                    "e publicada no catalogo da Apelmat."
                ),
            )
        self.message_user(request, f"{updated} area(s) publicada(s).")

    @admin.action(description="Recusar areas selecionadas")
    def reject_objectives(self, request, queryset):
        updated = queryset.update(
            status=ProfessionalObjective.Status.REJECTED,
            reviewed_by=request.user,
            reviewed_at=timezone.now(),
        )
        self.message_user(request, f"{updated} area(s) recusada(s).")

    @admin.action(description="Voltar areas selecionadas para analise")
    def send_to_review(self, request, queryset):
        updated = queryset.update(status=ProfessionalObjective.Status.REVIEW)
        self.message_user(request, f"{updated} area(s) em analise.")


@admin.register(ContactRequest)
class ContactRequestAdmin(admin.ModelAdmin):
    list_display = (
        "company",
        "professional",
        "objective",
        "status",
        "created_at",
        "whatsapp_professional",
        "whatsapp_company",
    )
    list_filter = ("status", "created_at", "decided_at")
    search_fields = (
        "company__display_name",
        "company__email",
        "company__contractor_profile__company_name",
        "professional__display_name",
        "professional__email",
        "professional__phone",
    )
    readonly_fields = (
        "company",
        "professional",
        "objective",
        "decided_by",
        "decided_at",
        "created_at",
        "updated_at",
        "whatsapp_professional",
        "whatsapp_company",
    )
    actions = ("approve_requests", "reject_requests")

    def save_model(self, request, obj, form, change):
        old_status = None
        if change:
            old_status = (
                ContactRequest.objects.filter(pk=obj.pk)
                .values_list("status", flat=True)
                .first()
            )
        if (
            old_status != obj.status
            and obj.status
            in (ContactRequest.Status.APPROVED, ContactRequest.Status.REJECTED)
        ):
            obj.decided_by = request.user
            obj.decided_at = timezone.now()
        super().save_model(request, obj, form, change)
        if old_status == obj.status:
            return
        if obj.status == ContactRequest.Status.APPROVED:
            self._notify_approval(obj)
        elif obj.status == ContactRequest.Status.REJECTED:
            self._notify_rejection(obj)

    @admin.display(description="WhatsApp profissional")
    def whatsapp_professional(self, obj):
        return self._whatsapp_link(
            obj.professional.phone,
            (
                f"Ola, {obj.professional.display_name}. Aqui e a Apelmat "
                "Empregos. Temos uma empresa associada interessada no seu "
                "perfil. Podemos conversar?"
            ),
        )

    @admin.display(description="WhatsApp empresa")
    def whatsapp_company(self, obj):
        return self._whatsapp_link(
            obj.company.phone,
            (
                f"Ola, {obj.company.display_name}. A Apelmat analisou sua "
                f"solicitacao sobre {obj.professional.display_name}."
            ),
        )

    def _whatsapp_link(self, phone, message):
        digits = "".join(character for character in phone if character.isdigit())
        if not digits:
            return "-"
        return format_html(
            '<a href="https://wa.me/{}?text={}" target="_blank">Abrir</a>',
            digits,
            quote(message),
        )

    @admin.action(description="Liberar contato para empresas selecionadas")
    def approve_requests(self, request, queryset):
        updated = 0
        for contact_request in queryset.select_related("company", "professional"):
            if contact_request.status == ContactRequest.Status.APPROVED:
                continue
            contact_request.status = ContactRequest.Status.APPROVED
            contact_request.decided_by = request.user
            contact_request.decided_at = timezone.now()
            contact_request.save(
                update_fields=(
                    "status",
                    "decided_by",
                    "decided_at",
                    "updated_at",
                )
            )
            self._notify_approval(contact_request)
            updated += 1
        self.message_user(request, f"{updated} contato(s) liberado(s).")

    @admin.action(description="Recusar solicitacoes selecionadas")
    def reject_requests(self, request, queryset):
        updated = 0
        for contact_request in queryset.select_related("company", "professional"):
            if contact_request.status == ContactRequest.Status.REJECTED:
                continue
            contact_request.status = ContactRequest.Status.REJECTED
            contact_request.decided_by = request.user
            contact_request.decided_at = timezone.now()
            contact_request.save(
                update_fields=(
                    "status",
                    "decided_by",
                    "decided_at",
                    "updated_at",
                )
            )
            self._notify_rejection(contact_request)
            updated += 1
        self.message_user(request, f"{updated} solicitacao(oes) recusada(s).")

    def _notify_approval(self, contact_request):
        Notification.objects.create(
            recipient=contact_request.company,
            kind=Notification.Kind.CONTACT_RELEASED,
            professional=contact_request.professional,
            contact_request=contact_request,
            title="Contato liberado pela Apelmat",
            body=(
                f"O contato de {contact_request.professional.display_name} "
                "foi liberado para sua empresa."
            ),
        )
        Notification.objects.create(
            recipient=contact_request.professional,
            kind=Notification.Kind.CONTACT_RELEASED,
            professional=contact_request.professional,
            contact_request=contact_request,
            title="Seu contato foi encaminhado",
            body=(
                "A Apelmat liberou seu contato para uma empresa associada "
                "interessada no seu perfil."
            ),
        )

    def _notify_rejection(self, contact_request):
        Notification.objects.create(
            recipient=contact_request.company,
            kind=Notification.Kind.CONTACT_REJECTED,
            professional=contact_request.professional,
            contact_request=contact_request,
            title="Solicitacao analisada",
            body=(
                "A Apelmat analisou a solicitacao e nao liberou este "
                "contato agora."
            ),
        )


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = (
        "recipient",
        "kind",
        "title",
        "is_read",
        "created_at",
    )
    list_filter = ("kind", "is_read", "created_at")
    search_fields = ("recipient__email", "title", "body")
