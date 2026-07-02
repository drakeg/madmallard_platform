from django.db import models
from businesses.models import Business

class ThemeSetting(models.Model):
    business = models.OneToOneField(Business, on_delete=models.CASCADE, related_name="theme")
    primary_color = models.CharField(max_length=20, default="#1f2937")
    accent_color = models.CharField(max_length=20, default="#f59e0b")
    font_family = models.CharField(max_length=120, default="system-ui")
    custom_css = models.TextField(blank=True)

    def __str__(self):
        return f"Theme for {self.business}"
