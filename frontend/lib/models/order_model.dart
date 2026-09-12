class OrderItemModel {
  final int id;
  final int orderId;
  final int bookId;
  final int sellerId;
  final num price;
  final int quantity;
  final String title;
  final String author;
  final String? imageUrl;
  final String sellerName;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.bookId,
    required this.sellerId,
    required this.price,
    this.quantity = 1,
    this.title = 'کتاب',
    this.author = '',
    this.imageUrl,
    this.sellerName = 'فروشنده',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id']?.toString() ?? '0') ?? 0,
      bookId: json['book_id'] is int ? json['book_id'] : int.tryParse(json['book_id']?.toString() ?? '0') ?? 0,
      sellerId: json['seller_id'] is int ? json['seller_id'] : int.tryParse(json['seller_id']?.toString() ?? '0') ?? 0,
      price: json['price'] is num ? json['price'] : num.tryParse(json['price']?.toString() ?? '0') ?? 0,
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'کتاب',
      author: json['author'] ?? '',
      imageUrl: json['image_url'],
      sellerName: json['seller_name'] ?? 'فروشنده',
    );
  }
}

class OrderModel {
  final int id;
  final int buyerId;
  final num totalAmount;
  final String status; // 'completed', 'pending', 'cancelled'
  final String paymentMethod;
  final String shippingAddress;
  final List<OrderItemModel> items;
  final DateTime? createdAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    this.items = const [],
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> itemsList = [];
    if (json['items'] != null && json['items'] is List) {
      itemsList = (json['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList();
    }

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      buyerId: json['buyer_id'] is int ? json['buyer_id'] : int.tryParse(json['buyer_id']?.toString() ?? '0') ?? 0,
      totalAmount: json['total_amount'] is num
          ? json['total_amount']
          : num.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
      status: json['status'] ?? 'completed',
      paymentMethod: json['payment_method'] ?? 'wallet',
      shippingAddress: json['shipping_address'] ?? '',
      items: itemsList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
