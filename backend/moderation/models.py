import uuid

from django.conf import settings
from django.db import models


class Block(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    blocker = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="blocks_created",
    )
    blocked = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="blocks_received",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=("blocker", "blocked"),
                name="unique_user_block",
            ),
            models.CheckConstraint(
                condition=~models.Q(blocker=models.F("blocked")),
                name="cannot_block_self",
            ),
        ]


class Report(models.Model):
    class TargetType(models.TextChoices):
        USER = "user", "Usuario"
        OPPORTUNITY = "opportunity", "Oportunidade"
        APPLICATION = "application", "Candidatura"

    class Status(models.TextChoices):
        OPEN = "open", "Aberta"
        REVIEWING = "reviewing", "Em analise"
        RESOLVED = "resolved", "Resolvida"
        DISMISSED = "dismissed", "Descartada"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reporter = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="reports",
    )
    target_type = models.CharField(
        max_length=20,
        choices=TargetType.choices,
    )
    target_id = models.UUIDField()
    reason = models.CharField(max_length=120)
    details = models.TextField(blank=True)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.OPEN,
    )
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ("-created_at",)

