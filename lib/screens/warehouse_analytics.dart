import '../models/models.dart';
import '../services/database_service.dart';

class WarehouseAnalytics {
  final DatabaseService _dbService = DatabaseService();

  /// Get inventory value distribution
  Future<Map<String, double>> getInventoryValueByCategory() async {
    final products = await _dbService.getAllProducts();
    final Map<String, double> categoryValues = {};

    for (final product in products) {
      if (product.status == 'active') {
        final value = product.price * product.quantity;
        categoryValues[product.category] =
            (categoryValues[product.category] ?? 0) + value;
      }
    }

    return categoryValues;
  }

  /// Get stock health metrics
  Future<Map<String, dynamic>> getStockHealthMetrics() async {
    final products = await _dbService.getAllProducts();

    int overstock = 0;
    int normalStock = 0;
    int lowStock = 0;
    int outOfStock = 0;

    for (final product in products) {
      if (product.status == 'active') {
        if (product.quantity == 0) {
          outOfStock++;
        } else if (product.quantity <= product.reorderLevel) {
          lowStock++;
        } else if (product.quantity > product.reorderLevel * 3) {
          overstock++;
        } else {
          normalStock++;
        }
      }
    }

    return {
      'outOfStock': outOfStock,
      'lowStock': lowStock,
      'normalStock': normalStock,
      'overstock': overstock,
      'totalActive': overstock + normalStock + lowStock + outOfStock,
    };
  }

  /// Get top products by value
  Future<List<Map<String, dynamic>>> getTopProductsByValue({
    int limit = 10,
  }) async {
    final products = await _dbService.getAllProducts();

    final List<Map<String, dynamic>> productValues = [];
    for (final product in products) {
      if (product.status == 'active') {
        productValues.add({
          'name': product.name,
          'sku': product.sku,
          'value': product.price * product.quantity,
          'quantity': product.quantity,
          'price': product.price,
        });
      }
    }

    productValues.sort(
      (a, b) => (b['value'] as num).compareTo(a['value'] as num),
    );
    return productValues.take(limit).toList();
  }

  /// Get category statistics
  Future<Map<String, int>> getCategoryStatistics() async {
    final products = await _dbService.getAllProducts();
    final Map<String, int> categoryCount = {};

    for (final product in products) {
      if (product.status == 'active') {
        categoryCount[product.category] =
            (categoryCount[product.category] ?? 0) + 1;
      }
    }

    return categoryCount;
  }

  /// Calculate inventory turnover
  Future<double> calculateInventoryTurnover(int days) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final endDate = DateTime.now();

      final transactions = await _dbService.getAllTransactions(
        startDate: startDate,
        endDate: endDate,
      );

      int totalOutbound = 0;
      for (final transaction in transactions) {
        if (transaction.transactionType == 'outbound') {
          totalOutbound += transaction.quantity;
        }
      }

      final stats = await _dbService.getWarehouseStats();
      final avgInventory = (stats['totalQuantity'] as int) / 2;

      if (avgInventory == 0) return 0;
      return totalOutbound / avgInventory;
    } catch (e) {
      return 0;
    }
  }

  /// Get slow moving items
  Future<List<Product>> getSlowMovingItems({int days = 90}) async {
    final products = await _dbService.getAllProducts();
    final slowMoving = <Product>[];

    for (final product in products) {
      final transactions = await _dbService.getTransactionsByProduct(
        product.id!,
      );

      final recentTransactions = transactions.where((t) {
        final age = DateTime.now().difference(t.timestamp).inDays;
        return age <= days && t.transactionType == 'outbound';
      }).toList();

      if (recentTransactions.isEmpty &&
          product.quantity > product.reorderLevel * 2) {
        slowMoving.add(product);
      }
    }

    return slowMoving;
  }

  /// Get fast moving items
  Future<List<Product>> getFastMovingItems({int days = 30}) async {
    final products = await _dbService.getAllProducts();
    final fastMoving = <Product>[];
    final transactionCounts = <int, int>{};

    for (final product in products) {
      if (product.status == 'active') {
        final transactions = await _dbService.getTransactionsByProduct(
          product.id!,
        );

        final recentOutbound = transactions.where((t) {
          final age = DateTime.now().difference(t.timestamp).inDays;
          return age <= days && t.transactionType == 'outbound';
        }).length;

        transactionCounts[product.id!] = recentOutbound;
      }
    }

    // Get products with more than average transactions
    final avgTransactions = transactionCounts.values.isEmpty
        ? 0
        : transactionCounts.values.reduce((a, b) => a + b) ~/
              transactionCounts.length;

    for (final product in products) {
      if ((transactionCounts[product.id!] ?? 0) > avgTransactions &&
          product.status == 'active') {
        fastMoving.add(product);
      }
    }

    return fastMoving;
  }

  /// Get reorder recommendations
  Future<List<Map<String, dynamic>>> getReorderRecommendations() async {
    final lowStockProducts = await _dbService.getLowStockProducts();
    final recommendations = <Map<String, dynamic>>[];

    for (final product in lowStockProducts) {
      final shortage = product.reorderLevel - product.quantity;
      final suggestedOrder = shortage + (product.reorderLevel * 2);

      recommendations.add({
        'productId': product.id,
        'sku': product.sku,
        'name': product.name,
        'currentStock': product.quantity,
        'reorderLevel': product.reorderLevel,
        'shortage': shortage,
        'suggestedOrderQuantity': suggestedOrder,
        'estimatedCost': product.price * suggestedOrder,
        'priority': shortage > product.reorderLevel ? 'high' : 'medium',
      });
    }

    // Sort by priority
    recommendations.sort((a, b) {
      final priorityMap = {'high': 0, 'medium': 1, 'low': 2};
      return (priorityMap[a['priority']] ?? 99).compareTo(
        priorityMap[b['priority']] ?? 99,
      );
    });

    return recommendations;
  }

  /// Get inventory summary report
  Future<Map<String, dynamic>> getInventorySummaryReport() async {
    final stats = await _dbService.getWarehouseStats();
    final categoryStats = await getCategoryStatistics();
    final healthMetrics = await getStockHealthMetrics();
    final topProducts = await getTopProductsByValue(limit: 5);

    return {
      'reportDate': DateTime.now().toIso8601String(),
      'totalProducts': stats['totalProducts'],
      'totalUnits': stats['totalQuantity'],
      'totalValue': stats['totalValue'],
      'lowStockCount': stats['lowStockCount'],
      'categories': categoryStats,
      'healthMetrics': healthMetrics,
      'topProductsByValue': topProducts,
    };
  }

  /// Get warehouse efficiency metrics
  Future<Map<String, dynamic>> getEfficiencyMetrics() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentTransactions = await _dbService.getAllTransactions(
      startDate: thirtyDaysAgo,
      endDate: now,
    );

    int inboundCount = 0;
    int outboundCount = 0;
    int totalInboundQty = 0;
    int totalOutboundQty = 0;

    for (final transaction in recentTransactions) {
      if (transaction.transactionType == 'inbound') {
        inboundCount++;
        totalInboundQty += transaction.quantity;
      } else if (transaction.transactionType == 'outbound') {
        outboundCount++;
        totalOutboundQty += transaction.quantity;
      }
    }

    return {
      'period': '30 days',
      'inboundTransactions': inboundCount,
      'outboundTransactions': outboundCount,
      'totalTransactions': inboundCount + outboundCount,
      'totalInboundQty': totalInboundQty,
      'totalOutboundQty': totalOutboundQty,
      'avgTransactionSize': recentTransactions.isEmpty
          ? 0
          : recentTransactions.map((t) => t.quantity).reduce((a, b) => a + b) /
                recentTransactions.length,
    };
  }
}
