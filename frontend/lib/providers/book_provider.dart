import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

/// ============================================================================
/// 📚 مدیریت وضعیت کتاب‌ها و دسته‌بندی‌ها (BookProvider)
/// ============================================================================
/// این پرووایدر مسئول تمام داده‌های مرتبط با کتاب‌ها است:
/// - دریافت دسته‌بندی‌ها (رمان، علمی، روانشناسی و...)
/// - فیلتر و جستجوی زنده در کتاب‌ها
/// - ثبت کتاب جدید توسط فروشنده
/// - دریافت لیست کتاب‌های من و حذف آن‌ها
class BookProvider with ChangeNotifier {
  List<BookModel> _books = [];              // لیست تمام کتاب‌های فعال در فروشگاه
  List<BookModel> _myListings = [];         // لیست کتاب‌هایی که خود کاربر جاری برای فروش گذاشته
  List<CategoryModel> _categories = [];     // لیست موضوعات و دسته‌بندی‌ها
  bool _isLoading = false;                  // نشانگر وضعیت بارگذاری کتاب‌ها
  bool _isLoadingMyListings = false;        // نشانگر وضعیت بارگذاری کتاب‌های من
  String? _errorMessage;                   // پیام خطای احتمالی

  // مقادیر فیلترهای فعال
  int? _selectedCategoryId;                 // دسته‌بندی انتخاب‌شده (null یعنی همه)
  String? _selectedCondition;               // وضعیت فیزیکی کتاب ('new', 'like_new', 'used')
  String? _searchQuery;                     // عبارت جستجوشده توسط کاربر
  String _sort = 'created_at';              // نحوه مرتب‌سازی ('price_asc', 'price_desc', 'created_at')

  // گترها (Getters)
  List<BookModel> get books => _books;
  List<BookModel> get myListings => _myListings;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMyListings => _isLoadingMyListings;
  String? get errorMessage => _errorMessage;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCondition => _selectedCondition;
  String? get searchQuery => _searchQuery;
  String get sort => _sort;

  /// ==========================================================================
  /// ۱. دریافت دسته‌بندی‌های موضوعی کتاب‌ها از سرور
  /// ==========================================================================
  Future<void> fetchCategories() async {
    final res = await ApiService.get(ApiConstants.categories);
    if (res.success && res.data != null && res.data['categories'] != null) {
      _categories = (res.data['categories'] as List)
          .map((c) => CategoryModel.fromJson(c))
          .toList();
      notifyListeners(); // اطلاع به UI برای نمایش چیپ‌های دسته‌بندی
    }
  }

  /// ==========================================================================
  /// ۲. دریافت لیست کتاب‌ها به همراه اعمال پارامترهای فیلتر و جستجو
  /// ==========================================================================
  Future<void> fetchBooks({
    String? search,
    int? categoryId,
    String? condition,
    String? sort,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // ذخیره پارامترهای جدید در وضعیت پرووایدر
    if (search != null) _searchQuery = search;
    if (categoryId != null) _selectedCategoryId = categoryId == 0 ? null : categoryId;
    if (condition != null) _selectedCondition = condition == 'all' ? null : condition;
    if (sort != null) _sort = sort;

    // تبدیل فیلترها به پارامترهای کوئری برای ارسال به اندپوینت
    final Map<String, String> query = {};
    if (_searchQuery != null && _searchQuery!.trim().isNotEmpty) {
      query['search'] = _searchQuery!.trim();
    }
    if (_selectedCategoryId != null) {
      query['category_id'] = _selectedCategoryId.toString();
    }
    if (_selectedCondition != null) {
      query['condition_status'] = _selectedCondition!;
    }
    if (_sort.isNotEmpty) {
      query['sort'] = _sort;
    }

    final res = await ApiService.get(ApiConstants.books, queryParams: query);
    _isLoading = false;

    if (res.success && res.data != null && res.data['books'] != null) {
      _books = (res.data['books'] as List)
          .map((b) => BookModel.fromJson(b))
          .toList();
      notifyListeners(); // نوسازی و نمایش لیست کتاب‌ها در کارت‌ها
    } else {
      _errorMessage = res.message ?? 'خطا در دریافت لیست کتاب‌ها';
      notifyListeners();
    }
  }

  /// ==========================================================================
  /// ۳. دریافت مشخصات کامل یک کتاب به همراه اطلاعات فروشنده و نظرات
  /// ==========================================================================
  Future<BookModel?> getBookDetails(int id) async {
    final res = await ApiService.get('${ApiConstants.books}/$id');
    if (res.success && res.data != null && res.data['book'] != null) {
      return BookModel.fromJson(res.data['book']);
    }
    return null;
  }

  /// ==========================================================================
  /// ۴. دریافت لیست کتاب‌هایی که خود کاربر برای فروش گذاشته است
  /// ==========================================================================
  Future<void> fetchMyListings() async {
    _isLoadingMyListings = true;
    notifyListeners();

    final res = await ApiService.get(ApiConstants.myListings);
    _isLoadingMyListings = false;

    if (res.success && res.data != null && res.data['books'] != null) {
      _myListings = (res.data['books'] as List)
          .map((b) => BookModel.fromJson(b))
          .toList();
      notifyListeners();
    }
  }

  /// ==========================================================================
  /// ۵. ثبت یک کتاب جدید برای فروش توسط کاربر جاری
  /// ==========================================================================
  Future<bool> addBook({
    required String title,
    required String author,
    required int categoryId,
    required num price,
    required String conditionStatus,
    String? isbn,
    String? description,
    String? imageUrl,
    int stock = 1,
  }) async {
    _isLoading = true;
    notifyListeners();

    final res = await ApiService.post(ApiConstants.books, {
      'title': title.trim(),
      'author': author.trim(),
      'category_id': categoryId,
      'price': price,
      'condition_status': conditionStatus,
      'isbn': isbn?.trim(),
      'description': description?.trim(),
      'image_url': imageUrl,
      'stock': stock,
    });

    _isLoading = false;
    if (res.success && res.data != null) {
      // نوسازی مجدد لیست عمومی کتاب‌ها و لیست کتاب‌های من
      await fetchBooks();
      await fetchMyListings();
      return true;
    } else {
      _errorMessage = res.message ?? 'خطا در ثبت کتاب برای فروش';
      notifyListeners();
      return false;
    }
  }

  /// ==========================================================================
  /// ۶. حذف کتاب توسط فروشنده
  /// ==========================================================================
  Future<bool> deleteBook(int id) async {
    final res = await ApiService.delete('${ApiConstants.books}/$id');
    if (res.success) {
      _myListings.removeWhere((b) => b.id == id);
      _books.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// ==========================================================================
  /// ۷. ثبت نظر و امتیاز کاربر برای کتاب
  /// ==========================================================================
  Future<bool> addReview(int bookId, int rating, String comment) async {
    final res = await ApiService.post('${ApiConstants.books}/$bookId/reviews', {
      'rating': rating,
      'comment': comment,
    });
    return res.success;
  }

  /// بازنشانی تمام فیلترها به حالت اولیه (نمایش همه کتاب‌ها)
  void resetFilters() {
    _selectedCategoryId = null;
    _selectedCondition = null;
    _searchQuery = null;
    _sort = 'created_at';
    fetchBooks();
  }
}
