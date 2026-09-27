import uuid
from django.db import models
from django.conf import settings
from store.models import Order  # افترضنا أن تطبيق المتجر اسمه store

class Driver(models.Model):
    class Status(models.TextChoices):
        OFFLINE = 'OFFLINE', 'Offline'
        AVAILABLE = 'AVAILABLE', 'Available'
        BUSY = 'BUSY', 'Busy'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='driver_profile')
    vehicle_type = models.CharField(max_length=50, blank=True, null=True)
    vehicle_number = models.CharField(max_length=50, blank=True, null=True)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OFFLINE)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=5.00)
    total_deliveries = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.status}"


class DriverDocument(models.Model):
    class DocType(models.TextChoices):
        ID_CARD = 'ID_CARD', 'ID Card'
        DRIVING_LICENSE = 'DRIVING_LICENSE', 'Driving License'
        VEHICLE_REGISTRATION = 'VEHICLE_REGISTRATION', 'Vehicle Registration'

    class DocStatus(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        VERIFIED = 'VERIFIED', 'Verified'
        REJECTED = 'REJECTED', 'Rejected'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='documents')
    document_type = models.CharField(max_length=50, choices=DocType.choices)
    file_url = models.TextField() # أو models.FileField حسب إعدادات التخزين
    status = models.CharField(max_length=20, choices=DocStatus.choices, default=DocStatus.PENDING)
    verified_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)


class Vehicle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='vehicles')
    type = models.CharField(max_length=50) # e.g., Car, Motorcycle
    model = models.CharField(max_length=100)
    plate_number = models.CharField(max_length=20)


class Delivery(models.Model):
    class Status(models.TextChoices):
        ASSIGNED = 'Assigned', 'Assigned'
        ACCEPTED = 'Accepted', 'Accepted'
        PICKING_UP = 'Picking Up', 'Picking Up'
        PICKED_UP = 'Picked Up', 'Picked Up'
        ON_THE_WAY = 'On The Way', 'On The Way'
        ARRIVED = 'Arrived', 'Arrived'
        DELIVERED = 'Delivered', 'Delivered'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='delivery')
    driver = models.ForeignKey(Driver, on_delete=models.SET_NULL, null=True, blank=True, related_name='deliveries')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ASSIGNED)
    pickup_location = models.JSONField(help_text="Format: {'lat': ..., 'lng': ...}")
    dropoff_location = models.JSONField(help_text="Format: {'lat': ..., 'lng': ...}")
    distance = models.DecimalField(max_digits=10, decimal_places=2, help_text="Distance in KM", null=True, blank=True)
    estimated_time = models.IntegerField(help_text="Estimated time in minutes", null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Delivery {self.id} - {self.status}"


class DriverLocation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='locations')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    timestamp = models.DateTimeField(auto_now_add=True)


class DriverEarning(models.Model):
    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending'
        PAID = 'PAID', 'Paid'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='earnings')
    delivery = models.OneToOneField(Delivery, on_delete=models.CASCADE)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    created_at = models.DateTimeField(auto_now_add=True)


class DeliveryHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    delivery = models.ForeignKey(Delivery, on_delete=models.CASCADE, related_name='history')
    old_status = models.CharField(max_length=50)
    new_status = models.CharField(max_length=50)
    changed_at = models.DateTimeField(auto_now_add=True)


# ==========================================
# إضافة نماذج اليوم الثاني عشر (نظام التتبع المباشر)
# ==========================================

class TrackingSession(models.Model):
    class Status(models.TextChoices):
        ACTIVE = 'ACTIVE', 'Active'
        COMPLETED = 'COMPLETED', 'Completed'
        TERMINATED = 'TERMINATED', 'Terminated'

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='tracking_session')
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='tracking_sessions')
    customer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='customer_trackings')
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.ACTIVE)
    started_at = models.DateTimeField(auto_now_add=True)
    ended_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"Tracking for Order {self.order.id} - {self.status}"


class DeliveryRoute(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    delivery = models.OneToOneField(Delivery, on_delete=models.CASCADE, related_name='route')
    distance = models.DecimalField(max_digits=10, decimal_places=2, help_text="Distance in KM")
    duration = models.IntegerField(help_text="Duration in minutes")
    polyline = models.TextField(help_text="Google Maps Polyline string")
    created_at = models.DateTimeField(auto_now_add=True)


class LocationHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name='location_history')
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    accuracy = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    speed = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        # إضافة Index لتسريع عمليات البحث الجغرافي واسترجاع مسار كابتن معين
        indexes = [
            models.Index(fields=['driver', '-created_at']),
        ]