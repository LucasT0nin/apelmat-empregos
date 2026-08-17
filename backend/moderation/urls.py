from rest_framework.routers import DefaultRouter

from .views import BlockViewSet, ReportViewSet


router = DefaultRouter()
router.register("blocks", BlockViewSet, basename="block")
router.register("reports", ReportViewSet, basename="report")

urlpatterns = router.urls

