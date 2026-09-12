import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/book_provider.dart';
import '../../widgets/book_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _conditionFilter = 'all';
  String _sortFilter = 'created_at';

  @override
  void initState() {
    super.initState();
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    _searchController.text = bookProvider.searchQuery ?? '';
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.fetchBooks(search: query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'جستجوی عنوان کتاب، نام نویسنده...',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              bookProvider.fetchBooks(search: '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Filters Row
                Row(
                  children: [
                    // Condition Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _conditionFilter,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('وضعیت: همه')),
                              DropdownMenuItem(value: 'new', child: Text('فقط نو')),
                              DropdownMenuItem(value: 'like_new', child: Text('در حد نو')),
                              DropdownMenuItem(value: 'used', child: Text('دست دوم')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _conditionFilter = val);
                                bookProvider.fetchBooks(condition: val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Sort Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortFilter,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                            items: const [
                              DropdownMenuItem(value: 'created_at', child: Text('جدیدترین')),
                              DropdownMenuItem(value: 'price_asc', child: Text('ارزان‌ترین')),
                              DropdownMenuItem(value: 'price_desc', child: Text('گران‌ترین')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _sortFilter = val);
                                bookProvider.fetchBooks(sort: val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results Count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نتایج جستجو: ${bookProvider.books.length} مورد',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                if (bookProvider.selectedCategoryId != null || _conditionFilter != 'all' || _searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _conditionFilter = 'all';
                        _sortFilter = 'created_at';
                      });
                      bookProvider.resetFilters();
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text('حذف فیلترها', style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
              ],
            ),
          ),

          // Grid Results
          Expanded(
            child: bookProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookProvider.books.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.find_in_page_outlined, size: 56, color: AppTheme.textLight),
                            const SizedBox(height: 12),
                            const Text(
                              'کتابی مطابق با جستجوی شما یافت نشد',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                bookProvider.resetFilters();
                              },
                              child: const Text('مشاهده تمام کتاب‌ها'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: bookProvider.books.length,
                        itemBuilder: (ctx, index) {
                          final book = bookProvider.books[index];
                          return BookCard(book: book);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
