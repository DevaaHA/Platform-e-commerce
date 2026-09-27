"""
URL configuration for config project (Souq JO Platform).
Production-Ready & High-Performance Version (Amazon/Temu Grade)
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView, SpectacularRedocView

urlpatterns = [
    # لوحة تحكم المشرفين المركزية (Super Admin)
    path('admin/', admin.site.urls),
    
    # 📚 مسارات توثيق واجهة برمجة التطبيقات (API Documentation)
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/schema/swagger-ui/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
    path('api/schema/redoc/', SpectacularRedocView.as_view(url_name='schema'), name='redoc'),

    # 🛒 مسارات تطبيق المتجر الأساسية (العملاء، المتاجر، المنتجات، السلة)
    path('api/', include('store.urls')),
    
    # 🚀 مسارات نظام التوصيل والكباتن
    path('api/v1/delivery/', include('delivery.urls')),
    
    # 🔥 مسارات الأنظمة المصغرة الجديدة (Microservices)
    path('api/v1/payments/', include('payments.urls')),
    path('api/v1/notifications/', include('notifications.urls')),
    path('api/v1/recommendations/', include('recommendations.urls')),
    path('api/v1/reviews/', include('reviews.urls')),
    path('api/v1/search/', include('search.urls')),
    path('api/v1/analytics/', include('analytics.urls')),
    path('api/v1/cms/', include('cms.urls')),
]

# تفعيل مسارات الوسائط (صور المنتجات، وثائق الكباتن) والملفات الثابتة محلياً أثناء التطوير
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)