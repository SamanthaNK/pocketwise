import '../../../core/utils/amount_utils.dart';

class TransactionModel {
  TransactionModel({
    required this.clientGeneratedId,
    this.serverId,
    required this.categoryId,
    this.categoryServerId,
    this.paymentMethodId,
    this.paymentMethodServerId,
    required this.type,
    required this.amount,
    this.description,
    required this.transactionDate,
    required this.isDeleted,
    required this.synced,
    required this.updatedAt,
  });

  final String clientGeneratedId;
  final int? serverId;
  final String categoryId;
  final int? categoryServerId;
  final String? paymentMethodId;
  final int? paymentMethodServerId;
  final String type; // 'income' | 'expense'
  final int amount;
  final String? description;
  final DateTime transactionDate;
  final bool isDeleted;
  final bool synced;
  final DateTime updatedAt;

  factory TransactionModel.fromServerJson(Map<String, dynamic> json) => TransactionModel(
        clientGeneratedId: json['client_generated_id'] as String,
        serverId: json['id'] as int,
        categoryId: '',
        categoryServerId: json['category_id'] as int,
        paymentMethodId: null,
        paymentMethodServerId: json['payment_method_id'] as int?,
        type: json['type'] as String,
        amount: parseAmountToInt(json['amount']),
        description: json['description'] as String?,
        transactionDate: DateTime.parse(json['transaction_date'] as String),
        isDeleted: false,
        synced: true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory TransactionModel.fromLocalMap(Map<String, dynamic> map) => TransactionModel(
        clientGeneratedId: map['client_generated_id'] as String,
        serverId: map['server_id'] as int?,
        categoryId: map['category_id'] as String,
        paymentMethodId: map['payment_method_id'] as String?,
        type: map['type'] as String,
        amount: map['amount'] as int,
        description: map['description'] as String?,
        transactionDate: DateTime.parse(map['transaction_date'] as String),
        isDeleted: (map['is_deleted'] as int) == 1,
        synced: (map['synced'] as int) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  TransactionModel copyWithLocalIds(String resolvedCategoryId, String? resolvedPaymentMethodId) => TransactionModel(
        clientGeneratedId: clientGeneratedId,
        serverId: serverId,
        categoryId: resolvedCategoryId,
        categoryServerId: categoryServerId,
        paymentMethodId: resolvedPaymentMethodId,
        paymentMethodServerId: paymentMethodServerId,
        type: type,
        amount: amount,
        description: description,
        transactionDate: transactionDate,
        isDeleted: isDeleted,
        synced: synced,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toLocalMap() => {
        'client_generated_id': clientGeneratedId,
        'server_id': serverId,
        'category_id': categoryId,
        'payment_method_id': paymentMethodId,
        'type': type,
        'amount': amount,
        'description': description,
        'transaction_date': transactionDate.toIso8601String().split('T').first,
        'is_deleted': isDeleted ? 1 : 0,
        'synced': synced ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}