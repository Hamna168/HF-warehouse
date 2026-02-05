// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['id'] as num?)?.toInt(),
  sku: json['sku'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  size: json['size'] as String,
  color: json['color'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  reorderLevel: (json['reorderLevel'] as num).toInt(),
  status: json['status'] as String? ?? 'active',
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'sku': instance.sku,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'size': instance.size,
  'color': instance.color,
  'price': instance.price,
  'quantity': instance.quantity,
  'reorderLevel': instance.reorderLevel,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

InventoryTransaction _$InventoryTransactionFromJson(
  Map<String, dynamic> json,
) => InventoryTransaction(
  id: (json['id'] as num?)?.toInt(),
  productId: (json['productId'] as num).toInt(),
  transactionType: json['transactionType'] as String,
  quantity: (json['quantity'] as num).toInt(),
  reason: json['reason'] as String,
  notes: json['notes'] as String,
  performedBy: json['performedBy'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
);

Map<String, dynamic> _$InventoryTransactionToJson(
  InventoryTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'productId': instance.productId,
  'transactionType': instance.transactionType,
  'quantity': instance.quantity,
  'reason': instance.reason,
  'notes': instance.notes,
  'performedBy': instance.performedBy,
  'timestamp': instance.timestamp.toIso8601String(),
};

StockMovement _$StockMovementFromJson(Map<String, dynamic> json) =>
    StockMovement(
      id: (json['id'] as num?)?.toInt(),
      productId: (json['productId'] as num).toInt(),
      quantityMoved: (json['quantityMoved'] as num).toInt(),
      fromLocation: json['fromLocation'] as String,
      toLocation: json['toLocation'] as String,
      status: json['status'] as String? ?? 'pending',
      movedBy: json['movedBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$StockMovementToJson(StockMovement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'quantityMoved': instance.quantityMoved,
      'fromLocation': instance.fromLocation,
      'toLocation': instance.toLocation,
      'status': instance.status,
      'movedBy': instance.movedBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num?)?.toInt(),
  username: json['username'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
  status: json['status'] as String? ?? 'active',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'email': instance.email,
  'role': instance.role,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
};

WareouseReport _$WareouseReportFromJson(Map<String, dynamic> json) =>
    WareouseReport(
      id: (json['id'] as num?)?.toInt(),
      reportType: json['reportType'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      data: json['data'] as Map<String, dynamic>,
      generatedBy: json['generatedBy'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$WareouseReportToJson(WareouseReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportType': instance.reportType,
      'title': instance.title,
      'description': instance.description,
      'data': instance.data,
      'generatedBy': instance.generatedBy,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
