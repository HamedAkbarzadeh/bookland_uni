import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/book_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/status_badge.dart';
import '../cart/cart_screen.dart';

/// ============================================================================
/// 📖 صفحه نمایش جزئیات کتاب (BookDetailsScreen)
/// ============================================================================
/// این صفحه جزئیات کامل یک کتاب خاص را نمایش می‌دهد:
/// ۱. تصویر با کیفیت جلد با انیمیشن Hero
/// ۲. وضعیت سلامت فیزیکی (نو / در حد نو / دست دوم)
/// ۳. عنوان، نویسنده، کد شابک و دسته‌بندی موضوعی
/// ۴. کارت مشخصات فروشنده (نام، شماره تماس، آواتار)
/// ۵. توضیحات کامل درباره تمیزی یا محتوای کتاب
/// ۶. بخش نظرات کاربران و فرم ثبت نظر و امتیاز با ستاره
/// ۷. نوار چسبان پایین (Bottom Bar) شامل قیمت به تومان و دکمه‌های خرید مستقیم یا افزودن به سبد
class BookDetailsScreen extends StatefulWidget {
  final int bookId; // شناسه کتاب ارسالی از صفحه قبلی

  const BookDetailsScreen({super.key, required this.bookId});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  BookModel? _book;       // مدل نگه‌دارنده اطلاعات کامل کتاب دریافتی از سرور
  bool _isLoading = true; // وضعیت لودینگ اولیه

  @override
  void initState() {
    super.initState();
    _loadBook(); // فراخوانی وب‌سرویس جزئیات کتاب در ابتدای باز شدن صفحه
  }

  /// دریافت اطلاعات کامل کتاب و نظرات آن از اندپوینت /api/books/:id
  Future<void> _loadBook() async {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    final book = await bookProvider.getBookDetails(widget.bookId);
    if (mounted) {
      setState(() {
        _book = book;
        _isLoading = false;
      });
    }
  }

  /// باز کردن مودال ثبت نظر و امتیاز ستاره‌ای در پایین صفحه (Bottom Sheet)
  void _showAddReviewDialog() {
    int rating = 5; // پیش‌فرض ۵ ستاره
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // برای اینکه کیبورد روی فیلد متنی نیفتد
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ثبت نظر و امتیاز برای این کتاب',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ردیف انتخاب ۵ ستاره امتیاز
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setSheetState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'تجربه مطالعه یا کیفیت این کتاب را بنویسید...',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (commentController.text.trim().isEmpty) return;
                  final bookProvider = Provider.of<BookProvider>(context, listen: false);
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await bookProvider.addReview(
                    widget.bookId,
                    rating,
                    commentController.text.trim(),
                  );
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  if (success) {
                    _loadBook(); // رفرش خودکار صفحه جهت نمایش نظر جدید
                    messenger.showSnackBar(
                      const SnackBar(content: Text('نظر شما با موفقیت ثبت شد'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('ارسال نظر'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('خطا')),
        body: const Center(child: Text('کتاب مورد نظر یافت نشد')),
      );
    }

    // آیا این کتاب متعلق به خود کاربر لاگین شده است؟ (جهت جلوگیری از خرید کتاب خود)
    final isMyBook = authProvider.user?.id == _book!.sellerId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _book!.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لینک کتاب کپی شد')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // قاب نمایش تصویر جلد کتاب
            Container(
              width: double.infinity,
              height: 280,
              color: const Color(0xFFF8FAFC),
              child: Center(
                child: Hero(
                  tag: 'book-cover-${_book!.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _book!.imageUrl != null && _book!.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _book!.imageUrl!,
                            height: 240,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => const Icon(Icons.book, size: 80, color: AppTheme.textLight),
                          )
                        : const Icon(Icons.book, size: 80, color: AppTheme.textLight),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // برچسب وضعیت و موضوع کتاب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          StatusBadge(condition: _book!.conditionStatus),
                          const SizedBox(width: 8),
                          StatusBadge(status: _book!.status),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _book!.categoryName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // عنوان کتاب
                  Text(
                    _book!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'نویسنده: ${_book!.author}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (_book!.isbn != null && _book!.isbn!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'شابک (ISBN): ${_book!.isbn}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // کارت اطلاعات فروشنده
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                          backgroundImage: _book!.sellerAvatar != null
                              ? NetworkImage(_book!.sellerAvatar!)
                              : null,
                          child: _book!.sellerAvatar == null
                              ? const Icon(Icons.person, color: AppTheme.primaryColor)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('فروشنده این کتاب:', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                              Text(
                                _book!.sellerName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              if (_book!.sellerPhone != null && _book!.sellerPhone!.isNotEmpty)
                                Text(
                                  'تلفن: ${_book!.sellerPhone}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                            ],
                          ),
                        ),
                        if (isMyBook)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'کتاب خود شما',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // توضیحات کتاب
                  const Text(
                    'درباره این کتاب',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _book!.description != null && _book!.description!.isNotEmpty
                        ? _book!.description!
                        : 'توضیحاتی برای این کتاب ثبت نشده است.',
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.6,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // بخش نظرات کاربران
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'نظرات کاربران (${_book!.reviews.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text('ثبت نظر'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_book!.reviews.isEmpty)
                    const Text(
                      'هنوز نظری برای این کتاب ثبت نشده است. اولین نفری باشید که نظر می‌دهد!',
                      style: TextStyle(fontSize: 12.5, color: AppTheme.textLight),
                    )
                  else
                    ..._book!.reviews.map((rev) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rev.userName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < rev.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                rev.comment!,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // نوار پایینی ثابت (Sticky Bottom Bar) برای نمایش قیمت و دکمه‌های اقدام خرید
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('قیمت فروش:', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text(
                  Formatters.formatPrice(_book!.price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isMyBook)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'کتاب ثبت‌شده شما',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              )
            else if (!_book!.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ناموجود / فروخته شده',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              )
            else
              Row(
                children: [
                  // دکمه افزودن به سبد خرید
                  OutlinedButton(
                    onPressed: () {
                      cartProvider.addToCart(_book!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('کتاب "${_book!.title}" به سبد خرید اضافه شد'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(
                            label: 'مشاهده سبد',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    child: const Icon(Icons.add_shopping_cart, size: 20),
                  ),
                  const SizedBox(width: 8),
                  // دکمه خرید مستقیم (افزودن و رفتن آنی به تسویه حساب)
                  ElevatedButton(
                    onPressed: () {
                      cartProvider.addToCart(_book!);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('خرید مستقیم'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
