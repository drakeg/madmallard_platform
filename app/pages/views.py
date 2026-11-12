from django.http import Http404
from django.shortcuts import get_object_or_404, render

from .models import Page


def _active_tenant(request):
    tenant = getattr(request, "tenant", None)
    if tenant is None or not tenant.is_active:
        raise Http404("Site not found")
    return tenant


def page_index(request):
    tenant = _active_tenant(request)
    pages = Page.objects.filter(
        business=tenant, is_published=True
    ).order_by("title", "pk")
    return render(request, "public/pages/index.html", {"pages": pages})


def page_detail(request, slug):
    tenant = _active_tenant(request)
    page = get_object_or_404(
        Page, business=tenant, is_published=True, slug=slug
    )
    return render(request, "public/pages/detail.html", {"page": page})
