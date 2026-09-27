from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    DriverProfileViewSet, 
    DriverOrderViewSet, 
    CustomerTrackingViewSet, 
    AdminDeliveryViewSet, 
    update_location
)

app_name = 'deliveries'

router = DefaultRouter()
router.register(r'driver/profile', DriverProfileViewSet, basename='driver-profile')
router.register(r'driver/orders', DriverOrderViewSet, basename='driver-orders')
router.register(r'customer/tracking', CustomerTrackingViewSet, basename='customer-tracking')

urlpatterns = [
    # تضمين الـ Routers التلقائية
    path('', include(router.urls)),
    
    # مسار تحديث موقع الـ GPS للكابتن
    path('location/update/', update_location, name='location-update'),
    
    # مسار لوحة مراقبة التوصيل الحية للأدمن
    path('admin/delivery/live/', AdminDeliveryViewSet.as_view({'get': 'list'}), name='admin-delivery-live'),
]