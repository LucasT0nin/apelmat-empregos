from rest_framework import serializers

from .models import Block, Report


class BlockSerializer(serializers.ModelSerializer):
    class Meta:
        model = Block
        fields = ("id", "blocked", "created_at")
        read_only_fields = ("id", "created_at")

    def validate_blocked(self, blocked):
        if blocked == self.context["request"].user:
            raise serializers.ValidationError(
                "Voce nao pode bloquear a si mesmo."
            )
        return blocked


class ReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Report
        fields = (
            "id",
            "target_type",
            "target_id",
            "reason",
            "details",
            "status",
            "created_at",
        )
        read_only_fields = ("id", "status", "created_at")

