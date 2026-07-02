from django.db import models
from businesses.models import Business

class Page(models.Model):
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="pages")
    slug = models.SlugField()
    title = models.CharField(max_length=200)
    body = models.TextField(blank=True)
    is_published = models.BooleanField(default=True)

    class Meta:
        unique_together = ("business", "slug")

    def __str__(self):
        return f"{self.business}: {self.title}"
