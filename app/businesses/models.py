from django.conf import settings
from django.db import models

class Business(models.Model):
    slug = models.SlugField(unique=True)
    public_name = models.CharField(max_length=120)
    legal_name = models.CharField(max_length=160, blank=True)
    tagline = models.CharField(max_length=240, blank=True)
    primary_domain = models.CharField(max_length=255, blank=True)
    theme_key = models.CharField(max_length=80, default="default")
    template_key = models.CharField(max_length=80, default="default")
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.public_name

class Domain(models.Model):
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="domains")
    hostname = models.CharField(max_length=255, unique=True)
    is_primary = models.BooleanField(default=False)

    def __str__(self):
        return self.hostname


class BusinessMembership(models.Model):
    """Explicit assignment permitting an editor to work on one business."""

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="business_memberships"
    )
    business = models.ForeignKey(
        Business, on_delete=models.CASCADE, related_name="memberships"
    )

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["user", "business"], name="unique_business_membership"
            )
        ]

    def __str__(self):
        return f"{self.user} — {self.business}"
