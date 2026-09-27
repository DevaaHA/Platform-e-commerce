from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    DriverViewSet, 
    DeliveryViewSet, 
    DriverEarningViewSet,
    TrackingSessionViewSet,
    DeliveryRouteViewSet,
    LocationHistoryViewSet
)

# استخدام DefaultRouter يوفر واجهات جاهزة وموحدة (Standardized) لعمليات الـ CRUD
router = DefaultRouter()

# ==========================================
# Core Delivery & Driver Endpoints
# ==========================================
router.register(r'drivers', DriverViewSet, basename='driver')
router.register(r'deliveries', DeliveryViewSet, basename='delivery')
router.register(r'driver/earnings', DriverEarningViewSet, basename='driver-earning')

# ==========================================
# Day 12: Real-Time Tracking & Routes Endpoints
# ==========================================
# مسار جلسات التتبع (لبدء وإنهاء التتبع من قبل الكابتن)
router.register(r'tracking/sessions', TrackingSessionViewSet, basename='tracking-session')

# مسار خطوط سير الرحلة (لتخزين المسار المتوقع للملاحة)
router.register(r'tracking/routes', DeliveryRouteViewSet, basename='delivery-route')

# مسار سجل المواقع (لجلب مسار الكابتن السابق ورسمه على الخريطة أو تحليله)
router.register(r'tracking/location-history', LocationHistoryViewSet, basename='location-history')

urlpatterns = [
    # تضمين جميع المسارات المسجلة في الـ Router
    path('', include(router.urls)),
]