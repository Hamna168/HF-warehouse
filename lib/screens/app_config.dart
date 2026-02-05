// lib/config/app_config.dart

class AppConfig {
  // App Metadata
  static const String APP_NAME = 'HF Warehouse';
  static const String APP_VERSION = '1.0.0';
  static const String APP_BUILD = '1';

  // API Configuration
  static const String GOOGLE_API_KEY =
      'AIzaSyASdYD1c6iMMQSNWToff7itKql1K0F6A0c';

  // Database Configuration
  static const String DATABASE_NAME = 'hf_warehouse.db';
  static const int DATABASE_VERSION = 1;

  // Feature Flags
  static const bool ENABLE_CHATBOT = true;
  static const bool ENABLE_EXPORT = true;
  static const bool ENABLE_ANALYTICS = true;
  static const bool ENABLE_AUDIT_LOG = true;

  // Warehouse Settings
  static const List<String> PRODUCT_CATEGORIES = [
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

  static const List<String> CLOTHING_SIZES = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'XXXL',
  ];

  static const List<String> LOCATIONS = [
    'Main Storage',
    'Section A',
    'Section B',
    'Section C',
    'Shipping Area',
    'Returns',
  ];

  // Transaction Types
  static const List<String> TRANSACTION_TYPES = [
    'inbound',
    'outbound',
    'adjustment',
  ];

  static const List<String> TRANSACTION_REASONS = [
    'purchase',
    'sale',
    'damage',
    'theft',
    'correction',
    'return',
    'transfer',
  ];

  // Report Types
  static const List<String> REPORT_TYPES = [
    'inventory',
    'sales',
    'movement',
    'audit',
  ];

  // User Roles
  static const List<String> USER_ROLES = ['admin', 'manager', 'staff'];

  // Color Theme
  static const String PRIMARY_COLOR = '#1A1A1A';
  static const String SECONDARY_COLOR = '#D4AF37';
  static const String ACCENT_COLOR = '#FAFAFA';

  // API Endpoints (if using backend)
  static const String API_BASE_URL = 'https://api.hfwarehouse.com';
  static const String API_TIMEOUT = '30';

  // Pagination
  static const int PAGE_SIZE = 20;
  static const int MAX_ITEMS_PER_REQUEST = 100;

  // Validation
  static const int MIN_PASSWORD_LENGTH = 8;
  static const int MAX_SKU_LENGTH = 50;
  static const int MAX_NAME_LENGTH = 255;

  // Date Formats
  static const String DATE_FORMAT = 'yyyy-MM-dd';
  static const String DATETIME_FORMAT = 'yyyy-MM-dd HH:mm:ss';
  static const String TIME_FORMAT = 'HH:mm:ss';

  // File Export Settings
  static const String EXPORT_FOLDER = 'HF Warehouse Exports';
  static const String EXCEL_SHEET_NAME = 'Inventory';

  // Performance Settings
  static const int CACHE_DURATION_MINUTES = 5;
  static const int SYNC_INTERVAL_MINUTES = 15;
  static const int REQUEST_TIMEOUT_SECONDS = 30;

  /// Get environment-specific configuration
  static String getEnvironment() {
    // Add your environment detection logic
    return 'production';
  }

  /// Check if feature is enabled
  static bool isFeatureEnabled(String featureName) {
    switch (featureName) {
      case 'chatbot':
        return ENABLE_CHATBOT;
      case 'export':
        return ENABLE_EXPORT;
      case 'analytics':
        return ENABLE_ANALYTICS;
      case 'audit_log':
        return ENABLE_AUDIT_LOG;
      default:
        return false;
    }
  }
}
