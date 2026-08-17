from rest_framework.routers import DefaultRouter

from .views import (
    ContactRequestViewSet,
    NotificationViewSet,
    ProfessionalObjectiveViewSet,
    ServiceCategoryViewSet,
)


router = DefaultRouter()
router.register("categories", ServiceCategoryViewSet, basename="category")
router.register(
    "professional-objectives",
    ProfessionalObjectiveViewSet,
    basename="professional-objective",
)
router.register(
    "contact-requests",
    ContactRequestViewSet,
    basename="contact-request",
)
router.register("notifications", NotificationViewSet, basename="notification")

urlpatterns = router.urls
