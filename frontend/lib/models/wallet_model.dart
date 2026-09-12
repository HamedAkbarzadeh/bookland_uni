class WalletTransactionModel {
  final int id;
  final int userId;
  final num amount;
  final String type; // 'deposit', 'withdrawal', 'sale_credit', 'purchase_debit'
  final String description;
  final DateTime? createdAt;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      amount: json['amount'] is num ? json['amount'] : num.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      type: json['type'] ?? 'deposit',
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  bool get isCredit => amount > 0 || type == 'deposit' || type == 'sale_credit';
}
