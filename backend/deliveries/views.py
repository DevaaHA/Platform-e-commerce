from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from django.utils import timezone
from .models import Driver, DriverLocation, DeliveryOrder, DeliveryZone, DeliveryTracking
from .serializers import (
    DriverSerializer, DriverLocationSerializer, DeliveryOrderSerializer, 
    DeliveryZoneSerializer, DeliveryTrackingSerializer
)
from .services import DeliveryService

class DriverProfileViewSet(viewsets.ModelViewSet):
    """إدارة ملف الكابتن وحالته (متاح، مشغول، غير متصل)"""
    serializer_class = DriverSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return Driver.objects.all().select_related('user')
        return Driver.objects.filter(user=self.request.user).select_related('user')

    @action(detail=False, methods=['patch'])
    def update_status(self, request):
        """تغيير حالة الكابتن (متاح / غير متصل)"""
        new_status = request.data.get('status')
        if new_status not in [Driver.DriverStatus.OFFLINE, Driver.DriverStatus.AVAILABLE]:
            return Response({"error": "حالة غير صالحة."}, status=status.HTTP_400_BAD_REQUEST)
        
        driver, created = Driver.objects.get_or_create(
            user=request.user, 
            defaults={'vehicle_type': 'مركبة عامة', 'vehicle_number': '0000'}
        )
        driver.status = new_status
        driver.save()
        return Response({"message": f"تم تحديث الحالة إلى {driver.get_status_display()}"}, status=status.HTTP_200_OK)


class DriverOrderViewSet(viewsets.ReadOnlyModelViewSet):
    """إدارة الطلبات المسندة للكابتن وقبولها وتحديث مراحلها"""
    serializer_class = DeliveryOrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        try:
            driver = self.request.user.driver_profile
            return DeliveryOrder.objects.filter(driver=driver).select_related('order', 'driver')
        except Driver.DoesNotExist:
            return DeliveryOrder.objects.none()

    @action(detail=True, methods=['post'])
    def accept(self, request, pk=None):
        """قبول الطلب من قبل الكابتن"""
        delivery = self.get_object()
        if delivery.status != DeliveryOrder.DeliveryStatus.ASSIGNED:
            return Response({"error": "لا يمكن قبول هذا الطلب حالياً."}, status=status.HTTP_400_BAD_REQUEST)
        
        delivery.status = DeliveryOrder.DeliveryStatus.ACCEPTED
        delivery.save()
        return Response({"message": "تم قبول الطلب بنجاح. يرجى التوجه إلى المتجر."}, status=status.HTTP_200_OK)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """تحديث مراحل التوصيل (استلام من المتجر، في الطريق، وصل، تم التوصيل)"""
        delivery = self.get_object()
        new_status = request.data.get('status')
        
        delivery.status = new_status
        if new_status == DeliveryOrder.DeliveryStatus.PICKED_UP:
            delivery.picked_at = timezone.now()
        elif new_status == DeliveryOrder.DeliveryStatus.DELIVERED:
            DeliveryService.complete_delivery(delivery)
        delivery.save()

        return Response({"message": f"تم تحديث حالة التوصيل إلى {delivery.get_status_display()}"}, status=status.HTTP_200_OK)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def update_location(request):
    """نقطة استقبال إحداثيات الـ GPS المباشرة من تطبيق الكابتن (Real-Time Location)"""
    lat = request.data.get('latitude')
    lng = request.data.get('longitude')
    accuracy = request.data.get('accuracy')

    if lat is None or lng is None:
        return Response({"error": "الإحداثيات مطلوبة."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        driver = request.user.driver_profile
        driver.current_lat = lat
        driver.current_lng = lng
        driver.save()

        # حفظ السجل التاريخي للإحداثيات
        DriverLocation.objects.create(driver=driver, latitude=lat, longitude=lng, accuracy=accuracy)
        
        # البحث عن رحلة نشطة حالية وحفظ تتبع المسار الحي
        active_delivery = DeliveryOrder.objects.filter(
            driver=driver, 
            status__in=[
                DeliveryOrder.DeliveryStatus.ACCEPTED, 
                DeliveryOrder.DeliveryStatus.PICKED_UP, 
                DeliveryOrder.DeliveryStatus.ON_THE_WAY, 
                DeliveryOrder.DeliveryStatus.ARRIVED
            ]
        ).first()

        if active_delivery:
            DeliveryTracking.objects.create(delivery=active_delivery, latitude=lat, longitude=lng)

        return Response({"status": "success", "message": "تم تحديث الموقع بنجاح."}, status=status.HTTP_200_OK)
    except Driver.DoesNotExist:
        return Response({"error": "حساب الكابتن غير مسجل."}, status=status.HTTP_403_FORBIDDEN)


class CustomerTrackingViewSet(viewsets.ReadOnlyModelViewSet):
    """تتبع العميل لطلبه وموقع الكابتن الحي"""
    serializer_class = DeliveryOrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return DeliveryOrder.objects.filter(order__user=self.request.user).select_related('driver', 'order')


class AdminDeliveryViewSet(viewsets.ViewSet):
    """لوحة تحكم الأدمن المركزية لمراقبة الكباتن والرحلات الحية على الخريطة"""
    permission_classes = [permissions.IsAdminUser]

    def list(self, request):
        active_deliveries = DeliveryOrder.objects.exclude(
            status__in=[DeliveryOrder.DeliveryStatus.DELIVERED, DeliveryOrder.DeliveryStatus.CANCELLED]
        ).select_related('driver__user', 'order')
        
        active_drivers = Driver.objects.filter(
            status__in=[Driver.DriverStatus.AVAILABLE, Driver.DriverStatus.BUSY]
        ).select_related('user')
        
        data = {
            "active_deliveries_count": active_deliveries.count(),
            "active_drivers_count": active_drivers.count(),
            "drivers": DriverSerializer(active_drivers, many=True).data,
            "deliveries": DeliveryOrderSerializer(active_deliveries, many=True).data
        }
        return Response(data, status=status.HTTP_200_OK)