import csv
import logging
from django.http import StreamingHttpResponse

logger = logging.getLogger(__name__)

class Echo:
    """
    مساعد تقني لتنفيذ واجهة الكتابة ومحاكاة الملفات لبث البيانات فوراً (Memory Efficient Streaming)
    """
    def write(self, value):
        return value


class ExportService:
    @staticmethod
    def export_sales_to_csv(queryset):
        """
        تصدير تقارير المبيعات بصيغة CSV باستخدام البث المباشر (Streaming).
        هذا التصميم يتيح استخراج تقارير ضخمة تضم ملايين السجلات في أجزاء من الثانية 
        دون التسبب في انقطاع الاتصال (Timeout) أو انهيار ذاكرة الخادم (RAM).
        """
        pseudo_buffer = Echo()
        writer = csv.writer(pseudo_buffer)

        def row_generator():
            # 1. إضافة BOM لدعم اللغة العربية بشكل مباشر في برامج Excel
            yield pseudo_buffer.write('\ufeff')
            
            # 2. كتابة رؤوس الأعمدة وبثها فوراً
            yield writer.writerow(['التاريخ', 'إجمالي الطلبات', 'إجمالي المبيعات (JOD)', 'صافي الأرباح (JOD)'])
            
            # 3. معالجة البيانات على دفعات بفضل iterator لتخفيف العرض على قاعدة البيانات
            for item in queryset.iterator(chunk_size=2000):
                yield writer.writerow([
                    item.date, 
                    item.total_orders, 
                    item.total_sales, 
                    item.total_profit
                ])

        # إرجاع استجابة تدفقية متصلة للمتصفح
        response = StreamingHttpResponse(row_generator(), content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = 'attachment; filename="souqjo_sales_report.csv"'
        
        return response