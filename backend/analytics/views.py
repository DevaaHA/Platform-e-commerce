import logging
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import (
    AnalyticsDailySummary, 
    ProductAnalytics, 
    StoreAnalytics, 
    DriverAnalytics
)
from .serializers import (
    AnalyticsDailySummarySerializer, 
    ProductAnalyticsSerializer, 
    StoreAnalyticsSerializer, 
    DriverAnalyticsSerializer
)
from .services import AnalyticsService
from .exports import ExportService

logger = logging.getLogger(__name__)

class AdminDashboardAnalyticsViewSet(viewsets.ViewSet):
    """
    لوحة تحكم وتحليلات الإدارة العليا (Super Admin Analytics ViewSet).
    مصممة وفق المعايير المؤسسية لتوفير أقصى سرعة أداء (High-Performance OLAP APIs).
    """
    permission_classes = [permissions.IsAdminUser]

    @action(detail=False, methods=['get'])
    def overview(self, request):
        """نظرة شاملة وعامة على مؤشرات الأداء والملخصات اليومية الأخيرة"""
        try:
            kpis = AnalyticsService.calculate_platform_kpis()
            daily_summaries = AnalyticsDailySummary.objects.all().order_by('-date')[:30]
            serializer = AnalyticsDailySummarySerializer(daily_summaries, many=True)
            
            return Response({
                "success": True,
                "kpis": kpis,
                "recent_analytics": serializer.data
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"🔥 Error in analytics overview: {str(e)}")
            return Response(
                {"error": "حدث خطأ أثناء جلب لوحة التحليلات العامة."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def sales_report(self, request):
        """تقرير المبيعات الشامل (محدود بآخر سنة لضمان استقرار الأداء)"""
        try:
            summaries = AnalyticsDailySummary.objects.all().order_by('-date')[:365]
            serializer = AnalyticsDailySummarySerializer(summaries, many=True)
            return Response({
                "success": True,
                "count": len(serializer.data),
                "data": serializer.data
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"🔥 Error fetching sales report: {str(e)}")
            return Response(
                {"error": "فشل في جلب تقرير المبيعات."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def export_sales(self, request):
        """تصدير تقارير المبيعات بصيغة CSV باستخدام البث الحي (Streaming)"""
        try:
            summaries = AnalyticsDailySummary.objects.all().order_by('-date')
            return ExportService.export_sales_to_csv(summaries)
        except Exception as e:
            logger.error(f"🔥 Error exporting sales: {str(e)}")
            return Response(
                {"error": "فشل تصدير التقرير."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def products_report(self, request):
        """تقرير أداء المنتجات (أفضل المنتجات مبيعاً بالاعتماد على الفهارس العكسية)"""
        try:
            products = ProductAnalytics.objects.all().order_by('-sales_count')[:100]
            serializer = ProductAnalyticsSerializer(products, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"🔥 Error fetching products report: {str(e)}")
            return Response(
                {"error": "فشل في جلب تقرير المنتجات."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def stores_report(self, request):
        """تقرير أداء المتاجر والتجار"""
        try:
            stores = StoreAnalytics.objects.all().order_by('-sales')[:100]
            serializer = StoreAnalyticsSerializer(stores, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"🔥 Error fetching stores report: {str(e)}")
            return Response(
                {"error": "فشل في جلب تقرير المتاجر."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=False, methods=['get'])
    def drivers_report(self, request):
        """تقرير أداء الكباتن وسرعة التوصيل"""
        try:
            drivers = DriverAnalytics.objects.all().order_by('-deliveries_count')[:100]
            serializer = DriverAnalyticsSerializer(drivers, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"🔥 Error fetching drivers report: {str(e)}")
            return Response(
                {"error": "فشل في جلب تقرير الكباتن."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )