import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/cart_provider.dart';
import 'home/home_screen.dart';
import 'explore/explore_screen.dart';
import 'books/add_book_screen.dart';
import 'orders/orders_screen.dart';
import 'profile/profile_screen.dart';
import 'cart/cart_screen.dart';

/// ============================================================================
/// 🧭 شاکله اصلی ناوبری و نوار پایین برنامه (MainNavScreen)
/// ============================================================================
/// این صفحه به عنوان پوسته اصلی (Navigation Shell) عمل می‌کند:
/// ۱. نوار نویگیشن پایین با ۵ بخش مجزا:
///    - خانه (HomeScreen)
///    - کاوش و جستجو (ExploreScreen)
///    - فروش کتاب (AddBookScreen)
///    - سفارش‌ها (OrdersScreen)
///    - پروفایل (ProfileScreen)
/// ۲. آیکون سبد خرید در نوار بالا با نشانگر عددی تعداد اقلام
class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  // اندیس تب فعال در حال حاضر (از ۰ تا ۴)
  int _currentIndex = 0;

  // لیست ۵ صفحه اصلی برنامه
  final List<Widget> _pages = const [
    HomeScreen(),      // تب ۰: خانه
    ExploreScreen(),   // تب ۱: جستجو و فیلترها
    AddBookScreen(),   // تب ۲: فرم ثبت کتاب جدید
    OrdersScreen(),    // تب ۳: خریدهای من و فروش‌های من
    ProfileScreen(),   // تب ۴: کیف پول و مشخصات کاربر
  ];

  @override
  Widget build(BuildContext context) {
    // دریافت اطلاعات سبد خرید برای نمایش تعداد کتاب‌ها روی آیکون
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      // نوار ابزار بالای صفحه (AppBar)
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu_book, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'بوک‌لند',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // آیکون سبد خرید به همراه بج عددی (Badge)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                tooltip: 'سبد خرید',
                onPressed: () {
                  // انتقال به صفحه سبد خرید
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              // اگر در سبد خرید کالایی باشد، دایره نارنجی تعداد نمایش داده می‌شود
              if (cartProvider.itemCount > 0)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),

      // IndexedStack: برای اینکه با تغییر تب‌ها وضعیت اسکرول و داده‌های صفحات حفظ شود
      // و صفحات از اول لود نشوند، از IndexedStack استفاده می‌کنیم.
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // نوار نویگیشن مدرن بر اساس استاندارد Material 3
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx; // تغییر تب فعال با کلیک کاربر
          });
        },
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: AppTheme.primaryColor),
            label: 'کاوش',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            selectedIcon: Icon(Icons.add_circle, color: AppTheme.primaryColor),
            label: 'فروش کتاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppTheme.primaryColor),
            label: 'سفارش‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}
