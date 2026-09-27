import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator

class UserActivity(models.Model):
    class ActivityType(models.TextChoices):
        VIEW = 'view', 'مشاهدة منتج'
        CART = 'cart', 'إضافة للسلة'
        WISHLIST = 'wishlist', 'إضافة للمفضلة'
        PURCHASE = 'purchase', 'شراء'
        SEARCH = 'search', 'بحث'
        SHARE = 'share', 'مشاركة'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='activities')
    activity_type = models.CharField(max_length=30, choices=ActivityType.choices, db_index=True)
    product_id = models.UUIDField(blank=True, null=True, db_index=True)
    metadata = models.JSONField(blank=True, null=True, help_text="بيانات إضافية عن النشاط بصيغة JSON")
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "نشاط المستخدم"
        verbose_name_plural = "أنشطة المستخدمين"
        indexes = [
            models.Index(fields=['user', 'activity_type', 'created_at']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.activity_type}"


class UserPreferences(models.Model):
    """تفضيلات المستخدم الصريحة لتوجيه محرك الذكاء الاصطناعي"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='ai_preferences')
    categories = models.JSONField(default=list, help_text="الأقسام المفضلة")
    brands = models.JSONField(default=list, help_text="العلامات التجارية المفضلة")
    price_range = models.JSONField(default=dict, help_text="نطاق السعر المفضل الحد الأدنى والأقصى")

    class Meta:
        verbose_name = "تفضيلات الذكاء الاصطناعي"
        verbose_name_plural = "تفضيلات الذكاء الاصطناعي للمستخدمين"


class Recommendation(models.Model):
    class RecommendationType(models.TextChoices):
        FOR_YOU = 'for_you', 'مقترح لك'
        SIMILAR = 'similar', 'منتجات مشابهة'
        ALSO_BOUGHT = 'also_bought', 'اشتراها عملاء آخرون'
        TRENDING = 'trending', 'الأكثر رواجاً'
        NEARBY = 'nearby', 'قريب منك'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, null=True, blank=True, related_name='recommendations')
    product_id = models.UUIDField(db_index=True)
    recommendation_type = models.CharField(max_length=30, choices=RecommendationType.choices, db_index=True)
    score = models.DecimalField(max_digits=5, decimal_places=4, default=Decimal('0.0000'), validators=[MinValueValidator(Decimal('0.0000'))])
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "توصية ذكية"
        verbose_name_plural = "التوصيات الذكية"
        indexes = [
            models.Index(fields=['user', 'recommendation_type', '-score']),
        ]


class ProductSimilarity(models.Model):
    """مصفوفة التشابه بين المنتجات (Content-Based Filtering Matrix)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product_id = models.UUIDField(db_index=True)
    similar_product_id = models.UUIDField(db_index=True)
    similarity_score = models.DecimalField(max_digits=5, decimal_places=4, validators=[MinValueValidator(Decimal('0.0000'))])

    class Meta:
        verbose_name = "تشابه المنتجات"
        verbose_name_plural = "مصفوفة تشابه المنتجات"
        unique_together = ('product_id', 'similar_product_id')


class TrendingProduct(models.Model):
    """المنتجات الرائجة بناءً على المشاهدات والمبيعات السريعة"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product_id = models.UUIDField(unique=True, db_index=True)
    views_count = models.IntegerField(default=0)
    sales_count = models.IntegerField(default=0)
    score = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    date = models.DateField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "منتج رائج"
        verbose_name_plural = "المنتجات الرائجة"


class AIModelStorage(models.Model):
    """إدارة نماذج التعلم الآلي وتتبع نسخها وحالتها"""
    class ModelStatus(models.TextChoices):
        ACTIVE = 'active', 'نشط'
        TRAINING = 'training', 'قيد التدريب'
        DEPRECATED = 'deprecated', 'معطل'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    model_name = models.CharField(max_length=100, db_index=True)
    version = models.CharField(max_length=50)
    status = models.CharField(max_length=20, choices=ModelStatus.choices, default=ModelStatus.ACTIVE)
    trained_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "نموذج ذكاء اصطناعي"
        verbose_name_plural = "نماذج الذكاء الاصطناعي"