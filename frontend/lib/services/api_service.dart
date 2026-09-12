import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// 🌐 کلاس پاسخ استاندارد سرور (ApiResponse Wrapper)
/// ============================================================================
/// این کلاس برای این است که خروجی تمام درخواست‌های اینترنتی یک ساختار یکپارچه داشته باشند:
/// - [success]: آیا عملیات با موفقیت انجام شد یا خیر؟
/// - [message]: پیام متنی سرور (مثلاً: ثبت‌نام با موفقیت انجام شد)
/// - [data]: داده‌های برگشتی (اطلاعات کاربر، لیست کتاب‌ها و...)
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({required this.success, this.message, this.data});
}

/// ============================================================================
/// 📡 لایه ارتباط با سرور و APIها (ApiService)
/// ============================================================================
/// تمامی ارتباطات HTTP فرانت‌اند فلاتر با بک‌اند اکسپرس از طریق این کلاس انجام می‌شود.
class ApiService {
  // کلید ذخیره‌سازی توکن احراز هویت در حافظه ماندگار دستگاه
  static const String _tokenKey = 'auth_token';

  /// خواندن توکن ذخیره‌شده از حافظه موبایل (SharedPreferences)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// ذخیره توکن جدید پس از ورود یا ثبت‌نام موفق کاربر
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// حذف توکن هنگام خروج از حساب کاربری (Logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// ساخت خودکار هدرهای مورد نیاز (Header)
  /// در صورتی که کاربر وارد شده باشد، توکن JWT به صورت Bearer ارسال می‌شود.
  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// ==========================================================================
  /// متد ارسال درخواست GET (دریافت اطلاعات: لیست کتاب‌ها، دسته‌بندی‌ها و...)
  /// ==========================================================================
  static Future<ApiResponse<dynamic>> get(String url, {Map<String, String>? queryParams}) async {
    try {
      Uri uri = Uri.parse(url);
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _headers();
      // ارسال درخواست با مهلت زمانی ۱۵ ثانیه جهت جلوگیری از فریز شدن برنامه
      final response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));

      // تبدیل بایت‌های دریافتی با کدگذاری UTF-8 جهت نمایش صحیح کلمات فارسی
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: decoded['success'] ?? true,
          message: decoded['message'],
          data: decoded['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'خطا در برقراری ارتباط با سرور',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'خطای شبکه یا عدم دسترسی به سرور: $e',
      );
    }
  }

  /// ==========================================================================
  /// متد ارسال درخواست POST (ایجاد و ارسال داده: ورود، ثبت‌نام، خرید، ثبت کتاب)
  /// ==========================================================================
  static Future<ApiResponse<dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _headers();
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: decoded['success'] ?? true,
          message: decoded['message'],
          data: decoded['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'خطا در ثبت اطلاعات',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'خطای شبکه یا عدم دسترسی به سرور: $e',
      );
    }
  }

  /// ==========================================================================
  /// متد ارسال درخواست PUT (ویرایش اطلاعات کتاب یا پروفایل)
  /// ==========================================================================
  static Future<ApiResponse<dynamic>> put(String url, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _headers();
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: decoded['success'] ?? true,
          message: decoded['message'],
          data: decoded['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'خطا در بروزرسانی اطلاعات',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'خطای ارتباط با سرور: $e',
      );
    }
  }

  /// ==========================================================================
  /// متد ارسال درخواست DELETE (حذف کتاب توسط فروشنده)
  /// ==========================================================================
  static Future<ApiResponse<dynamic>> delete(String url) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _headers();
      final response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 15));

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: decoded['success'] ?? true,
          message: decoded['message'],
          data: decoded['data'],
        );
      } else {
        return ApiResponse(
          success: false,
          message: decoded['message'] ?? 'خطا در حذف آیتم',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'خطای شبکه یا ارتباط با سرور: $e',
      );
    }
  }
}
