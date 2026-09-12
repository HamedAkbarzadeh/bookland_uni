/// ============================================================================
/// ⭐ مدل نظر و امتیاز کاربر برای کتاب (ReviewModel)
/// ============================================================================
class ReviewModel {
  final int id;                 // شناسه نظر
  final int bookId;             // شناسه کتابی که نظر برای آن ثبت شده
  final int userId;             // شناسه کاربری که نظر داده
  final int rating;             // امتیاز (عددی از ۱ تا ۵)
  final String? comment;        // متن نظر کاربر
  final String userName;        // نام کاربری ثبت‌کننده نظر
  final String? userAvatar;     // تصویر پروفایل کاربر
  final DateTime? createdAt;    // تاریخ ثبت نظر

  ReviewModel({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rating,
    this.comment,
    this.userName = 'کاربر',
    this.userAvatar,
    this.createdAt,
  });

  /// تبدیل آبجکت JSON دریافتی از سرور نودجی‌اس به آبجکت دارت (Deserialization)
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      bookId: json['book_id'] is int ? json['book_id'] : int.tryParse(json['book_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      rating: json['rating'] is int ? json['rating'] : int.tryParse(json['rating']?.toString() ?? '5') ?? 5,
      comment: json['comment'],
      userName: json['user_name'] ?? 'کاربر',
      userAvatar: json['user_avatar'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}

/// ============================================================================
/// 📚 مدل اصلی کتاب (BookModel)
/// ============================================================================
/// این کلاس متناظر با جدول `books` در پایگاه داده MySQL و فیلدهای سرور اکسپرس است.
class BookModel {
  final int id;                     // شناسه یکتای کتاب در دیتابیس
  final int sellerId;               // شناسه کاربر فروشنده
  final int categoryId;             // شناسه دسته‌بندی موضوعی
  final String title;               // عنوان کتاب
  final String author;              // نام نویسنده یا مترجم
  final String? isbn;               // شابک (اختیاری)
  final String? description;        // توضیحات کتاب و میزان تمیزی
  final num price;                  // قیمت فروش به تومان
  final String conditionStatus;     // وضعیت سلامت: 'new' (نو)، 'like_new' (در حد نو)، 'used' (دست دوم)
  final String? imageUrl;           // آدرس اینترنتی تصویر جلد
  final int stock;                  // تعداد موجودی (معمولاً ۱ برای کتاب‌های دست‌دوم)
  final String status;              // وضعیت موجودی: 'available' (موجود)، 'sold' (فروخته‌شده)
  final String sellerName;          // نام فروشنده
  final String? sellerPhone;        // تلفن فروشنده جهت هماهنگی ارسال
  final String? sellerAvatar;       // عکس پروفایل فروشنده
  final String? sellerEmail;        // ایمیل فروشنده
  final String categoryName;        // نام دسته‌بندی فارسی (مثلاً: رمان و داستانی)
  final List<ReviewModel> reviews;  // لیست نظرات ثبت‌شده کاربران برای این کتاب
  final DateTime? createdAt;        // تاریخ ثبت کتاب

  BookModel({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.author,
    this.isbn,
    this.description,
    required this.price,
    this.conditionStatus = 'like_new',
    this.imageUrl,
    this.stock = 1,
    this.status = 'available',
    this.sellerName = 'فروشنده',
    this.sellerPhone,
    this.sellerAvatar,
    this.sellerEmail,
    this.categoryName = 'عمومی',
    this.reviews = const [],
    this.createdAt,
  });

  /// کارخانه تبدیل JSON به آبجکت معتبر دارت
  factory BookModel.fromJson(Map<String, dynamic> json) {
    List<ReviewModel> revs = [];
    if (json['reviews'] != null && json['reviews'] is List) {
      revs = (json['reviews'] as List).map((r) => ReviewModel.fromJson(r)).toList();
    }

    return BookModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sellerId: json['seller_id'] is int ? json['seller_id'] : int.tryParse(json['seller_id']?.toString() ?? '0') ?? 0,
      categoryId: json['category_id'] is int ? json['category_id'] : int.tryParse(json['category_id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      isbn: json['isbn'],
      description: json['description'],
      price: json['price'] is num ? json['price'] : num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      conditionStatus: json['condition_status'] ?? 'like_new',
      imageUrl: json['image_url'],
      stock: json['stock'] is int ? json['stock'] : int.tryParse(json['stock']?.toString() ?? '1') ?? 1,
      status: json['status'] ?? 'available',
      sellerName: json['seller_name'] ?? 'فروشنده',
      sellerPhone: json['seller_phone'],
      sellerAvatar: json['seller_avatar'],
      sellerEmail: json['seller_email'],
      categoryName: json['category_name'] ?? 'عمومی',
      reviews: revs,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  /// گتر کمکی برای بررسی اینکه آیا کتاب هنوز قابل خرید است یا خیر
  bool get isAvailable => status == 'available' && stock > 0;
}
