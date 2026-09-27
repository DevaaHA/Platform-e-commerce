import uuid
from decimal import Decimal
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator

class Driver(models.Model):
    class DriverStatus(models.TextChoices):
        OFFLINE = 'offline', 'غير متصل'
        AVAILABLE = 'available', 'متاح'
        BUSY = 'busy', 'مشغول في توصيل'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='driver_profile')
    vehicle_type = models.CharField(max_length=50, verbose_name="نوع المركبة") # سيارة، دراجة نارية
    vehicle_number = models.CharField(max_length=50, verbose_name="رقم اللوحة")
    status = models.CharField(max_length=20, choices=DriverStatus.choices, default=DriverStatus.OFFLINE, db_index=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=Decimal('5.00'), validators=[MinValueValidator(Decimal('0.00'))])
    current_lat = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True, verbose_name="خط العرض الحالي")
    current_lng = models.DecimalField(max_digits=9, decimal_places=6, blank=True, null=True, verbose_name="خط الطول الحالي")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "كابتن توصيل"
        verbose_name_plural = "كواتن التوصيل"

    def __str__(self):
        return f"{self.user.get_full_name()} ({self.get_status_display()})"


class DriverLocation(models.Model):
    """سجل تاريخي لإحداثيات الكابتن لتحليل المسارات"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='locations')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    accuracy = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "موقع الكابتن"
        verbose_name_plural = "مواقع الكباتن"


class DeliveryOrder(models.Model):
    class DeliveryStatus(models.TextChoices):
        FINDING = 'finding', 'جاري البحث عن كابتن'
        ASSIGNED = 'assigned', 'تم التعيين'
        ACCEPTED = 'accepted', 'قبل الكابتن الطلب'
        PICKED_UP = 'picked_up', 'تم استلام الطلب من المتجر'
        ON_THE_WAY = 'on_the_way', 'في الطريق إلى العميل'
        ARRIVED = 'arrived', 'وصول الكابتن لموقع العميل'
        DELIVERED = 'delivered', 'تم التوصيل بنجاح'
        CANCELLED = 'cancelled', 'ملغي'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField('orders.Order', on_delete=models.PROTECT, related_name='delivery_detail')
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries')
    status = models.CharField(max_length=30, choices=DeliveryStatus.choices, default=DeliveryStatus.FINDING, db_index=True)
    assigned_at = models.DateTimeField(blank=True, null=True)
    picked_at = models.DateTimeField(blank=True, null=True)
    delivered_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "تفاصيل التوصيل"
        verbose_name_plural = "تفاصيل التوصيل"
        indexes = [
            models.Index(fields=['status', 'created_at']),
        ]

    def __str__(self):
        return f"Delivery for Order #{self.order.id} - {self.get_status_display()}"


class DeliveryZone(models.Model):
    """إدارة مناطق التوصيل الرسومية (Geofencing)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100, verbose_name="اسم المنطقة")
    city = models.CharField(max_length=100, db_index=True, verbose_name="المدينة")
    coordinates = models.JSONField(help_text="إحداثيات المضلع الجغرافي للمنطقة (GeoJSON)")
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))], verbose_name="رسوم التوصيل")
    status = models.BooleanField(default=True, db_index=True)

    class Meta:
        verbose_name = "منطقة توصيل"
        verbose_name_plural = "مناطق التوصيل"

    def __str__(self):
        return f"{self.name} ({self.city})"


class DriverEarnings(models.Model):
    class EarningStatus(models.TextChoices):
        PENDING = 'pending', 'معلق'
        PAID = 'paid', 'تم الصرف'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.PROTECT, related_name='earnings')
    order = models.ForeignKey('orders.Order', on_delete=models.PROTECT)
    amount = models.DecimalField(max_digits=10, decimal_places=2, validators=[MinValueValidator(Decimal('0.00'))])
    status = models.CharField(max_length=20, choices=EarningStatus.choices, default=EarningStatus.PENDING, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        verbose_name = "أرباح الكابتن"
        verbose_name_plural = "أرباح الكباتن"


class DeliveryTracking(models.Model):
    """تتبع مسار الرحلة الحي (Live Tracking History)"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    delivery = models.ForeignKey(DeliveryOrder, on_delete=models.CASCADE, related_name='tracking_history')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    timestamp = models.DateTimeField(auto_now_add=True, db_index=True)