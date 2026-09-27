from rest_framework import serializers
from .models import Driver, DriverLocation, DeliveryOrder, DeliveryZone, DriverEarnings, DeliveryTracking

class DriverSerializer(serializers.ModelSerializer):
    full_name = serializers.CharField(source='user.get_full_name', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = Driver
        fields = '__all__'
        read_only_fields = ['id', 'rating', 'current_lat', 'current_lng', 'updated_at']

class DriverLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLocation
        fields = '__all__'
        read_only_fields = ['id', 'created_at']

    def validate_latitude(self, value):
        if not (-90 <= value <= 90):
            raise serializers.ValidationError("خط العرض يجب أن يكون بين -90 و 90.")
        return value

    def validate_longitude(self, value):
        if not (-180 <= value <= 180):
            raise serializers.ValidationError("خط الطول يجب أن يكون بين -180 و 180.")
        return value

class DeliveryOrderSerializer(serializers.ModelSerializer):
    driver_details = DriverSerializer(source='driver', read_only=True)

    class Meta:
        model = DeliveryOrder
        fields = '__all__'
        read_only_fields = ['id', 'assigned_at', 'picked_at', 'delivered_at', 'created_at']

class DeliveryZoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryZone
        fields = '__all__'

class DriverEarningsSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverEarnings
        fields = '__all__'
        read_only_fields = ['id', 'created_at']

class DeliveryTrackingSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeliveryTracking
        fields = '__all__'
        read_only_fields = ['id', 'timestamp']