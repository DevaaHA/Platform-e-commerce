#!/usr/bin/env python
"""
SouqJo Enterprise E-Commerce Platform
Django's command-line utility for high-performance administrative tasks.
"""
import os
import sys


def main():
    """Run administrative tasks with optimized environment settings."""
    # ضبط مسار الإعدادات ليطابق مجلد config بدقة تامة
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate your virtual environment?"
        ) from exc
    
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()