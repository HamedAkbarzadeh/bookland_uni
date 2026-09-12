import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// ============================================================================
/// 🔐 مدیریت وضعیت احراز هویت و کاربر (AuthProvider)
/// ============================================================================
/// این کلاس از `ChangeNotifier` ارث‌بری می‌کند.
/// هر زمان که وضعیت کاربر تغییر کند (مثلاً لاگین شود یا کیف پولش شارژ شود)،
/// با فراخوانی متد `notifyListeners()` تمام صفحات برنامه فوراً آپدیت می‌شوند.
class AuthProvider with ChangeNotifier {
  // متغیرهای خصوصی نگه‌دارنده وضعیت
  UserModel? _user;           // اطلاعات کاربر لاگین شده (نام، ایمیل، موجودی و...)
  bool _isLoading = false;    // آیا در حال ارسال درخواست به سرور هستیم؟ (برای نمایش لودینگ)
  String? _errorMessage;     // آخرین پیام خطایی که از سمت سرور دریافت شده است

  // گترها (Getters) برای دسترسی صفحات به مقادیر بالا به صورت فقط خواندنی
  UserModel? get user => _user;
  bool get isAuthenticated => _user != null; // اگر کاربر نال نباشد یعنی لاگین است
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ==========================================================================
  /// ۱. بررسی خودکار نشست کاربر هنگام باز شدن برنامه (Auto Login)
  /// ==========================================================================
  /// توکن قبلی را از حافظه می‌خواند و در صورت معتبر بودن، اطلاعات کاربر را لود می‌کند.
  Future<bool> tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return false;

    _isLoading = true;
    notifyListeners(); // به صفحات اعلام کن که در حال بررسی هستیم

    try {
      final res = await ApiService.get(ApiConstants.me);
      if (res.success && res.data != null && res.data['user'] != null) {
        _user = UserModel.fromJson(res.data['user']);
        _isLoading = false;
        notifyListeners(); // ورود خودکار موفق بود، صفحات را با اطلاعات کاربر رفرش کن
        return true;
      }
    } catch (_) {}

    // اگر توکن منقضی یا نامعتبر بود، آن را پاک می‌کنیم
    await ApiService.clearToken();
    _user = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// ==========================================================================
  /// ۲. ورود به حساب کاربری (Login)
  /// ==========================================================================
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post(ApiConstants.login, {
      'email': email.trim(),
      'password': password,
    });

    _isLoading = false;
    if (res.success && res.data != null) {
      final token = res.data['token'];
      if (token != null) {
        await ApiService.setToken(token); // ذخیره توکن در موبایل
      }
      if (res.data['user'] != null) {
        _user = UserModel.fromJson(res.data['user']); // پر کردن مدل کاربر
      }
      notifyListeners(); // اطلاع به UI برای رفتن به صفحه اصلی
      return true;
    } else {
      _errorMessage = res.message ?? 'خطا در ورود';
      notifyListeners();
      return false;
    }
  }

  /// ==========================================================================
  /// ۳. ثبت‌نام کاربر جدید (Register)
  /// ==========================================================================
  Future<bool> register(String name, String email, String password, {String? phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final res = await ApiService.post(ApiConstants.register, {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone?.trim() ?? '',
    });

    _isLoading = false;
    if (res.success && res.data != null) {
      final token = res.data['token'];
      if (token != null) {
        await ApiService.setToken(token);
      }
      if (res.data['user'] != null) {
        _user = UserModel.fromJson(res.data['user']);
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = res.message ?? 'خطا در ثبت‌نام';
      notifyListeners();
      return false;
    }
  }

  /// ==========================================================================
  /// ۴. افزایش موجودی / شارژ آنلاین کیف پول (Top-up Wallet)
  /// ==========================================================================
  Future<bool> topUpWallet(num amount) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.post(ApiConstants.topUp, {'amount': amount});
    _isLoading = false;

    if (res.success && res.data != null) {
      final newBalance = res.data['balance'] is num
          ? res.data['balance']
          : num.tryParse(res.data['balance'].toString()) ?? _user!.walletBalance;
      // ساخت یک نمونه جدید از کاربر با موجودی بروزرسانی‌شده
      _user = _user!.copyWith(walletBalance: newBalance);
      notifyListeners(); // آپدیت آنی موجودی در نوار بالای صفحه و صفحه پروفایل
      return true;
    } else {
      _errorMessage = res.message;
      notifyListeners();
      return false;
    }
  }

  /// بروزرسانی موجودی کیف پول به صورت دستی پس از خرید
  void updateBalance(num newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(walletBalance: newBalance);
      notifyListeners();
    }
  }

  /// ==========================================================================
  /// ۵. خروج از حساب کاربری (Logout)
  /// ==========================================================================
  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners(); // پاکسازی وضعیت و هدایت کاربر به صفحه لاگین
  }
}
