import 'package:flutter/material.dart';

class CategoryModel {
  final int id;
  final String name;
  final String slug;
  final String? icon;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'],
    );
  }

  IconData get iconData {
    switch (icon) {
      case 'auto_stories':
        return Icons.auto_stories;
      case 'psychology':
        return Icons.psychology;
      case 'history_edu':
        return Icons.history_edu;
      case 'trending_up':
        return Icons.trending_up;
      case 'science':
        return Icons.science;
      case 'menu_book':
        return Icons.menu_book;
      default:
        return Icons.book;
    }
  }
}
