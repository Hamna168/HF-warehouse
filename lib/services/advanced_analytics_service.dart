import '../models/models.dart';
import '../services/database_service.dart';

/// Advanced Analytics Service
/// Solves: HIDDEN COSTS & BLIND SPOTS
///
/// Problems:
/// 1. Can't see which items are dead stock (cash trapped)
/// 2. Can't predict stockouts before they happen
/// 3. No visibility into seasonal trends
/// 4. Can't optimize warehouse space
///
/// Solutions:
/// 1. Dead stock vs fast mover analysis
/// 2. Predictive stockout alerts
/// 3. Trend analysis & forecasting
/// 4. Space optimization recommendations
class AdvancedAnalyticsService {
  final DatabaseService _dbService = DatabaseService();

  /// SOLVES HIDDEN COSTS
  /// Analyze dead stock vs fast movers with financial impact
  Future<DeadStockAnalysis> analyzeDeadStock({int daysInactive = 30}) async {
    final products = await _dbService.getAllProducts();
    final now = DateTime.now();

    final deadStock = <Product>[];
    final fastMovers = <Product>[];
    final slowMovers = <Product>[];

    for (final product in products) {
      if (product.status != 'active') continue;

      final transactions = await _dbService.getTransactionsByProduct(
        product.id!,
      );

      // Filter recent transactions
      final recentSales = transactions
          .where(
            (t) =>
                t.transactionType == 'outbound' &&
                t.reason == 'sale' &&
                now.difference(t.timestamp).inDays <= daysInactive,
          )
          .toList();

      if (recentSales.isEmpty) {
        // NO SALES = DEAD STOCK
        deadStock.add(product);
      } else {
        // Calculate velocity (units per day)
        final totalUnitsSold = recentSales.fold<int>(
          0,
          (sum, tx) => sum + tx.quantity,
        );
        final velocity = totalUnitsSold / daysInactive;

        if (velocity > 1.0) {
          // Fast mover: >1 unit/day on average
          fastMovers.add(product);
        } else {
          slowMovers.add(product);
        }
      }
    }

    // Calculate financial impact
    double deadStockValue = 0;
    for (final product in deadStock) {
      deadStockValue += (product.price * product.quantity);
    }

    double slowMovingValue = 0;
    for (final product in slowMovers) {
      slowMovingValue += (product.price * product.quantity);
    }

    return DeadStockAnalysis(
      deadStockItems: deadStock,
      fastMovers: fastMovers,
      slowMovers: slowMovers,
      deadStockCashTrapped: deadStockValue,
      slowMovingCashTrapped: slowMovingValue,
      totalCashAtRisk: deadStockValue + slowMovingValue,
      recommendations: _generateDeadStockRecommendations(
        deadStock,
        slowMovers,
        deadStockValue + slowMovingValue,
      ),
    );
  }

  List<String> _generateDeadStockRecommendations(
    List<Product> deadStock,
    List<Product> slowMovers,
    double totalValue,
  ) {
    final recommendations = <String>[];

    // Calculate dead stock value
    double deadStockValue = 0;
    for (final product in deadStock) {
      deadStockValue += (product.price * product.quantity);
    }

    // Calculate slow moving value
    double slowMovingValue = 0;
    for (final product in slowMovers) {
      slowMovingValue += (product.price * product.quantity);
    }

    if (deadStock.isNotEmpty) {
      recommendations.add(
        '🚨 CRITICAL: ${deadStock.length} items with NO sales in 30 days. '
        '\$${deadStockValue.toStringAsFixed(2)} cash trapped. '
        'Action: Clear dead stock with discounts or donations.',
      );
    }

    if (slowMovers.isNotEmpty) {
      recommendations.add(
        '⚠️ WARNING: ${slowMovers.length} slow-moving items detected. '
        '\$${slowMovingValue.toStringAsFixed(2)} moving slowly. '
        'Action: Reduce reorder quantities, increase visibility, or discontinue.',
      );
    }

    if (totalValue > 10000) {
      recommendations.add(
        '💰 FINANCIAL IMPACT: \$${totalValue.toStringAsFixed(2)} cash tied up in non-moving inventory. '
        'This could be freed by optimizing your assortment.',
      );
    }

    return recommendations;
  }

  /// SOLVES STOCKOUTS
  /// Predict when items will run out based on consumption patterns
  Future<StockoutPrediction> predictStockouts() async {
    final products = await _dbService.getAllProducts();
    final riskItems = <StockoutRisk>[];

    for (final product in products) {
      if (product.status != 'active' || product.quantity == 0) continue;

      final transactions = await _dbService.getTransactionsByProduct(
        product.id!,
      );

      // Get last 14 days of sales
      final recentSales = transactions
          .where(
            (t) =>
                t.transactionType == 'outbound' &&
                t.reason == 'sale' &&
                DateTime.now().difference(t.timestamp).inDays <= 14,
          )
          .toList();

      if (recentSales.isEmpty) continue;

      // Calculate daily consumption rate
      final totalSold = recentSales.fold<int>(0, (sum, t) => sum + t.quantity);
      final dailyRate = totalSold / 14.0;

      if (dailyRate > 0) {
        // Predict days until stockout
        final daysUntilStockout = product.quantity / dailyRate;

        // Flag as risk if less than 7 days until stockout
        if (daysUntilStockout < 7) {
          riskItems.add(
            StockoutRisk(
              productId: product.id!,
              productName: product.name,
              sku: product.sku,
              currentQuantity: product.quantity,
              dailyConsumption: dailyRate,
              daysUntilStockout: daysUntilStockout,
              reorderLevel: product.reorderLevel,
              severity: daysUntilStockout < 3
                  ? RiskSeverity.critical
                  : RiskSeverity.warning,
            ),
          );
        }
      }
    }

    // Sort by urgency
    riskItems.sort(
      (a, b) => a.daysUntilStockout.compareTo(b.daysUntilStockout),
    );

    return StockoutPrediction(
      itemsAtRisk: riskItems,
      hasImmediateRisk: riskItems.any((r) => r.daysUntilStockout < 3),
      estimatedRevenueLoss: _estimateRevenueLoss(riskItems),
      recommendedActions: _generateStockoutActions(riskItems),
    );
  }

  double _estimateRevenueLoss(List<StockoutRisk> risks) {
    double loss = 0;
    for (final risk in risks) {
      // Assume 30% of customers go elsewhere if out of stock
      loss +=
          (risk.dailyConsumption *
          30 *
          0.3); // Lost customers × days OOS × 30% abandonment
    }
    return loss;
  }

  List<String> _generateStockoutActions(List<StockoutRisk> risks) {
    final actions = <String>[];

    final criticalRisks = risks.where((r) => r.daysUntilStockout < 3).toList();
    final warningRisks = risks
        .where((r) => r.daysUntilStockout >= 3 && r.daysUntilStockout < 7)
        .toList();

    if (criticalRisks.isNotEmpty) {
      actions.add(
        '🚨 IMMEDIATE: ${criticalRisks.length} items will stockout in <3 days! '
        'Contact suppliers NOW.',
      );
    }

    if (warningRisks.isNotEmpty) {
      actions.add(
        '⚠️ URGENT: ${warningRisks.length} items will stockout in 3-7 days. '
        'Reorder immediately.',
      );
    }

    actions.add(
      'Set automated reorder notifications at 40% of reorder level to prevent this.',
    );

    return actions;
  }

  /// SOLVES SCALE PARALYSIS
  /// Space optimization recommendations
  Future<SpaceOptimizationReport> optimizeWarehouseSpace() async {
    final products = await _dbService.getAllProducts();
    final byCategory = <String, List<Product>>{};

    // Group by category
    for (final product in products) {
      if (product.status == 'active') {
        byCategory.putIfAbsent(product.category, () => []).add(product);
      }
    }

    double totalValue = 0;
    int totalUnits = 0;
    final spaceAllocations = <CategoryAllocation>[];

    for (final entry in byCategory.entries) {
      final category = entry.key;
      final categoryProducts = entry.value;

      double categoryValue = 0;
      int categoryUnits = 0;

      for (final product in categoryProducts) {
        categoryValue += (product.price * product.quantity);
        categoryUnits += product.quantity;
      }

      totalValue += categoryValue;
      totalUnits += categoryUnits;

      spaceAllocations.add(
        CategoryAllocation(
          category: category,
          items: categoryProducts.length,
          units: categoryUnits,
          value: categoryValue,
          percentOfInventory: 0, // Will calculate below
        ),
      );
    }

    // Calculate percentages
    for (final allocation in spaceAllocations) {
      allocation.percentOfInventory = (allocation.value / totalValue) * 100;
    }

    // Sort by value (most valuable categories get prime shelf space)
    spaceAllocations.sort((a, b) => b.value.compareTo(a.value));

    return SpaceOptimizationReport(
      categoryAllocations: spaceAllocations,
      totalInventoryValue: totalValue,
      totalUnits: totalUnits,
      recommendations: _generateSpaceRecommendations(spaceAllocations),
    );
  }

  List<String> _generateSpaceRecommendations(
    List<CategoryAllocation> allocations,
  ) {
    final recommendations = <String>[];

    // Recommend allocating shelf space based on value, not just items
    recommendations.add('📦 SPACE ALLOCATION (by value, not just volume):');
    for (final allocation in allocations) {
      final shelves = (allocation.percentOfInventory / 20)
          .ceil(); // ~20% per standard shelf unit
      recommendations.add(
        '  ${allocation.category}: ${shelves} shelf units (${allocation.percentOfInventory.toStringAsFixed(1)}% of value)',
      );
    }

    recommendations.add(
      '\n💡 High-value items near checkout. Dead stock in back or consider discontinuing.',
    );

    return recommendations;
  }

  /// Get comprehensive health dashboard
  Future<InventoryHealthDashboard> getHealthDashboard() async {
    final deadStock = await analyzeDeadStock();
    final stockouts = await predictStockouts();
    final space = await optimizeWarehouseSpace();

    return InventoryHealthDashboard(
      deadStockAnalysis: deadStock,
      stockoutPredictions: stockouts,
      spaceOptimization: space,
      overallHealthScore: _calculateHealthScore(deadStock, stockouts),
      generatedAt: DateTime.now(),
    );
  }

  double _calculateHealthScore(
    DeadStockAnalysis dead,
    StockoutPrediction stockouts,
  ) {
    double score = 100.0;

    // Deduct for dead stock
    score -= (dead.deadStockItems.length * 5);

    // Deduct for stockout risks
    score -= (stockouts.itemsAtRisk.length * 3);

    // Deduct for critical stockout risks
    final criticalRisks = stockouts.itemsAtRisk
        .where((r) => r.daysUntilStockout < 3)
        .length;
    score -= (criticalRisks * 10);

    return score.clamp(0, 100);
  }
}

// Models
class DeadStockAnalysis {
  final List<Product> deadStockItems;
  final List<Product> fastMovers;
  final List<Product> slowMovers;
  final double deadStockCashTrapped;
  final double slowMovingCashTrapped;
  final double totalCashAtRisk;
  final List<String> recommendations;

  DeadStockAnalysis({
    required this.deadStockItems,
    required this.fastMovers,
    required this.slowMovers,
    required this.deadStockCashTrapped,
    required this.slowMovingCashTrapped,
    required this.totalCashAtRisk,
    required this.recommendations,
  });
}

class StockoutPrediction {
  final List<StockoutRisk> itemsAtRisk;
  final bool hasImmediateRisk;
  final double estimatedRevenueLoss;
  final List<String> recommendedActions;

  StockoutPrediction({
    required this.itemsAtRisk,
    required this.hasImmediateRisk,
    required this.estimatedRevenueLoss,
    required this.recommendedActions,
  });
}

enum RiskSeverity {
  critical, // <3 days
  warning, // 3-7 days
  low, // >7 days
}

class StockoutRisk {
  final int productId;
  final String productName;
  final String sku;
  final int currentQuantity;
  final double dailyConsumption;
  final double daysUntilStockout;
  final int reorderLevel;
  final RiskSeverity severity;

  StockoutRisk({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.currentQuantity,
    required this.dailyConsumption,
    required this.daysUntilStockout,
    required this.reorderLevel,
    required this.severity,
  });
}

class CategoryAllocation {
  final String category;
  final int items;
  final int units;
  final double value;
  double percentOfInventory;

  CategoryAllocation({
    required this.category,
    required this.items,
    required this.units,
    required this.value,
    required this.percentOfInventory,
  });
}

class SpaceOptimizationReport {
  final List<CategoryAllocation> categoryAllocations;
  final double totalInventoryValue;
  final int totalUnits;
  final List<String> recommendations;

  SpaceOptimizationReport({
    required this.categoryAllocations,
    required this.totalInventoryValue,
    required this.totalUnits,
    required this.recommendations,
  });
}

class InventoryHealthDashboard {
  final DeadStockAnalysis deadStockAnalysis;
  final StockoutPrediction stockoutPredictions;
  final SpaceOptimizationReport spaceOptimization;
  final double overallHealthScore;
  final DateTime generatedAt;

  InventoryHealthDashboard({
    required this.deadStockAnalysis,
    required this.stockoutPredictions,
    required this.spaceOptimization,
    required this.overallHealthScore,
    required this.generatedAt,
  });

  String get status {
    if (overallHealthScore >= 80) return '✅ HEALTHY';
    if (overallHealthScore >= 60) return '⚠️ WARNING';
    return '🚨 CRITICAL';
  }
}
