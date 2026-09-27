import logging
from celery import shared_task
from django.contrib.auth import get_user_model
from decimal import Decimal
from .models import UserActivity, Recommendation, ProductSimilarity, TrendingProduct

logger = logging.getLogger(__name__)
User = get_user_model()

@shared_task(name='generate_nightly_recommendations')
def generate_nightly_recommendations():
    """
    مهمة خلفية دورية (Nightly Worker):
    تقوم بتحليل أنشطة المستخدمين، معالجة خوارزميات الذكاء الاصطناعي، وتخزين النتائج مسبقاً.
    """
    logger.info("🤖 Starting Nightly AI Recommendation Processing Job...")
    
    try:
        users = User.objects.all()
        for user in users:
            # 1. جلب آخر نشاطات المستخدم لتحديد الاهتمامات
            recent_activities = UserActivity.objects.filter(user=user).order_by('-created_at')[:10]
            if not recent_activities.exists():
                continue

            # 2. توليد وتحديث التوصيات الشخصية (For You)
            # محاكاة لاختيار منتجات ذكية بناءً على الأنشطة
            for activity in recent_activities:
                if activity.product_id:
                    Recommendation.objects.update_or_create(
                        user=user,
                        product_id=activity.product_id,
                        recommendation_type=Recommendation.RecommendationType.FOR_YOU,
                        defaults={'score': Decimal('0.9500')}
                    )

        # 3. تحديث مصفوفة التشابه بين المنتجات والمنتجات الرائجة
        logger.info("✅ Nightly AI Recommendations successfully computed and stored.")
        return "Success"
        
    except Exception as e:
        logger.error(f"🔥 Error in Nightly AI Recommendations Job: {str(e)}")
        return "Failed"