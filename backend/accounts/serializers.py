from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.utils import timezone
from drf_spectacular.utils import extend_schema_field
from rest_framework import serializers

from .models import ContractorProfile, ProfessionalProfile, User
from marketplace.models import ContactRequest, ProfessionalObjective


def normalize_phone(value):
    digits = "".join(character for character in value if character.isdigit())
    if len(digits) in (10, 11):
        digits = f"55{digits}"
    if not 12 <= len(digits) <= 15:
        raise serializers.ValidationError(
            "Informe um WhatsApp valido com DDD."
        )
    return f"+{digits}"


class ProfessionalProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProfessionalProfile
        fields = (
            "headline",
            "bio",
            "area",
            "city",
            "state",
            "availability",
            "years_of_experience",
            "resume",
            "profile_visible",
            "catalog_status",
            "verified_by_apelmat",
            "review_notes",
            "reviewed_at",
        )
        read_only_fields = (
            "catalog_status",
            "verified_by_apelmat",
            "review_notes",
            "reviewed_at",
        )

    def validate_resume(self, value):
        if value.size > 10 * 1024 * 1024:
            raise serializers.ValidationError(
                "O curriculo deve ter no maximo 10 MB."
            )
        if not value.name.lower().endswith(".pdf"):
            raise serializers.ValidationError(
                "Envie o curriculo no formato PDF."
            )
        signature = value.read(5)
        value.seek(0)
        if signature != b"%PDF-":
            raise serializers.ValidationError(
                "O arquivo enviado nao e um PDF valido."
            )
        return value


class ContractorProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContractorProfile
        exclude = ("id", "user", "created_at", "updated_at")
        extra_kwargs = {"document": {"write_only": True}}


class UserSerializer(serializers.ModelSerializer):
    professional_profile = ProfessionalProfileSerializer(read_only=True)
    contractor_profile = ContractorProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "display_name",
            "phone",
            "account_type",
            "is_verified",
            "is_staff",
            "professional_profile",
            "contractor_profile",
            "created_at",
        )
        read_only_fields = (
            "id",
            "account_type",
            "is_verified",
            "is_staff",
            "created_at",
        )

    def validate_phone(self, value):
        return normalize_phone(value)


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    phone = serializers.CharField(required=True, allow_blank=False)
    accept_terms = serializers.BooleanField(write_only=True)

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "display_name",
            "phone",
            "account_type",
            "accept_terms",
            "password",
        )
        read_only_fields = ("id",)

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate_account_type(self, value):
        if value != User.AccountType.PROFESSIONAL:
            raise serializers.ValidationError(
                "Cadastro pelo app e somente para quem quer trabalhar."
            )
        return value

    def validate_phone(self, value):
        return normalize_phone(value)

    def validate_accept_terms(self, value):
        if not value:
            raise serializers.ValidationError(
                "Aceite os Termos de Uso e a Politica de Privacidade."
            )
        return value

    @transaction.atomic
    def create(self, validated_data):
        password = validated_data.pop("password")
        validated_data.pop("accept_terms")
        accepted_at = timezone.now()
        validated_data["accepted_terms_at"] = accepted_at
        validated_data["accepted_privacy_at"] = accepted_at
        user = User.objects.create_user(password=password, **validated_data)
        ProfessionalProfile.objects.create(user=user)
        ContractorProfile.objects.create(user=user)
        return user


class AdminContractorCreateSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    phone = serializers.CharField(required=True, allow_blank=False)
    company_name = serializers.CharField(write_only=True, required=True)
    city = serializers.CharField(write_only=True, required=False, allow_blank=True)
    state = serializers.CharField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = User
        fields = (
            "id",
            "email",
            "display_name",
            "phone",
            "company_name",
            "city",
            "state",
            "password",
        )
        read_only_fields = ("id",)

    def validate_password(self, value):
        validate_password(value)
        return value

    def validate_phone(self, value):
        return normalize_phone(value)

    def validate_state(self, value):
        return value.strip().upper()

    @transaction.atomic
    def create(self, validated_data):
        password = validated_data.pop("password")
        company_name = validated_data.pop("company_name").strip()
        city = validated_data.pop("city", "").strip()
        state = validated_data.pop("state", "").strip().upper()
        now = timezone.now()
        user = User.objects.create_user(
            password=password,
            account_type=User.AccountType.CONTRACTOR,
            accepted_terms_at=now,
            accepted_privacy_at=now,
            **validated_data,
        )
        ProfessionalProfile.objects.create(user=user, profile_visible=False)
        ContractorProfile.objects.create(
            user=user,
            company_name=company_name,
            city=city,
            state=state,
        )
        return user


class ProfessionalDirectorySerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    display_name = serializers.CharField(
        source="user.display_name", read_only=True
    )
    email = serializers.EmailField(source="user.email", read_only=True)
    phone = serializers.CharField(source="user.phone", read_only=True)
    verified_by_apelmat = serializers.BooleanField(read_only=True)
    catalog_status = serializers.CharField(read_only=True)
    catalog_status_label = serializers.CharField(
        source="get_catalog_status_display",
        read_only=True,
    )
    objectives = serializers.SerializerMethodField()
    contact_request_id = serializers.SerializerMethodField()
    contact_request_status = serializers.SerializerMethodField()
    contact_request_status_label = serializers.SerializerMethodField()
    has_resume = serializers.SerializerMethodField()
    resume_download_url = serializers.SerializerMethodField()

    class Meta:
        model = ProfessionalProfile
        fields = (
            "user_id",
            "display_name",
            "email",
            "phone",
            "headline",
            "bio",
            "city",
            "state",
            "availability",
            "years_of_experience",
            "verified_by_apelmat",
            "catalog_status",
            "catalog_status_label",
            "objectives",
            "contact_request_id",
            "contact_request_status",
            "contact_request_status_label",
            "has_resume",
            "resume_download_url",
            "updated_at",
        )

    def _contact_request(self, obj):
        request = self.context.get("request")
        if not request or not request.user.is_authenticated:
            return None
        if request.user.is_staff:
            return None
        return (
            ContactRequest.objects.filter(
                company=request.user,
                professional=obj.user,
            )
            .order_by("-created_at")
            .first()
        )

    def _contact_released(self, obj) -> bool:
        request = self.context.get("request")
        if request and request.user.is_staff:
            return True
        contact_request = self._contact_request(obj)
        return (
            contact_request is not None
            and contact_request.status == ContactRequest.Status.APPROVED
        )

    def to_representation(self, instance):
        data = super().to_representation(instance)
        if not self._contact_released(instance):
            data["email"] = None
            data["phone"] = None
        return data

    @extend_schema_field(serializers.ListField(child=serializers.DictField()))
    def get_objectives(self, obj) -> list[dict[str, object]]:
        request = self.context.get("request")
        objectives = obj.user.professional_objectives.order_by("role")
        if not (request and request.user.is_staff):
            objectives = objectives.filter(status=ProfessionalObjective.Status.PUBLISHED)
        return [
            {
                "id": str(objective.id),
                "role": objective.role,
                "role_label": objective.get_role_display(),
                "summary": objective.summary,
                "salary_expectation": objective.salary_expectation,
                "availability": objective.availability,
                "answers": objective.answers,
                "status": objective.status,
                "status_label": objective.get_status_display(),
            }
            for objective in objectives
        ]

    def get_contact_request_id(self, obj) -> str | None:
        contact_request = self._contact_request(obj)
        return str(contact_request.id) if contact_request else None

    def get_contact_request_status(self, obj) -> str | None:
        contact_request = self._contact_request(obj)
        return contact_request.status if contact_request else None

    def get_contact_request_status_label(self, obj) -> str | None:
        contact_request = self._contact_request(obj)
        return contact_request.get_status_display() if contact_request else None

    def get_has_resume(self, obj) -> bool:
        return bool(obj.resume)

    def get_resume_download_url(self, obj) -> str | None:
        if not obj.resume or not self._contact_released(obj):
            return None
        request = self.context.get("request")
        path = f"/api/accounts/professionals/{obj.user_id}/resume/"
        return request.build_absolute_uri(path) if request else path
