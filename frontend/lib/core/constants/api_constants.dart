class ApiConstants {
  // 🚀 رابط الأساس الموحد للخادم
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // 1. مسارات المصادقة (Authentication)
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String refreshToken = '/auth/refresh/';
  static const String verifyEmail = '/auth/verify-email/';
  static const String sendOtp = '/auth/send-otp/';
  static const String verifyOtp = '/auth/verify-otp/';
  static const String forgotPassword = '/auth/forgot-password/';
  static const String resetPassword = '/auth/reset-password/';

  // 2. مسارات المنتجات (Products)
  static const String products = '/products/';
  static String productDetail(String id) => '/products/$id/';

  // مسارات إدارة المتاجر
  static const String stores = '/stores/';
  static String storeSettings(String id) => '/stores/$id/settings/';
  static String storeHours(String id) => '/stores/$id/hours/';
  static const String subscriptions = '/subscriptions/';

  // 3. مسارات الملف الشخصي (Profile)
  static const String profile = '/profile/';
  static const String updatePassword = '/profile/password/';
  static const String uploadAvatar = '/profile/avatar/'; // 🚀 مسار رفع الصورة
  static const String addresses = '/profile/addresses/';
  static String addressDetail(String id) => '/profile/addresses/$id/';
  static const String savedPaymentMethods = '/profile/payment-methods/';

  // المحفظة والولاء
  static const String wallet = '/wallet/';
  static const String walletTransactions = '/wallet/transactions/';
  static const String loyaltyPoints = '/loyalty-points/';
  static const String redeemPoints = '/loyalty-points/redeem/';

  // غرفة القياس بالذكاء الاصطناعي
  static const String aiFittingSettings = '/ai-fitting/settings/';
  static const String aiFittingGenerate = '/ai-fitting/generate/';

  // 4. مسارات المستخدمين وإدارة الصلاحيات (Users & RBAC)
  static const String users = '/users/';
  static const String roles = '/roles/';
  static const String permissions = '/permissions/';
  static const String auditLogs = '/audit-logs/';

  // 5. مسارات إدارة المنتجات والمخزون
  static const String storeProducts = '/products/';
  static String storeProductDetail(String id) =>
      '/products/$id/'; // ✅ تمت إعادتها لحل الخطأ
  static String updateStock(String id) => '/products/$id/stock/';
  static String userStatus(String id) => '/users/$id/status/';
  static String userResetPassword(String id) => '/users/$id/reset-password/';

  // 6. مسارات المخزون
  static const String inventoryList = '/inventory/';
  static String inventoryDetail(String id) => '/inventory/$id/';
  static const String inventoryAdjust = '/inventory/adjust/';
  static const String inventoryReserve = '/inventory/reserve/';
  static const String inventoryTransactions = '/inventory/transactions/';
  static const String inventoryAlerts = '/inventory/alerts/';

  // 7. مسارات سلة التسوق وقائمة الرغبات (Wishlist & Cart)
  static const String cart = '/cart/';
  static const String cartItems = '/cart/items/';
  static String cartItemDetail(String id) => '/cart/items/$id/';
  static const String wishlist = '/wishlist/';
  static const String wishlistItems = '/wishlist/items/';
  static String wishlistDetail(String id) => '/wishlist/items/$id/';
  static const String cartSummary = '/cart/summary/';

  // 8. مسارات إدارة الطلبات والفواتير
  static const String orders = '/orders/';
  static String orderDetail(String id) => '/orders/$id/';
  static String cancelOrder(String id) => '/orders/$id/cancel/';
  static String returnOrder(String id) => '/orders/$id/return/';

  // طلبات التاجر
  static const String storeOrders = '/store/orders/';
  static String storeOrderDetail(String id) => '/store/orders/$id/';
  static String acceptStoreOrder(String id) => '/store/orders/$id/accept/';
  static String updateStoreOrderStatus(String id) =>
      '/store/orders/$id/status/';

  // الفواتير
  static String orderInvoice(String id) => '/orders/$id/invoice/';

  // 9. مسارات المعاملات المالية والدفع
  static const String paymentCreate = '/payments/create/';
  static String paymentDetail(String id) => '/payments/$id/';
  static String retryPayment(String id) => '/payments/$id/retry/';
  static const String paymentWebhook = '/payments/webhook/';
  static const String customerPayments = '/customer/payments/';
  static const String refunds = '/refunds/';

  // 10. مسارات الكوبونات والعروض الترويجية
  static const String couponsList = '/coupons/';
  static const String applyCoupon = '/cart/apply-coupon/';
  static const String removeCoupon = '/cart/remove-coupon/';
  static const String promotionsList = '/promotions/';

  // 11. مسارات الكباتن والتوصيل
  static const String driverDashboard = '/driver/dashboard/';
  static const String driverAvailableOrders = '/driver/orders/available/';
  static String driverAcceptOrder(String id) => '/driver/orders/$id/accept/';
  static String updateDeliveryStatus(String id) => '/deliveries/$id/status/';
  static String deliveryDetail(String id) => '/deliveries/$id/';
  static const String driverEarnings = '/driver/earnings/';
  static const String driverLocation = '/driver/location/';
  static const String adminDrivers = '/admin/drivers/';

  // 12. مسارات التتبع والخرائط المباشرة
  static const String locationUpdate = '/location/update/';
  static String currentDriverLocation(String driverId) =>
      '/location/current/$driverId/';
  static String trackingSession(String orderId) => '/tracking/$orderId/';
  static const String calculateRoute = '/routes/calculate/';

  // 13. مسارات نظام الإشعارات
  static const String notificationsList = '/notifications/';
  static String notificationRead(String id) => '/notifications/$id/read/';
  static String notificationDelete(String id) => '/notifications/$id/';
  static const String notificationSettings = '/user/notification-settings/';
  static const String registerDevice = '/devices/register/';

  // 14. مسارات التقييمات والمراجعات
  static String productReviews(String productId) =>
      '/products/$productId/reviews/';
  static String storeReviews(String storeId) => '/stores/$storeId/reviews/';
  static String driverReviews(String driverId) => '/drivers/$driverId/reviews/';
  static const String createReview = '/review/create/';
  static const String adminReviews = '/admin/reviews/';
  static String reviewModeration(String id) => '/admin/reviews/$id/approve/';

  // 15. مسارات التقارير والتحليلات الشاملة
  static const String adminDashboardAnalytics = '/admin/dashboard/';
  static const String storeDashboardAnalytics = '/store/dashboard/';
  static const String driverDashboardAnalytics = '/driver/dashboard/';
  static const String salesReports = '/admin/reports/sales/';
  static const String productReports = '/admin/reports/products/';
  static const String storeReports = '/admin/reports/stores/';
  static const String exportReports = '/admin/reports/export/';

  // 16. مسارات لوحة تحكم السوبر أدمن وإدارة المنصة
  static const String superAdminDashboard = '/admin/dashboard/';
  static const String adminUsersList = '/admin/users/';
  static const String adminStoresList = '/admin/stores/';
  static String adminStoreApprove(String id) => '/admin/stores/$id/approve/';
  static String adminStoreStatus(String id) => '/admin/stores/$id/status/';
  static const String adminRolesList = '/admin/roles/';

  // 17. مسارات نظام المحتوى والإعلانات (CMS)
  static const String homepageContent = '/homepage/';
  static const String bannersList = '/banners/';
  static const String adminBanners = '/admin/banners/';
  static const String faqList = '/faq/';
  static const String advertisements = '/advertisements/';

  // 18. مسارات إعدادات النظام والتهيئة العامة
  static const String systemSettings = '/admin/settings/';
  static const String paymentSettings = '/admin/payment-settings/';
  static const String deliverySettings = '/admin/delivery-settings/';
  static const String localizationSettings = '/settings/languages/';

  // 19. مسارات نظام المراقبة وسجلات التدقيق (Audit Logs)
  static const String auditLogsList = '/admin/audit-logs/';
  static String auditLogDetail(String id) => '/admin/audit-logs/$id/';
  static const String securityEventsList = '/admin/security/events/';
  static const String loginHistoryList = '/admin/login-history/';

  // 20. مسارات نظام الدفع المتقدم والفوترة
  static const String createPayment =
      '/payments/create/'; // ✅ تمت إعادتها لحل الخطأ
  static const String processPayment = '/payments/process/';
  static const String adminFinance = '/admin/finance/';

  // 22. مسارات نظام البحث المتقدم واكتشاف المنتجات
  static const String searchProducts = '/search/';
  static const String searchSuggestions = '/search/suggestions/';
  static const String searchFilters = '/search/filters/';
  static const String searchHistory = '/search/history/';

  // 23. مسارات نظام التوصيات والذكاء الاصطناعي (AI Recommendations)
  static const String userRecommendations = '/recommendations/';
  static String similarProducts(String id) => '/products/$id/similar/';
  static String alsoBoughtProducts(String id) => '/products/$id/also-bought/';
  static const String trendingProducts = '/products/trending/';
  static const String trackEvent = '/events/track/';
}
