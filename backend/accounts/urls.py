from django.urls import path

from .views import (
    AdminContractorCreateView,
    ContractorProfileView,
    AdminProfessionalStatusView,
    DeleteAccountView,
    MeView,
    ProfessionalProfileView,
    ProfessionalListView,
    RegisterView,
    ResumeDownloadView,
)


urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path(
        "contractors/",
        AdminContractorCreateView.as_view(),
        name="admin-contractor-create",
    ),
    path("me/", MeView.as_view(), name="me"),
    path(
        "me/professional/",
        ProfessionalProfileView.as_view(),
        name="professional-profile",
    ),
    path(
        "me/contractor/",
        ContractorProfileView.as_view(),
        name="contractor-profile",
    ),
    path(
        "me/delete/",
        DeleteAccountView.as_view(),
        name="delete-account",
    ),
    path(
        "professionals/",
        ProfessionalListView.as_view(),
        name="professional-list",
    ),
    path(
        "professionals/<uuid:user_id>/publish/",
        AdminProfessionalStatusView.as_view(action="publish"),
        name="professional-admin-publish",
    ),
    path(
        "professionals/<uuid:user_id>/pause/",
        AdminProfessionalStatusView.as_view(action="pause"),
        name="professional-admin-pause",
    ),
    path(
        "professionals/<uuid:user_id>/review/",
        AdminProfessionalStatusView.as_view(action="review"),
        name="professional-admin-review",
    ),
    path(
        "professionals/<uuid:user_id>/resume/",
        ResumeDownloadView.as_view(),
        name="professional-resume",
    ),
]
