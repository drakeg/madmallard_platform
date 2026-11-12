from django.core.management.base import BaseCommand
from businesses.models import Business
from pages.models import Page

DEMO_PAGES = {
    "adventures": [
        ("our-journey", "Our Journey", "We're building a collection of RV travel stories, practical gear notes, and destination ideas. This is sample content for the local preview. Edit or replace it through the Django administration."),
        ("what-we-explore", "What We Explore", "From historic sites and scenic stops to memorable meals and campground discoveries, our adventures are about enjoying the journey. This sample page demonstrates tenant-specific content."),
    ],
    "personal-training": [
        ("our-approach", "Our Approach", "We focus on practical, repeatable habits: consistent movement, sustainable nutrition, and long-term progress. This demonstration content can be customized in the Django administration."),
        ("training-fundamentals", "Training Fundamentals", "Start with manageable goals, sound technique, and routines you can repeat. Programs and coaching enrollment are not yet available in this preview."),
    ],
    "solutions": [
        ("how-we-work", "How We Work", "We favor clear requirements, maintainable infrastructure, automation, and useful documentation. This is a preview page, not a live service engagement."),
        ("areas-of-focus", "Areas of Focus", "Cloud infrastructure, DevOps workflows, operational reliability, and Linux automation are core areas of interest. Customize these descriptions through the Django administration."),
    ],
}


class Command(BaseCommand):
    help = "Create non-destructive sample pages for local review only"

    def handle(self, *args, **options):
        for slug, pages in DEMO_PAGES.items():
            business = Business.objects.filter(slug=slug).first()
            if business is None:
                self.stdout.write(self.style.WARNING(f"Skipping missing tenant {slug}"))
                continue
            for page_slug, title, body in pages:
                _, created = Page.objects.get_or_create(
                    business=business, slug=page_slug,
                    defaults={"title": title, "body": body, "is_published": True},
                )
                if created:
                    self.stdout.write(f"Created sample page {slug}/{page_slug}")
