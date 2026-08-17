from django.db import migrations


CATEGORIES = (
    ("Administrativo", "administrativo"),
    ("Construcao e reformas", "construcao-reformas"),
    ("Cuidados pessoais", "cuidados-pessoais"),
    ("Educacao", "educacao"),
    ("Eletrica", "eletrica"),
    ("Eventos", "eventos"),
    ("Limpeza", "limpeza"),
    ("Manutencao", "manutencao"),
    ("Mecanica", "mecanica"),
    ("Tecnologia", "tecnologia"),
    ("Transporte", "transporte"),
    ("Outros", "outros"),
)


def create_categories(apps, schema_editor):
    category_model = apps.get_model("marketplace", "ServiceCategory")
    for name, slug in CATEGORIES:
        category_model.objects.get_or_create(
            slug=slug,
            defaults={"name": name, "is_active": True},
        )


def remove_categories(apps, schema_editor):
    category_model = apps.get_model("marketplace", "ServiceCategory")
    category_model.objects.filter(
        slug__in=[slug for _, slug in CATEGORIES]
    ).delete()


class Migration(migrations.Migration):
    dependencies = [
        ("marketplace", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(create_categories, remove_categories),
    ]

