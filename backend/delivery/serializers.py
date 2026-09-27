from rest_framework import serializers
from .models import (
    Driver, Vehicle, Delivery, DriverLocation, DriverEarning, 
    DriverDocument, DeliveryHistory,
    TrackingSession, DeliveryRoute, LocationHistory
)

# ==========================================
# Base Delivery & Driver Serializers
# ==========================================

class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = '__all__'
        read_only_fields = ('id',)

class DriverDocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverDocument
        fields = '__all__'
        read_only_fields = ('id',)

class DriverSerializer(serializers.ModelSerializer):
    # دمج بيانات المركبات والوثائق لتظهر مباشرة عند استدعاء الكابتن (لتقليل الـ API calls)
    vehicles = VehicleSerializer(many=True, read_only=True)
    documents = DriverDocumentSerializer(many=True, read_only=True)
    
    class Meta:
        model = Driver
        fields = '__all__'
        # حماية الحقول التي يتم توليدها تلقائياً أو التي تعتمد على النظام
        read_only_fields = ('id', 'created_at', 'rating', 'total_deliveries')

class DeliverySerializer(serializers.ModelSerializer):
    class Meta:
        model = Delivery
        fields = '__all__'
        read_only_fields = ('id', 'delivered_at')

class DriverLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLocation
        fields = '__all__'
        read_only_fields = ('id', 'timestamp')

class DriverEarningSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverEarning
        fields = '__all__'
        read_only_fields = ('id', 'created_at')

class DeliveryHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryHistory
        fields = '__all__'
        read_only_fields = ('id', 'changed_at')


# ==========================================
# Day 12: Real-Time Tracking & Routes Serializers
# ==========================================

class TrackingSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = TrackingSession
        fields = '__all__'
        read_only_fields = ('id', 'started_at', 'ended_at')

class DeliveryRouteSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryRoute
        fields = '__all__'
        read_only_fields = ('id', 'created_at')

class LocationHistorySerializer(serializers.ModelSerializer):
    class Meta:
        model = LocationHistory
        fields = '__all__'
        read_only_fields = ('id', 'created_at')