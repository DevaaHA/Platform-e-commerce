import logging
from decimal import Decimal
from django.db.models import Count
from .models import UserActivity, ProductSimilarity, Recommendation, TrendingProduct

logger = logging.getLogger(__name__)

class EventTrackingService:
    @staticmethod
    def track_activity(user, activity_type, product_id=None, metadata=None):
        """تسجيل تفاعلات وسلوك المستخدم الفوري لتحليلها لاحقاً بواسطة الذكاء الاصطناعي"""
        try:
            activity = UserActivity.objects.create(
                user=user,
                activity_type=activity_type,
                product_id=product_id,
                metadata=metadata or {}
            )
            logger.info(f"📊 Activity Tracked: {user.email} -> {activity_type}")
            return activity
        except Exception as e:
            logger.error(f"❌ Failed to track activity: {str(e)}")
            return None


class ProductSimilarityEngine:
    @staticmethod
    def calculate_similarity(product_a, product_b):
        """
        محرك قياس التشابه بين منتجين (بناءً على الفئة، العلامة التجارية، والتقارب السعري)
        """
        score = Decimal('0.0000')
        
        if product_a.get('category') == product_b.get('category'):
            score += Decimal('0.40')
            
        if product_a.get('brand') == product_b.get('brand'):
            score += Decimal('0.30')
            
        price_a = Decimal(str(product_a.get('price', 0)))
        price_b = Decimal(str(product_b.get('price', 0)))
        
        if price_a > 0:
            price_diff_ratio = abs(price_a - price_b) / price_a
            if price_diff_ratio <= Decimal('0.20'): # تقارب بالسعر بنسبة 20%
                score += Decimal('0.30')
                
        return score


class RecommendationService:
    @staticmethod
    def get_personalized_recommendations(user):
        """جلب التوصيات المخصصة للمستخدم (Recommended For You)"""
        recommendations = Recommendation.objects.filter(
            user=user, 
            recommendation_type=Recommendation.RecommendationType.FOR_YOU
        ).order_by('-score')[:10]
        
        return [str(rec.product_id) for rec in recommendations]

    @staticmethod
    def get_similar_products(product_id):
        """جلب المنتجات المشابهة لصفحة المنتج (You May Also Like)"""
        similar = ProductSimilarity.objects.filter(product_id=product_id).order_by('-similarity_score')[:6]
        return [str(item.similar_product_id) for item in similar]

    @staticmethod
    def get_trending_products():
        """جلب المنتجات الأكثر رواجاً وانشاراً"""
        trending = TrendingProduct.objects.order_by('-score', '-sales_count')[:10]
        return [str(item.product_id) for item in trending]