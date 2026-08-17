from django.contrib import admin

from .models import Block, Report


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = (
        "target_type",
        "target_id",
        "reason",
        "status",
        "reporter",
        "created_at",
    )
    list_filter = ("target_type", "status", "reason")
    search_fields = ("details", "reporter__email")


admin.site.register(Block)

