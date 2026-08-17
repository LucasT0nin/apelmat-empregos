from django.db import migrations


CATEGORIES = (
    ("Operador", "operador"),
    ("Administrativo", "administrativo"),
    ("Logistica", "logistica"),
    ("Manutencao", "manutencao"),
    ("Eletrica", "eletrica"),
    ("Mecanica", "mecanica"),
    ("Transporte", "transporte"),
    ("Limpeza", "limpeza"),
    ("Producao", "producao"),
    ("Seguranca", "seguranca"),
    ("Outros", "outros"),
)


def create_categories(apps, schema_editor):
    category_model = apps.get_model("marketplace", "ServiceCategory")
    for name, slug in CATEGORIES:
        category_model.objects.update_or_create(
            slug=slug,
            defaults={"name": name, "is_active": True},
        )


class Migration(migrations.Migration):
    dependencies = [
        ("marketplace", "0003_professional_area_notifications"),
    ]

    operations = [
        migrations.RunPython(create_categories, migrations.RunPython.noop),
    ]

