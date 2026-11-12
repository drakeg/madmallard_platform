from django.test import TestCase, override_settings
from django.urls import reverse

from businesses.models import Business, Domain
from .models import Page


@override_settings(
    ALLOWED_HOSTS=[".example.com"],
    DEBUG=False,
    DEFAULT_TENANT_SLUG="adventures",
)
class TenantPageTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.adventures = Business.objects.create(
            slug="adventures", public_name="Adventures", is_active=True
        )
        cls.solutions = Business.objects.create(
            slug="solutions", public_name="Solutions", is_active=True
        )
        Domain.objects.create(business=cls.adventures, hostname="travel.example.com")
        Domain.objects.create(business=cls.solutions, hostname="tech.example.com")
        Page.objects.create(
            business=cls.adventures, slug="shared", title="Travel only",
            body="Public travel text", is_published=True
        )
        Page.objects.create(
            business=cls.solutions, slug="shared", title="Tech only",
            body="Public tech text", is_published=True
        )
        Page.objects.create(
            business=cls.adventures, slug="draft", title="Unpublished",
            body="Private draft text", is_published=False
        )
        Page.objects.create(
            business=cls.solutions, slug="exclusive", title="Tech exclusive",
            body="Only for tech", is_published=True
        )

    def test_same_slug_is_isolated_by_hostname(self):
        response = self.client.get(
            reverse("page_detail", args=["shared"]),
            HTTP_HOST="travel.example.com"
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Travel only")
        self.assertNotContains(response, "Tech only")
        response = self.client.get(
            reverse("page_detail", args=["shared"]),
            HTTP_HOST="tech.example.com"
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Tech only")
        self.assertNotContains(response, "Travel only")

    def test_cross_tenant_page_returns_404(self):
        response = self.client.get(
            reverse("page_detail", args=["exclusive"]),
            HTTP_HOST="travel.example.com"
        )
        self.assertEqual(response.status_code, 404)

    def test_unpublished_page_returns_404(self):
        response = self.client.get(
            reverse("page_detail", args=["draft"]),
            HTTP_HOST="travel.example.com"
        )
        self.assertEqual(response.status_code, 404)

    def test_index_lists_only_published_pages_for_tenant(self):
        response = self.client.get(
            reverse("page_index"), HTTP_HOST="travel.example.com"
        )
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Travel only")
        self.assertNotContains(response, "Tech only")
        self.assertNotContains(response, "Unpublished")

    def test_page_content_is_escaped(self):
        Page.objects.create(
            business=self.adventures, slug="html", title="Markup",
            body="<script>alert(1)</script>", is_published=True
        )
        response = self.client.get(
            reverse("page_detail", args=["html"]),
            HTTP_HOST="travel.example.com"
        )
        self.assertEqual(response.status_code, 200)
        self.assertNotContains(response, "<script>", html=False)
        self.assertContains(response, "&lt;script&gt;", html=False)

    @override_settings(DEBUG=True)
    def test_preview_navigation_retains_selected_tenant(self):
        response = self.client.get(
            "/pages/?tenant=solutions", HTTP_HOST="travel.example.com"
        )
        self.assertContains(response, "Tech only")
        self.assertNotContains(response, "Travel only")
        self.assertContains(response, "/pages/shared/?tenant=solutions")
        response = self.client.get(
            "/pages/shared/?tenant=solutions", HTTP_HOST="travel.example.com"
        )
        self.assertContains(response, "Tech only")

    def test_unknown_tenant_slug_returns_404(self):
        self.assertEqual(
            self.client.get("/pages/missing/", HTTP_HOST="travel.example.com").status_code,
            404,
        )
