from django.core.management.base import BaseCommand
from businesses.models import Business, Domain

TENANTS = [
    {
        "slug": "adventures",
        "public_name": "Mad Mallards Adventures",
        "tagline": "RV travel, gear, food, history, and road-life content.",
        "theme_key": "adventures",
        "template_key": "adventures",
        "domains": ["localhost"],
    },
    {
        "slug": "personal-training",
        "public_name": "Mad Mallard Personal Training",
        "tagline": "Practical fitness, nutrition, and coaching.",
        "theme_key": "personal_training",
        "template_key": "personal_training",
        "domains": [],
    },
    {
        "slug": "solutions",
        "public_name": "Mad Mallard Solutions",
        "tagline": "Cloud, Linux, automation, and DevOps solutions.",
        "theme_key": "solutions",
        "template_key": "solutions",
        "domains": [],
    },
]

class Command(BaseCommand):
    help = "Seed initial Mad Mallard business tenants"

    def handle(self, *args, **options):
        for item in TENANTS:
            domains = item.pop("domains")
            business, _ = Business.objects.update_or_create(slug=item["slug"], defaults=item)
            for hostname in domains:
                Domain.objects.get_or_create(business=business, hostname=hostname, defaults={"is_primary": True})
            self.stdout.write(self.style.SUCCESS(f"Seeded {business.public_name}"))
