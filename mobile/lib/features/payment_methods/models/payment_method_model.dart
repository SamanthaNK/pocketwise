class PaymentMethodModel {
  PaymentMethodModel({
    required this.clientGeneratedId,
    this.serverId,
    required this.type,
    this.provider,
    required this.label,
    required this.isDefault,
    required this.isArchived,
    required this.isDeleted,
    required this.synced,
    required this.updatedAt,
  });

  final String clientGeneratedId;
  final int? serverId;
  final String type;
  final String? provider;
  final String label;
  final bool isDefault;
  final bool isArchived;
  final bool isDeleted;
  final bool synced;
  final DateTime updatedAt;

  factory PaymentMethodModel.fromServerJson(Map<String, dynamic> json) => PaymentMethodModel(
        clientGeneratedId: json['client_generated_id'] as String,
        serverId: json['id'] as int,
        type: json['type'] as String,
        provider: json['provider'] as String?,
        label: json['label'] as String,
        isDefault: json['is_default'] as bool,
        isArchived: json['is_archived'] as bool,
        isDeleted: false,
        synced: true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  factory PaymentMethodModel.fromLocalMap(Map<String, dynamic> map) => PaymentMethodModel(
        clientGeneratedId: map['client_generated_id'] as String,
        serverId: map['server_id'] as int?,
        type: map['type'] as String,
        provider: map['provider'] as String?,
        label: map['label'] as String,
        isDefault: (map['is_default'] as int) == 1,
        isArchived: (map['is_archived'] as int) == 1,
        isDeleted: (map['is_deleted'] as int) == 1,
        synced: (map['synced'] as int) == 1,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toLocalMap() => {
        'client_generated_id': clientGeneratedId,
        'server_id': serverId,
        'type': type,
        'provider': provider,
        'label': label,
        'is_default': isDefault ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'is_deleted': isDeleted ? 1 : 0,
        'synced': synced ? 1 : 0,
        'updated_at': updatedAt.toIso8601String(),
      };
}