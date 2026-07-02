from django.conf import settings
from .models import Business, Domain

class TenantMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        tenant = None
        host = request.get_host().split(":")[0].lower()
        slug_override = request.GET.get("tenant")
        if slug_override:
            tenant = Business.objects.filter(slug=slug_override, is_active=True).first()
        if tenant is None:
            domain = Domain.objects.select_related("business").filter(hostname=host, business__is_active=True).first()
            tenant = domain.business if domain else None
        if tenant is None:
            tenant = Business.objects.filter(slug=settings.DEFAULT_TENANT_SLUG, is_active=True).first()
        request.tenant = tenant
        return self.get_response(request)
