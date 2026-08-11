import '../../../core/utils/amount_utils.dart';

class SavingsContributionModel {
  SavingsContributionModel({
    required this.clientGeneratedId,
    this.serverId,
    required this.goalId,
    required this.amount,
    required this.contributionType,
    required this.contributionDate,
    required this.isDeleted,
    required this.synced,
    required this.createdAt,
  });

  final String clientGeneratedId;
  final int? serverId;
  final String goalId;
  final int amount;
  final String contributionType; // 'deposit' | 'withdrawal'
  final DateTime contributionDate;
  final bool isDeleted;
  final bool synced;
  final DateTime createdAt;

  factory SavingsContributionModel.fromServerJson(Map<String, dynamic> json) => SavingsContributionModel(
        clientGeneratedId: json['client_generated_id'] as String,
        serverId: json['id'] as int,
        goalId: '',
        amount: parseAmountToInt(json['amount']),
        contributionType: json['contribution_type'] as String,
        contributionDate: DateTime.parse(json['contribution_date'] as String),
        isDeleted: false,
        synced: true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  factory SavingsContributionModel.fromLocalMap(Map<String, dynamic> map) => SavingsContributionModel(
        clientGeneratedId: map['client_generated_id'] as String,
        serverId: map['server_id'] as int?,
        goalId: map['goal_id'] as String,
        amount: map['amount'] as int,
        contributionType: map['contribution_type'] as String,
        contributionDate: DateTime.parse(map['contribution_date'] as String),
        isDeleted: (map['is_deleted'] as int) == 1,
        synced: (map['synced'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  SavingsContributionModel copyWithGoalId(String resolvedGoalId) => SavingsContributionModel(
        clientGeneratedId: clientGeneratedId,
        serverId: serverId,
        goalId: resolvedGoalId,
        amount: amount,
        contributionType: contributionType,
        contributionDate: contributionDate,
        isDeleted: isDeleted,
        synced: synced,
        createdAt: createdAt,
      );

  Map<String, dynamic> toLocalMap() => {
        'client_generated_id': clientGeneratedId,
        'server_id': serverId,
        'goal_id': goalId,
        'amount': amount,
        'contribution_type': contributionType,
        'contribution_date': contributionDate.toIso8601String().split('T').first,
        'is_deleted': isDeleted ? 1 : 0,
        'synced': synced ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}