from django.http import HttpResponse
from django.test import RequestFactory, TestCase, override_settings

from businesses.middleware import TenantMiddleware
from businesses.models import Business, Domain


class TenantMiddlewareTests(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.adventures = Business.objects.create(
            slug="adventures", public_name="Adventures", is_active=True
        )
        self.training = Business.objects.create(
            slug="training", public_name="Training", is_active=True
        )
        self.disabled = Business.objects.create(
            slug="disabled", public_name="Disabled", is_active=False
        )
        Domain.objects.create(
            business=self.adventures, hostname="adventures.example.com", is_primary=True
        )
        self.middleware = TenantMiddleware(lambda request: HttpResponse("ok"))

    def resolve(self, path="/", host="adventures.example.com"):
        request = self.factory.get(path, HTTP_HOST=host)
        self.middleware(request)
        return request.tenant

    @override_settings(DEBUG=False, DEFAULT_TENANT_SLUG="training")
    def test_production_ignores_query_override_on_known_domain(self):
        self.assertEqual(
            self.resolve("/?tenant=training"), self.adventures
        )

    @override_settings(DEBUG=True)
    def test_development_allows_active_tenant_override(self):
        self.assertEqual(
            self.resolve("/?tenant=training"), self.training
        )

    @override_settings(DEBUG=True)
    def test_development_rejects_inactive_tenant_override(self):
        self.assertEqual(
            self.resolve("/?tenant=disabled"), self.adventures
        )

    @override_settings(DEBUG=False, DEFAULT_TENANT_SLUG="training")
    def test_unknown_hostname_falls_back_to_default_tenant(self):
        self.assertEqual(
            self.resolve("/?tenant=adventures", host="unknown.example.com"),
            self.training,
        )

    @override_settings(DEBUG=False)
    def test_hostname_lookup_is_case_insensitive(self):
        self.assertEqual(
            self.resolve(host="ADVENTURES.EXAMPLE.COM"), self.adventures
        )
