from rest_framework import serializers
from .models import (
    Setting, PaymentSetting, DeliverySetting, 
    TaxSetting, CurrencySetting
)

class SettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Setting
        fields = '__all__'
        # منع تعديل المُعرّف وتواريخ الإنشاء/التحديث يدوياً
        read_only_fields = ['id', 'created_at', 'updated_at']

class PaymentSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentSetting
        fields = '__all__'
        read_only_fields = ['id']
        # إخفاء بيانات الاعتماد (API Keys) عند طلبها في الـ GET لحمايتها تماماً
        extra_kwargs = {
            'credentials': {'write_only': True}
        }

    def validate_credentials(self, value):
        """التحقق من أن البيانات الحساسة مدخلة بصيغة JSON صحيحة"""
        if not isinstance(value, dict):
            raise serializers.ValidationError("بيانات الاعتماد يجب أن تكون بصيغة JSON صحيحة.")
        return value

class DeliverySettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliverySetting
        fields = '__all__'
        read_only_fields = ['id']

    def validate_base_fee(self, value):
        """منع إدخال رسوم توصيل سالبة"""
        if value < 0:
            raise serializers.ValidationError("رسوم التوصيل الأساسية لا يمكن أن تكون قيمة سالبة.")
        return value

    def validate_free_threshold(self, value):
        """التحقق من منطقية الحد الأدنى للتوصيل المجاني"""
        if value < 0:
            raise serializers.ValidationError("الحد الأدنى للتوصيل المجاني يجب أن يكون صفراً أو أكثر.")
        return value

    def validate(self, data):
        """تحقق منطقي شامل يمنع التناقضات التسعيرية"""
        base_fee = data.get('base_fee', 0)
        free_threshold = data.get('free_threshold', 0)
        
        # لا يعقل أن تكون رسوم التوصيل أعلى من الحد المطلوب للحصول على توصيل مجاني
        if free_threshold > 0 and base_fee >= free_threshold:
            raise serializers.ValidationError(
                "هناك خطأ منطقي: رسوم التوصيل الأساسية أعلى من أو تساوي الحد الأدنى للتوصيل المجاني."
            )
        return data

class TaxSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaxSetting
        fields = '__all__'
        read_only_fields = ['id']

    def validate_percentage(self, value):
        """التحقق من أن نسبة الضريبة مئوية صحيحة"""
        if value < 0 or value > 100:
            raise serializers.ValidationError("نسبة الضريبة يجب أن تكون رقماً منطقياً بين 0 و 100.")
        return value

class CurrencySettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = CurrencySetting
        fields = '__all__'
        read_only_fields = ['id']

    def validate_exchange_rate(self, value):
        """منع إدخال أسعار صرف صفرية أو سالبة تكسر العمليات الحسابية"""
        if value <= 0:
            raise serializers.ValidationError("سعر الصرف يجب أن يكون قيمة موجبة أكبر من الصفر.")
        return value