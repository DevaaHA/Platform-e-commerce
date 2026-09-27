import requests

def get_ai_response(user_query, context):
    """
    تقوم هذه الدالة بإرسال الطلب إلى نموذج Llama 3 المحلي 
    وتعيد صياغة الرد بناءً على سياق المنتجات المتوفرة.
    """
    # تحويل السياق إلى نص مرتب
    context_str = "\n".join(context) if isinstance(context, list) else str(context)
    
    prompt = f"""أنت مساعد تسوق خبير في متجر SouqJo الإلكتروني.
    البيانات المتاحة حول المنتجات:
    {context_str}
    
    مهمتك: أجب على استفسار العميل التالي بناءً على البيانات المذكورة فقط.
    استفسار العميل: {user_query}
    
    قواعد الرد:
    - كن ودوداً، مهنياً، ومختصراً.
    - إذا لم تتوفر المعلومة في البيانات، اعتذر بلطف.
    - شجع العميل على الشراء بأسلوب مقنع."""

    try:
        # إرسال الطلب لمحرك Ollama مع timeout لتجنب التعليق
        response = requests.post(
            "http://localhost:11434/api/generate", 
            json={
                "model": "llama3",
                "prompt": prompt,
                "stream": False
            },
            timeout=15  # الانتظار لمدة 15 ثانية كحد أقصى
        )
        
        # التحقق من نجاح الرد
        if response.status_code == 200:
            return response.json().get('response', "عذراً، لم أستطع توليد رد.")
        else:
            return "عذراً، حدث خطأ في التواصل مع المحرك الذكي."
            
    except requests.exceptions.ConnectionError:
        return "المحرك الذكي غير متصل حالياً. يرجى التأكد من عمل Ollama."
    except Exception as e:
        return f"حدث خطأ غير متوقع: {str(e)}"