import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings

class AnalyticsDailySummary(models.Model):
    """الملخص اليومي الشامل (لتغذية الرسوم البيانية الرئيسية بسرعة فائقة)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    date = models.DateField(unique=True, db_index=True)
    total_orders = models.IntegerField(default=0)
    total_sales = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    total_profit = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    total_users = models.IntegerField(default=0)
    total_stores = models.IntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True) # تتبع آخر تحديث من الـ Celery Worker

    class Meta:
        verbose_name = "ملخص يومي"
        verbose_name_plural = "الملخصات اليومية"
        ordering = ['-date']
        indexes = [
            models.Index(fields=['-date']),
        ]

    def __str__(self):
        return f"Summary for {self.date} - Sales: {self.total_sales} JOD"


class ProductAnalytics(models.Model):
    """تحليلات أداء المنتجات (لتغذية قوائم أفضل المنتجات مبيعاً)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product_id = models.UUIDField(unique=True, db_index=True)
    views = models.IntegerField(default=0)
    sales_count = models.IntegerField(default=0)
    revenue = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal('0.00'))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "تحليل المنتج"
        verbose_name_plural = "تحليلات المنتجات"
        # فهارس مركبة وعكسية لاستخراج الـ Top Sellers بـ O(1) Time Complexity
        indexes = [
            models.Index(fields=['-sales_count']),
            models.Index(fields=['-revenue']),
            models.Index(fields=['-views']),
        ]

    def __str__(self):
        return f"Product Analytics {self.product_id}"


class StoreAnalytics(models.Model):
    """تحليلات أداء المتاجر والتجار"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store_id = models.UUIDField(unique=True, db_index=True)
    orders_count = models.IntegerField(default=0)
    sales = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    profit = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal('0.00'))
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal('0.00'))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "تحليل المتجر"
        verbose_name_plural = "تحليلات المتاجر"
        indexes = [
            models.Index(fields=['-sales']),
            models.Index(fields=['-rating']),
        ]

    def __str__(self):
        return f"Store Analytics {self.store_id}"


class DriverAnalytics(models.Model):
    """مؤشرات أداء الكباتن (KPIs)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver_id = models.UUIDField(unique=True, db_index=True)
    deliveries_count = models.IntegerField(default=0)
    earnings = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal('0.00'))
    average_delivery_time = models.IntegerField(default=0, help_text="متوسط وقت التوصيل بالدقائق")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "تحليل الكابتن"
        verbose_name_plural = "تحليلات الكباتن"
        indexes = [
            models.Index(fields=['-deliveries_count']),
            models.Index(fields=['average_delivery_time']), # تصاعدي لمعرفة أسرع الكباتن
        ]

    def __str__(self):
        return f"Driver Analytics {self.driver_id}"


class CustomerAnalytics(models.Model):
    """تحليل القيمة الدائمة للعميل (Customer Lifetime Value - CLV)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.UUIDField(unique=True, db_index=True)
    orders_count = models.IntegerField(default=0)
    total_spent = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    last_order = models.DateTimeField(blank=True, null=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "تحليل العميل"
        verbose_name_plural = "تحليلات العملاء"
        indexes = [
            models.Index(fields=['-total_spent']),
            models.Index(fields=['-orders_count']),
        ]

    def __str__(self):
        return f"Customer Analytics {self.user_id}"