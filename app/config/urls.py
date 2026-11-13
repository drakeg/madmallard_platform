from django.contrib import admin
from django.urls import path

from core.views import home
from pages.views import page_detail, page_index

urlpatterns = [
    path("admin/", admin.site.urls),
    path("pages/", page_index, name="page_index"),
    path("pages/<slug:slug>/", page_detail, name="page_detail"),
    path("", home, name="home"),
]
