from django.shortcuts import render

TEMPLATE_MAP = {
    "adventures": "public/adventures/home.html",
    "personal_training": "public/personal_training/home.html",
    "solutions": "public/solutions/home.html",
}

def home(request):
    tenant = getattr(request, "tenant", None)
    template = TEMPLATE_MAP.get(getattr(tenant, "template_key", ""), "public/default.html")
    return render(request, template, {"tenant": tenant})
