from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    search_products, 
    autocomplete_search, 
    SearchHistoryViewSet, 
    AdminSearchAnalyticsViewSet
)

app_name = 'search'

router = DefaultRouter()
router.register(r'search/history', SearchHistoryViewSet, basename='search-history')

urlpatterns = [
    path('search/', search_products, name='search-main'),
    path('search/suggestions/', autocomplete_search, name='search-suggestions'),
    path('admin/search/analytics/', AdminSearchAnalyticsViewSet.as_view({'get': 'list'}), name='admin-search-analytics'),
    path('', include(router.urls)),
]