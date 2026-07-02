from django.contrib import admin
from .models import Business, Domain

class DomainInline(admin.TabularInline):
    model = Domain
    extra = 1

@admin.register(Business)
class BusinessAdmin(admin.ModelAdmin):
    list_display = ("public_name", "slug", "primary_domain", "theme_key", "template_key", "is_active")
    prepopulated_fields = {"slug": ("public_name",)}
    inlines = [DomainInline]

@admin.register(Domain)
class DomainAdmin(admin.ModelAdmin):
    list_display = ("hostname", "business", "is_primary")
