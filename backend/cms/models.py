import uuid
from django.db import models
from django.conf import settings

class BannerLinkType(models.TextChoices):
    PRODUCT = 'product', 'منتج'
    STORE = 'store', 'متجر'
    CATEGORY = 'category', 'تصنيف'
    PAGE = 'page', 'صفحة داخلية'
    EXTERNAL = 'external', 'رابط خارجي'

class StatusType(models.TextChoices):
    ACTIVE = 'active', 'نشط'
    INACTIVE = 'inactive', 'غير نشط'
    PENDING = 'pending', 'معلق'

class Banner(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    image = models.TextField()
    mobile_image = models.TextField(blank=True, null=True)
    link_type = models.CharField(max_length=20, choices=BannerLinkType.choices, default=BannerLinkType.PRODUCT)
    link_id = models.UUIDField(blank=True, null=True)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    status = models.CharField(max_length=20, choices=StatusType.choices, default=StatusType.ACTIVE)

    def __str__(self):
        return self.title

class CMSPage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True, db_index=True)
    content = models.TextField()
    seo_title = models.CharField(max_length=255, blank=True, null=True)
    seo_description = models.TextField(blank=True, null=True)
    status = models.BooleanField(default=True)

    def __str__(self):
        return self.title

class FAQ(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    question = models.TextField()
    answer = models.TextField()
    category = models.CharField(max_length=100)
    order = models.IntegerField(default=0)
    status = models.BooleanField(default=True)

    def __str__(self):
        return self.question

class HomepageSection(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=100)
    type = models.CharField(max_length=50)
    position = models.IntegerField(default=0)
    settings = models.JSONField(default=dict)
    status = models.BooleanField(default=True)

    class Meta:
        ordering = ['position']

class Advertisement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store_id = models.UUIDField(db_index=True)
    type = models.CharField(max_length=50) # featured_store, featured_product, banner
    budget = models.DecimalField(max_digits=10, decimal_places=2)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    status = models.CharField(max_length=20, choices=StatusType.choices, default=StatusType.PENDING)

    def __str__(self):
        return f"Ad {self.type} for Store {self.store_id}"

class AdvertisementAnalytics(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    advertisement = models.ForeignKey(Advertisement, on_delete=models.CASCADE, related_name='analytics')
    impressions = models.IntegerField(default=0)
    clicks = models.IntegerField(default=0)
    date = models.DateField(db_index=True)