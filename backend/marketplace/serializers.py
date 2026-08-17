from django.utils import timezone
from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import (
    ContactRequest,
    Notification,
    ProfessionalObjective,
    ServiceCategory,
)


class ServiceCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceCategory
        fields = ("id", "name", "slug")


class ProfessionalObjectiveSerializer(serializers.ModelSerializer):
    professional_id = serializers.UUIDField(
        source="professional.id",
        read_only=True,
    )
    professional_name = serializers.CharField(
        source="professional.display_name",
        read_only=True,
    )
    professional_email = serializers.EmailField(
        source="professional.email",
        read_only=True,
    )
    professional_phone = serializers.CharField(
        source="professional.phone",
        read_only=True,
    )
    role_label = serializers.CharField(source="get_role_display", read_only=True)
    status_label = serializers.CharField(source="get_status_display", read_only=True)

    class Meta:
        model = ProfessionalObjective
        fields = (
            "id",
            "professional_id",
            "professional_name",
            "professional_email",
            "professional_phone",
            "role",
            "role_label",
            "summary",
            "salary_expectation",
            "availability",
            "answers",
            "status",
            "status_label",
            "admin_notes",
            "created_at",
            "updated_at",
        )
        read_only_fields = (
            "id",
            "professional_id",
            "professional_name",
            "professional_email",
            "professional_phone",
            "status",
            "status_label",
            "admin_notes",
            "created_at",
            "updated_at",
        )

    def validate(self, attrs):
        request = self.context["request"]
        user = request.user
        if user.is_staff or user.account_type != "professional":
            raise serializers.ValidationError(
                "Sua conta precisa estar habilitada como profissional."
            )
        queryset = ProfessionalObjective.objects.filter(professional=user)
        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)
        if not self.instance and queryset.count() >= 3:
            raise serializers.ValidationError(
                "Voce pode publicar no maximo 3 areas de trabalho."
            )
        role = attrs.get("role", getattr(self.instance, "role", None))
        if queryset.filter(role=role).exists():
            raise serializers.ValidationError(
                {"role": "Voce ja cadastrou esta area de trabalho."}
            )
        return attrs

    def create(self, validated_data):
        return ProfessionalObjective.objects.create(
            professional=self.context["request"].user,
            status=ProfessionalObjective.Status.REVIEW,
            **validated_data,
        )

    def update(self, instance, validated_data):
        for field, value in validated_data.items():
            setattr(instance, field, value)
        instance.status = ProfessionalObjective.Status.REVIEW
        instance.save()
        return instance


class ContactRequestSerializer(serializers.ModelSerializer):
    professional = serializers.UUIDField(write_only=True)
    objective = serializers.PrimaryKeyRelatedField(
        queryset=ProfessionalObjective.objects.all(),
        allow_null=True,
        required=False,
    )
    company_id = serializers.UUIDField(source="company.id", read_only=True)
    company_name = serializers.CharField(
        source="company.contractor_profile.company_name",
        read_only=True,
    )
    company_email = serializers.SerializerMethodField()
    company_phone = serializers.SerializerMethodField()
    professional_id = serializers.UUIDField(
        source="professional.id", read_only=True
    )
    professional_name = serializers.CharField(
        source="professional.display_name", read_only=True
    )
    professional_city = serializers.CharField(
        source="professional.professional_profile.city", read_only=True
    )
    professional_state = serializers.CharField(
        source="professional.professional_profile.state", read_only=True
    )
    role = serializers.CharField(source="objective.role", read_only=True)
    role_label = serializers.CharField(
        source="objective.get_role_display", read_only=True
    )
    status_label = serializers.CharField(source="get_status_display", read_only=True)
    professional_email = serializers.SerializerMethodField()
    professional_phone = serializers.SerializerMethodField()
    resume_download_url = serializers.SerializerMethodField()

    class Meta:
        model = ContactRequest
        fields = (
            "id",
            "company_id",
            "company_name",
            "company_email",
            "company_phone",
            "professional",
            "professional_id",
            "professional_name",
            "professional_city",
            "professional_state",
            "objective",
            "role",
            "role_label",
            "status",
            "status_label",
            "professional_email",
            "professional_phone",
            "resume_download_url",
            "release_notes",
            "created_at",
            "updated_at",
            "decided_at",
        )
        read_only_fields = (
            "id",
            "company_id",
            "company_name",
            "company_email",
            "company_phone",
            "professional_id",
            "professional_name",
            "professional_city",
            "professional_state",
            "role",
            "role_label",
            "status",
            "status_label",
            "professional_email",
            "professional_phone",
            "resume_download_url",
            "release_notes",
            "created_at",
            "updated_at",
            "decided_at",
        )

    def _released(self, obj):
        request = self.context.get("request")
        return obj.status == ContactRequest.Status.APPROVED or (
            request and request.user.is_staff
        )

    def _staff_user(self):
        request = self.context.get("request")
        return bool(request and request.user.is_staff)

    def get_company_email(self, obj) -> str | None:
        return obj.company.email if self._staff_user() else None

    def get_company_phone(self, obj) -> str | None:
        return obj.company.phone if self._staff_user() else None

    def get_professional_email(self, obj) -> str | None:
        return obj.professional.email if self._released(obj) else None

    def get_professional_phone(self, obj) -> str | None:
        return obj.professional.phone if self._released(obj) else None

    def get_resume_download_url(self, obj) -> str | None:
        if not self._released(obj):
            return None
        try:
            has_resume = bool(obj.professional.professional_profile.resume)
        except AttributeError:
            return None
        if not has_resume:
            return None
        request = self.context.get("request")
        path = f"/api/accounts/professionals/{obj.professional_id}/resume/"
        return request.build_absolute_uri(path) if request else path

    def validate(self, attrs):
        request = self.context["request"]
        if request.user.is_staff or request.user.account_type != "contractor":
            raise serializers.ValidationError(
                "Somente empresas podem solicitar contatos."
            )
        user_model = get_user_model()
        professional_id = attrs.pop("professional", None)
        try:
            professional = user_model.objects.select_related(
                "professional_profile"
            ).get(id=professional_id, is_active=True)
        except user_model.DoesNotExist as error:
            raise serializers.ValidationError(
                {"professional": "Profissional nao encontrado."}
            ) from error
        if professional.id == request.user.id:
            raise serializers.ValidationError(
                "Voce nao pode solicitar seu proprio contato."
            )
        if professional.is_staff or professional.account_type != "professional":
            raise serializers.ValidationError(
                "Este usuario nao esta cadastrado como profissional."
            )
        try:
            profile = professional.professional_profile
        except AttributeError as error:
            raise serializers.ValidationError(
                "Este profissional ainda nao possui curriculo."
            ) from error
        if (
            not profile.profile_visible
            or profile.catalog_status != "published"
        ):
            raise serializers.ValidationError(
                "Este profissional ainda nao esta publicado no catalogo."
            )

        objective = attrs.get("objective")
        if objective and objective.professional_id != professional.id:
            raise serializers.ValidationError(
                {"objective": "Esta area nao pertence ao profissional."}
            )
        if objective and objective.status != ProfessionalObjective.Status.PUBLISHED:
            raise serializers.ValidationError(
                {"objective": "Esta area ainda nao foi aprovada pela Apelmat."}
            )

        duplicate = ContactRequest.objects.filter(
            company=request.user,
            professional=professional,
            status__in=(
                ContactRequest.Status.PENDING,
                ContactRequest.Status.APPROVED,
            ),
        )
        if duplicate.exists():
            raise serializers.ValidationError(
                "Voce ja possui uma solicitacao ativa para este profissional."
            )
        attrs["professional"] = professional
        return attrs

    def create(self, validated_data):
        request = self.context["request"]
        contact_request = ContactRequest.objects.create(
            company=request.user,
            status=ContactRequest.Status.PENDING,
            **validated_data,
        )
        self._notify_admins(contact_request)
        return contact_request

    def update(self, instance, validated_data):
        request = self.context["request"]
        old_status = instance.status
        instance = super().update(instance, validated_data)
        if (
            request.user.is_staff
            and instance.status != old_status
            and instance.status
            in (ContactRequest.Status.APPROVED, ContactRequest.Status.REJECTED)
        ):
            instance.decided_by = request.user
            instance.decided_at = timezone.now()
            instance.save(update_fields=("decided_by", "decided_at", "updated_at"))
            self._notify_decision(instance)
        return instance

    def _notify_admins(self, contact_request):
        user_model = get_user_model()
        recipients = user_model.objects.filter(is_staff=True, is_active=True)
        for recipient in recipients:
            Notification.objects.create(
                recipient=recipient,
                kind=Notification.Kind.CONTACT_REQUEST,
                professional=contact_request.professional,
                contact_request=contact_request,
                title="Nova solicitacao de contato",
                body=(
                    f"{contact_request.company.display_name} solicitou contato "
                    f"de {contact_request.professional.display_name}."
                ),
            )

    def _notify_decision(self, contact_request):
        if contact_request.status == ContactRequest.Status.APPROVED:
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
        elif contact_request.status == ContactRequest.Status.REJECTED:
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


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = (
            "id",
            "kind",
            "title",
            "body",
            "opportunity",
            "professional",
            "contact_request",
            "is_read",
            "created_at",
        )
        read_only_fields = (
            "id",
            "kind",
            "title",
            "body",
            "opportunity",
            "professional",
            "contact_request",
            "created_at",
        )
