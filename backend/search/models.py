import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator

class SearchHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='search_history')
    keyword = models.CharField(max_length=255, db_index=True, verbose_name="كلمة البحث")
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "سجل البحث"
        verbose_name_plural = "سجلات البحث"
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.email} - {self.keyword}"


class SearchLog(models.Model):
    """تحليلات كلمات البحث وقياس مدى نجاح النتائج أو فشلها"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    keyword = models.CharField(max_length=255, db_index=True)
    results_count = models.IntegerField(default=0, verbose_name="عدد النتائج")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "سجل تحليلات البحث"
        verbose_name_plural = "سجلات تحليلات البحث"


class ProductSearchMetadata(models.Model):
    """مؤشرات الأداء الخاصة بالمنتج لغايات خوارزمية الترتيب والترشيح"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product_id = models.UUIDField(unique=True, db_index=True) # ارتباط مع نموذج المنتج
    views = models.IntegerField(default=0)
    searches = models.IntegerField(default=0)
    clicks = models.IntegerField(default=0)
    sales_count = models.IntegerField(default=0, db_index=True)

    class Meta:
        verbose_name = "مؤشر بحث المنتج"
        verbose_name_plural = "مؤشرات بحث المنتجات"


class SearchFilterConfig(models.Model):
    class FilterType(models.TextChoices):
        RANGE = 'range', 'مدى (رقمي)'
        CHOICE = 'choice', 'اختيارات متعددة'
        BOOLEAN = 'boolean', 'قيمة منطقية'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, verbose_name="اسم الفلتر")
    type = models.CharField(max_length=20, choices=FilterType.choices, default=FilterType.CHOICE)
    options = models.JSONField(help_text="الخيارات المتاحة للفلتر بصيغة JSON")
    status = models.BooleanField(default=True, db_index=True)

    class Meta:
        verbose_name = "إعدادات الفلتر"
        verbose_name_plural = "إعدادات الفلاتر"

    def __str__(self):
        return self.name