from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    NotificationViewSet,
    UserNotificationSettingViewSet,
    DeviceTokenViewSet,
    AdminBroadcastViewSet
)

# تحديد مساحة الاسم (Namespace) للتطبيق لضمان عدم تعارض الروابط في المنظومة الكبيرة
app_name = 'notifications'

# 1. راوتر العملاء (User Router): مخصص حصراً للواجهة الأمامية وتطبيق الهاتف
user_router = DefaultRouter()

# مركز الإشعارات (قراءة، تحديث، تحديد كمقروء عبر الـ @action)
user_router.register(r'notifications', NotificationViewSet, basename='notification')

# إعدادات الإشعارات (تفعيل/إيقاف القنوات مثل Push, Email, SMS)
user_router.register(r'notification-settings', UserNotificationSettingViewSet, basename='notification-setting')

# تسجيل وإدارة أجهزة الـ Device Tokens (خاص بخوادم FCM)
user_router.register(r'devices', DeviceTokenViewSet, basename='device-token')


# 2. راوتر الإدارة (Admin Router): معزول تماماً ومخصص للوحة تحكم الأدمن
admin_router = DefaultRouter()

# إدارة الحملات التسويقية والإشعارات الجماعية (Broadcasts)
admin_router.register(r'broadcasts', AdminBroadcastViewSet, basename='admin-broadcast')


urlpatterns = [
    # دمج مسارات العملاء (تظهر كـ /api/v1/notifications/...)
    path('', include(user_router.urls)),
    
    # دمج مسارات الأدمن تحت مسار فرعي واضح وآمن (تظهر كـ /api/v1/notifications/admin/broadcasts/...)
    path('admin/', include(admin_router.urls)),
]