from django.urls import path, include
from rest_framework.routers import DefaultRouter

# استيراد كافة المتحكمات (ViewSets) الخاصة بالإعدادات
from .views import (
    AdminSettingViewSet, 
    AdminPaymentSettingViewSet, 
    AdminDeliverySettingViewSet,
    AdminTaxSettingViewSet,
    AdminCurrencySettingViewSet
)

# إنشاء الـ Router الرئيسي لتوليد المسارات تلقائياً (RESTful API Standard)
router = DefaultRouter()

# 1. مسارات الإعدادات العامة للمنصة
router.register(r'admin/settings', AdminSettingViewSet, basename='admin-setting')

# 2. مسارات التحكم ببوابات الدفع
router.register(r'admin/payment-settings', AdminPaymentSettingViewSet, basename='admin-payment-setting')

# 3. مسارات التحكم برسوم وشروط التوصيل
router.register(r'admin/delivery-settings', AdminDeliverySettingViewSet, basename='admin-delivery-setting')

# 4. مسارات التحكم بالضرائب والرسوم الإضافية
router.register(r'admin/tax-settings', AdminTaxSettingViewSet, basename='admin-tax-setting')

# 5. مسارات التحكم بالعملات، أسعار الصرف، واللغات
router.register(r'admin/currency-settings', AdminCurrencySettingViewSet, basename='admin-currency-setting')

# تجميع المسارات وتصديرها
urlpatterns = [
    path('', include(router.urls)),
]