import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class ApiService {
  // استخدام Singleton Pattern لضمان إنشاء نسخة واحدة فقط من الـ Dio
  static final ApiService _instance = ApiService._internal();
  late final Dio dio;

  // متغيرات لتخزين معرف المتجر والتوكن
  static String? currentStoreId;
  static String? authToken;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 🚀 Interceptor احترافي لإدارة التوكن تلقائياً
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 1. حقن معرف المتجر (Multi-Tenant)
          if (currentStoreId != null && currentStoreId!.isNotEmpty) {
            options.headers['X-Store-ID'] = currentStoreId;
          }

          // 2. حقن التوكن (تذكرة المرور) للمصادقة مع Django
          authToken ??= await _getTokenFromStorage();
          if (authToken != null && authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 401) {
            developer.log('Token Expired or Invalid.', name: 'ApiService');
            clearToken();
          }
          return handler.next(e);
        },
      ),
    );
  }

  // ---------------- إدارة التوكن (Token Management) ----------------

  static Future<String?> _getTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  static Future<void> setAuthToken(String token) async {
    authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    developer.log('✅ Token Saved Successfully', name: 'ApiService');
  }

  static Future<void> clearToken() async {
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    developer.log('🚪 Token Cleared', name: 'ApiService');
  }

  // ---------------- دوال الاتصال الأساسية ----------------

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(endpoint, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    try {
      return await dio.post(endpoint, data: data);
    } on DioException catch (e) {
      developer.log(
        'API Error: ${e.response?.data}',
        name: 'ApiService',
        error: e,
      );
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String endpoint, {dynamic data}) async {
    try {
      return await dio.patch(endpoint, data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String endpoint) async {
    try {
      return await dio.delete(endpoint);
    } catch (e) {
      rethrow;
    }
  }

  // ---------------- 🚀 دالة رفع الصور والملفات الديناميكية ----------------

  /// تقوم برفع صورة إلى السيرفر بصيغة Multipart
  /// [endpoint]: رابط الـ API (مثل مسار تحديث البروفايل)
  /// [filePath]: مسار الصورة على هاتف المستخدم
  /// [fileKey]: اسم الحقل في الباك إند (الافتراضي: profile_image)
  Future<Response> uploadMultipart(
    String endpoint,
    String filePath, {
    String fileKey = 'profile_image',
  }) async {
    try {
      // 1. تجهيز اسم الملف
      String fileName = filePath.split('/').last;

      // 2. تحويل الملف إلى صيغة يقبلها السيرفر (FormData)
      FormData formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath, filename: fileName),
      });

      // 3. إرسال الطلب (استخدمنا PATCH لأننا نحدث البروفايل، ويمكن تغييرها لـ POST حسب السيرفر)
      return await dio.patch(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            // تجاوز الـ headers الافتراضية لإرسال ملفات
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      developer.log(
        'Image Upload Error: ${e.response?.data}',
        name: 'ApiService',
        error: e,
      );
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
