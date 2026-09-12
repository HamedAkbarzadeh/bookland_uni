import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.fetchMyOrders();
    orderProvider.fetchMySales();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('مدیریت سفارش‌ها و فروش'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'خریدهای من (کتاب‌های خریداری‌شده)'),
            Tab(text: 'فروش‌های من (کتاب‌های فروخته‌شده)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. My Purchases
          RefreshIndicator(
            onRefresh: () async => orderProvider.fetchMyOrders(),
            child: orderProvider.isLoadingOrders
                ? const Center(child: CircularProgressIndicator())
                : orderProvider.myOrders.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 56, color: AppTheme.textLight),
                            SizedBox(height: 12),
                            Text(
                              'شما هنوز سفارشی ثبت نکرده‌اید',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orderProvider.myOrders.length,
                        itemBuilder: (ctx, index) {
                          final order = orderProvider.myOrders[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'سفارش #${Formatters.toPersianDigits('${order.id}')}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: const Text(
                                        'تکمیل شده',
                                        style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                ...order.items.map((item) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: item.imageUrl!,
                                                  width: 36,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 36,
                                                  height: 48,
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.book, size: 20),
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                              Text('فروشنده: ${item.sellerName}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatPrice(item.price * item.quantity),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('مجموع پرداختی:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    Text(
                                      Formatters.formatPrice(order.totalAmount),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // 2. My Sales
          RefreshIndicator(
            onRefresh: () async => orderProvider.fetchMySales(),
            child: orderProvider.isLoadingSales
                ? const Center(child: CircularProgressIndicator())
                : orderProvider.mySales.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sell_outlined, size: 56, color: AppTheme.textLight),
                            SizedBox(height: 12),
                            Text(
                              'هنوز کتابی از شما خریداری نشده است',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'کتاب‌های بیشتری ثبت کنید تا شانس فروش شما افزایش یابد!',
                              style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orderProvider.mySales.length,
                        itemBuilder: (ctx, index) {
                          final sale = orderProvider.mySales[index];
                          final price = sale['price'] is num
                              ? sale['price']
                              : num.tryParse(sale['price']?.toString() ?? '0') ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'فروش کتاب: ${sale['title'] ?? ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: const Text(
                                        'واریز شده به کیف پول',
                                        style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: AppTheme.textLight),
                                    const SizedBox(width: 4),
                                    Text('خریدار: ${sale['buyer_name'] ?? 'ناشناس'}', style: const TextStyle(fontSize: 12)),
                                    const Spacer(),
                                    if (sale['buyer_phone'] != null && sale['buyer_phone'] != '')
                                      Text('تماس: ${sale['buyer_phone']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (sale['shipping_address'] != null && sale['shipping_address'] != '')
                                  Text(
                                    'آدرس ارسال: ${sale['shipping_address']}',
                                    style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                                  ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('مبلغ واریزی به شما:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                    Text(
                                      Formatters.formatPrice(price),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
