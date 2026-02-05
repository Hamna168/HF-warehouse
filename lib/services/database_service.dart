import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'hf_warehouse.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Products Table
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        size TEXT,
        color TEXT,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        reorderLevel INTEGER NOT NULL DEFAULT 10,
        status TEXT DEFAULT 'active',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Inventory Transactions Table
    await db.execute('''
      CREATE TABLE inventoryTransactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        transactionType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        performedBy TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Stock Movements Table
    await db.execute('''
      CREATE TABLE stockMovements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        quantityMoved INTEGER NOT NULL,
        fromLocation TEXT NOT NULL,
        toLocation TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        movedBy TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        FOREIGN KEY(productId) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Users Table
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        role TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        createdAt TEXT NOT NULL
      )
    ''');

    // Reports Table
    await db.execute('''
      CREATE TABLE reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reportType TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        data TEXT NOT NULL,
        generatedBy TEXT NOT NULL,
        generatedAt TEXT NOT NULL
      )
    ''');

    // Create Indexes for better query performance
    await db.execute('CREATE INDEX idx_products_status ON products(status)');
    await db.execute(
      'CREATE INDEX idx_products_category ON products(category)',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_productId ON inventoryTransactions(productId)',
    );
    await db.execute(
      'CREATE INDEX idx_movements_productId ON stockMovements(productId)',
    );
  }

  // ============ PRODUCT OPERATIONS ============

  Future<int> addProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<Product?> getProduct(int id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  Future<List<Product>> getAllProducts({
    String? category,
    String? status,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM products WHERE 1=1';
    List<dynamic> args = [];

    if (category != null) {
      query += ' AND category = ?';
      args.add(category);
    }
    if (status != null) {
      query += ' AND status = ?';
      args.add(status);
    }
    query += ' ORDER BY updatedAt DESC';

    final result = await db.rawQuery(query, args);
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    return (await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
    )).map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM products WHERE quantity <= reorderLevel AND status = ? ORDER BY quantity ASC',
      ['active'],
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateProductQuantity(int productId, int quantity) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE products SET quantity = quantity + ?, updatedAt = ? WHERE id = ?',
      [quantity, DateTime.now().toIso8601String(), productId],
    );
  }

  // ============ INVENTORY TRANSACTION OPERATIONS ============

  Future<int> addTransaction(InventoryTransaction transaction) async {
    final db = await database;
    return await db.insert('inventoryTransactions', transaction.toMap());
  }

  Future<List<InventoryTransaction>> getTransactionsByProduct(
    int productId,
  ) async {
    final db = await database;
    final result = await db.query(
      'inventoryTransactions',
      where: 'productId = ?',
      whereArgs: [productId],
      orderBy: 'timestamp DESC',
    );
    return result.map((map) => InventoryTransaction.fromMap(map)).toList();
  }

  Future<List<InventoryTransaction>> getAllTransactions({
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String query = 'SELECT * FROM inventoryTransactions WHERE 1=1';
    List<dynamic> args = [];

    if (transactionType != null) {
      query += ' AND transactionType = ?';
      args.add(transactionType);
    }
    if (startDate != null) {
      query += ' AND timestamp >= ?';
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      query += ' AND timestamp <= ?';
      args.add(endDate.toIso8601String());
    }
    query += ' ORDER BY timestamp DESC';

    final result = await db.rawQuery(query, args);
    return result.map((map) => InventoryTransaction.fromMap(map)).toList();
  }

  // ============ STOCK MOVEMENT OPERATIONS ============

  Future<int> addStockMovement(StockMovement movement) async {
    final db = await database;
    return await db.insert('stockMovements', movement.toMap());
  }

  Future<List<StockMovement>> getPendingMovements() async {
    final db = await database;
    final result = await db.query(
      'stockMovements',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'createdAt ASC',
    );
    return result.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<int> updateMovementStatus(int id, String status) async {
    final db = await database;
    return await db.update(
      'stockMovements',
      {
        'status': status,
        'completedAt': status == 'completed'
            ? DateTime.now().toIso8601String()
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============ USER OPERATIONS ============

  Future<int> addUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users', orderBy: 'username ASC');
    return result.map((map) => User.fromMap(map)).toList();
  }

  // ============ REPORTS OPERATIONS ============

  Future<int> saveReport(WareouseReport report) async {
    final db = await database;
    return await db.insert('reports', {
      'reportType': report.reportType,
      'title': report.title,
      'description': report.description,
      'data': report.data.toString(),
      'generatedBy': report.generatedBy,
      'generatedAt': report.generatedAt.toIso8601String(),
    });
  }

  // ============ STATISTICS ============

  Future<Map<String, dynamic>> getWarehouseStats() async {
    final db = await database;

    final totalProducts = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE status = ?',
      ['active'],
    );

    final totalQuantity = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM products WHERE status = ?',
      ['active'],
    );

    final lowStockCount = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE quantity <= reorderLevel AND status = ?',
      ['active'],
    );

    final totalValue = await db.rawQuery(
      'SELECT SUM(price * quantity) as total FROM products WHERE status = ?',
      ['active'],
    );

    return {
      'totalProducts': (totalProducts.first['count'] as int?) ?? 0,
      'totalQuantity': (totalQuantity.first['total'] as int?) ?? 0,
      'lowStockCount': (lowStockCount.first['count'] as int?) ?? 0,
      'totalValue': ((totalValue.first['total'] as num?) ?? 0).toDouble(),
    };
  }

  Future<void> deleteDatabase() async {
    final db = await database;
    await db.close();
    String path = join(await getDatabasesPath(), 'hf_warehouse.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
