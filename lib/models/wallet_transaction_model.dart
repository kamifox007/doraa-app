class WalletTransactionModel {
  final String id;
  final String userId;
  final double amount;
  final String type; // 'topup', 'withdrawal', 'transfer_in', 'transfer_out', 'commission', 'subscription'
  final String status; // 'pending', 'completed', 'failed', 'rejected'
  final String? description;
  final DateTime createdAt;

  WalletTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'description': description,
    };
  }
}
