from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PaymentMethodViewSet, 
    CustomerPaymentViewSet, 
    InvoiceViewSet, 
    RefundViewSet, 
    AdminFinanceViewSet,
    payment_webhook
)

# تعيين اسم النطاق لتجنب تداخل المسارات في المشاريع الضخمة
app_name = 'payments'

# إنشاء الـ Router الرئيسي لتوليد مسارات الـ RESTful بكفاءة عالية
router = DefaultRouter()
router.register(r'payment-methods', PaymentMethodViewSet, basename='payment-methods')
router.register(r'payments', CustomerPaymentViewSet, basename='payments')
router.register(r'invoices', InvoiceViewSet, basename='invoices')
router.register(r'refunds', RefundViewSet, basename='refunds')

urlpatterns = [
    # تضمين مسارات الـ ViewSets الأساسية تلقائياً
    path('', include(router.urls)),
    
    # مسار مخصص للوحة الإدارة المالية (ملخصات الأرباح، الإيرادات، ومستحقات المتاجر)
    path('admin/finance-summary/', AdminFinanceViewSet.as_view({'get': 'list'}), name='admin-finance-summary'),
    
    # مسار استقبال إشعارات بوابات الدفع (Stripe Webhook Endpoint) للتأكيد الخلفي وتجنب تكرار الدفع
    path('webhook/', payment_webhook, name='payment-webhook'),
]