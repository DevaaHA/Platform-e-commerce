import uuid
from django.db import models
from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator

class ReviewType(models.TextChoices):
    PRODUCT = 'product', 'منتج'
    STORE = 'store', 'متجر'
    DRIVER = 'driver', 'كابتن'

class StatusType(models.TextChoices):
    PENDING = 'pending', 'معلق للمراجعة'
    APPROVED = 'approved', 'منشور'
    REJECTED = 'rejected', 'مرفوض'


class Review(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reviews')
    type = models.CharField(max_length=20, choices=ReviewType.choices, default=ReviewType.PRODUCT)
    
    # ارتباط مرن بالكيانات المختلفة (منتج، متجر، أو كابتن) وطلب الشراء
    product_id = models.UUIDField(blank=True, null=True, db_index=True)
    store_id = models.UUIDField(blank=True, null=True, db_index=True)
    driver_id = models.UUIDField(blank=True, null=True, db_index=True)
    order_id = models.UUIDField(unique=True, help_text="لضمان عدم تكرار التقييم لنفس الطلب")
    
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=20, choices=StatusType.choices, default=StatusType.PENDING)
    verified_purchase = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['product_id', 'status']),
            models.Index(fields=['store_id', 'status']),
            models.Index(fields=['rating']),
        ]

    def __str__(self):
        return f"Review {self.rating}★ by {self.user.email} ({self.type})"


class ReviewImage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='images')
    image_url = models.TextField()

    def __str__(self):
        return f"Image for Review {self.review.id}"


class RatingsSummary(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    entity_type = models.CharField(max_length=20, choices=ReviewType.choices)
    entity_id = models.UUIDField(db_index=True)
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.00)
    total_reviews = models.IntegerField(default=0)
    five_star = models.IntegerField(default=0)
    four_star = models.IntegerField(default=0)
    three_star = models.IntegerField(default=0)
    two_star = models.IntegerField(default=0)
    one_star = models.IntegerField(default=0)

    class Meta:
        unique_together = ('entity_type', 'entity_id')

    def __str__(self):
        return f"Summary {self.entity_type} {self.entity_id}: {self.average_rating}★ ({self.total_reviews})"


class ReviewReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    review = models.ForeignKey(Review, on_delete=models.CASCADE, related_name='reports')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    reason = models.TextField()
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report on Review {self.review.id} by {self.user.email}"