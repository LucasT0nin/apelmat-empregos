from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils import timezone

from .models import ContractorProfile, ProfessionalProfile, User
from marketplace.models import Notification


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    ordering = ("email",)
    list_display = (
        "email",
        "display_name",
        "account_type",
        "is_verified",
        "is_staff",
        "is_active",
    )
    search_fields = ("email", "display_name", "phone")
    fieldsets = (
        (None, {"fields": ("email", "password")}),
        (
            "Dados pessoais",
            {
                "fields": (
                    "display_name",
                    "phone",
                    "account_type",
                    "is_verified",
                )
            },
        ),
        (
            "Permissoes",
            {
                "fields": (
                    "is_active",
                    "is_staff",
                    "is_superuser",
                    "groups",
                    "user_permissions",
                )
            },
        ),
        ("Datas", {"fields": ("last_login", "date_joined")}),
    )
    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": (
                    "email",
                    "display_name",
                    "password1",
                    "password2",
                ),
            },
        ),
    )


@admin.register(ProfessionalProfile)
class ProfessionalProfileAdmin(admin.ModelAdmin):
    list_display = (
        "user",
        "city",
        "state",
        "catalog_status",
        "verified_by_apelmat",
        "profile_visible",
        "updated_at",
    )
    list_filter = (
        "catalog_status",
        "verified_by_apelmat",
        "profile_visible",
        "state",
    )
    search_fields = (
        "user__display_name",
        "user__email",
        "user__phone",
        "headline",
        "bio",
        "city",
    )
    readonly_fields = ("reviewed_by", "reviewed_at", "created_at", "updated_at")
    actions = ("publish_profiles", "pause_profiles", "send_to_review")

    @admin.action(description="Publicar/verificar curriculos selecionados")
    def publish_profiles(self, request, queryset):
        now = timezone.now()
        updated = queryset.update(
            catalog_status=ProfessionalProfile.CatalogStatus.PUBLISHED,
            verified_by_apelmat=True,
            reviewed_by=request.user,
            reviewed_at=now,
            profile_visible=True,
        )
        for profile in queryset.select_related("user"):
            Notification.objects.create(
                recipient=profile.user,
                kind=Notification.Kind.PROFILE_REVIEW,
                professional=profile.user,
                title="Curriculo publicado",
                body=(
                    "Seu curriculo foi verificado pela Apelmat e publicado "
                    "no catalogo para empresas associadas."
                ),
            )
        self.message_user(request, f"{updated} curriculo(s) publicado(s).")

    @admin.action(description="Pausar curriculos selecionados")
    def pause_profiles(self, request, queryset):
        updated = queryset.update(
            catalog_status=ProfessionalProfile.CatalogStatus.PAUSED,
            profile_visible=False,
            verified_by_apelmat=False,
        )
        self.message_user(request, f"{updated} curriculo(s) pausado(s).")

    @admin.action(description="Enviar curriculos selecionados para analise")
    def send_to_review(self, request, queryset):
        updated = queryset.update(
            catalog_status=ProfessionalProfile.CatalogStatus.REVIEW,
            verified_by_apelmat=False,
        )
        self.message_user(request, f"{updated} curriculo(s) em analise.")


@admin.register(ContractorProfile)
class ContractorProfileAdmin(admin.ModelAdmin):
    list_display = ("company_name", "user", "city", "state", "updated_at")
    search_fields = (
        "company_name",
        "document",
        "user__display_name",
        "user__email",
        "user__phone",
    )
    list_filter = ("state",)
