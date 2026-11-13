from django.contrib.auth.models import Permission, User
from django.test import TestCase, override_settings
from django.urls import reverse

from businesses.models import Business, BusinessMembership, Domain
from pages.models import Page


@override_settings(ALLOWED_HOSTS=["testserver"])
class TenantPageAdminTests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.adventures = Business.objects.create(
            slug="adventures", public_name="Adventures", is_active=True
        )
        cls.solutions = Business.objects.create(
            slug="solutions", public_name="Solutions", is_active=True
        )
        cls.unassigned = Business.objects.create(
            slug="inactive", public_name="Inactive", is_active=False
        )
        cls.travel_page = Page.objects.create(
            business=cls.adventures, slug="travel", title="Travel",
        )
        cls.tech_page = Page.objects.create(
            business=cls.solutions, slug="technology", title="Technology",
        )
        cls.editor = User.objects.create_user(
            username="adventures-editor", password="localtest", is_staff=True
        )
        cls.other = User.objects.create_user(
            username="unassigned-editor", password="localtest", is_staff=True
        )
        cls.superuser = User.objects.create_superuser(
            username="site-owner", password="localtest", email="owner@example.com"
        )
        BusinessMembership.objects.create(
            user=cls.editor, business=cls.adventures
        )
        permissions = Permission.objects.filter(
            content_type__app_label="pages",
            codename__in=["add_page", "change_page", "delete_page", "view_page"],
        )
        cls.editor.user_permissions.add(*permissions)
        cls.other.user_permissions.add(*permissions)

    def as_user(self, user):
        self.client.force_login(user)

    def test_editor_list_is_scoped_to_assigned_business(self):
        self.as_user(self.editor)
        response = self.client.get(reverse("admin:pages_page_changelist"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Travel")
        self.assertNotContains(response, "Technology")
        self.assertNotContains(response, "Solutions")

    def test_editor_cannot_view_change_or_delete_other_business(self):
        self.as_user(self.editor)
        for operation in ["change", "delete", "history"]:
            url = reverse(
                f"admin:pages_page_{operation}", args=[self.tech_page.pk]
            )
            self.assertNotEqual(self.client.get(url).status_code, 200)
        self.assertIn(
            self.client.post(
                reverse("admin:pages_page_change", args=[self.tech_page.pk]),
                {"business": self.adventures.pk, "title": "Stolen",
                 "slug": "technology", "is_published": "on"},
            ).status_code, [403, 404, 302]
        )
        self.tech_page.refresh_from_db()
        self.assertEqual(self.tech_page.title, "Technology")

    def test_editor_cannot_assign_page_to_unowned_business(self):
        self.as_user(self.editor)
        url = reverse("admin:pages_page_add")
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Adventures")
        self.assertNotContains(response, '<option value="%s">Solutions</option>' % self.solutions.pk, html=False)
        response = self.client.post(url, {
            "business": self.solutions.pk,
            "title": "Injected",
            "slug": "injected",
            "body": "bad",
            "is_published": "on",
            "_save": "Save",
        })
        self.assertEqual(response.status_code, 200)
        self.assertFalse(Page.objects.filter(slug="injected").exists())

    def test_editor_can_change_owned_page_but_not_reassign_it(self):
        self.as_user(self.editor)
        change_url = reverse("admin:pages_page_change", args=[self.travel_page.pk])
        success = self.client.post(change_url, {
            "business": self.adventures.pk, "title": "Updated Travel",
            "slug": "travel", "body": "Editorial update",
            "is_published": "on", "_save": "Save",
        })
        self.assertEqual(success.status_code, 302)
        self.travel_page.refresh_from_db()
        self.assertEqual(self.travel_page.title, "Updated Travel")

        response = self.client.post(change_url, {
            "business": self.solutions.pk, "title": "Unauthorized Reassignment",
            "slug": "travel", "body": "Bad change", "_save": "Save",
        })
        self.assertEqual(response.status_code, 200)
        self.travel_page.refresh_from_db()
        self.assertEqual(self.travel_page.business_id, self.adventures.pk)
        self.assertEqual(self.travel_page.title, "Updated Travel")

    def test_unassigned_staff_has_no_page_access(self):
        self.as_user(self.other)
        self.assertNotEqual(
            self.client.get(reverse("admin:pages_page_add")).status_code, 200
        )
        response = self.client.get(reverse("admin:pages_page_changelist"))
        self.assertIn(response.status_code, [200, 403])
        if response.status_code == 200:
            self.assertNotContains(response, "Travel")
            self.assertNotContains(response, "Technology")

    def test_business_domain_and_membership_admin_are_superuser_only(self):
        self.as_user(self.editor)
        for model in ["business", "domain", "businessmembership"]:
            for operation in ["changelist", "add"]:
                url = reverse(f"admin:businesses_{model}_{operation}")
                self.assertNotEqual(self.client.get(url).status_code, 200)
        self.as_user(self.superuser)
        for model in ["business", "domain", "businessmembership"]:
            self.assertEqual(
                self.client.get(
                    reverse(f"admin:businesses_{model}_changelist")
                ).status_code, 200
            )

    def test_superuser_can_view_both_businesses(self):
        self.as_user(self.superuser)
        response = self.client.get(reverse("admin:pages_page_changelist"))
        self.assertContains(response, "Travel")
        self.assertContains(response, "Technology")

    def test_membership_does_not_replace_django_model_permissions(self):
        user = User.objects.create_user(
            username="staff-no-permissions", password="localtest", is_staff=True
        )
        BusinessMembership.objects.create(user=user, business=self.adventures)
        self.as_user(user)
        self.assertNotEqual(
            self.client.get(reverse("admin:pages_page_add")).status_code, 200
        )
