from django.db.models import Q
from django.utils import timezone
from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from .models import (
    ContactRequest,
    Notification,
    ProfessionalObjective,
    ServiceCategory,
)
from .serializers import (
    ContactRequestSerializer,
    NotificationSerializer,
    ProfessionalObjectiveSerializer,
    ServiceCategorySerializer,
)


class ServiceCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = ServiceCategory.objects.filter(is_active=True)
    serializer_class = ServiceCategorySerializer
    permission_classes = (permissions.AllowAny,)
    pagination_class = None


class ProfessionalObjectiveViewSet(viewsets.ModelViewSet):
    serializer_class = ProfessionalObjectiveSerializer
    filterset_fields = ("role", "status")
    search_fields = ("summary",)
    ordering_fields = ("created_at", "updated_at")

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return ProfessionalObjective.objects.none()
        user = self.request.user
        queryset = ProfessionalObjective.objects.select_related(
            "professional"
        ).order_by("role")
        if user.is_staff:
            return queryset
        return queryset.filter(professional=user)

    def get_permissions(self):
        return [permissions.IsAuthenticated()]

    @action(detail=False, methods=("get",))
    def mine(self, request):
        queryset = self.get_queryset().filter(professional=request.user)
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page or queryset, many=True)
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return Response(serializer.data)

    @action(detail=True, methods=("post",))
    def publish(self, request, pk=None):
        return self._set_admin_status(
            request,
            status_value=ProfessionalObjective.Status.PUBLISHED,
            title="Area profissional publicada",
            body_template=(
                "Sua area {role} foi aprovada e publicada no catalogo da Apelmat."
            ),
        )

    @action(detail=True, methods=("post",))
    def reject(self, request, pk=None):
        return self._set_admin_status(
            request,
            status_value=ProfessionalObjective.Status.REJECTED,
            title="Area profissional recusada",
            body_template=(
                "A Apelmat analisou sua area {role} e nao publicou agora."
            ),
        )

    @action(detail=True, methods=("post",))
    def review(self, request, pk=None):
        return self._set_admin_status(
            request,
            status_value=ProfessionalObjective.Status.REVIEW,
            title="Area profissional em analise",
            body_template="Sua area {role} voltou para analise da Apelmat.",
        )

    def _set_admin_status(self, request, *, status_value, title, body_template):
        if not request.user.is_staff:
            raise PermissionDenied("Somente administradores podem fazer isso.")
        objective = self.get_object()
        objective.status = status_value
        objective.reviewed_by = request.user
        objective.reviewed_at = timezone.now()
        objective.save(
            update_fields=("status", "reviewed_by", "reviewed_at", "updated_at")
        )
        Notification.objects.create(
            recipient=objective.professional,
            kind=Notification.Kind.PROFILE_REVIEW,
            professional=objective.professional,
            title=title,
            body=body_template.format(role=objective.get_role_display()),
        )
        return Response(self.get_serializer(objective).data)


class ContactRequestViewSet(viewsets.ModelViewSet):
    serializer_class = ContactRequestSerializer
    http_method_names = ("get", "post", "head", "options")
    filterset_fields = ("status", "professional", "objective")
    search_fields = (
        "professional__display_name",
        "company__display_name",
        "company__contractor_profile__company_name",
    )
    ordering_fields = ("created_at", "updated_at", "decided_at")

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return ContactRequest.objects.none()
        user = self.request.user
        queryset = ContactRequest.objects.select_related(
            "company",
            "company__contractor_profile",
            "professional",
            "professional__professional_profile",
            "objective",
        )
        if user.is_staff:
            return queryset
        return queryset.filter(Q(company=user) | Q(professional=user))

    def get_permissions(self):
        return [permissions.IsAuthenticated()]

    @action(detail=False, methods=("get",))
    def mine(self, request):
        queryset = self.get_queryset().filter(company=request.user)
        page = self.paginate_queryset(queryset)
        serializer = self.get_serializer(page or queryset, many=True)
        if page is not None:
            return self.get_paginated_response(serializer.data)
        return Response(serializer.data)

    @action(detail=True, methods=("post",))
    def approve(self, request, pk=None):
        return self._set_admin_status(request, ContactRequest.Status.APPROVED)

    @action(detail=True, methods=("post",))
    def reject(self, request, pk=None):
        return self._set_admin_status(request, ContactRequest.Status.REJECTED)

    def _set_admin_status(self, request, status_value):
        if not request.user.is_staff:
            raise PermissionDenied("Somente administradores podem fazer isso.")
        contact_request = self.get_object()
        previous_status = contact_request.status
        contact_request.status = status_value
        contact_request.decided_by = request.user
        contact_request.decided_at = timezone.now()
        contact_request.save(
            update_fields=("status", "decided_by", "decided_at", "updated_at")
        )
        if previous_status != status_value:
            self._notify_decision(contact_request)
        return Response(self.get_serializer(contact_request).data)

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


class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    filterset_fields = ("is_read", "kind")
    ordering_fields = ("created_at",)

    def get_queryset(self):
        if getattr(self, "swagger_fake_view", False):
            return Notification.objects.none()
        return Notification.objects.filter(recipient=self.request.user)

    @action(detail=True, methods=("post",), url_path="read")
    def mark_read(self, request, pk=None):
        notification = self.get_object()
        notification.is_read = True
        notification.save(update_fields=("is_read",))
        return Response(self.get_serializer(notification).data)

    @action(detail=False, methods=("post",), url_path="read-all")
    def mark_all_read(self, request):
        updated = self.get_queryset().filter(is_read=False).update(is_read=True)
        return Response({"updated": updated})
