class CategoryModel {
  CategoryModel({
    required this.clientGeneratedId,
    this.serverId,
    required this.name,
    required this.type,
    required this.icon,
    this.budgetGroup,
    required this.isDefault,
    required this.isArchived,
    required this.isDeleted,
    required this.synced,
    required this.updatedAt,
  });

  final String clientGeneratedId;
  final int? serverId;
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String? budgetGroup;
  final bool isDefault;
  final bool isArchived;
  final bool isDeleted;
  final bool synced;
  final DateTime updatedAt;

  factory CategoryModel.fromServerJson(Map<String, dynamic> json) => CategoryModel(
        clientGeneratedId: json['client_generated_id'] as String,
        serverId: json['id'] as int,
        name: json['name'] as String,
        type: json['type'] as String,
        icon: json['icon'] as String,
        budgetGroup: json['budget_group'] as String?,
        isDefault: json['is_default'] as bool,
        isArchived: json['is_archived'] as bool,
        isDeleted: false,
        synced: true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory CategoryModel.fromLocalMap(Map<String, dynamic> map) => CategoryModel(
        clientGeneratedId: map['client_generated_id'] as String,
        serverId: map['server_id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        icon: map['icon'] as String,
        budgetGroup: map['budget_group'] as String?,
        isDefault: (map['is_default'] as int) == 1,
        isArchived: (map['is_archived'] as int) == 1,
        isDeleted: (map['is_deleted'] as int) == 1,
        synced: (map['synced'] as int) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toLocalMap() => {
        'client_generated_id': clientGeneratedId,
        'server_id': serverId,
        'name': name,
        'type': type,
        'icon': icon,
        'budget_group': budgetGroup,
        'is_default': isDefault ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'synced': synced ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}