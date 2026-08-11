import '../../../core/utils/amount_utils.dart';

class SavingsGoalModel {
  SavingsGoalModel({
    required this.clientGeneratedId,
    this.serverId,
    required this.name,
    required this.targetAmount,
    this.targetDate,
    required this.savedAmount,
    required this.isDeleted,
    required this.synced,
    required this.updatedAt,
  });

  final String clientGeneratedId;
  final int? serverId;
  final String name;
  final int targetAmount;
  final DateTime? targetDate;
  final int savedAmount;
  final bool isDeleted;
  final bool synced;
  final DateTime updatedAt;

  factory SavingsGoalModel.fromServerJson(Map<String, dynamic> json) => SavingsGoalModel(
        clientGeneratedId: json['client_generated_id'] as String,
        serverId: json['id'] as int,
        name: json['name'] as String,
        targetAmount: parseAmountToInt(json['target_amount']),
        targetDate: json['target_date'] == null ? null : DateTime.parse(json['target_date'] as String),
        savedAmount: parseAmountToInt(json['saved_amount']),
        isDeleted: false,
        synced: true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory SavingsGoalModel.fromLocalMap(Map<String, dynamic> map) => SavingsGoalModel(
        clientGeneratedId: map['client_generated_id'] as String,
        serverId: map['server_id'] as int?,
        name: map['name'] as String,
        targetAmount: map['target_amount'] as int,
        targetDate: map['target_date'] == null ? null : DateTime.parse(map['target_date'] as String),
        savedAmount: map['saved_amount'] as int,
        isDeleted: (map['is_deleted'] as int) == 1,
        synced: (map['synced'] as int) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toLocalMap() => {
        'client_generated_id': clientGeneratedId,
        'server_id': serverId,
        'name': name,
        'target_amount': targetAmount,
        'target_date': targetDate?.toIso8601String().split('T').first,
        'saved_amount': savedAmount,
        'is_deleted': isDeleted ? 1 : 0,
        'synced': synced ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}