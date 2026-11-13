from django.contrib import admin

from .models import Business, BusinessMembership, Domain


class SuperuserOnlyAdmin(admin.ModelAdmin):
    """Business configuration is managed by platform superusers only."""

    def has_module_permission(self, request):
        return request.user.is_active and request.user.is_superuser

    def has_view_permission(self, request, obj=None):
        return request.user.is_active and request.user.is_superuser

    def has_add_permission(self, request):
        return request.user.is_active and request.user.is_superuser

    def has_change_permission(self, request, obj=None):
        return request.user.is_active and request.user.is_superuser

    def has_delete_permission(self, request, obj=None):
        return request.user.is_active and request.user.is_superuser


class DomainInline(admin.TabularInline):
    model = Domain
    extra = 1


@admin.register(Business)
class BusinessAdmin(SuperuserOnlyAdmin):
    list_display = (
        "public_name", "slug", "primary_domain", "theme_key",
        "template_key", "is_active",
    )
    prepopulated_fields = {"slug": ("public_name",)}
    inlines = [DomainInline]


@admin.register(Domain)
class DomainAdmin(SuperuserOnlyAdmin):
    list_display = ("hostname", "business", "is_primary")


@admin.register(BusinessMembership)
class BusinessMembershipAdmin(SuperuserOnlyAdmin):
    list_display = ("user", "business")
    list_filter = ("business",)
    autocomplete_fields = ()
