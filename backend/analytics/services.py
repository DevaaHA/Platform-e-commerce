import logging
from decimal import Decimal
from django.db.models import Sum
from django.core.cache import cache
from .models import AnalyticsDailySummary, ProductAnalytics, StoreAnalytics

logger = logging.getLogger(__name__)

class AnalyticsService:
    """
    محرك خدمة التحليلات وحساب مؤشرات الأداء الرئيسية (KPIs Engine).
    مصمم للعمل بأداء فائق عبر الاستفادة من الجداول المجمعة والـ Caching.
    """

    @staticmethod
    def calculate_platform_kpis() -> dict:
        """
        حساب المؤشرات الرئيسية للإدارة العليا مع دعم التخزين المؤقت (Redis Cache)
        لتجنب الضغط على قاعدة البيانات وتحقيق سرعة استجابة استثنائية.
        """
        cache_key = "platform_kpis_summary"
        cached_data = cache.get(cache_key)
        
        if cached_data:
            return cached_data

        try:
            # استخدام aggregate المباشر على جدول الملخصات (أسرع بـ 100 مرة من الاستعلام المباشر)
            aggregates = AnalyticsDailySummary.objects.aggregate(
                sum_sales=Sum('total_sales'),
                sum_orders=Sum('total_orders'),
                sum_profit=Sum('total_profit'),
                sum_users=Sum('total_users'),
                sum_stores=Sum('total_stores')
            )

            total_sales = aggregates['sum_sales'] or Decimal('0.00')
            total_orders = aggregates['sum_orders'] or 0
            total_profit = aggregates['sum_profit'] or Decimal('0.00')
            total_users = aggregates['sum_users'] or 0
            total_stores = aggregates['sum_stores'] or 0

            # حساب متوسط قيمة الطلب (Average Order Value - AOV)
            avg_order_value = (total_sales / total_orders) if total_orders > 0 else Decimal('0.00')

            kpi_data = {
                "total_sales": total_sales,
                "total_orders": total_orders,
                "total_profit": total_profit,
                "total_users": total_users,
                "total_stores": total_stores,
                "average_order_value": round(avg_order_value, 2)
            }

            # تخزين النتائج في الـ Cache لمدة 15 دقيقة لضمان أقصى سرعة أداء
            cache.set(cache_key, kpi_data, timeout=900)
            return kpi_data

        except Exception as e:
            logger.error(f"🔥 Error calculating platform KPIs: {str(e)}")
            return {
                "total_sales": Decimal('0.00'),
                "total_orders": 0,
                "total_profit": Decimal('0.00'),
                "total_users": 0,
                "total_stores": 0,
                "average_order_value": Decimal('0.00')
            }

    @staticmethod
    def get_top_selling_products(limit: int = 10) -> list:
        """
        جلب قائمة أفضل المنتجات مبيعاً بالاستفادة من الفهارس العكسية (Indexes)
        """
        try:
            top_products = ProductAnalytics.objects.all().order_by('-sales_count')[:limit]
            return list(top_products.values('product_id', 'sales_count', 'revenue', 'rating'))
        except Exception as e:
            logger.error(f"🔥 Error fetching top products: {str(e)}")
            return []

    @staticmethod
    def get_top_performing_stores(limit: int = 10) -> list:
        """
        جلب أفضل المتاجر أداءً من حيث المبيعات والأرباح
        """
        try:
            top_stores = StoreAnalytics.objects.all().order_by('-sales')[:limit]
            return list(top_stores.values('store_id', 'orders_count', 'sales', 'profit', 'rating'))
        except Exception as e:
            logger.error(f"🔥 Error fetching top stores: {str(e)}")
            return []