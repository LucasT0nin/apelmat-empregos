from django.db import migrations


def create_general_category(apps, schema_editor):
    category_model = apps.get_model("marketplace", "ServiceCategory")
    category_model.objects.update_or_create(
        slug="geral",
        defaults={"name": "Geral", "is_active": True},
    )


class Migration(migrations.Migration):
    dependencies = [
        ("marketplace", "0005_opportunity_kind_alter_notification_kind"),
    ]

    operations = [
        migrations.RunPython(
            create_general_category,
            migrations.RunPython.noop,
        ),
    ]
