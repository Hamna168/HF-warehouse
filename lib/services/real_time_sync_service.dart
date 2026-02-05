import 'dart:async';
import '../models/models.dart';
import '../services/database_service.dart';

/// Real-Time Inventory Sync Service
/// Solves: GHOST STOCK TRAP
///
/// Problem: Manual systems have data lag. By the time you record a sale,
/// inventory could be wrong. Customer sees "10 units" but shelf is empty.
///
/// Solution: Timestamp-based conflict resolution + automatic sync
class RealTimeSyncService {
  final DatabaseService _dbService = DatabaseService();
  late StreamController<InventoryAlert> _alertStream;
  Timer? _syncTimer;

  // Track last known state for conflict detection
  Map<int, InventorySnapshot> _lastKnownState = {};

  RealTimeSyncService() {
    _alertStream = StreamController<InventoryAlert>.broadcast();
    _startAutoSync();
  }

  /// Stream of critical inventory alerts
  Stream<InventoryAlert> get alerts => _alertStream.stream;

  /// Start continuous sync every 5 seconds (not minutes)
  void _startAutoSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _syncAllInventory();
    });
  }

  /// Sync all inventory with conflict detection
  Future<void> _syncAllInventory() async {
    try {
      final products = await _dbService.getAllProducts();

      for (final product in products) {
        if (product.status == 'active') {
          await _checkAndResolveConflicts(product);
          await _checkCriticalThresholds(product);
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  /// Check for quantity conflicts and resolve with timestamps
  Future<void> _checkAndResolveConflicts(Product product) async {
    final lastKnown = _lastKnownState[product.id];

    if (lastKnown == null) {
      // First sync - record initial state
      _lastKnownState[product.id!] = InventorySnapshot(
        productId: product.id!,
        quantity: product.quantity,
        lastUpdated: product.updatedAt,
        syncedAt: DateTime.now(),
      );
      return;
    }

    // Check if quantity changed unexpectedly
    if (product.quantity != lastKnown.quantity) {
      final timeDiff = DateTime.now().difference(lastKnown.syncedAt);

      // CRITICAL: If quantity dropped unexpectedly in last 5 seconds
      if (product.quantity < lastKnown.quantity && timeDiff.inSeconds <= 5) {
        final shortage = lastKnown.quantity - product.quantity;

        // Alert immediately - possible ghost stock issue
        _alertStream.add(
          InventoryAlert(
            type: AlertType.criticalQuantityDrop,
            productId: product.id!,
            productName: product.name,
            severity: AlertSeverity.critical,
            message:
                'IMMEDIATE ALERT: ${product.name} quantity dropped by $shortage units in the last 5 seconds! '
                'Check physical stock immediately - data may be out of sync.',
            timestamp: DateTime.now(),
            expectedQuantity: lastKnown.quantity,
            actualQuantity: product.quantity,
            suggestedAction:
                'Check physical shelf location immediately and verify stock.',
          ),
        );
      }

      // Update snapshot
      _lastKnownState[product.id!] = InventorySnapshot(
        productId: product.id!,
        quantity: product.quantity,
        lastUpdated: product.updatedAt,
        syncedAt: DateTime.now(),
      );
    }
  }

  /// Check critical thresholds (SOLVES STOCKOUTS)
  Future<void> _checkCriticalThresholds(Product product) async {
    // Critical low: Less than 30% of reorder level
    if (product.quantity < (product.reorderLevel * 0.3).toInt()) {
      _alertStream.add(
        InventoryAlert(
          type: AlertType.criticalLowStock,
          productId: product.id!,
          productName: product.name,
          severity: AlertSeverity.critical,
          message:
              '🚨 CRITICAL: ${product.name} at ${product.quantity} units! '
              'This is ${product.reorderLevel - product.quantity} units below reorder level.',
          timestamp: DateTime.now(),
          suggestedAction: 'URGENT: Order immediately to avoid stockouts.',
        ),
      );
    }
    // Warning low: Between 30-70% of reorder level
    else if (product.quantity < product.reorderLevel) {
      _alertStream.add(
        InventoryAlert(
          type: AlertType.lowStock,
          productId: product.id!,
          productName: product.name,
          severity: AlertSeverity.warning,
          message:
              '⚠️ WARNING: ${product.name} approaching reorder level. '
              'Current: ${product.quantity} | Reorder Level: ${product.reorderLevel}',
          timestamp: DateTime.now(),
          suggestedAction: 'Plan to reorder soon.',
        ),
      );
    }
  }

  /// Record a transaction with immediate verification
  /// SOLVES: Data lag and ghost stock
  Future<bool> recordTransactionWithVerification(
    InventoryTransaction transaction,
    int? expectedQuantityBefore,
  ) async {
    try {
      // Step 1: Get current actual quantity
      final product = await _dbService.getProduct(transaction.productId);
      if (product == null) return false;

      // Step 2: Verify expected quantity matches reality (conflict detection)
      if (expectedQuantityBefore != null &&
          product.quantity != expectedQuantityBefore) {
        // CONFLICT DETECTED: Quantity doesn't match what UI thinks it should be
        _alertStream.add(
          InventoryAlert(
            type: AlertType.dataConflict,
            productId: product.id!,
            productName: product.name,
            severity: AlertSeverity.warning,
            message:
                'DATA CONFLICT: ${product.name} quantity mismatch!\n'
                'Expected: $expectedQuantityBefore\n'
                'Actual: ${product.quantity}\n'
                'Another user may have made a transaction. Refresh and try again.',
            timestamp: DateTime.now(),
            expectedQuantity: expectedQuantityBefore,
            actualQuantity: product.quantity,
            suggestedAction:
                'Refresh inventory view and confirm quantities before proceeding.',
          ),
        );
        return false;
      }

      // Step 3: Record transaction with timestamp
      await _dbService.addTransaction(transaction);

      // Step 4: Immediately sync to catch conflicts early
      await _syncAllInventory();

      return true;
    } catch (e) {
      print('Transaction verification error: $e');
      return false;
    }
  }

  /// Get inventory accuracy score (0-100%)
  /// Lower = more data lag
  Future<double> getInventoryAccuracyScore() async {
    try {
      final products = await _dbService.getAllProducts();
      if (products.isEmpty) return 100.0;

      int accurateCount = 0;

      for (final product in products) {
        // Check if last update was within last hour (good accuracy)
        final timeSinceUpdate = DateTime.now()
            .difference(product.updatedAt)
            .inMinutes;
        if (timeSinceUpdate <= 60) {
          accurateCount++;
        }
      }

      return (accurateCount / products.length) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get data freshness report
  Future<DataFreshnessReport> getFreshnessReport() async {
    final products = await _dbService.getAllProducts();
    final now = DateTime.now();

    final staleProducts = <Product>[]; // Not updated in 1+ hour
    final freshProducts = <Product>[]; // Updated in last 15 min
    final mediumProducts = <Product>[]; // Updated 15min-1hour ago

    for (final product in products) {
      if (product.status == 'active') {
        final minutesSinceUpdate = now.difference(product.updatedAt).inMinutes;

        if (minutesSinceUpdate <= 15) {
          freshProducts.add(product);
        } else if (minutesSinceUpdate <= 60) {
          mediumProducts.add(product);
        } else {
          staleProducts.add(product);
        }
      }
    }

    return DataFreshnessReport(
      freshData: freshProducts.length,
      mediumData: mediumProducts.length,
      staleData: staleProducts.length,
      accuracyPercentage: (freshProducts.length / products.length) * 100,
      lastCompleteSync: now,
      stalestProduct: staleProducts.isNotEmpty ? staleProducts.first : null,
    );
  }

  void dispose() {
    _syncTimer?.cancel();
    _alertStream.close();
  }
}

// Models for real-time sync
class InventorySnapshot {
  final int productId;
  final int quantity;
  final DateTime lastUpdated;
  final DateTime syncedAt;

  InventorySnapshot({
    required this.productId,
    required this.quantity,
    required this.lastUpdated,
    required this.syncedAt,
  });
}

enum AlertType {
  criticalQuantityDrop, // Ghost stock detected
  criticalLowStock, // Stockout imminent
  lowStock, // Reorder soon
  dataConflict, // Sync conflict detected
  slowSync, // Sync taking too long
}

enum AlertSeverity {
  critical, // Immediate action needed
  warning, // Action needed soon
  info, // FYI
}

class InventoryAlert {
  final AlertType type;
  final int productId;
  final String productName;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final int? expectedQuantity;
  final int? actualQuantity;
  final String suggestedAction;

  InventoryAlert({
    required this.type,
    required this.productId,
    required this.productName,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.expectedQuantity,
    this.actualQuantity,
    required this.suggestedAction,
  });
}

class DataFreshnessReport {
  final int freshData; // Updated < 15 min ago
  final int mediumData; // Updated 15min-1hour ago
  final int staleData; // Updated > 1 hour ago
  final double accuracyPercentage;
  final DateTime lastCompleteSync;
  final Product? stalestProduct;

  DataFreshnessReport({
    required this.freshData,
    required this.mediumData,
    required this.staleData,
    required this.accuracyPercentage,
    required this.lastCompleteSync,
    this.stalestProduct,
  });

  String get healthStatus {
    if (accuracyPercentage >= 80) return '✅ HEALTHY';
    if (accuracyPercentage >= 50) return '⚠️ WARNING';
    return '🚨 CRITICAL';
  }
}
