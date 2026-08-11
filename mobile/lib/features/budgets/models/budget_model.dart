import '../../../core/utils/amount_utils.dart';

class BudgetModel {
  BudgetModel({
    required this.id,
    required this.ruleType,
    required this.periodType,
    this.categoryId,
    this.categoryServerId,
    this.budgetGroup,
    required this.limitAmount,
    this.declaredIncome,
    required this.spent,
    required this.isActive,
    required this.isDeleted,
    required this.updatedAt,
  });

  final int id;
  final String ruleType;
  final String periodType;
  final String? categoryId;
  final int? categoryServerId;
  final String? budgetGroup;
  final int limitAmount;
  final int? declaredIncome;
  final int spent;
  final bool isActive;
  final bool isDeleted;
  final DateTime updatedAt;

  factory BudgetModel.fromServerJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as int,
        ruleType: json['rule_type'] as String,
        periodType: json['period_type'] as String,
        categoryServerId: json['category_id'] as int?,
        budgetGroup: json['budget_group'] as String?,
        limitAmount: parseAmountToInt(json['limit_amount']),
        declaredIncome: json['declared_income'] == null ? null : parseAmountToInt(json['declared_income']),
        spent: parseAmountToInt(json['spent']),
        isActive: json['is_active'] as bool,
        isDeleted: false,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory BudgetModel.fromLocalMap(Map<String, dynamic> map) => BudgetModel(
        id: map['id'] as int,
        ruleType: map['rule_type'] as String,
        periodType: map['period_type'] as String,
        categoryId: map['category_id'] as String?,
        budgetGroup: map['budget_group'] as String?,
        limitAmount: map['limit_amount'] as int,
        declaredIncome: map['declared_income'] as int?,
        spent: map['spent'] as int,
        isActive: (map['is_active'] as int) == 1,
        isDeleted: (map['is_deleted'] as int) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  BudgetModel copyWithLocalCategoryId(String? resolvedCategoryId) => BudgetModel(
        id: id,
        ruleType: ruleType,
        periodType: periodType,
        categoryId: resolvedCategoryId,
        categoryServerId: categoryServerId,
        budgetGroup: budgetGroup,
        limitAmount: limitAmount,
        declaredIncome: declaredIncome,
        spent: spent,
        isActive: isActive,
        isDeleted: isDeleted,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toLocalMap() => {
        'id': id,
        'rule_type': ruleType,
        'period_type': periodType,
        'category_id': categoryId,
        'budget_group': budgetGroup,
        'limit_amount': limitAmount,
        'declared_income': declaredIncome,
        'spent': spent,
        'is_active': isActive ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}