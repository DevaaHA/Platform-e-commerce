from django.db import models
from django.contrib.auth.models import AbstractUser, Group, Permission, BaseUserManager
from django.utils import timezone
from decimal import Decimal
import uuid

# ==========================================
# 0. مدير المستخدمين المخصص (Custom User Manager)
# ==========================================

class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email field must be set')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, password, **extra_fields)


# ==========================================
# 1. نماذج RBAC (الأدوار والصلاحيات المتقدمة للمتاجر)
# ==========================================

class Role(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=50, unique=True, db_index=True)
    display_name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    store = models.ForeignKey('Store', on_delete=models.CASCADE, null=True, blank=True, related_name='tenant_roles')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.display_name


class PermissionModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    module = models.CharField(max_length=50, db_index=True)
    action = models.CharField(max_length=50)
    description = models.TextField(blank=True, null=True)

    class Meta:
        unique_together = ('module', 'action')

    def __str__(self):
        return f"{self.module} - {self.action}"


class RolePermissions(models.Model):
    role = models.ForeignKey(Role, on_delete=models.CASCADE, related_name='permissions_rel')
    permission = models.ForeignKey(PermissionModel, on_delete=models.CASCADE)


# ==========================================
# 2. نماذج المستخدمين والمصادقة
# ==========================================

class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    username = models.CharField(max_length=150, unique=True, null=True, blank=True)
    email = models.EmailField(unique=True, db_index=True) 
    phone = models.CharField(max_length=20, unique=True, null=True, blank=True, db_index=True)
    email_verified = models.BooleanField(default=False)
    phone_verified = models.BooleanField(default=False)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    
    store = models.ForeignKey('Store', on_delete=models.SET_NULL, null=True, blank=True, related_name='tenant_users')
    
    # حقل الدور المرتبط بنظام الـ Role المتقدم (بالإضافة إلى إمكانية تخزين نوع الحساب كنص لتسهيل الاستعلام)
    role_obj = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True, blank=True, related_name='users')
    
    # 🚀 التحديث هنا: تم إضافة المشرف (supervisor)
    ROLE_CHOICES = (
        ('customer', 'مشتري (Customer)'),
        ('store_admin', 'تاجر / صاحب متجر (Store Owner)'),
        ('driver', 'كابتن توصيل (Driver)'),
        ('supervisor', 'مشرف (Supervisor)'),
        ('admin', 'مدير النظام (Admin)'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='customer', db_index=True)
    
    deleted_at = models.DateTimeField(null=True, blank=True)
    login_attempts = models.IntegerField(default=0)
    locked_until = models.DateTimeField(null=True, blank=True)
    
    groups = models.ManyToManyField(Group, related_name='store_user_set', blank=True)
    user_permissions = models.ManyToManyField(Permission, related_name='store_user_permissions_set', blank=True)
    
    objects = UserManager()
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['first_name', 'last_name']

    def __str__(self):
        return f"{self.email} ({self.role})"


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    birth_date = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, choices=[('M', 'Male'), ('F', 'Female')], null=True, blank=True)
    city = models.CharField(max_length=100, null=True, blank=True)
    address = models.TextField(null=True, blank=True)
    postal_code = models.CharField(max_length=20, null=True, blank=True)
    
    # الحقول الجديدة المضافة لربطها مع الفلاتر
    major = models.CharField(max_length=100, null=True, blank=True) # التخصص الأكاديمي
    wallet_balance = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    points = models.IntegerField(default=0)
    coupons_count = models.IntegerField(default=0)

    def __str__(self):
        return f"Profile for {self.user.email}"


class OTPCode(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='otps')
    code = models.CharField(max_length=6, db_index=True)
    type = models.CharField(max_length=10, choices=[('Email', 'Email'), ('SMS', 'SMS')])
    expires_at = models.DateTimeField()
    attempts = models.IntegerField(default=0)
    verified = models.BooleanField(default=False)


# ==========================================
# 3. نماذج إدارة المتاجر (Store Management)
# ==========================================

class Store(models.Model):
    STATUS_CHOICES = [('Pending', 'Pending'), ('Active', 'Active'), ('Suspended', 'Suspended'), ('Rejected', 'Rejected')]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='stores')
    name_ar = models.CharField(max_length=200)
    name_en = models.CharField(max_length=200)
    slug = models.SlugField(unique=True, db_index=True)
    description = models.TextField()
    email = models.EmailField()
    phone = models.CharField(max_length=20)
    logo = models.ImageField(upload_to='stores/logos/')
    cover_image = models.ImageField(upload_to='stores/covers/')
    city = models.CharField(max_length=100)
    area = models.CharField(max_length=100)
    address = models.TextField()
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Pending', db_index=True)
    featured = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name_ar


class StoreSettings(models.Model):
    store = models.OneToOneField(Store, on_delete=models.CASCADE, related_name='settings')
    minimum_order = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    free_delivery = models.BooleanField(default=False)
    preparation_time = models.PositiveIntegerField(default=30)
    auto_accept_orders = models.BooleanField(default=False)
    notification_email = models.BooleanField(default=True)
    notification_sms = models.BooleanField(default=False)
    notification_push = models.BooleanField(default=True)


class StoreHours(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='hours')
    day = models.CharField(max_length=20)
    open_time = models.TimeField()
    close_time = models.TimeField()
    is_closed = models.BooleanField(default=False)


class StoreEmployees(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='employees')
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    role = models.CharField(max_length=50)


class StoreSubscription(models.Model):
    STATUS_CHOICES = [('Active', 'Active'), ('Expired', 'Expired'), ('Cancelled', 'Cancelled')]
    store = models.OneToOneField(Store, on_delete=models.CASCADE, related_name='subscription')
    plan_name = models.CharField(max_length=100)
    start_date = models.DateField()
    end_date = models.DateField()
    commission = models.DecimalField(max_digits=5, decimal_places=2)
    max_products = models.PositiveIntegerField()
    max_staff = models.PositiveIntegerField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Active')


# ==========================================
# 4. نماذج المنتجات والتصنيفات
# ==========================================

class Category(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='categories', null=True, blank=True)
    name = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Product(models.Model):
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='products', null=True, blank=True)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='products')
    name = models.CharField(max_length=200, db_index=True)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class ProductVariant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='variants')
    name = models.CharField(max_length=100)
    sku = models.CharField(max_length=100, unique=True, db_index=True)
    barcode = models.CharField(max_length=100, null=True, blank=True, db_index=True)
    price_modifier = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.product.name} - {self.name}"


# ==========================================
# 5. نماذج إدارة المخزون (Inventory Ledger)
# ==========================================

class Warehouse(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='warehouses')
    name = models.CharField(max_length=150)
    city = models.CharField(max_length=100)
    address = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} - {self.store.name_ar}"


class Inventory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='inventory_records')
    variant = models.OneToOneField(ProductVariant, on_delete=models.CASCADE, null=True, blank=True, related_name='inventory')
    warehouse = models.ForeignKey(Warehouse, on_delete=models.SET_NULL, null=True, blank=True, related_name='inventory_items')
    
    quantity = models.IntegerField(default=0)
    reserved_quantity = models.IntegerField(default=0)
    minimum_quantity = models.IntegerField(default=5)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def available_quantity(self):
        return self.quantity - self.reserved_quantity

    def __str__(self):
        return f"Inventory for {self.product.name}"


class InventoryTransaction(models.Model):
    TRANSACTION_TYPES = [
        ('ADD', 'إضافة كمية'),
        ('DEDUCT', 'خصم كمية'),
        ('ADJUST', 'تعديل يدوي / جرد'),
        ('RESERVE', 'حجز كمية'),
        ('RELEASE', 'تحرير كمية محجوزة'),
        ('RETURN', 'مرتجع'),
        ('DAMAGE', 'تلف'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    inventory = models.ForeignKey(Inventory, on_delete=models.CASCADE, related_name='transactions')
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    
    previous_quantity = models.IntegerField()
    new_quantity = models.IntegerField()
    difference = models.IntegerField()
    
    reference_type = models.CharField(max_length=50, null=True, blank=True) 
    reference_id = models.UUIDField(null=True, blank=True, db_index=True)
    
    reason = models.TextField(null=True, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    created_at = models.DateTimeField(auto_now_add=True)


class InventoryAlert(models.Model):
    ALERT_TYPES = [
        ('LOW_STOCK', 'مخزون منخفض'),
        ('OUT_OF_STOCK', 'نفاد المخزون'),
    ]
    STATUS_CHOICES = [
        ('UNRESOLVED', 'غير معالج'),
        ('RESOLVED', 'تمت المعالجة'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    inventory = models.ForeignKey(Inventory, on_delete=models.CASCADE, related_name='alerts')
    alert_type = models.CharField(max_length=20, choices=ALERT_TYPES)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='UNRESOLVED', db_index=True)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)


# ==========================================
# 6. نماذج السلة والطلبات والمفضلة
# ==========================================

class Cart(models.Model):
    STATUS_CHOICES = [
        ('active', 'Active'),
        ('converted', 'Converted'),
        ('abandoned', 'Abandoned'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='carts', null=True, blank=True)
    session_id = models.CharField(max_length=255, null=True, blank=True, db_index=True)
    status = models.CharField(max_length=50, choices=STATUS_CHOICES, default='active')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Cart {self.id} - {self.status}"


class CartItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    variant = models.ForeignKey(ProductVariant, on_delete=models.SET_NULL, null=True, blank=True)
    store = models.ForeignKey(Store, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        price = self.unit_price if self.unit_price is not None else Decimal('0.00')
        disc = self.discount if self.discount is not None else Decimal('0.00')
        self.subtotal = (Decimal(str(price)) - Decimal(str(disc))) * Decimal(str(self.quantity))
        super().save(*args, **kwargs)


class Order(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=100, unique=True, db_index=True)
    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='store_orders')
    status = models.CharField(max_length=50, default='Pending', db_index=True)
    payment_status = models.CharField(max_length=50, default='Pending', db_index=True)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    tax = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    address_id = models.UUIDField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.order_number


class StoreOrder(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='store_breakdowns')
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='store_orders')
    status = models.CharField(max_length=50, default='Pending')
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    commission = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    store_amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)


class OrderItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    variant = models.ForeignKey(ProductVariant, on_delete=models.SET_NULL, null=True, blank=True)
    quantity = models.IntegerField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)


class OrderStatusHistory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='status_history')
    old_status = models.CharField(max_length=50, null=True, blank=True)
    new_status = models.CharField(max_length=50)
    changed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    notes = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)


class Invoice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.OneToOneField(Order, on_delete=models.CASCADE, related_name='invoice')
    invoice_number = models.CharField(max_length=100, unique=True, db_index=True)
    pdf_file = models.TextField(blank=True, null=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)


class Return(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='returns')
    customer = models.ForeignKey(User, on_delete=models.CASCADE)
    reason = models.TextField()
    status = models.CharField(max_length=50, default='Pending')
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='approved_returns')
    created_at = models.DateTimeField(auto_now_add=True)


class Wishlist(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='wishlist')
    created_at = models.DateTimeField(auto_now_add=True)


class WishlistItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    wishlist = models.ForeignKey(Wishlist, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('wishlist', 'product')


class SavedItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='saved_items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'product')


# ==========================================
# 7. نماذج الكوبونات والخصومات (Discount & Promotions Engine)
# ==========================================

class Coupon(models.Model):
    DISCOUNT_TYPES = [
        ('PERCENTAGE', 'نسبة مئوية'),
        ('FIXED', 'مبلغ ثابت'),
        ('FREE_DELIVERY', 'شحن مجاني')
    ]
    STATUS_CHOICES = [
        ('ACTIVE', 'فعال'),
        ('EXPIRED', 'منتهي'),
        ('DISABLED', 'معطل')
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='coupons', null=True, blank=True)
    code = models.CharField(max_length=50, unique=True, db_index=True)
    name = models.CharField(max_length=100)
    type = models.CharField(max_length=20, choices=DISCOUNT_TYPES)
    value = models.DecimalField(max_digits=10, decimal_places=2)
    max_discount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    minimum_order = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    
    usage_limit = models.PositiveIntegerField(null=True, blank=True)
    usage_limit_per_user = models.PositiveIntegerField(default=1)
    used_count = models.PositiveIntegerField(default=0)
    
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE', db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def is_valid(self):
        now = timezone.now()
        if self.status != 'ACTIVE': return False
        if self.start_date > now or self.end_date < now: return False
        if self.usage_limit and self.used_count >= self.usage_limit: return False
        return True

    def __str__(self):
        return self.code


class CouponUsage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coupon = models.ForeignKey(Coupon, on_delete=models.CASCADE, related_name='usages')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='coupon_usages')
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True, related_name='coupon_usages')
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2)
    used_at = models.DateTimeField(auto_now_add=True)


class DiscountRule(models.Model):
    RULE_TYPES = [
        ('SPECIFIC_PRODUCT', 'منتج محدد'),
        ('SPECIFIC_CATEGORY', 'تصنيف محدد'),
        ('EXCLUDE_PRODUCT', 'استثناء منتج')
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    coupon = models.ForeignKey(Coupon, on_delete=models.CASCADE, related_name='rules')
    rule_type = models.CharField(max_length=30, choices=RULE_TYPES)
    value = models.JSONField()


class Promotion(models.Model):
    STATUS_CHOICES = [('ACTIVE', 'فعال'), ('UPCOMING', 'قادم'), ('ENDED', 'منتهي')]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name='promotions', null=True, blank=True)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    type = models.CharField(max_length=50)
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='UPCOMING', db_index=True)

    def __str__(self):
        return self.name


class PromotionItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    promotion = models.ForeignKey(Promotion, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='promotions')
    discount_percentage = models.DecimalField(max_digits=5, decimal_places=2)