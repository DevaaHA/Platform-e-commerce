from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import transaction

from .models import (
    Driver, Delivery, DriverLocation, DriverEarning, DeliveryHistory,
    TrackingSession, DeliveryRoute, LocationHistory
)
from .serializers import (
    DriverSerializer, DeliverySerializer, DriverLocationSerializer, 
    DriverEarningSerializer, DeliveryHistorySerializer,
    TrackingSessionSerializer, DeliveryRouteSerializer, LocationHistorySerializer
)

# ==========================================
# Core Delivery & Driver Views
# ==========================================

class DriverViewSet(viewsets.ModelViewSet):
    # استخدام prefetch_related لتحسين الأداء وجلب المركبات والوثائق باستعلام واحد (N+1 Optimization)
    queryset = Driver.objects.prefetch_related('vehicles', 'documents').all()
    serializer_class = DriverSerializer
    permission_classes = [IsAuthenticated]

    # PATCH /api/v1/delivery/drivers/{id}/status/
    @action(detail=True, methods=['patch'])
    def status(self, request, pk=None):
        driver = self.get_object()
        new_status = request.data.get('status')
        
        if new_status in dict(Driver.Status.choices):
            driver.status = new_status
            driver.save(update_fields=['status']) # تحديث حقل واحد فقط لسرعة الأداء
            return Response({'message': f'Driver status updated to {new_status}'}, status=status.HTTP_200_OK)
        return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)


class DeliveryViewSet(viewsets.ModelViewSet):
    queryset = Delivery.objects.all()
    serializer_class = DeliverySerializer
    permission_classes = [IsAuthenticated]

    # PATCH /api/v1/delivery/deliveries/{id}/status/
    @action(detail=True, methods=['patch'])
    def status(self, request, pk=None):
        delivery = self.get_object()
        new_status = request.data.get('status')
        old_status = delivery.status

        if new_status in dict(Delivery.Status.choices):
            # استخدام transaction.atomic لضمان تحديث الحالة وتسجيلها معاً لتجنب فقدان البيانات
            with transaction.atomic():
                delivery.status = new_status
                delivery.save(update_fields=['status'])
                
                # توثيق تغيير الحالة بشكل تلقائي
                DeliveryHistory.objects.create(
                    delivery=delivery,
                    old_status=old_status,
                    new_status=new_status
                )
            return Response({
                'message': f'Delivery status updated to {new_status}',
                'history_logged': True
            }, status=status.HTTP_200_OK)
            
        return Response({'error': 'Invalid status'}, status=status.HTTP_400_BAD_REQUEST)


class DriverEarningViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = DriverEarning.objects.select_related('delivery').all()
    serializer_class = DriverEarningSerializer
    permission_classes = [IsAuthenticated]


# ==========================================
# Day 12: Real-Time Tracking & Routes Views
# ==========================================

class TrackingSessionViewSet(viewsets.ModelViewSet):
    queryset = TrackingSession.objects.select_related('driver', 'customer', 'order').all()
    serializer_class = TrackingSessionSerializer
    permission_classes = [IsAuthenticated]

    # يمكن إضافة مسارات مخصصة هنا لبدء وإنهاء التتبع
    @action(detail=True, methods=['post'])
    def end_session(self, request, pk=None):
        session = self.get_object()
        session.status = TrackingSession.Status.COMPLETED
        session.save(update_fields=['status'])
        return Response({'status': 'Tracking session completed'}, status=status.HTTP_200_OK)


class DeliveryRouteViewSet(viewsets.ModelViewSet):
    queryset = DeliveryRoute.objects.all()
    serializer_class = DeliveryRouteSerializer
    permission_classes = [IsAuthenticated]


class LocationHistoryViewSet(viewsets.ReadOnlyModelViewSet):
    # هذا الـ ViewSet للقراءة فقط، سيتم استخدامه لرسم مسار الكابتن السابق أو لتحليل الـ AI
    queryset = LocationHistory.objects.all().order_by('-created_at')
    serializer_class = LocationHistorySerializer
    permission_classes = [IsAuthenticated]

    # جلب مسار كابتن معين
    def get_queryset(self):
        queryset = super().get_queryset()
        driver_id = self.request.query_params.get('driver_id')
        if driver_id:
            queryset = queryset.filter(driver_id=driver_id)
        return queryset