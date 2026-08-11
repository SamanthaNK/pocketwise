import '../../../core/utils/amount_utils.dart';

class DebtModel {
  DebtModel({
    required this.clientGeneratedId,
    this.serverId,
    required this.personName,
    required this.amount,
    required this.direction,
    this.dueDate,
    this.note,
    required this.isSettled,
    this.settledAt,
    required this.isDeleted,
    required this.synced,
    required this.updatedAt,
  });

  final String clientGeneratedId;
  final int? serverId;
  final String personName;
  final int amount;
  final String direction; // 'owed_to_user' | 'owed_by_user'
  final DateTime? dueDate;
  final String? note;
  final bool isSettled;
  final DateTime? settledAt;
  final bool isDeleted;
  final bool synced;
  final DateTime updatedAt;

  factory DebtModel.fromServerJson(Map<String, dynamic> json) => DebtModel(
        clientGeneratedId: json['client_generated_id'] as String,
        serverId: json['id'] as int,
        personName: json['person_name'] as String,
        amount: parseAmountToInt(json['amount']),
        direction: json['direction'] as String,
        dueDate: json['due_date'] == null ? null : DateTime.parse(json['due_date'] as String),
        note: json['note'] as String?,
        isSettled: json['is_settled'] as bool,
        settledAt: json['settled_at'] == null ? null : DateTime.parse(json['settled_at'] as String),
        isDeleted: false,
        synced: true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory DebtModel.fromLocalMap(Map<String, dynamic> map) => DebtModel(
        clientGeneratedId: map['client_generated_id'] as String,
        serverId: map['server_id'] as int?,
        personName: map['person_name'] as String,
        amount: map['amount'] as int,
        direction: map['direction'] as String,
        dueDate: map['due_date'] == null ? null : DateTime.parse(map['due_date'] as String),
        note: map['note'] as String?,
        isSettled: (map['is_settled'] as int) == 1,
        settledAt: map['settled_at'] == null ? null : DateTime.parse(map['settled_at'] as String),
        isDeleted: (map['is_deleted'] as int) == 1,
        synced: (map['synced'] as int) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toLocalMap() => {
        'client_generated_id': clientGeneratedId,
        'server_id': serverId,
        'person_name': personName,
        'amount': amount,
        'direction': direction,
        'due_date': dueDate?.toIso8601String().split('T').first,
        'note': note,
        'is_settled': isSettled ? 1 : 0,
        'settled_at': settledAt?.toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
        'synced': synced ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}