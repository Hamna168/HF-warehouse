import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

// Product Model
@JsonSerializable()
class Product {
  final int? id;
  final String sku;
  final String name;
  final String description;
  final String category;
  final String size;
  final String color;
  final double price;
  final int quantity;
  final int reorderLevel;
  final String status; // active, inactive, discontinued
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.category,
    required this.size,
    required this.color,
    required this.price,
    required this.quantity,
    required this.reorderLevel,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'description': description,
      'category': category,
      'size': size,
      'color': color,
      'price': price,
      'quantity': quantity,
      'reorderLevel': reorderLevel,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      sku: map['sku'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      size: map['size'],
      color: map['color'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      reorderLevel: map['reorderLevel'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

// Inventory Transaction Model
@JsonSerializable()
class InventoryTransaction {
  final int? id;
  final int productId;
  final String transactionType; // inbound, outbound, adjustment
  final int quantity;
  final String reason; // purchase, sale, damage, theft, correction
  final String notes;
  final String performedBy;
  final DateTime timestamp;

  InventoryTransaction({
    this.id,
    required this.productId,
    required this.transactionType,
    required this.quantity,
    required this.reason,
    required this.notes,
    required this.performedBy,
    required this.timestamp,
  });

  factory InventoryTransaction.fromJson(Map<String, dynamic> json) =>
      _$InventoryTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryTransactionToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'transactionType': transactionType,
      'quantity': quantity,
      'reason': reason,
      'notes': notes,
      'performedBy': performedBy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory InventoryTransaction.fromMap(Map<String, dynamic> map) {
    return InventoryTransaction(
      id: map['id'],
      productId: map['productId'],
      transactionType: map['transactionType'],
      quantity: map['quantity'],
      reason: map['reason'],
      notes: map['notes'],
      performedBy: map['performedBy'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

// Stock Movement Model
@JsonSerializable()
class StockMovement {
  final int? id;
  final int productId;
  final int quantityMoved;
  final String fromLocation;
  final String toLocation;
  final String status; // pending, completed, cancelled
  final String movedBy;
  final DateTime createdAt;
  final DateTime? completedAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.quantityMoved,
    required this.fromLocation,
    required this.toLocation,
    this.status = 'pending',
    required this.movedBy,
    required this.createdAt,
    this.completedAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) =>
      _$StockMovementFromJson(json);
  Map<String, dynamic> toJson() => _$StockMovementToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantityMoved': quantityMoved,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'status': status,
      'movedBy': movedBy,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['productId'],
      quantityMoved: map['quantityMoved'],
      fromLocation: map['fromLocation'],
      toLocation: map['toLocation'],
      status: map['status'] ?? 'pending',
      movedBy: map['movedBy'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }
}

// User Model
@JsonSerializable()
class User {
  final int? id;
  final String username;
  final String email;
  final String role; // admin, manager, staff
  final String status; // active, inactive
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.role,
    this.status = 'active',
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      role: map['role'],
      status: map['status'] ?? 'active',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

// Reports Model
@JsonSerializable()
class WareouseReport {
  final int? id;
  final String reportType; // inventory, sales, movement, audit
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final String generatedBy;
  final DateTime generatedAt;

  WareouseReport({
    this.id,
    required this.reportType,
    required this.title,
    required this.description,
    required this.data,
    required this.generatedBy,
    required this.generatedAt,
  });

  factory WareouseReport.fromJson(Map<String, dynamic> json) =>
      _$WareouseReportFromJson(json);
  Map<String, dynamic> toJson() => _$WareouseReportToJson(this);
}
