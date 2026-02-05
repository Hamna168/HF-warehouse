import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/excel_export_service.dart';

// Product Provider
class ProductProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;

  Future<void> loadProducts({String? category}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (category != null && category != 'All') {
        _products = await _dbService.getAllProducts(category: category);
        _selectedCategory = category;
      } else {
        _products = await _dbService.getAllProducts();
        _selectedCategory = 'All';
      }
      _filteredProducts = List.from(_products);
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await _dbService.addProduct(product);
      await loadProducts(category: _selectedCategory);
    } catch (e) {
      debugPrint('Error adding product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _dbService.updateProduct(product);
      await loadProducts(category: _selectedCategory);
    } catch (e) {
      debugPrint('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dbService.deleteProduct(id);
      await loadProducts(category: _selectedCategory);
    } catch (e) {
      debugPrint('Error deleting product: $e');
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      _filteredProducts = await _dbService.searchProducts(query);
    }
    notifyListeners();
  }

  Future<void> exportToExcel() async {
    try {
      await ExcelExportService.exportProductsToExcel(_products);
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
    }
  }
}

// Inventory Transaction Provider
class TransactionProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<InventoryTransaction> _transactions = [];
  bool _isLoading = false;

  List<InventoryTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> loadTransactions({
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbService.getAllTransactions(
        transactionType: transactionType,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(InventoryTransaction transaction) async {
    try {
      await _dbService.addTransaction(transaction);

      // Update product quantity
      int quantityChange = transaction.transactionType == 'inbound'
          ? transaction.quantity
          : -transaction.quantity;
      await _dbService.updateProductQuantity(
        transaction.productId,
        quantityChange,
      );

      await loadTransactions();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> exportToExcel() async {
    try {
      await ExcelExportService.exportTransactionsToExcel(_transactions);
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
    }
  }
}

// Stock Movement Provider
class StockMovementProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<StockMovement> _movements = [];
  bool _isLoading = false;

  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;

  Future<void> loadPendingMovements() async {
    _isLoading = true;
    notifyListeners();

    try {
      _movements = await _dbService.getPendingMovements();
    } catch (e) {
      debugPrint('Error loading movements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMovement(StockMovement movement) async {
    try {
      await _dbService.addStockMovement(movement);
      await loadPendingMovements();
    } catch (e) {
      debugPrint('Error adding movement: $e');
    }
  }

  Future<void> updateMovementStatus(int id, String status) async {
    try {
      await _dbService.updateMovementStatus(id, status);
      await loadPendingMovements();
    } catch (e) {
      debugPrint('Error updating movement: $e');
    }
  }
}

// Dashboard Provider
class DashboardProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> loadStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await _dbService.getWarehouseStats();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
