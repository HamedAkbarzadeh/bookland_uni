import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'screens/splash_screen.dart';

/// ============================================================================
/// 🚀 نقطه شروع و ورودی کل اپلیکیشن فلاتر (Main Entry Point)
/// ============================================================================
/// این تابع [main] اولین خط کدی است که موقع باز شدن برنامه اجرا می‌شود.
void main() {
  // اطمینان از مقداردهی اولیه فریم‌ورک فلاتر قبل از اجرای ویجت‌ها
  WidgetsFlutterBinding.ensureInitialized();

  // اجرای ویجت ریشه برنامه
  runApp(const BookHubApp());
}

/// ============================================================================
/// 🏛️ ویجت ریشه برنامه (Root Widget)
/// ============================================================================
/// این کلاس کل برنامه را در بر می‌گیرد و شامل تنظیمات کلی مانند:
/// ۱. پرووایدرها (مدیریت وضعیت برنامه - State Management)
/// ۲. تنظیمات زبان و راست‌چین بودن (RTL / فارسی)
/// ۳. قالب و تم رنگی (Material 3 Theme)
class BookHubApp extends StatelessWidget {
  const BookHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider: برای اینکه تمام صفحات برنامه به اطلاعات احراز هویت، کتاب‌ها،
    // سبد خرید و سفارش‌ها دسترسی داشته باشند، پرووایدرها را در بالاترین سطح تعریف می‌کنیم.
    return MultiProvider(
      providers: [
        // ۱. مدیریت ورود، خروج، مشخصات کاربر و کیف پول
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ۲. مدیریت دریافت لیست کتاب‌ها، دسته‌بندی‌ها و فیلترها
        ChangeNotifierProvider(create: (_) => BookProvider()),

        // ۳. مدیریت سبد خرید و فرآیند ثبت سفارش
        ChangeNotifierProvider(create: (_) => CartProvider()),

        // ۴. مدیریت تاریخچه خریدها و فروش‌های کاربر
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        // عنوان برنامه در تسک‌بار یا نمای برنامه‌های باز
        title: 'بوک‌لند | بازار خرید و فروش کتاب',
        debugShowCheckedModeBanner: false, // حذف نوار قرمز دیباگ در گوشه صفحه

        // تم اختصاصی برنامه (رنگ‌ها، استایل دکمه‌ها و فرم‌ها)
        theme: AppTheme.lightTheme,

        // تنظیم زبان برنامه به فارسی ایران جهت راست‌چین شدن خودکار (RTL)
        locale: const Locale('fa', 'IR'),
        supportedLocales: const [
          Locale('fa', 'IR'),
          Locale('en', 'US'),
        ],

        // پکیج‌های استاندارد فلاتر برای ترجمه و پشتیبانی کامل متریال از راست‌چین
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // اولین صفحه‌ای که کاربر می‌بیند: صفحه اسپلش (لوگو و انیمیشن شروع)
        home: const SplashScreen(),
      ),
    );
  }
}
