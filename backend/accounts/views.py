from pathlib import Path

from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.http import FileResponse, Http404
from drf_spectacular.types import OpenApiTypes
from drf_spectacular.utils import extend_schema
from rest_framework import filters, generics, parsers, permissions, status, views
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response

from marketplace.models import ContactRequest, ProfessionalObjective
from marketplace.notifications import notify_admins_about_professional_review

from .models import ContractorProfile, ProfessionalProfile
from .serializers import (
    AdminContractorCreateSerializer,
    ContractorProfileSerializer,
    ProfessionalProfileSerializer,
    ProfessionalDirectorySerializer,
    RegisterSerializer,
    UserSerializer,
)


def can_hire(user):
    return user.is_staff or user.account_type == "contractor"


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = (permissions.AllowAny,)


class AdminContractorCreateView(generics.CreateAPIView):
    serializer_class = AdminContractorCreateSerializer
    permission_classes = (permissions.IsAdminUser,)


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class ProfessionalProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = ProfessionalProfileSerializer
    parser_classes = (
        parsers.JSONParser,
        parsers.MultiPartParser,
        parsers.FormParser,
    )

    def get_object(self):
        if (
            not self.request.user.is_staff
            and self.request.user.account_type != "professional"
        ):
            raise PermissionDenied(
                "Somente profissionais podem editar curriculo."
            )
        profile, _ = ProfessionalProfile.objects.get_or_create(
            user=self.request.user
        )
        return profile

    def perform_update(self, serializer):
        old_resume = serializer.instance.resume.name
        profile = serializer.save()
        if old_resume and old_resume != profile.resume.name:
            profile.resume.storage.delete(old_resume)
        profile.catalog_status = ProfessionalProfile.CatalogStatus.REVIEW
        profile.verified_by_apelmat = False
        profile.reviewed_by = None
        profile.reviewed_at = None
        profile.save(
            update_fields=(
                "catalog_status",
                "verified_by_apelmat",
                "reviewed_by",
                "reviewed_at",
                "updated_at",
            )
        )
        notify_admins_about_professional_review(profile)


class ContractorProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = ContractorProfileSerializer

    def get_object(self):
        if (
            not self.request.user.is_staff
            and self.request.user.account_type != "contractor"
        ):
            raise PermissionDenied(
                "Somente contratantes podem editar perfil de empresa."
            )
        profile, _ = ContractorProfile.objects.get_or_create(
            user=self.request.user
        )
        return profile


class DeleteAccountView(generics.GenericAPIView):
    serializer_class = UserSerializer

    def delete(self, request):
        if request.user.is_staff:
            raise PermissionDenied(
                "Contas administrativas nao podem ser excluidas pelo app."
            )
        try:
            resume = request.user.professional_profile.resume
            if resume:
                resume.delete(save=False)
        except ProfessionalProfile.DoesNotExist:
            pass
        request.user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class ProfessionalListView(generics.ListAPIView):
    serializer_class = ProfessionalDirectorySerializer
    filter_backends = (filters.SearchFilter, filters.OrderingFilter)
    search_fields = (
        "user__display_name",
        "headline",
        "bio",
        "city",
        "state",
        "user__professional_objectives__summary",
    )
    ordering_fields = ("updated_at", "years_of_experience")
    ordering = ("-updated_at",)

    def get_queryset(self):
        if not can_hire(self.request.user):
            raise PermissionDenied(
                "Somente contas contratantes podem consultar curriculos."
            )
        queryset = (
            ProfessionalProfile.objects.select_related("user")
            .prefetch_related("user__professional_objectives")
            .filter(
                user__is_active=True,
                user__is_staff=False,
                user__account_type="professional",
            )
        )
        if self.request.user.is_staff:
            return queryset.distinct()
        return queryset.filter(
            profile_visible=True,
            catalog_status=ProfessionalProfile.CatalogStatus.PUBLISHED,
            user__professional_objectives__status=(
                ProfessionalObjective.Status.PUBLISHED
            ),
        ).distinct()


class AdminProfessionalStatusView(views.APIView):
    permission_classes = (permissions.IsAdminUser,)
    serializer_class = ProfessionalDirectorySerializer
    action = None

    def post(self, request, user_id):
        profile = get_object_or_404(
            ProfessionalProfile.objects.select_related("user"),
            user_id=user_id,
            user__is_active=True,
            user__is_staff=False,
            user__account_type="professional",
        )
        now = timezone.now()
        if self.action == "publish":
            profile.catalog_status = ProfessionalProfile.CatalogStatus.PUBLISHED
            profile.verified_by_apelmat = True
            profile.profile_visible = True
            profile.reviewed_by = request.user
            profile.reviewed_at = now
            notification_title = "Curriculo publicado"
            notification_body = (
                "Seu curriculo foi verificado pela Apelmat e publicado "
                "no catalogo para empresas associadas."
            )
        elif self.action == "pause":
            profile.catalog_status = ProfessionalProfile.CatalogStatus.PAUSED
            profile.verified_by_apelmat = False
            profile.profile_visible = False
            profile.reviewed_by = request.user
            profile.reviewed_at = now
            notification_title = "Curriculo pausado"
            notification_body = (
                "Seu curriculo foi pausado pela Apelmat e saiu do catalogo."
            )
        elif self.action == "review":
            profile.catalog_status = ProfessionalProfile.CatalogStatus.REVIEW
            profile.verified_by_apelmat = False
            profile.profile_visible = True
            profile.reviewed_by = request.user
            profile.reviewed_at = now
            notification_title = "Curriculo em analise"
            notification_body = (
                "Seu curriculo voltou para analise da Apelmat."
            )
        else:
            return Response(
                {"detail": "Acao administrativa invalida."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        profile.save(
            update_fields=(
                "catalog_status",
                "verified_by_apelmat",
                "profile_visible",
                "reviewed_by",
                "reviewed_at",
                "updated_at",
            )
        )
        from marketplace.models import Notification

        Notification.objects.create(
            recipient=profile.user,
            kind=Notification.Kind.PROFILE_REVIEW,
            professional=profile.user,
            title=notification_title,
            body=notification_body,
        )
        serializer = ProfessionalDirectorySerializer(
            profile,
            context={"request": request},
        )
        return Response(serializer.data)


@extend_schema(responses={(200, "application/pdf"): OpenApiTypes.BINARY})
class ResumeDownloadView(views.APIView):
    def get(self, request, user_id):
        try:
            profile = ProfessionalProfile.objects.select_related("user").get(
                user_id=user_id,
                user__is_active=True,
            )
        except ProfessionalProfile.DoesNotExist as error:
            raise Http404 from error

        released = ContactRequest.objects.filter(
            company=request.user,
            professional=profile.user,
            status=ContactRequest.Status.APPROVED,
        ).exists()
        if (
            request.user.id != profile.user_id
            and not request.user.is_staff
            and not released
        ):
            raise PermissionDenied(
                "Este curriculo ainda nao foi liberado pela Apelmat."
            )
        if not profile.resume:
            raise Http404("Curriculo nao encontrado.")

        try:
            return FileResponse(
                profile.resume.open("rb"),
                as_attachment=True,
                filename=Path(profile.resume.name).name,
                content_type="application/pdf",
            )
        except FileNotFoundError as error:
            raise Http404("Arquivo do curriculo nao encontrado.") from error
