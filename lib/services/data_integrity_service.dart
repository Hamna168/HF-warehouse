import '../models/models.dart';

/// Data Integrity & Validation Service
/// Solves: HUMAN ERROR & DATA INTEGRITY ISSUES
///
/// Problems:
/// 1. Fat-finger mistakes (100 vs 10)
/// 2. Double-entry burden (paper → computer = 2x errors)
/// 3. Invalid data states
///
/// Solutions:
/// 1. Validation rules with clear error messages
/// 2. Single-entry system (one point of truth)
/// 3. Automatic anomaly detection
class DataIntegrityService {
  // Validation Rules
  static const int MAX_REALISTIC_TRANSACTION =
      10000; // No one moves 50k units at once
  static const int MAX_PRICE = 100000; // $100k per unit (luxury items)
  static const int MAX_SKU_LENGTH = 50;
  static const int MAX_QUANTITY = 1000000;

  /// Comprehensive product validation
  /// Returns (isValid, errorMessage)
  static (bool, String) validateProductCreation(Product product) {
    // SKU validation
    if (product.sku.isEmpty) {
      return (false, 'SKU cannot be empty');
    }
    if (product.sku.length > MAX_SKU_LENGTH) {
      return (false, 'SKU too long (max $MAX_SKU_LENGTH chars)');
    }
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(product.sku)) {
      return (
        false,
        'SKU must contain only uppercase letters, numbers, and hyphens',
      );
    }

    // Name validation
    if (product.name.isEmpty) {
      return (false, 'Product name cannot be empty');
    }
    if (product.name.length > 255) {
      return (false, 'Product name too long (max 255 chars)');
    }

    // Price validation - CATCHES FAT-FINGER ERRORS
    if (product.price <= 0) {
      return (false, 'Price must be greater than 0');
    }
    if (product.price > MAX_PRICE) {
      return (
        false,
        'Price suspiciously high (\$$MAX_PRICE+). Check for typo?',
      );
    }

    // Quantity validation
    if (product.quantity < 0) {
      return (false, 'Quantity cannot be negative');
    }
    if (product.quantity > MAX_QUANTITY) {
      return (false, 'Quantity suspiciously high ($MAX_QUANTITY+)');
    }

    // Reorder level validation
    if (product.reorderLevel < 0) {
      return (false, 'Reorder level cannot be negative');
    }
    if (product.reorderLevel > product.quantity) {
      return (
        false,
        'Reorder level should not exceed current quantity (unless you want to order now)',
      );
    }

    // Category validation
    final validCategories = [
      'T-Shirts',
      'Jeans',
      'Shirts',
      'Sweaters',
      'Hoodies',
      'Pants',
      'Jackets',
      'Dresses',
      'Skirts',
      'Accessories',
    ];
    if (!validCategories.contains(product.category)) {
      return (false, 'Invalid category: ${product.category}');
    }

    return (true, '');
  }

  /// Validate transaction - SOLVES DOUBLE-ENTRY PROBLEMS
  /// Single point of truth: One transaction record = one physical movement
  static (bool, String) validateTransaction(
    InventoryTransaction transaction,
    int currentQuantity,
  ) {
    // Quantity validation
    if (transaction.quantity <= 0) {
      return (false, 'Transaction quantity must be positive');
    }
    if (transaction.quantity > MAX_REALISTIC_TRANSACTION) {
      return (
        false,
        'Transaction quantity suspiciously high ($MAX_REALISTIC_TRANSACTION+). Check for typo?',
      );
    }

    // Type validation
    const validTypes = ['inbound', 'outbound', 'adjustment'];
    if (!validTypes.contains(transaction.transactionType)) {
      return (false, 'Invalid transaction type');
    }

    // Reason validation
    const validReasons = [
      'purchase',
      'sale',
      'damage',
      'theft',
      'correction',
      'return',
      'transfer',
    ];
    if (!validReasons.contains(transaction.reason)) {
      return (false, 'Invalid transaction reason');
    }

    // Outbound validation - PREVENTS OVERSELLING
    if (transaction.transactionType == 'outbound') {
      if (transaction.quantity > currentQuantity) {
        return (
          false,
          'Cannot sell \$${transaction.quantity} units. Only $currentQuantity available in stock. '
              'This prevents the Ghost Stock problem.',
        );
      }
    }

    // User validation
    if (transaction.performedBy.isEmpty) {
      return (false, 'Transaction must be assigned to a user (audit trail)');
    }

    return (true, '');
  }

  /// Detect anomalies - CATCHES ERRORS AFTER THEY HAPPEN
  /// Analyzes patterns to find suspicious data
  static AnomalyReport detectAnomalies(
    Product product,
    List<InventoryTransaction> recentTransactions,
  ) {
    final issues = <String>[];
    final warnings = <String>[];

    // Check 1: Impossible quantity drops
    if (recentTransactions.isNotEmpty) {
      int totalOutbound = 0;
      for (final tx in recentTransactions) {
        if (tx.transactionType == 'outbound') {
          totalOutbound += tx.quantity;
        }
      }

      // If more units were sold in the last day than exist, something's wrong
      if (totalOutbound > product.quantity && recentTransactions.length > 1) {
        issues.add(
          'CRITICAL: More units sold (${totalOutbound}) than in inventory (${product.quantity})! '
          'Check for duplicate transactions or data entry errors.',
        );
      }
    }

    // Check 2: Price inconsistencies
    if (product.price == 0) {
      issues.add('Price is \$0. Is this a free item or data entry error?');
    }
    if (product.price % 1 != 0) {
      // Fractional cents (weird but not impossible)
      warnings.add('Price has unusual decimal places: \$${product.price}');
    }

    // Check 3: Dead stock warning
    if (product.quantity > product.reorderLevel * 5) {
      warnings.add(
        'DEAD STOCK WARNING: ${product.name} has ${product.quantity} units '
        '(${(product.quantity / product.reorderLevel).toInt()}x reorder level). '
        'Is this selling? Cash may be tied up.',
      );
    }

    // Check 4: Never-sold warning
    if (recentTransactions.isEmpty &&
        product.createdAt.difference(DateTime.now()).inDays > 30) {
      warnings.add(
        '${product.name} has no sales in the last 30 days. '
        'Consider discontinuing if demand is gone.',
      );
    }

    return AnomalyReport(
      productId: product.id!,
      productName: product.name,
      criticalIssues: issues,
      warnings: warnings,
      hasIssues: issues.isNotEmpty,
      score: 100 - (issues.length * 25) - (warnings.length * 10),
    );
  }

  /// Calculate potential financial impact of data errors
  static double calculatePotentialLoss(
    List<Product> products,
    double avgErrorRate, // percentage (5 = 5% error rate)
  ) {
    double totalValue = 0;
    for (final product in products) {
      totalValue += (product.price * product.quantity);
    }

    return totalValue * (avgErrorRate / 100);
  }

  /// Validate complete inventory state
  static InventoryHealthReport validateCompleteInventory(
    List<Product> products,
  ) {
    int validProducts = 0;
    int suspiciousProducts = 0;
    int problematicProducts = 0;
    double totalValue = 0;
    int totalUnits = 0;

    for (final product in products) {
      if (product.status == 'active') {
        final (isValid, _) = validateProductCreation(product);

        if (isValid) {
          validProducts++;
        } else {
          problematicProducts++;
        }

        // Check for suspicious patterns
        if (product.price == 0 || product.reorderLevel > product.quantity * 2) {
          suspiciousProducts++;
        }

        totalValue += (product.price * product.quantity);
        totalUnits += product.quantity;
      }
    }

    return InventoryHealthReport(
      totalProducts: products.length,
      validProducts: validProducts,
      suspiciousProducts: suspiciousProducts,
      problematicProducts: problematicProducts,
      totalInventoryValue: totalValue,
      totalUnits: totalUnits,
      healthScore: (validProducts / products.length) * 100,
      lastValidated: DateTime.now(),
    );
  }
}

// Models
class AnomalyReport {
  final int productId;
  final String productName;
  final List<String> criticalIssues;
  final List<String> warnings;
  final bool hasIssues;
  final int score; // 0-100, higher = healthier

  AnomalyReport({
    required this.productId,
    required this.productName,
    required this.criticalIssues,
    required this.warnings,
    required this.hasIssues,
    required this.score,
  });

  String get status {
    if (score >= 80) return '✅ HEALTHY';
    if (score >= 50) return '⚠️ WARNING';
    return '🚨 CRITICAL';
  }
}

class InventoryHealthReport {
  final int totalProducts;
  final int validProducts;
  final int suspiciousProducts;
  final int problematicProducts;
  final double totalInventoryValue;
  final int totalUnits;
  final double healthScore; // 0-100%
  final DateTime lastValidated;

  InventoryHealthReport({
    required this.totalProducts,
    required this.validProducts,
    required this.suspiciousProducts,
    required this.problematicProducts,
    required this.totalInventoryValue,
    required this.totalUnits,
    required this.healthScore,
    required this.lastValidated,
  });

  String get overallStatus {
    if (healthScore >= 90) return '✅ EXCELLENT';
    if (healthScore >= 75) return '✅ GOOD';
    if (healthScore >= 50) return '⚠️ WARNING';
    return '🚨 CRITICAL';
  }

  double get estimatedDataLoss {
    // Estimate financial impact based on health score
    return totalInventoryValue * ((100 - healthScore) / 100);
  }
}
