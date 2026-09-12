import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import 'auth/login_screen.dart';
import 'main_nav_screen.dart';

/// ============================================================================
/// ✨ صفحه اسپلش و بارگذاری اولیه برنامه (SplashScreen)
/// ============================================================================
/// این صفحه دارای استیت پویا (StatefulWidget) و انیمیشن است.
/// کارهای اصلی این صفحه:
/// ۱. اجرای انیمیشن نرم بزرگ‌نمایی و محوشدگی لوگوی بوک‌لند
/// ۲. بارگذاری دسته‌بندی‌ها و کتاب‌ها در پس‌زمینه
/// ۳. بررسی توکن قبلی کاربر:
///    - اگر وارد شده باشد -> انتقال مستقیم به صفحه اصلی (MainNavScreen)
///    - اگر وارد نشده باشد -> انتقال به صفحه ورود (LoginScreen)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;      // کنترل‌کننده مدت زمان و تکرار انیمیشن
  late Animation<double> _scaleAnimation;    // انیمیشن تغییر اندازه لوگو (بزرگ‌نمایی ملایم)
  late Animation<double> _fadeAnimation;     // انیمیشن پدیدار شدن تدریجی متن‌ها

  @override
  void initState() {
    super.initState();

    // ۱. تنظیم مدت زمان انیمیشن روی ۱.۲ ثانیه
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // انیمیشن اندازه از ۸۰٪ تا ۱۰۰٪ با حرکت فنری نرم
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // انیمیشن وضوح تصویر از ۰ (کاملاً شفاف) تا ۱ (کاملاً واضح)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    // شروع اجرای انیمیشن
    _controller.forward();

    // شروع فرآیند بارگذاری اولیه اطلاعات برنامه
    _initializeApp();
  }

  /// متد بارگذاری اولیه و بررسی وضعیت لاگین
  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookProvider = Provider.of<BookProvider>(context, listen: false);

    // دریافت دسته‌بندی‌ها و کتاب‌ها در پس‌زمینه تا موقع ورود کاربر معطل نماند
    bookProvider.fetchCategories();
    bookProvider.fetchBooks();

    // مکث کوتاه ۱.۶ ثانیه‌ای تا کاربر از دیدن انیمیشن اسپلش لذت ببرد
    await Future.delayed(const Duration(milliseconds: 1600));

    // بررسی اینکه آیا قبلاً کاربر وارد شده و توکن معتبر دارد یا خیر
    final bool hasValidSession = await authProvider.tryAutoLogin();

    // اگر صفحه هنوز باز بود (کاربر از برنامه خارج نشده بود):
    if (!mounted) return;

    if (hasValidSession) {
      // کاربر وارد شده بود -> برو به صفحه اصلی
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavScreen()),
      );
    } else {
      // کاربر مهمان است -> برو به صفحه ورود
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // آزادسازی حافظه کنترلر انیمیشن جهت جلوگیری از افت پرفورمنس
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // آیکون گرادیان بوک‌لند با سایه نرم
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryLight],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'بوک‌لند | بازار کتاب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'خرید و فروش آسان کتاب‌های نو و دست‌دوم',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                // لودینگ دایره‌ای ظریف
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
