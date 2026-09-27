from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AdminDashboardAnalyticsViewSet

router = DefaultRouter()
router.register(r'admin/dashboard-analytics', AdminDashboardAnalyticsViewSet, basename='admin-analytics')

urlpatterns = [
    path('', include(router.urls)),
]