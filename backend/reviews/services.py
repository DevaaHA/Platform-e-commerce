from decimal import Decimal
from django.db import transaction
from .models import Review, RatingsSummary, ReviewType, StatusType

class RatingCalculationService:
    @staticmethod
    @transaction.atomic
    def update_ratings_summary(entity_type, entity_id):
        """
        تقوم هذه الخدمة بإعادة حساب متوسط التقييم وتوزيع النجوم (من 1 إلى 5) بدقة فائقة
        """
        approved_reviews = Review.objects.filter(
            type=entity_type,
            status=StatusType.APPROVED
        )
        
        if entity_type == ReviewType.PRODUCT:
            approved_reviews = approved_reviews.filter(product_id=entity_id)
        elif entity_type == ReviewType.STORE:
            approved_reviews = approved_reviews.filter(store_id=entity_id)
        elif entity_type == ReviewType.DRIVER:
            approved_reviews = approved_reviews.filter(driver_id=entity_id)
            
        total_reviews = approved_reviews.count()
        
        if total_reviews == 0:
            RatingsSummary.objects.update_or_create(
                entity_type=entity_type,
                entity_id=entity_id,
                defaults={
                    'average_rating': Decimal('0.00'),
                    'total_reviews': 0,
                    'five_star': 0, 'four_star': 0, 'three_star': 0, 'two_star': 0, 'one_star': 0
                }
            )
            return

        five_star = approved_reviews.filter(rating=5).count()
        four_star = approved_reviews.filter(rating=4).count()
        three_star = approved_reviews.filter(rating=3).count()
        two_star = approved_reviews.filter(rating=2).count()
        one_star = approved_reviews.filter(rating=1).count()

        total_score = (5 * five_star) + (4 * four_star) + (3 * three_star) + (2 * two_star) + (1 * one_star)
        average_rating = Decimal(total_score) / Decimal(total_reviews)
        average_rating = round(average_rating, 2)

        RatingsSummary.objects.update_or_create(
            entity_type=entity_type,
            entity_id=entity_id,
            defaults={
                'average_rating': average_rating,
                'total_reviews': total_reviews,
                'five_star': five_star,
                'four_star': four_star,
                'three_star': three_star,
                'two_star': two_star,
                'one_star': one_star,
            }
        ) 