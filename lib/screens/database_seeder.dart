import '../models/models.dart';
import '../services/database_service.dart';

class DatabaseSeeder {
  static final DatabaseService _dbService = DatabaseService();

  static Future<void> seedInitialData() async {
    try {
      // Check if data already exists
      final existingProducts = await _dbService.getAllProducts();
      if (existingProducts.isNotEmpty) {
        return; // Already seeded
      }

      // Seed Products - Clothing Warehouse Data
      final products = [
        // T-Shirts
        Product(
          sku: 'TS-001',
          name: 'Classic Cotton T-Shirt',
          description: 'Premium quality cotton t-shirt for everyday wear',
          category: 'T-Shirts',
          size: 'S-XXL',
          color: 'White',
          price: 19.99,
          quantity: 150,
          reorderLevel: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'TS-002',
          name: 'Classic Cotton T-Shirt',
          description: 'Premium quality cotton t-shirt for everyday wear',
          category: 'T-Shirts',
          size: 'S-XXL',
          color: 'Black',
          price: 19.99,
          quantity: 120,
          reorderLevel: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'TS-003',
          name: 'Graphic T-Shirt',
          description: 'Stylish graphic printed t-shirt',
          category: 'T-Shirts',
          size: 'S-XXL',
          color: 'Navy Blue',
          price: 24.99,
          quantity: 85,
          reorderLevel: 40,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Jeans
        Product(
          sku: 'JN-001',
          name: 'Classic Denim Jeans',
          description: 'Timeless denim jeans with perfect fit',
          category: 'Jeans',
          size: '28-36',
          color: 'Dark Blue',
          price: 59.99,
          quantity: 200,
          reorderLevel: 80,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'JN-002',
          name: 'Slim Fit Jeans',
          description: 'Modern slim fit denim',
          category: 'Jeans',
          size: '28-36',
          color: 'Light Blue',
          price: 64.99,
          quantity: 95,
          reorderLevel: 60,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'JN-003',
          name: 'Ripped Jeans',
          description: 'Trendy ripped style jeans',
          category: 'Jeans',
          size: '28-36',
          color: 'Black',
          price: 69.99,
          quantity: 45,
          reorderLevel: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Shirts
        Product(
          sku: 'SH-001',
          name: 'Formal Button-Up Shirt',
          description: 'Professional formal shirt for business',
          category: 'Shirts',
          size: 'XS-XXL',
          color: 'White',
          price: 49.99,
          quantity: 110,
          reorderLevel: 40,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'SH-002',
          name: 'Oxford Shirt',
          description: 'Classic oxford cotton shirt',
          category: 'Shirts',
          size: 'XS-XXL',
          color: 'Light Blue',
          price: 54.99,
          quantity: 78,
          reorderLevel: 35,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Sweaters & Hoodies
        Product(
          sku: 'SW-001',
          name: 'Crew Neck Sweater',
          description: 'Cozy knit sweater perfect for casual wear',
          category: 'Sweaters',
          size: 'XS-XXL',
          color: 'Gray',
          price: 49.99,
          quantity: 65,
          reorderLevel: 30,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'SW-002',
          name: 'Hoodie Sweatshirt',
          description: 'Comfortable hoodie with kangaroo pocket',
          category: 'Hoodies',
          size: 'S-XXL',
          color: 'Black',
          price: 59.99,
          quantity: 88,
          reorderLevel: 45,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Pants
        Product(
          sku: 'PT-001',
          name: 'Chino Pants',
          description: 'Smart casual chino trousers',
          category: 'Pants',
          size: '28-36',
          color: 'Khaki',
          price: 54.99,
          quantity: 92,
          reorderLevel: 40,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'PT-002',
          name: 'Cargo Pants',
          description: 'Multi-pocket cargo pants for utility',
          category: 'Pants',
          size: '28-36',
          color: 'Olive Green',
          price: 64.99,
          quantity: 35,
          reorderLevel: 50,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Jackets
        Product(
          sku: 'JK-001',
          name: 'Denim Jacket',
          description: 'Classic denim jacket for layering',
          category: 'Jackets',
          size: 'XS-XXL',
          color: 'Blue',
          price: 79.99,
          quantity: 45,
          reorderLevel: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Product(
          sku: 'JK-002',
          name: 'Leather Jacket',
          description: 'Premium leather jacket',
          category: 'Jackets',
          size: 'XS-XL',
          color: 'Black',
          price: 199.99,
          quantity: 12,
          reorderLevel: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Add all products
      for (final product in products) {
        await _dbService.addProduct(product);
      }

      // Seed sample inventory transactions
      final now = DateTime.now();
      final transactions = [
        InventoryTransaction(
          productId: 1,
          transactionType: 'inbound',
          quantity: 100,
          reason: 'purchase',
          notes: 'Regular stock purchase from supplier',
          performedBy: 'John Manager',
          timestamp: now.subtract(const Duration(days: 2)),
        ),
        InventoryTransaction(
          productId: 4,
          transactionType: 'inbound',
          quantity: 150,
          reason: 'purchase',
          notes: 'Bulk order received',
          performedBy: 'Jane Supervisor',
          timestamp: now.subtract(const Duration(days: 1)),
        ),
        InventoryTransaction(
          productId: 2,
          transactionType: 'outbound',
          quantity: 30,
          reason: 'sale',
          notes: 'Online store sales',
          performedBy: 'Mike Staff',
          timestamp: now,
        ),
      ];

      for (final transaction in transactions) {
        await _dbService.addTransaction(transaction);
      }

      print('✅ Database seeded successfully with sample data');
    } catch (e) {
      print('❌ Error seeding database: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      await _dbService.deleteDatabase();
      print('✅ Database cleared');
    } catch (e) {
      print('❌ Error clearing database: $e');
    }
  }
}
