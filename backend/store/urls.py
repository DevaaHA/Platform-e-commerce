from django.urls import path, include
from rest_framework_simplejwt.views import TokenRefreshView
from rest_framework.routers import DefaultRouter

from .views import (
    RegisterView,
    CustomLoginView,
    ProductListCreateView,
    CartAPIView,
    CartItemAPIView,
    CartMergeAPIView,
    WishlistView,
    UserListView,
    UserDetailView,
    RoleListView,
    PermissionListView,
    StoreViewSet,
    StoreSettingsView,
    StoreSubscriptionView,
    InventoryViewSet,
    InventoryTransactionViewSet,
    CustomerOrderViewSet,
    StoreOrderViewSet,
    ReturnManagementViewSet,
    WalletAPIView,
    UserProfileView, # 🚀 استيراد كلاس البروفايل الجديد بدلاً من الدالة القديمة
    CouponViewSet,
    PromotionViewSet,
    ApplyCouponView
)

router = DefaultRouter()
router.register(r'stores', StoreViewSet, basename='store')
router.register(r'inventory', InventoryViewSet, basename='inventory')
router.register(r'inventory-transactions', InventoryTransactionViewSet, basename='inventory-transactions')
router.register(r'orders', CustomerOrderViewSet, basename='customer-orders')
router.register(r'store/orders', StoreOrderViewSet, basename='store-orders')
router.register(r'returns', ReturnManagementViewSet, basename='returns')
router.register(r'coupons', CouponViewSet, basename='coupon')
router.register(r'promotions', PromotionViewSet, basename='promotion')

urlpatterns = [
    # --- مسارات المصادقة ---
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/login/', CustomLoginView.as_view(), name='login'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # 🚀 مسارات الملف الشخصي المحدثة (تدعم جلب البيانات، التعديل، ورفع الصورة)
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('profile/avatar/', UserProfileView.as_view(), name='user-avatar-upload'),

    # --- مسارات المنتجات ---
    path('products/', ProductListCreateView.as_view(), name='product-list'),

    # --- مسارات السلة ---
    path('cart/', CartAPIView.as_view(), name='cart-detail'),
    path('cart/items/', CartItemAPIView.as_view(), name='cart-items-add'),
    path('cart/items/<uuid:item_id>/', CartItemAPIView.as_view(), name='cart-item-modify'),
    path('cart/merge/', CartMergeAPIView.as_view(), name='cart-merge'),
    path('cart/apply-coupon/', ApplyCouponView.as_view(), name='apply-coupon'),
    
    # 🚀 المسارات المحدثة والكاملة للـ Wishlist لمنع خطأ 404
    path('wishlist/', WishlistView.as_view(), name='wishlist'),
    path('wishlist/items/', WishlistView.as_view(), name='wishlist-items'),
    path('wishlist/items/<uuid:item_id>/', WishlistView.as_view(), name='wishlist-item-detail'),

    # --- مسارات المستخدمين والأدوار ---
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<uuid:pk>/', UserDetailView.as_view(), name='user-detail'),
    path('roles/', RoleListView.as_view(), name='project-roles'),
    path('permissions/', PermissionListView.as_view(), name='permission-permissions'),

    # --- مسارات إعدادات المتاجر ---
    path('stores/<uuid:store_id>/settings/', StoreSettingsView.as_view(), name='store-settings'),
    path('stores/<uuid:store_id>/subscription/', StoreSubscriptionView.as_view(), name='store-subscription'),

    # --- مسار المحفظة ---
    path('wallet/', WalletAPIView.as_view(), name='wallet-api'),

    # --- مسارات الـ Router الأساسية ---
    path('', include(router.urls)),
]