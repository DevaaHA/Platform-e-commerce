from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError

from .models import Review, ReviewReport, StatusType
from .serializers import ReviewSerializer, ReviewReportSerializer
from .services import RatingCalculationService

class ReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.filter(status=StatusType.APPROVED)
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        order_id = self.request.data.get('order_id')
        if order_id and Review.objects.filter(user=self.request.user, order_id=order_id).exists():
            raise ValidationError("لقد قمت بتقييم هذا الطلب مسبقاً لمنع التكرار.")
        
        review = serializer.save(
            user=self.request.user,
            status=StatusType.APPROVED,
            verified_purchase=True
        )
        
        # تحديث ملخص التقييمات تلقائياً
        entity_type = review.type
        entity_id = review.product_id if entity_type == 'product' else (review.store_id if entity_type == 'store' else review.driver_id)
        if entity_id:
            RatingCalculationService.update_ratings_summary(entity_type, entity_id)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def report(self, request, pk=None):
        review = self.get_object()
        reason = request.data.get('reason')
        if not reason:
            return Response({'error': 'Reason is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        report = ReviewReport.objects.create(
            review=review,
            user=request.user,
            reason=reason
        )
        return Response({'status': 'Review reported successfully', 'report_id': str(report.id)}, status=status.HTTP_201_CREATED)


class AdminReviewViewSet(viewsets.ModelViewSet):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    permission_classes = [permissions.IsAdminUser]

    @action(detail=True, methods=['patch'])
    def approve(self, request, pk=None):
        review = self.get_object()
        review.status = StatusType.APPROVED
        review.save(update_fields=['status'])
        
        entity_type = review.type
        entity_id = review.product_id if entity_type == 'product' else (review.store_id if entity_type == 'store' else review.driver_id)
        if entity_id:
            RatingCalculationService.update_ratings_summary(entity_type, entity_id)
            
        return Response({'status': 'Review approved and summary updated'}, status=status.HTTP_200_OK)