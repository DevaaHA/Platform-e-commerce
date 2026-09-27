import logging
from rest_framework import viewsets, permissions, status
from rest_framework.response import Response
from django.core.cache import cache

from .models import (
    Setting, PaymentSetting, DeliverySetting, 
    TaxSetting, CurrencySetting
)
from .serializers import (
    SettingSerializer, PaymentSettingSerializer, 
    DeliverySettingSerializer, TaxSettingSerializer, 
    CurrencySettingSerializer
)

# تفعيل نظام تسجيل الأحداث لمراقبة التعديلات الحساسة
logger = logging.getLogger(__name__)

class AdminSettingViewSet(viewsets.ModelViewSet):
    """
    متحكم الإعدادات العامة للمنصة
    """
    queryset = Setting.objects.all()
    serializer_class = SettingSerializer
    permission_classes = [permissions.IsAdminUser]

    def _invalidate_cache(self):
        # مسح الكاش من الذاكرة لضمان تحديث الواجهات فوراً بدون تأخير
        cache.delete('platform_public_settings')
        cache.delete('platform_all_settings')

    def create(self, request, *args, **kwargs):
        response = super().create(request, *args, **kwargs)
        self._invalidate_cache()
        return response

    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        self._invalidate_cache()
        return response

    def destroy(self, request, *args, **kwargs):
        response = super().destroy(request, *args, **kwargs)
        self._invalidate_cache()
        return response


class AdminPaymentSettingViewSet(viewsets.ModelViewSet):
    """
    متحكم بوابات الدفع (بيانات حساسة)
    """
    queryset = PaymentSetting.objects.all()
    serializer_class = PaymentSettingSerializer
    permission_classes = [permissions.IsAdminUser]

    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        # تسجيل أمني يوضح من قام بتعديل بوابات الدفع
        logger.info(f"🚨 Payment settings updated by Admin: {request.user.email}")
        cache.delete('active_payment_gateways')
        return response


class AdminDeliverySettingViewSet(viewsets.ModelViewSet):
    """
    متحكم إعدادات التوصيل (Singleton Pattern)
    """
    queryset = DeliverySetting.objects.all()
    serializer_class = DeliverySettingSerializer
    permission_classes = [permissions.IsAdminUser]

    def create(self, request, *args, **kwargs):
        # ضمان وجود سجل واحد فقط لإعدادات التوصيل العامة (يمنع التكرار)
        if DeliverySetting.objects.exists():
            return Response(
                {'error': 'إعدادات التوصيل موجودة مسبقاً. يرجى تعديلها بدلاً من إنشاء واحدة جديدة.'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        response = super().create(request, *args, **kwargs)
        cache.delete('delivery_settings_config')
        return response

    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        cache.delete('delivery_settings_config')
        return response


class AdminTaxSettingViewSet(viewsets.ModelViewSet):
    """
    متحكم إعدادات الضرائب والرسوم
    """
    queryset = TaxSetting.objects.all()
    serializer_class = TaxSettingSerializer
    permission_classes = [permissions.IsAdminUser]

    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        cache.delete('active_tax_rates')
        return response


class AdminCurrencySettingViewSet(viewsets.ModelViewSet):
    """
    متحكم العملات وأسعار الصرف
    """
    queryset = CurrencySetting.objects.all()
    serializer_class = CurrencySettingSerializer
    permission_classes = [permissions.IsAdminUser]

    def update(self, request, *args, **kwargs):
        response = super().update(request, *args, **kwargs)
        cache.delete('platform_currencies')
        return response