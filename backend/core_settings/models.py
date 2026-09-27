import uuid
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.core.exceptions import ValidationError
from django.db import transaction

class Setting(models.Model):
    class SettingType(models.TextChoices):
        BOOLEAN = 'boolean', 'منطقي (Boolean)'
        INTEGER = 'integer', 'رقم صحيح (Integer)'
        DECIMAL = 'decimal', 'رقم عشري (Decimal)'
        STRING = 'string', 'نص (String)'
        JSON = 'json', 'كائن (JSON)'

    class SettingGroup(models.TextChoices):
        GENERAL = 'general', 'إعدادات عامة'
        ORDERS = 'orders', 'الطلبات'
        STORES = 'stores', 'المتاجر'
        SYSTEM = 'system', 'النظام'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    key = models.CharField(max_length=100, unique=True, db_index=True, verbose_name="مفتاح الإعداد")
    value = models.JSONField(verbose_name="القيمة")
    type = models.CharField(max_length=50, choices=SettingType.choices, default=SettingType.STRING, verbose_name="نوع البيانات")
    group = models.CharField(max_length=50, choices=SettingGroup.choices, default=SettingGroup.GENERAL, db_index=True, verbose_name="المجموعة")
    description = models.TextField(blank=True, null=True, verbose_name="الوصف")
    is_public = models.BooleanField(default=False, db_index=True, verbose_name="متاح للواجهات الأمامية") 
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "إعداد النظام"
        verbose_name_plural = "إعدادات النظام"
        ordering = ['group', 'key']

    def __str__(self):
        return f"{self.get_group_display()} - {self.key}"

class PaymentSetting(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    provider = models.CharField(max_length=100, unique=True, verbose_name="مزود خدمة الدفع")
    credentials = models.JSONField(help_text="بيانات الاعتماد المشفرة (API Keys & Secrets)", verbose_name="بيانات الربط")
    status = models.BooleanField(default=False, db_index=True, verbose_name="الحالة")

    class Meta:
        verbose_name = "إعدادات الدفع"
        verbose_name_plural = "إعدادات الدفع"
        ordering = ['-status', 'provider']

    def __str__(self):
        return f"{self.provider} ({'مفعل' if self.status else 'معطل'})"

class DeliverySetting(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    base_fee = models.DecimalField(
        max_digits=10, decimal_places=2, default=0.00,
        validators=[MinValueValidator(0.00)],
        verbose_name="رسوم التوصيل الأساسية"
    )
    free_threshold = models.DecimalField(
        max_digits=10, decimal_places=2, default=0.00,
        validators=[MinValueValidator(0.00)],
        verbose_name="الحد الأدنى للتوصيل المجاني"
    )
    max_distance = models.IntegerField(
        default=10, 
        validators=[MinValueValidator(1)],
        help_text="بالكيلومترات", 
        verbose_name="أقصى مسافة"
    )
    estimated_time = models.IntegerField(
        default=30, 
        validators=[MinValueValidator(1)],
        help_text="بالدقائق", 
        verbose_name="الوقت المقدر"
    )

    class Meta:
        verbose_name = "إعدادات التوصيل"
        verbose_name_plural = "إعدادات التوصيل"

    def clean(self):
        # منع وجود أكثر من سجل لإعدادات التوصيل (Singleton Pattern Database Level)
        if not self.pk and DeliverySetting.objects.exists():
            raise ValidationError("لا يمكن إنشاء أكثر من سجل لإعدادات التوصيل. يرجى تعديل السجل الحالي.")

    def save(self, *args, **kwargs):
        self.full_clean()
        super().save(*args, **kwargs)

    def __str__(self):
        return "إعدادات التوصيل العامة للمنصة"

class TaxSetting(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, verbose_name="اسم الضريبة")
    percentage = models.DecimalField(
        max_digits=5, decimal_places=2, default=0.00,
        validators=[MinValueValidator(0.00), MaxValueValidator(100.00)],
        verbose_name="النسبة المئوية"
    )
    enabled = models.BooleanField(default=True, db_index=True, verbose_name="مفعلة")

    class Meta:
        verbose_name = "إعدادات الضرائب"
        verbose_name_plural = "إعدادات الضرائب"
        ordering = ['-enabled', 'name']

    def __str__(self):
        return f"{self.name} - {self.percentage}%"

class CurrencySetting(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    currency_code = models.CharField(max_length=10, unique=True, verbose_name="رمز العملة")
    symbol = models.CharField(max_length=5, verbose_name="الرمز")
    exchange_rate = models.DecimalField(
        max_digits=10, decimal_places=4, default=1.0000,
        validators=[MinValueValidator(0.0001)],
        verbose_name="سعر الصرف"
    )
    is_default = models.BooleanField(default=False, db_index=True, verbose_name="العملة الافتراضية")

    class Meta:
        verbose_name = "إعدادات العملات"
        verbose_name_plural = "إعدادات العملات"
        ordering = ['-is_default', 'currency_code']

    @transaction.atomic
    def save(self, *args, **kwargs):
        # الذكاء هنا: إذا تم تعيين هذه العملة كافتراضية، قم بإلغاء الافتراضية عن باقي العملات تلقائياً
        if self.is_default:
            CurrencySetting.objects.filter(is_default=True).exclude(pk=self.pk).update(is_default=False)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.currency_code} ({self.symbol})"