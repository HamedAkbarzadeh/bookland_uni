import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/book_provider.dart';
import '../../widgets/status_badge.dart';
import '../books/book_details_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  @override
  void initState() {
    super.initState();
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    bookProvider.fetchMyListings();
  }

  void _confirmDelete(int bookId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف کتاب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('آیا از حذف کتاب "$title" از لیست فروش اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final bookProvider = Provider.of<BookProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final success = await bookProvider.deleteBook(bookId);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (success) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('کتاب با موفقیت حذف شد'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('حذف کتاب'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('کتاب‌های من برای فروش'),
      ),
      body: bookProvider.isLoadingMyListings
          ? const Center(child: CircularProgressIndicator())
          : bookProvider.myListings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.menu_book, size: 64, color: AppTheme.textLight),
                      const SizedBox(height: 12),
                      const Text(
                        'شما هنوز کتابی برای فروش ثبت نکرده‌اید',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ثبت اولین کتاب برای فروش'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookProvider.myListings.length,
                  itemBuilder: (ctx, index) {
                    final book = bookProvider.myListings[index];
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
                                    width: 64,
                                    height: 84,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 64,
                                    height: 84,
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
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'نویسنده: ${book.author}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    StatusBadge(status: book.status),
                                    const SizedBox(width: 6),
                                    Text(
                                      Formatters.formatPrice(book.price),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 20, color: AppTheme.primaryColor),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BookDetailsScreen(bookId: book.id),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                onPressed: () => _confirmDelete(book.id, book.title),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
