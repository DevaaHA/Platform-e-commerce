from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import HomepageViewSet, BannerViewSet, CMSPageViewSet, FAQViewSet, AdvertisementViewSet

router = DefaultRouter()
router.register(r'homepage', HomepageViewSet, basename='homepage')
router.register(r'banners', BannerViewSet, basename='banner')
router.register(r'pages', CMSPageViewSet, basename='cms-page')
router.register(r'faq', FAQViewSet, basename='faq')
router.register(r'advertisements', AdvertisementViewSet, basename='advertisement')

urlpatterns = [
    path('', include(router.urls)),
]