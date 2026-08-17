from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [
        ("accounts", "0001_initial"),
    ]

    operations = [
        migrations.AddField(
            model_name="professionalprofile",
            name="area",
            field=models.CharField(
                blank=True,
                choices=[
                    ("operador", "Operador"),
                    ("administrativo", "Administrativo"),
                    ("logistica", "Logistica"),
                    ("manutencao", "Manutencao"),
                    ("eletrica", "Eletrica"),
                    ("mecanica", "Mecanica"),
                    ("transporte", "Transporte"),
                    ("limpeza", "Limpeza"),
                    ("producao", "Producao"),
                    ("seguranca", "Seguranca"),
                    ("outros", "Outros"),
                ],
                max_length=30,
            ),
        ),
    ]

