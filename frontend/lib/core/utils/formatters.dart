import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Formatters {
  static String toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    for (int i = 0; i < english.length; i++) {
      input = input.replaceAll(english[i], persian[i]);
    }
    return input;
  }

  static String formatPrice(num price) {
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(price);
    return '${toPersianDigits(formatted)} تومان';
  }

  static String conditionToPersian(String? condition) {
    switch (condition) {
      case 'new':
        return 'نو (آکبند)';
      case 'like_new':
        return 'در حد نو';
      case 'used':
      default:
        return 'دست دوم';
    }
  }

  static Color conditionColor(String? condition) {
    switch (condition) {
      case 'new':
        return Colors.green.shade700;
      case 'like_new':
        return Colors.teal.shade600;
      case 'used':
      default:
        return Colors.amber.shade800;
    }
  }

  static String statusToPersian(String? status) {
    switch (status) {
      case 'available':
        return 'موجود';
      case 'sold':
        return 'فروخته شد';
      case 'reserved':
        return 'رزرو شده';
      default:
        return status ?? '';
    }
  }

  static Color statusColor(String? status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'sold':
        return Colors.grey.shade600;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
