from django.conf import settings
from urllib.parse import urlencode


def tenant(request):
    current = getattr(request, "tenant", None)
    # Keep navigation inside the chosen site when previewing via ?tenant=.
    # This parameter is never used in production.
    preview_query = ""
    if (
        settings.DEBUG
        and current is not None
        and request.GET.get("tenant") == current.slug
    ):
        preview_query = "?" + urlencode({"tenant": current.slug})
    return {"tenant": current, "tenant_preview_query": preview_query}
