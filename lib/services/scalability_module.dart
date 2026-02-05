import '../models/models.dart';
import '../services/database_service.dart';

/// Scalability Module
/// Solves: SCALE PARALYSIS
///
/// Problem: Manual systems hit a ceiling. One person can manage 50 items,
/// but 500 items across 2 locations = impossible without 24/7 labor.
///
/// Solution: Multi-location support + automated workflows + delegation
class ScalabilityModule {
  final DatabaseService _dbService = DatabaseService();

  // Warehouse locations
  static const List<String> WAREHOUSE_LOCATIONS = [
    'Main Storage',
    'Section A',
    'Section B',
    'Section C',
    'Shipping Area',
    'Returns',
  ];

  /// Multi-Location Inventory Summary
  /// Shows total inventory across all locations at a glance
  Future<MultiLocationSummary> getMultiLocationInventory() async {
    final products = await _dbService.getAllProducts();
    final movements = <StockMovement>[];

    // Get all pending movements
    movements.addAll(await _dbService.getPendingMovements());

    // Build location view
    final locationInventory = <String, LocationStock>{};

    for (final location in WAREHOUSE_LOCATIONS) {
      locationInventory[location] = LocationStock(
        location: location,
        items: 0,
        units: 0,
        value: 0,
      );
    }

    // Distribute inventory across locations (simplified model)
    // In production, would track exact location for each unit
    for (final product in products) {
      if (product.status == 'active') {
        // Distribute based on pending movements
        final locationMovements = movements
            .where((m) => m.productId == product.id)
            .toList();

        if (locationMovements.isEmpty) {
          // Default to main storage
          locationInventory['Main Storage']!.items++;
          locationInventory['Main Storage']!.units += product.quantity;
          locationInventory['Main Storage']!.value +=
              (product.price * product.quantity);
        } else {
          // Distribute based on movements
          for (final movement in locationMovements) {
            locationInventory[movement.toLocation]!.items++;
            locationInventory[movement.toLocation]!.units +=
                movement.quantityMoved;
            locationInventory[movement.toLocation]!.value +=
                (product.price * movement.quantityMoved);
          }
        }
      }
    }

    return MultiLocationSummary(
      locations: locationInventory,
      totalItems: products.where((p) => p.status == 'active').length,
      totalUnits: products.fold<int>(
        0,
        (sum, p) => p.status == 'active' ? sum + p.quantity : sum,
      ),
      totalValue: products.fold<double>(
        0,
        (sum, p) => p.status == 'active' ? sum + (p.price * p.quantity) : sum,
      ),
      lastUpdated: DateTime.now(),
    );
  }

  /// Automated Reorder Workflow
  /// SOLVES: Manager doesn't have to manually check reorder levels constantly
  Future<AutomatedReorderPlan> generateAutomatedReorders() async {
    final lowStockProducts = await _dbService.getLowStockProducts();
    final reorders = <ReorderTask>[];

    for (final product in lowStockProducts) {
      final shortage = product.reorderLevel - product.quantity;
      final suggestedQuantity = shortage + (product.reorderLevel * 2);

      reorders.add(
        ReorderTask(
          productId: product.id!,
          sku: product.sku,
          productName: product.name,
          currentStock: product.quantity,
          reorderLevel: product.reorderLevel,
          suggestedOrderQuantity: suggestedQuantity,
          estimatedCost: product.price * suggestedQuantity,
          priority: shortage > product.reorderLevel
              ? OrderPriority.urgent
              : OrderPriority.normal,
          autoOrderEligible:
              product.price < 1000, // Only auto-order cheap items
        ),
      );
    }

    // Sort by urgency
    reorders.sort((a, b) {
      if (a.priority != b.priority) {
        return a.priority.index.compareTo(b.priority.index);
      }
      return b.estimatedCost.compareTo(a.estimatedCost);
    });

    return AutomatedReorderPlan(
      reorderTasks: reorders,
      totalReorderValue: reorders.fold<double>(
        0,
        (sum, r) => sum + r.estimatedCost,
      ),
      urgentItems: reorders
          .where((r) => r.priority == OrderPriority.urgent)
          .length,
      automationSuggestion: _generateAutomationSuggestion(reorders),
    );
  }

  /// Task Delegation System
  /// SOLVES: Manager can delegate inventory work to multiple staff
  Future<DelegationPlan> generateDelegationPlan(int staffCount) async {
    if (staffCount <= 0) {
      return DelegationPlan(tasks: [], staffAssignments: {});
    }

    // Get all work items
    final products = await _dbService.getAllProducts();
    final movements = await _dbService.getPendingMovements();
    final stats = await _dbService.getWarehouseStats();

    // Create task list
    final allTasks = <DelegatedTask>[];

    // Task 1: Cycle counts (physical inventory checks)
    final cycleCountItems = (products.length / staffCount).ceil();
    for (int i = 0; i < staffCount; i++) {
      allTasks.add(
        DelegatedTask(
          id: 'cycle-count-$i',
          type: TaskType.cycleCount,
          description: 'Physical inventory count for assigned items',
          priority: TaskPriority.high,
          estimatedMinutes: cycleCountItems * 2, // 2 min per item
          assignedTo: 'Staff Member ${i + 1}',
          dueDate: DateTime.now().add(const Duration(days: 1)),
        ),
      );
    }

    // Task 2: Process stock movements
    final movementsPerStaff = (movements.length / staffCount).ceil();
    for (int i = 0; i < staffCount; i++) {
      if (movements.isNotEmpty) {
        allTasks.add(
          DelegatedTask(
            id: 'movements-$i',
            type: TaskType.processMovements,
            description: 'Process pending stock transfers',
            priority: TaskPriority.high,
            estimatedMinutes: movementsPerStaff * 5, // 5 min per movement
            assignedTo: 'Staff Member ${i + 1}',
            dueDate: DateTime.now(),
          ),
        );
      }
    }

    // Task 3: Data quality checks
    allTasks.add(
      DelegatedTask(
        id: 'quality-check',
        type: TaskType.dataQualityCheck,
        description: 'Verify inventory accuracy and flag discrepancies',
        priority: TaskPriority.medium,
        estimatedMinutes: 30,
        assignedTo: 'Senior Staff',
        dueDate: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    // Task 4: Low stock review
    allTasks.add(
      DelegatedTask(
        id: 'low-stock-review',
        type: TaskType.lowStockReview,
        description: 'Review low stock items and determine reorder strategy',
        priority: TaskPriority.medium,
        estimatedMinutes: 45,
        assignedTo: 'Manager',
        dueDate: DateTime.now().add(const Duration(days: 2)),
      ),
    );

    return DelegationPlan(
      tasks: allTasks,
      staffAssignments: _distributeWorkload(allTasks, staffCount),
    );
  }

  /// Scalability Report
  /// Shows if current setup can scale to more items/locations
  Future<ScalabilityReport> assessScalability() async {
    final products = await _dbService.getAllProducts();
    final stats = await _dbService.getWarehouseStats();

    int totalItems = products.length;
    int totalUnits = stats['totalQuantity'] as int;
    int locations = WAREHOUSE_LOCATIONS.length;

    // Calculate complexity score
    int complexityScore = 0;
    complexityScore += (totalItems ~/ 50); // +1 point per 50 items
    complexityScore += (locations * 10); // +10 points per location

    // Estimate required staff
    double estimatedStaffNeeded = (totalItems / 200)
        .ceil()
        .toDouble(); // 1 person per 200 items
    estimatedStaffNeeded += (locations / 2)
        .ceil()
        .toDouble(); // 1 person per 2 locations

    // Calculate capacity headroom
    const int itemCapacity = 5000; // System can handle 5000 items
    const int locationCapacity = 20; // System can handle 20 locations

    double itemHeadroom = ((itemCapacity - totalItems) / itemCapacity) * 100;
    double locationHeadroom =
        ((locationCapacity - locations) / locationCapacity) * 100;

    return ScalabilityReport(
      currentItems: totalItems,
      currentUnits: totalUnits,
      currentLocations: locations,
      complexityScore: complexityScore,
      estimatedStaffNeeded: estimatedStaffNeeded.toInt(),
      itemCapacity: itemCapacity,
      locationCapacity: locationCapacity,
      itemHeadroom: itemHeadroom,
      locationHeadroom: locationHeadroom,
      canScale: itemHeadroom > 20 && locationHeadroom > 20,
      recommendations: _generateScalabilityRecommendations(
        totalItems,
        locations,
        estimatedStaffNeeded.toInt(),
      ),
    );
  }

  /// Workflow Automation Status
  /// Track which tasks are automated vs manual
  Future<AutomationStatus> getAutomationStatus() async {
    final products = await _dbService.getAllProducts();
    final stats = await _dbService.getWarehouseStats();

    // Calculate what's automated
    final automatedTasks = {
      'Real-time data sync': true,
      'Low stock alerts': true,
      'Reorder suggestions': true,
      'Anomaly detection': true,
      'Data validation': true,
      'Performance analytics': true,
    };

    final manualTasks = {
      'Physical inventory counting': true,
      'Supplier management': true,
      'Price negotiations': true,
      'Long-term strategy': true,
    };

    double timeSaved = 0;
    // Estimate time saved (in hours per month)
    timeSaved += 40; // Low stock monitoring
    timeSaved += 20; // Data entry validation
    timeSaved += 15; // Reporting
    timeSaved += 10; // Anomaly detection

    return AutomationStatus(
      automatedTasks: automatedTasks,
      manualTasks: manualTasks,
      automationPercentage:
          (automatedTasks.length /
              (automatedTasks.length + manualTasks.length)) *
          100,
      hoursPerMonthSaved: timeSaved,
      laborCostSaved: timeSaved * 25, // Assume $25/hour
      canScaleTo: _estimateScalability(products.length),
    );
  }

  // Helper functions
  String _generateAutomationSuggestion(List<ReorderTask> reorders) {
    final urgentCount = reorders
        .where((r) => r.priority == OrderPriority.urgent)
        .length;
    final totalCost = reorders.fold<double>(
      0,
      (sum, r) => sum + r.estimatedCost,
    );

    if (urgentCount > 5) {
      return '🚨 Set up automated reordering for top-moving items to prevent stockouts.';
    }
    if (totalCost > 50000) {
      return '💰 Consider implementing purchase order workflow to manage supplier relationships.';
    }
    return '✅ Current reorder process is manageable manually.';
  }

  Map<String, List<DelegatedTask>> _distributeWorkload(
    List<DelegatedTask> tasks,
    int staffCount,
  ) {
    final distribution = <String, List<DelegatedTask>>{};

    for (int i = 0; i < staffCount; i++) {
      distribution['Staff ${i + 1}'] = [];
    }

    // Distribute tasks round-robin
    for (int i = 0; i < tasks.length; i++) {
      final staffKey = 'Staff ${(i % staffCount) + 1}';
      distribution[staffKey]!.add(tasks[i]);
    }

    return distribution;
  }

  List<String> _generateScalabilityRecommendations(
    int items,
    int locations,
    int estimatedStaff,
  ) {
    final recommendations = <String>[];

    if (items > 1000) {
      recommendations.add(
        '📈 You have $items items. Recommended: Hire $estimatedStaff staff members.',
      );
    }

    if (locations > 5) {
      recommendations.add(
        '🏢 With $locations locations, consider a centralized inventory management team.',
      );
    }

    recommendations.add(
      '🤖 Use automated reordering and alerts to reduce manager oversight burden.',
    );

    recommendations.add(
      '📊 Export monthly reports and share with suppliers for collaborative forecasting.',
    );

    return recommendations;
  }

  String _estimateScalability(int itemCount) {
    if (itemCount < 100) {
      return 'Excellent - can handle 50x current size';
    } else if (itemCount < 500) {
      return 'Good - can handle 10x current size';
    } else if (itemCount < 1000) {
      return 'Fair - can handle 5x current size';
    } else {
      return 'Limited - consider enterprise system for >5000 items';
    }
  }
}

// Models
class MultiLocationSummary {
  final Map<String, LocationStock> locations;
  final int totalItems;
  final int totalUnits;
  final double totalValue;
  final DateTime lastUpdated;

  MultiLocationSummary({
    required this.locations,
    required this.totalItems,
    required this.totalUnits,
    required this.totalValue,
    required this.lastUpdated,
  });
}

class LocationStock {
  final String location;
  int items;
  int units;
  double value;

  LocationStock({
    required this.location,
    required this.items,
    required this.units,
    required this.value,
  });
}

class ReorderTask {
  final int productId;
  final String sku;
  final String productName;
  final int currentStock;
  final int reorderLevel;
  final int suggestedOrderQuantity;
  final double estimatedCost;
  final OrderPriority priority;
  final bool autoOrderEligible;

  ReorderTask({
    required this.productId,
    required this.sku,
    required this.productName,
    required this.currentStock,
    required this.reorderLevel,
    required this.suggestedOrderQuantity,
    required this.estimatedCost,
    required this.priority,
    required this.autoOrderEligible,
  });
}

enum OrderPriority {
  urgent, // <1 day until stockout
  normal, // 1-7 days until stockout
  planned, // 7+ days
}

class AutomatedReorderPlan {
  final List<ReorderTask> reorderTasks;
  final double totalReorderValue;
  final int urgentItems;
  final String automationSuggestion;

  AutomatedReorderPlan({
    required this.reorderTasks,
    required this.totalReorderValue,
    required this.urgentItems,
    required this.automationSuggestion,
  });
}

enum TaskType { cycleCount, processMovements, dataQualityCheck, lowStockReview }

enum TaskPriority { high, medium, low }

class DelegatedTask {
  final String id;
  final TaskType type;
  final String description;
  final TaskPriority priority;
  final int estimatedMinutes;
  final String assignedTo;
  final DateTime dueDate;
  bool completed = false;

  DelegatedTask({
    required this.id,
    required this.type,
    required this.description,
    required this.priority,
    required this.estimatedMinutes,
    required this.assignedTo,
    required this.dueDate,
  });
}

class DelegationPlan {
  final List<DelegatedTask> tasks;
  final Map<String, List<DelegatedTask>> staffAssignments;

  DelegationPlan({required this.tasks, required this.staffAssignments});

  int getTotalEstimatedMinutes() {
    return tasks.fold<int>(0, (sum, t) => sum + t.estimatedMinutes);
  }
}

class ScalabilityReport {
  final int currentItems;
  final int currentUnits;
  final int currentLocations;
  final int complexityScore;
  final int estimatedStaffNeeded;
  final int itemCapacity;
  final int locationCapacity;
  final double itemHeadroom;
  final double locationHeadroom;
  final bool canScale;
  final List<String> recommendations;

  ScalabilityReport({
    required this.currentItems,
    required this.currentUnits,
    required this.currentLocations,
    required this.complexityScore,
    required this.estimatedStaffNeeded,
    required this.itemCapacity,
    required this.locationCapacity,
    required this.itemHeadroom,
    required this.locationHeadroom,
    required this.canScale,
    required this.recommendations,
  });

  String get scalingPotential {
    if (itemHeadroom > 50) {
      return '✅ EXCELLENT - Can grow significantly';
    } else if (itemHeadroom > 20) {
      return '✅ GOOD - Can grow 2-3x';
    } else {
      return '⚠️ LIMITED - Time to plan for enterprise system';
    }
  }
}

class AutomationStatus {
  final Map<String, bool> automatedTasks;
  final Map<String, bool> manualTasks;
  final double automationPercentage;
  final double hoursPerMonthSaved;
  final double laborCostSaved;
  final String canScaleTo;

  AutomationStatus({
    required this.automatedTasks,
    required this.manualTasks,
    required this.automationPercentage,
    required this.hoursPerMonthSaved,
    required this.laborCostSaved,
    required this.canScaleTo,
  });
}
