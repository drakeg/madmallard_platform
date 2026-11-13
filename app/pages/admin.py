from django.contrib import admin
from django.core.exceptions import PermissionDenied

from businesses.models import BusinessMembership
from .models import Page


@admin.register(Page)
class PageAdmin(admin.ModelAdmin):
    list_display = ("title", "business", "slug", "is_published")
    list_filter = ("business", "is_published")
    search_fields = ("title", "slug")

    def _assigned_business_ids(self, request):
        if request.user.is_superuser:
            return None
        return BusinessMembership.objects.filter(
            user=request.user, business__is_active=True
        ).values_list("business_id", flat=True)

    def _allowed(self, request, obj=None):
        if not request.user.is_active or not request.user.is_staff:
            return False
        if request.user.is_superuser:
            return True
        ids = self._assigned_business_ids(request)
        if obj is None:
            return bool(ids.exists())
        return BusinessMembership.objects.filter(
            user=request.user, business_id=obj.business_id,
            business__is_active=True
        ).exists()

    def get_list_filter(self, request):
        # Do not expose names of unassigned businesses in filter choices.
        return super().get_list_filter(request) if request.user.is_superuser else ("is_published",)

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(business_id__in=self._assigned_business_ids(request))

    def formfield_for_foreignkey(self, db_field, request, **kwargs):
        if db_field.name == "business" and not request.user.is_superuser:
            from businesses.models import Business
            kwargs["queryset"] = Business.objects.filter(
                pk__in=self._assigned_business_ids(request), is_active=True
            )
        return super().formfield_for_foreignkey(db_field, request, **kwargs)

    def has_view_permission(self, request, obj=None):
        return super().has_view_permission(request, obj) and self._allowed(request, obj)

    def has_add_permission(self, request):
        return super().has_add_permission(request) and self._allowed(request)

    def has_change_permission(self, request, obj=None):
        return super().has_change_permission(request, obj) and self._allowed(request, obj)

    def has_delete_permission(self, request, obj=None):
        return super().has_delete_permission(request, obj) and self._allowed(request, obj)

    def save_model(self, request, obj, form, change):
        if not self._allowed(request, obj):
            raise PermissionDenied("You cannot edit pages for this business.")
        return super().save_model(request, obj, form, change)
