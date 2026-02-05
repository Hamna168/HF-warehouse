import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/hf_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/hf_widgets.dart';
import '../services/real_time_sync_service.dart';
import '../services/data_integrity_service.dart';
import '../services/advanced_analytics_service.dart';
import '../services/scalability_module.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late RealTimeSyncService _syncService;
  late AdvancedAnalyticsService _analyticsService;
  late ScalabilityModule _scalabilityModule;

  List<InventoryAlert> _alerts = [];

  @override
  void initState() {
    super.initState();

    _syncService = RealTimeSyncService();
    _analyticsService = AdvancedAnalyticsService();
    _scalabilityModule = ScalabilityModule();

    // Listen to real-time alerts
    _syncService.alerts.listen((alert) {
      setState(() {
        _alerts.insert(0, alert);
        if (_alerts.length > 10) _alerts.removeLast();
      });

      // Show critical alerts as toast
      if (alert.severity == AlertSeverity.critical) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(alert.message),
            backgroundColor: HFBrandColors.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadStats();
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HFAppBar(
        title: 'HF Warehouse Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardProvider>().loadStats();
              context.read<ProductProvider>().loadProducts();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DashboardProvider>().loadStats();
          context.read<ProductProvider>().loadProducts();
        },
        child: _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Consumer2<DashboardProvider, ProductProvider>(
      builder: (context, dashboardProvider, productProvider, _) {
        if (dashboardProvider.isLoading || productProvider.isLoading) {
          return const HFLoadingShimmer();
        }

        final stats = dashboardProvider.stats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HFBrandColors.primaryBlack,
                      HFBrandColors.darkGray,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to HF Warehouse',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: HFBrandColors.accentWhite),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart inventory management with real-time protection',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HFBrandColors.accentWhite.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // SECTION 1: GHOST STOCK PROTECTION (Real-time Sync)
              _buildGhostStockSection(context),

              const SizedBox(height: 24),

              // SECTION 2: DATA INTEGRITY & ERROR DETECTION
              _buildDataIntegritySection(context, productProvider),

              const SizedBox(height: 24),

              // Stats Grid
              Text(
                'Inventory Overview',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  HFStatCard(
                    label: 'Active Products',
                    value: '${stats['totalProducts'] ?? 0}',
                    icon: Icons.inventory_2,
                    iconColor: HFBrandColors.primaryGold,
                  ),
                  HFStatCard(
                    label: 'Total Units',
                    value: '${stats['totalQuantity'] ?? 0}',
                    icon: Icons.archive,
                    iconColor: HFBrandColors.infoBlue,
                  ),
                  HFStatCard(
                    label: 'Low Stock Items',
                    value: '${stats['lowStockCount'] ?? 0}',
                    icon: Icons.warning,
                    iconColor: HFBrandColors.warningOrange,
                  ),
                  HFStatCard(
                    label: 'Total Value',
                    value: '\$${(stats['totalValue'] ?? 0).toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    iconColor: HFBrandColors.successGreen,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // SECTION 3: DEAD STOCK & STOCKOUT ANALYSIS
              _buildAnalyticsSection(context, productProvider),

              const SizedBox(height: 24),

              // SECTION 4: SCALABILITY & GROWTH
              _buildScalabilitySection(context),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: HFButton(
                      label: 'Add Product',
                      icon: Icons.add,
                      onPressed: () {
                        Navigator.pushNamed(context, '/add-product');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HFButton(
                      label: 'Export Data',
                      icon: Icons.download,
                      isOutlined: true,
                      onPressed: () {
                        _showExportOptions(context);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Management Tools
              Text(
                'Management Tools',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildManagementTools(context),

              const SizedBox(height: 24),

              // Low Stock Alert
              if ((stats['lowStockCount'] ?? 0) > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HFBrandColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HFBrandColors.errorRed),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: HFBrandColors.errorRed,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Low Stock Alert',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: HFBrandColors.errorRed),
                            ),
                            Text(
                              '${stats['lowStockCount']} items need reordering',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/products');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HFBrandColors.errorRed,
                        ),
                        child: const Text('View'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// PROBLEM #1: GHOST STOCK PROTECTION
  /// Real-time sync prevents overselling
  Widget _buildGhostStockSection(BuildContext context) {
    return FutureBuilder<DataFreshnessReport>(
      future: _syncService.getFreshnessReport(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final freshness = snapshot.data!;
        final isHealthy = freshness.accuracyPercentage >= 80;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🛡️ Ghost Stock Protection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHealthy
                    ? HFBrandColors.successGreen.withOpacity(0.1)
                    : HFBrandColors.warningOrange.withOpacity(0.1),
                border: Border.all(
                  color: isHealthy
                      ? HFBrandColors.successGreen
                      : HFBrandColors.warningOrange,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Data Accuracy',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${freshness.accuracyPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isHealthy
                              ? HFBrandColors.successGreen
                              : HFBrandColors.warningOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${freshness.freshData} items updated in last 15 min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: freshness.accuracyPercentage / 100,
                    minHeight: 6,
                    backgroundColor: HFBrandColors.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isHealthy
                          ? HFBrandColors.successGreen
                          : HFBrandColors.warningOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✓ Real-time sync every 5 seconds prevents overselling',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isHealthy
                          ? HFBrandColors.successGreen
                          : HFBrandColors.warningOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// PROBLEM #2: DATA INTEGRITY & ERROR DETECTION
  /// Shows data health and validation status
  Widget _buildDataIntegritySection(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    final allProducts = productProvider.products;

    return FutureBuilder<InventoryHealthReport>(
      future: Future.sync(() {
        return DataIntegrityService.validateCompleteInventory(allProducts);
      }),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final health = snapshot.data!;
        final isHealthy = health.healthScore >= 90;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '✓ Data Integrity Status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHealthy
                    ? HFBrandColors.successGreen.withOpacity(0.1)
                    : HFBrandColors.errorRed.withOpacity(0.1),
                border: Border.all(
                  color: isHealthy
                      ? HFBrandColors.successGreen
                      : HFBrandColors.errorRed,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Health',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        health.overallStatus,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isHealthy
                              ? HFBrandColors.successGreen
                              : HFBrandColors.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHealthStat(
                        context,
                        '${health.validProducts}',
                        'Valid',
                        HFBrandColors.successGreen,
                      ),
                      _buildHealthStat(
                        context,
                        '${health.suspiciousProducts}',
                        'Suspicious',
                        HFBrandColors.warningOrange,
                      ),
                      _buildHealthStat(
                        context,
                        '${health.problematicProducts}',
                        'Problems',
                        HFBrandColors.errorRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '💰 Data Loss Risk: \$${health.estimatedDataLoss.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// PROBLEM #3 & #4: DEAD STOCK & STOCKOUT ANALYSIS
  /// Shows hidden costs and growth threats
  Widget _buildAnalyticsSection(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    return FutureBuilder<InventoryHealthDashboard>(
      future: _analyticsService.getHealthDashboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final dashboard = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Inventory Intelligence',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),

            // Dead Stock Alert
            if (dashboard.deadStockAnalysis.deadStockItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HFBrandColors.warningOrange.withOpacity(0.1),
                  border: Border.all(color: HFBrandColors.warningOrange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          color: HFBrandColors.warningOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dead Stock Alert',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: HFBrandColors.warningOrange),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${dashboard.deadStockAnalysis.deadStockItems.length} items with zero sales',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '💰 Cash Trapped: \$${dashboard.deadStockAnalysis.deadStockCashTrapped.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: HFButton(
                        label: 'View Dead Stock',
                        onPressed: () {
                          _showDeadStockDetails(context, dashboard);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Stockout Risk Alert
            if (dashboard.stockoutPredictions.hasImmediateRisk) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HFBrandColors.errorRed.withOpacity(0.1),
                  border: Border.all(color: HFBrandColors.errorRed),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: HFBrandColors.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Stockout Risk - URGENT',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: HFBrandColors.errorRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '⏰ ${dashboard.stockoutPredictions.itemsAtRisk.where((r) => r.daysUntilStockout < 3).length} items will run out in <3 days!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Estimated Revenue Loss: \$${dashboard.stockoutPredictions.estimatedRevenueLoss.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: HFButton(
                        label: 'View Risk Items',
                        onPressed: () {
                          _showStockoutRisks(context, dashboard);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  /// PROBLEM #5: SCALABILITY & GROWTH CAPACITY
  /// Shows if business can grow
  Widget _buildScalabilitySection(BuildContext context) {
    return FutureBuilder<ScalabilityReport>(
      future: _scalabilityModule.assessScalability(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final report = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🚀 Growth & Scalability',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HFBrandColors.infoBlue.withOpacity(0.1),
                border: Border.all(color: HFBrandColors.infoBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scaling Potential',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: HFBrandColors.successGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.scalingPotential.split(' - ')[0],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: HFBrandColors.accentWhite,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildScalabilityRow(
                    context,
                    'Current Items',
                    '${report.currentItems}',
                    'Capacity: ${report.itemCapacity}',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: report.currentItems / report.itemCapacity,
                    minHeight: 8,
                    backgroundColor: HFBrandColors.lightGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      HFBrandColors.infoBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Headroom: ${report.itemHeadroom.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '👥 Estimated Staff Needed: ${report.estimatedStaffNeeded} people',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper widgets
  Widget _buildHealthStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildScalabilityRow(
    BuildContext context,
    String label,
    String value,
    String detail,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildManagementTools(BuildContext context) {
    return Column(
      children: [
        HFCard(
          onTap: () => Navigator.pushNamed(context, '/products'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HFBrandColors.primaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory,
                  color: HFBrandColors.primaryGold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Products',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'View and edit product catalog',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HFCard(
          onTap: () => Navigator.pushNamed(context, '/transactions'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HFBrandColors.infoBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.swap_horiz,
                  color: HFBrandColors.infoBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventory Transactions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Track stock movements',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
        const SizedBox(height: 12),
        HFCard(
          onTap: () => Navigator.pushNamed(context, '/movements'),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HFBrandColors.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: HFBrandColors.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Movements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Manage warehouse transfers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeadStockDetails(
    BuildContext context,
    InventoryHealthDashboard dashboard,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dead Stock Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Items with zero sales (30 days):',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final item in dashboard.deadStockAnalysis.deadStockItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${item.quantity} units × \$${item.price} = \$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Text(
                'Total Cash Trapped: \$${dashboard.deadStockAnalysis.deadStockCashTrapped.toStringAsFixed(2)}',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: HFBrandColors.errorRed),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStockoutRisks(
    BuildContext context,
    InventoryHealthDashboard dashboard,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stockout Risk Analysis'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final risk in dashboard.stockoutPredictions.itemsAtRisk)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: risk.severity == RiskSeverity.critical
                          ? HFBrandColors.errorRed.withOpacity(0.1)
                          : HFBrandColors.warningOrange.withOpacity(0.1),
                      border: Border.all(
                        color: risk.severity == RiskSeverity.critical
                            ? HFBrandColors.errorRed
                            : HFBrandColors.warningOrange,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          risk.productName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current: ${risk.currentQuantity} units',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Daily use: ${risk.dailyConsumption.toStringAsFixed(1)} units',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '⏰ Stockout in ${risk.daysUntilStockout.toStringAsFixed(1)} days',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: risk.severity == RiskSeverity.critical
                                    ? HFBrandColors.errorRed
                                    : HFBrandColors.warningOrange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Export Options',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export Products to Excel'),
              subtitle: const Text('Download inventory list'),
              onTap: () {
                Navigator.pop(context);
                context.read<ProductProvider>().exportToExcel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Products exported successfully'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Export Transactions to Excel'),
              subtitle: const Text('Download transaction history'),
              onTap: () {
                Navigator.pop(context);
                context.read<TransactionProvider>().exportToExcel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transactions exported successfully'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
