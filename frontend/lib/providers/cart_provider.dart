import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';

/// ============================================================================
/// 🛒 کلاس آیتم سبد خرید (CartItem)
/// ============================================================================
/// نماینده یک کتاب موجود در سبد خرید به همراه تعداد درخواستی
class CartItem {
  final BookModel book; // مشخصات کتاب
  int quantity;         // تعداد درخواستی خریدار

  CartItem({required this.book, this.quantity = 1});

  // محاسبه قیمت جزء برای این ردیف (قیمت کتاب × تعداد)
  num get subtotal => book.price * quantity;
}

/// ============================================================================
/// 🛍️ مدیریت وضعیت سبد خرید و تسویه حساب (CartProvider)
/// ============================================================================
/// این کلاس تمام فعالیت‌های سبد خرید را مدیریت می‌کند:
/// - افزودن کتاب به سبد
/// - افزایش/کاهش تعداد یا حذف
/// - محاسبه کل مبلغ پرداختی
/// - ارسال درخواست نهایی خرید به سرور (Checkout)
class CartProvider with ChangeNotifier {
  // نقشه نگه‌دارنده آیتم‌های سبد خرید بر اساس شناسه کتاب (bookId -> CartItem)
  final Map<int, CartItem> _items = {};
  bool _isCheckingOut = false; // وضعیت در حال ثبت سفارش
  String? _checkoutError;      // پیام خطای احتمالی تسویه

  // گترها (Getters)
  Map<int, CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isCheckingOut => _isCheckingOut;
  String? get checkoutError => _checkoutError;

  /// محاسبه مبلغ کل سبد خرید (مجموع تمام ردیف‌ها) به تومان
  num get totalAmount {
    num total = 0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return total;
  }

  /// ==========================================================================
  /// ۱. افزودن کتاب به سبد خرید
  /// ==========================================================================
  void addToCart(BookModel book) {
    if (_items.containsKey(book.id)) {
      // اگر قبلاً در سبد بود و موجودی انبار اجازه دهد، تعداد را ۱ دانه زیاد می‌کنیم
      if (_items[book.id]!.quantity < book.stock) {
        _items[book.id]!.quantity += 1;
      }
    } else {
      // اضافه کردن کتاب جدید به سبد
      _items[book.id] = CartItem(book: book, quantity: 1);
    }
    notifyListeners(); // به روزرسانی نشانگر عددی سبد خرید در نوار بالا
  }

  /// ==========================================================================
  /// ۲. حذف کامل یک کتاب از سبد خرید
  /// ==========================================================================
  void removeFromCart(int bookId) {
    _items.remove(bookId);
    notifyListeners();
  }

  /// ==========================================================================
  /// ۳. تغییر تعداد یک کتاب در سبد (با دکمه‌های + و -)
  /// ==========================================================================
  void updateQuantity(int bookId, int quantity) {
    if (!_items.containsKey(bookId)) return;
    if (quantity <= 0) {
      removeFromCart(bookId);
    } else {
      final maxStock = _items[bookId]!.book.stock;
      _items[bookId]!.quantity = quantity > maxStock ? maxStock : quantity;
      notifyListeners();
    }
  }

  /// خالی کردن کامل سبد خرید پس از پرداخت موفق
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// ==========================================================================
  /// ۴. فرآیند تسویه حساب و ثبت سفارش در سرور (Checkout)
  /// ==========================================================================
  Future<bool> checkout({
    required String shippingAddress,
    String paymentMethod = 'wallet',
  }) async {
    if (_items.isEmpty) return false;

    _isCheckingOut = true;
    _checkoutError = null;
    notifyListeners();

    // آماده‌سازی آرایه اقلام سفارش برای ارسال به سرور
    final orderItems = _items.values.map((item) => {
      'book_id': item.book.id,
      'quantity': item.quantity,
    }).toList();

    // ارسال درخواست ثبت سفارش به اندپوینت /api/orders
    final res = await ApiService.post(ApiConstants.orders, {
      'items': orderItems,
      'shipping_address': shippingAddress.trim(),
      'payment_method': paymentMethod,
    });

    _isCheckingOut = false;

    if (res.success) {
      clearCart(); // پس از ثبت موفق، سبد خرید خالی می‌شود
      notifyListeners();
      return true;
    } else {
      _checkoutError = res.message ?? 'خطا در ثبت سفارش خرید';
      notifyListeners();
      return false;
    }
  }
}
