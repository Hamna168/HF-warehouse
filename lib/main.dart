import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Theme and Style Imports
import 'theme/hf_theme.dart';

// Provider Imports - Ensure these files exist in your project
import 'providers/app_providers.dart';
import 'providers/user_provider.dart'; // FIXED: Crucial import for UserProvider

// Model and Screen Imports
import 'models/models.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chatbot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Logic for Chrome/Edge
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Logic for Windows/Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const HFWarehouseApp());
}

class HFWarehouseApp extends StatelessWidget {
  const HFWarehouseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => StockMovementProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'HF Warehouse',
        theme: HFTheme.lightTheme,
        home: const MainNavigationScreen(),
        routes: {
          '/dashboard': (context) => const DashboardScreen(),
          '/chatbot': (context) => const ChatbotScreen(),
          '/products': (context) => const ProductsScreen(),
          '/add-product': (context) => const AddProductScreen(),
          '/transactions': (context) => const TransactionsScreen(),
          '/add-transaction': (context) => const AddTransactionScreen(),
          '/movements': (context) => const StockMovementsScreen(),
          '/add-movement': (context) => const AddStockMovementScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductsScreen(),
    const TransactionsScreen(),
    const ChatbotScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Breakpoint logic
        bool isMobile = constraints.maxWidth < 600;
        bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1100;

        return Scaffold(
          body: Row(
            children: [
              // 1. Sidebar for Desktop/Tablet
              if (!isMobile)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  extended: !isTablet, // Labels show only on full desktop
                  backgroundColor: HFBrandColors.primaryBlack,
                  selectedIconTheme: const IconThemeData(
                    color: HFBrandColors.primaryGold,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: HFBrandColors.mediumGray,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: HFBrandColors.primaryGold,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: HFBrandColors.mediumGray,
                  ),
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2),
                      label: Text('Products'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt),
                      label: Text('Transactions'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.chat),
                      label: Text('Assistant'),
                    ),
                  ],
                ),

              // 2. Main Content Area
              Expanded(
                child: Container(
                  color: Colors.white, // Background for the content
                  child: _screens[_selectedIndex],
                ),
              ),
            ],
          ),

          // 3. Bottom Bar for Mobile
          bottomNavigationBar: isMobile
              ? BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: HFBrandColors.primaryBlack,
                  selectedItemColor: HFBrandColors.primaryGold,
                  unselectedItemColor: HFBrandColors.mediumGray,
                  onTap: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2),
                      label: 'Products',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.receipt),
                      label: 'Transactions',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: 'Assistant',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

// --- Responsive List View Wrapper ---
// Use this pattern inside your screens to keep content from getting too wide
Widget responsiveContentWrapper(Widget child) {
  return Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-product'),
          ),
        ],
      ),
      body: responsiveContentWrapper(
        Consumer<ProductProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading)
              return const Center(child: CircularProgressIndicator());
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Quantity')),
                ],
                rows: provider.filteredProducts.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text(product.sku)),
                      DataCell(Text(product.name)),
                      // FIXED: \$ used to escape dollar sign
                      DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                      DataCell(Text(product.quantity.toString())),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _statusController = TextEditingController(text: 'active');

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _reorderLevelController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final now = DateTime.now();
      final product = Product(
        sku: _skuController.text,
        name: _nameController.text,
        description: _descriptionController.text,
        category: _categoryController.text,
        size: _sizeController.text,
        color: _colorController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        reorderLevel: int.parse(_reorderLevelController.text),
        status: _statusController.text,
        createdAt: now,
        updatedAt: now,
      );
      context.read<ProductProvider>().addProduct(product);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: responsiveContentWrapper(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _sizeController,
                    decoration: const InputDecoration(labelText: 'Size'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Color'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (double.tryParse(value) == null)
                        return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _reorderLevelController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder Level',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Product'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
          ),
        ],
      ),
      body: responsiveContentWrapper(
        Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading)
              return const Center(child: CircularProgressIndicator());
            if (provider.transactions.isEmpty)
              return const Center(child: Text('No transactions found'));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Product ID')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Reason')),
                  DataColumn(label: Text('Notes')),
                  DataColumn(label: Text('Performed By')),
                  DataColumn(label: Text('Timestamp')),
                ],
                rows: provider.transactions.map((transaction) {
                  return DataRow(
                    cells: [
                      DataCell(Text(transaction.id?.toString() ?? '')),
                      DataCell(Text(transaction.productId.toString())),
                      DataCell(Text(transaction.transactionType)),
                      DataCell(Text(transaction.quantity.toString())),
                      DataCell(Text(transaction.reason)),
                      DataCell(Text(transaction.notes)),
                      DataCell(Text(transaction.performedBy)),
                      DataCell(Text(transaction.timestamp.toString())),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({Key? key}) : super(key: key);

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockMovementProvider>().loadPendingMovements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Movements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add-movement'),
          ),
        ],
      ),
      body: responsiveContentWrapper(
        Consumer<StockMovementProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading)
              return const Center(child: CircularProgressIndicator());
            if (provider.movements.isEmpty)
              return const Center(child: Text('No pending movements'));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Product ID')),
                  DataColumn(label: Text('Quantity Moved')),
                  DataColumn(label: Text('From Location')),
                  DataColumn(label: Text('To Location')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Moved By')),
                  DataColumn(label: Text('Created At')),
                  DataColumn(label: Text('Completed At')),
                ],
                rows: provider.movements.map((movement) {
                  return DataRow(
                    cells: [
                      DataCell(Text(movement.id?.toString() ?? '')),
                      DataCell(Text(movement.productId.toString())),
                      DataCell(Text(movement.quantityMoved.toString())),
                      DataCell(Text(movement.fromLocation)),
                      DataCell(Text(movement.toLocation)),
                      DataCell(Text(movement.status)),
                      DataCell(Text(movement.movedBy)),
                      DataCell(Text(movement.createdAt.toString())),
                      DataCell(Text(movement.completedAt?.toString() ?? '')),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _transactionTypeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();
  final _performedByController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    _transactionTypeController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    _performedByController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final transaction = InventoryTransaction(
        productId: int.parse(_productIdController.text),
        transactionType: _transactionTypeController.text,
        quantity: int.parse(_quantityController.text),
        reason: _reasonController.text,
        notes: _notesController.text,
        performedBy: _performedByController.text,
        timestamp: DateTime.now(),
      );
      context.read<TransactionProvider>().addTransaction(transaction);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: responsiveContentWrapper(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _productIdController,
                    decoration: const InputDecoration(labelText: 'Product ID'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _transactionTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction Type',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _performedByController,
                    decoration: const InputDecoration(
                      labelText: 'Performed By',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Transaction'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddStockMovementScreen extends StatefulWidget {
  const AddStockMovementScreen({Key? key}) : super(key: key);

  @override
  State<AddStockMovementScreen> createState() => _AddStockMovementScreenState();
}

class _AddStockMovementScreenState extends State<AddStockMovementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productIdController = TextEditingController();
  final _quantityMovedController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _movedByController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    _quantityMovedController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _movedByController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final movement = StockMovement(
        productId: int.parse(_productIdController.text),
        quantityMoved: int.parse(_quantityMovedController.text),
        fromLocation: _fromLocationController.text,
        toLocation: _toLocationController.text,
        movedBy: _movedByController.text,
        createdAt: DateTime.now(),
      );
      context.read<StockMovementProvider>().addMovement(movement);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock Movement')),
      body: responsiveContentWrapper(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _productIdController,
                    decoration: const InputDecoration(labelText: 'Product ID'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _quantityMovedController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity Moved',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value!.isEmpty) return 'Required';
                      if (int.tryParse(value) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _fromLocationController,
                    decoration: const InputDecoration(
                      labelText: 'From Location',
                    ),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _toLocationController,
                    decoration: const InputDecoration(labelText: 'To Location'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _movedByController,
                    decoration: const InputDecoration(labelText: 'Moved By'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Movement'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
