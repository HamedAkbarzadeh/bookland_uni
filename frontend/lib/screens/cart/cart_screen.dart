import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

/// ============================================================================
/// 🛒 صفحه سبد خرید و تسویه حساب نهایی (CartScreen)
/// ============================================================================
/// این صفحه مراحل پایانی خرید کتاب را مدیریت می‌کند:
/// ۱. نمایش لیست اقلام موجود در سبد با امکان کم/زیاد کردن تعداد یا حذف
/// ۲. دریافت نشانی دقیق پستی خریدار جهت تحویل فیزیکی کتاب
/// ۳. انتخاب شیوه پرداخت (کیف پول بوک‌لند یا درگاه شتاب آزمایشی)
/// ۴. بررسی موجودی کیف پول و دیالوگ شارژ آنلاین سریع در صورت کسری موجودی
/// ۵. ارسال نهایی سفارش و نمایش پیام تبریک به همراه ثبت فاکتور
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // کنترلر آدرس ارسال با یک متن پیش‌فرض برای سهولت در تست
  final _addressController = TextEditingController(text: 'تهران، خیابان انقلاب، پلاک ۱۲، واحد ۴');
  String _paymentMethod = 'wallet'; // شیوه پرداخت پیش‌فرض: کیف پول

  /// ==========================================================================
  /// دیالوگ افزایش اعتبار سریع در صورتی که موجودی کیف پول کاربر برای خرید کم باشد
  /// ==========================================================================
  void _showTopUpDialog(BuildContext context, num requiredAmount) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // محاسبه مبلغ کسری
    final topUpAmount = (requiredAmount - (authProvider.user?.walletBalance ?? 0)).clamp(50000, 5000000);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('شارژ سریع کیف پول', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'موجودی فعلی شما: ${Formatters.formatPrice(authProvider.user?.walletBalance ?? 0)}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              'مبلغ کسری: ${Formatters.formatPrice(topUpAmount)}',
              style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            const Text(
              'با کلیک بر روی دکمه زیر، کیف پول شما به صورت شبیه‌سازی‌شده شارژ می‌شود.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              // افزایش اعتبار کیف پول
              await authProvider.topUpWallet(topUpAmount);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('کیف پول با موفقیت به مبلغ ${Formatters.formatPrice(topUpAmount)} شارژ شد!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('شارژ آنلاین آنی'),
          ),
        ],
      ),
    );
  }

  /// ==========================================================================
  /// پردازش و ثبت نهایی سفارش خرید
  /// ==========================================================================
  Future<void> _handleCheckout() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // ۱. بررسی وارد شدن نشانی پستی
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً آدرس ارسال را وارد کنید')),
      );
      return;
    }

    final total = cartProvider.totalAmount;
    final currentBalance = authProvider.user?.walletBalance ?? 0;

    // ۲. اگر شیوه پرداخت کیف پول بود و موجودی کافی نبود، دیالوگ شارژ باز شود
    if (_paymentMethod == 'wallet' && currentBalance < total) {
      _showTopUpDialog(context, total);
      return;
    }

    // ۳. ارسال درخواست ثبت سفارش به بک‌اند اکسپرس
    final success = await cartProvider.checkout(
      shippingAddress: _addressController.text,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;

    if (success) {
      // رفرش کردن موجودی کیف پول و لیست سفارش‌ها در بک‌گراند
      await authProvider.tryAutoLogin();
      await orderProvider.fetchMyOrders();

      if (!context.mounted) return;

      // نمایش دیالوگ تبریک خرید موفق
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 18),
              const Text(
                'خرید با موفقیت انجام شد! 🎉',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'سفارش شما ثبت شد و فروشنده برای هماهنگی ارسال با شما تماس خواهد گرفت.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);     // بستن دیالوگ
                  if (mounted) {
                    Navigator.pop(context); // بازگشت از صفحه سبد خرید
                  }
                },
                child: const Text('مشاهده سفارش‌ها و فاکتور'),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cartProvider.checkoutError ?? 'خطا در ثبت سفارش'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cartList = cartProvider.items.values.toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('سبد خرید کتاب'),
        actions: [
          if (cartList.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              tooltip: 'خالی کردن سبد',
              onPressed: () => cartProvider.clearCart(),
            ),
        ],
      ),
      // اگر سبد خالی بود، پیام متناسب نمایش می‌دهیم
      body: cartList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 72, color: AppTheme.textLight),
                  const SizedBox(height: 16),
                  const Text(
                    'سبد خرید شما در حال حاضر خالی است',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'کتاب‌های مورد علاقه خود را انتخاب کنید و به سبد اضافه نمایید.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('مشاهده و انتخاب کتاب‌ها'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // لیست اقلام سبد خرید
                  ...cartList.map((item) {
                    final book = item.book;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: book.imageUrl!,
                                    width: 60,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 60,
                                    height: 80,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.book, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'نویسنده: ${book.author}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  Formatters.formatPrice(item.subtotal),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // دکمه‌های مثبت و منفی تعداد کتاب در سبد
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  cartProvider.updateQuantity(book.id, item.quantity - 1);
                                },
                              ),
                              Text(
                                Formatters.toPersianDigits('${item.quantity}'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  cartProvider.updateQuantity(book.id, item.quantity + 1);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // فیلد نشانی تحویل پستی
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor),
                            SizedBox(width: 6),
                            Text(
                              'نشانی تحویل گیرنده',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'استان، شهر، آدرس دقیق، کد پستی و شماره تماس گیرنده...',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // انتخاب شیوه پرداخت (کیف پول / درگاه تست)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'شیوه پرداخت',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<String>(
                          groupValue: _paymentMethod,
                          onChanged: (v) {
                            if (v != null) setState(() => _paymentMethod = v);
                          },
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                value: 'wallet',
                                title: Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, size: 18, color: Colors.green),
                                    const SizedBox(width: 6),
                                    const Text('کیف پول بوک‌لند'),
                                    const Spacer(),
                                    Text(
                                      Formatters.formatPrice(authProvider.user?.walletBalance ?? 0),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                                subtitle: const Text('پرداخت سریع و کسر آنی از اعتبار حساب', style: TextStyle(fontSize: 11)),
                              ),
                              RadioListTile<String>(
                                value: 'gateway',
                                title: const Row(
                                  children: [
                                    Icon(Icons.credit_card, size: 18, color: AppTheme.primaryColor),
                                    SizedBox(width: 6),
                                    Text('درگاه پرداخت بانکی (آزمایشی)'),
                                  ],
                                ),
                                subtitle: const Text('اتصال به شاپرک و پرداخت شتابی', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // کادر خلاصه فاکتور
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('جمع کل خرید کتاب‌ها:'),
                            Text(
                              Formatters.formatPrice(cartProvider.totalAmount),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('هزینه ارسال پستی:'),
                            Text('رایگان (طرح ویژه)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'مبلغ قابل پرداخت:',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              Formatters.formatPrice(cartProvider.totalAmount),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // دکمه ثبت نهایی و پرداخت
                  ElevatedButton(
                    onPressed: cartProvider.isCheckingOut ? null : _handleCheckout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: cartProvider.isCheckingOut
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('پرداخت و ثبت نهایی سفارش (${Formatters.formatPrice(cartProvider.totalAmount)})'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
