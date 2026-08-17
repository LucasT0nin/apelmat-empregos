from accounts.models import User

from .models import Notification


def notify_admins_about_professional_review(profile):
    recipients = User.objects.filter(is_staff=True, is_active=True)
    for recipient in recipients:
        Notification.objects.create(
            recipient=recipient,
            kind=Notification.Kind.PROFILE_REVIEW,
            professional=profile.user,
            title="Curriculo aguardando analise",
            body=(
                f"{profile.user.display_name} atualizou o curriculo e "
                "aguarda publicacao no catalogo."
            ),
        )
