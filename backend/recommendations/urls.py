from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    get_recommendations,
    get_similar_products,
    get_trending_products,
    track_user_event,
    UserPreferencesViewSet,
    admin_ai_analytics
)

app_name = 'recommendations'

router = DefaultRouter()
router.register(r'user/preferences', UserPreferencesViewSet, basename='user-preferences')

urlpatterns = [
    path('recommendations/', get_recommendations, name='user-recommendations'),
    path('products/<str:pk>/similar/', get_similar_products, name='product-similar'),
    path('products/trending/', get_trending_products, name='products-trending'),
    path('events/track/', track_user_event, name='events-track'),
    path('admin/ai/analytics/', admin_ai_analytics, name='admin-ai-analytics'),
    path('', include(router.urls)),
]