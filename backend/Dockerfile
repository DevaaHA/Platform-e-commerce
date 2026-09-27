# استخدام نسخة بايثون خفيفة
FROM python:3.11-slim

# إعداد مجلد العمل داخل الحاوية
WORKDIR /app

# منع بايثون من كتابة ملفات .pyc وإلغاء الـ Buffering
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# تثبيت المتطلبات (سننشئ الملف لاحقاً)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# نسخ باقي ملفات المشروع
COPY . .