from rest_framework import serializers
from .models import (
    AnalyticsDailySummary, 
    ProductAnalytics, 
    StoreAnalytics, 
    DriverAnalytics, 
    CustomerAnalytics
)

class AnalyticsDailySummarySerializer(serializers.ModelSerializer):
    """محول الملخص اليومي لأداء المنصة (قراءة فقط)"""
    class Meta:
        model = AnalyticsDailySummary
        fields = '__all__'
        read_only_fields = '__all__' # حماية صارمة: يمنع التعديل اليدوي ويضمن مصدر الحقيقة الوحيد للباك إند


class ProductAnalyticsSerializer(serializers.ModelSerializer):
    """محول تحليلات المنتجات والمبيعات"""
    class Meta:
        model = ProductAnalytics
        fields = '__all__'
        read_only_fields = '__all__'


class StoreAnalyticsSerializer(serializers.ModelSerializer):
    """محول تحليلات أداء المتاجر"""
    class Meta:
        model = StoreAnalytics
        fields = '__all__'
        read_only_fields = '__all__'


class DriverAnalyticsSerializer(serializers.ModelSerializer):
    """محول مؤشرات أداء الكباتن (KPIs)"""
    class Meta:
        model = DriverAnalytics
        fields = '__all__'
        read_only_fields = '__all__'


class CustomerAnalyticsSerializer(serializers.ModelSerializer):
    """محول تحليل سلوك وقيمة العملاء (CLV)"""
    class Meta:
        model = CustomerAnalytics
        fields = '__all__'
        read_only_fields = '__all__'