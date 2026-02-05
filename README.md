# HF Warehouse Management System

A comprehensive, enterprise-grade warehouse management application for clothing inventory built with Flutter. Designed with clean architecture, bold branding, and intelligent automation.

## 🎯 Overview

**HF Warehouse** is a full-stack solution for managing clothing warehouse operations including:
- 📦 Inventory Management
- 📊 Real-time Analytics & Reports
- 🔄 Stock Movement Tracking
- 🤖 AI-powered Chatbot Assistant
- 📈 Performance Analytics
- 💾 SQLite Database with Excel Export

## 🏗️ Architecture

### Tech Stack
- **Frontend:** Flutter 3.0+ (Agile/Clean Architecture)
- **State Management:** Provider Pattern
- **Database:** SQLite with sqflite
- **AI/Chatbot:** Google Generative AI (Gemini)
- **Export:** Excel Generation
- **UI Framework:** Material Design 3

### Project Structure
```
hf_warehouse/
├── lib/
│   ├── main.dart                 # App entry point & navigation
│   ├── theme/
│   │   └── hf_theme.dart        # Brand colors & theme configuration
│   ├── models/
│   │   ├── models.dart          # Data models for all entities
│   │   └── models.g.dart        # JSON serialization (auto-generated)
│   ├── services/
│   │   ├── database_service.dart      # SQLite operations
│   │   ├── chatbot_service.dart       # AI assistant logic
│   │   └── excel_export_service.dart  # Excel report generation
│   ├── providers/
│   │   └── app_providers.dart   # State management (Provider)
│   ├── screens/
│   │   ├── dashboard_screen.dart      # Main dashboard
│   │   ├── chatbot_screen.dart        # AI assistant UI
│   │   └── [other screens]
│   └── widgets/
│       └── hf_widgets.dart      # Reusable branded components
├── pubspec.yaml                 # Dependencies
└── README.md                    # This file
```

## 🎨 Brand Design System

### Color Palette (HF Brand)
- **Primary Black:** `#1A1A1A` - Main brand color
- **Gold Accent:** `#D4AF37` - Secondary highlight
- **Clean White:** `#FAFAFA` - Background
- **Status Colors:** Green (success), Orange (warning), Red (error), Blue (info)

### Typography
- **Font Family:** Poppins (Google Fonts)
- **Bold & Modern:** Professional warehouse branding
- **Consistent Sizing:** Hierarchical text scales

### UI Components
- Custom `HFButton`, `HFCard`, `HFTextField`, `HFStatCard`
- Loading states with shimmer effects
- Empty states with actionable CTAs
- Responsive grid layouts

## 🗄️ Database Schema

### Products Table
```sql
CREATE TABLE products(
  id INTEGER PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  size TEXT,
  color TEXT,
  price REAL NOT NULL,
  quantity INTEGER DEFAULT 0,
  reorderLevel INTEGER DEFAULT 10,
  status TEXT DEFAULT 'active',
  createdAt TEXT,
  updatedAt TEXT
)
```

### Inventory Transactions Table
```sql
CREATE TABLE inventoryTransactions(
  id INTEGER PRIMARY KEY,
  productId INTEGER FOREIGN KEY,
  transactionType TEXT (inbound|outbound|adjustment),
  quantity INTEGER NOT NULL,
  reason TEXT,
  notes TEXT,
  performedBy TEXT,
  timestamp TEXT
)
```

### Stock Movements Table
```sql
CREATE TABLE stockMovements(
  id INTEGER PRIMARY KEY,
  productId INTEGER FOREIGN KEY,
  quantityMoved INTEGER,
  fromLocation TEXT,
  toLocation TEXT,
  status TEXT (pending|completed|cancelled),
  movedBy TEXT,
  createdAt TEXT,
  completedAt TEXT
)
```

### Users Table
```sql
CREATE TABLE users(
  id INTEGER PRIMARY KEY,
  username TEXT UNIQUE,
  email TEXT UNIQUE,
  role TEXT (admin|manager|staff),
  status TEXT (active|inactive),
  createdAt TEXT
)
```

### Reports Table
```sql
CREATE TABLE reports(
  id INTEGER PRIMARY KEY,
  reportType TEXT,
  title TEXT,
  description TEXT,
  data TEXT (JSON),
  generatedBy TEXT,
  generatedAt TEXT
)
```

## 🤖 AI Chatbot Features

The HF Warehouse Assistant provides intelligent automation:

### Capabilities
- ✅ **Inventory Queries:** Real-time stock levels
- ✅ **Low Stock Alerts:** Automatic reordering suggestions
- ✅ **Analytics:** Product performance analysis
- ✅ **Task Automation:** Create transactions, movements, reports
- ✅ **Smart Recommendations:** Based on warehouse data

### Example Queries
```
"What products are low on stock?"
"Show me inventory summary"
"Analyze product performance"
"What should I reorder?"
"Create a new inventory transaction"
"Generate a warehouse report"
```

## 📊 Excel Export Features

### Export Formats
1. **Products Inventory** - Complete product catalog with pricing
2. **Transaction History** - All inventory movements
3. **Summary Report** - Key metrics and analytics

### Export Structure
- Professional headers with HF branding
- Color-coded data (alternate rows)
- Auto-fit columns
- Summary statistics sheet
- Date-stamped exports

## 🚀 Getting Started

### Prerequisites
- Flutter 3.0+
- Dart SDK
- Android Studio / Xcode (for emulator)
- Google API Key (for Chatbot)

### Installation

1. **Clone the repository**
```bash
git clone <repo-url>
cd hf_warehouse
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate JSON serialization**
```bash
flutter pub run build_runner build
```

4. **Configure API Keys**
Create `.env` file or update chatbot_service.dart:
```dart
const String API_KEY = 'YOUR_GOOGLE_API_KEY';
```

5. **Run the app**
```bash
flutter run
```

## 📱 Features Breakdown

### Dashboard
- **Quick Stats:** Total products, units, inventory value, low stock count
- **Welcome Header:** Personalized greeting
- **Quick Actions:** Add products, export data
- **Management Tools:** Easy access to all modules
- **Alerts:** Low stock notifications

### Products Management
- ✅ Add/Edit/Delete products
- ✅ Filter by category
- ✅ Search functionality
- ✅ View product details
- ✅ Bulk operations
- ✅ Stock status indicators

### Inventory Transactions
- ✅ Log inbound/outbound movements
- ✅ Track adjustments
- ✅ Record reasons for changes
- ✅ Automatic quantity updates
- ✅ Transaction history
- ✅ Date range filtering

### Stock Movements
- ✅ Plan warehouse transfers
- ✅ Track movement status
- ✅ Location-based transfers
- ✅ Completion tracking
- ✅ Pending movement queue

### AI Assistant
- ✅ Natural language queries
- ✅ Real-time inventory lookup
- ✅ Recommendations engine
- ✅ Multi-turn conversations
- ✅ Task automation

## 🔐 Security & Data Integrity

### Database Consistency
- ✅ Foreign key constraints
- ✅ Transaction rollback support
- ✅ Automatic timestamp tracking
- ✅ Status validation
- ✅ Inventory audit trail

### Error Handling
- ✅ Try-catch blocks throughout
- ✅ User-friendly error messages
- ✅ Logging & debugging
- ✅ Network error recovery
- ✅ Input validation

## 📈 Performance Optimization

### Database
- Indexed queries on frequently searched fields
- Efficient joins for related data
- Lazy loading for large datasets
- Pagination support

### UI
- Provider for state management
- Refresh indicators
- Loading states
- Shimmer effects
- Efficient rebuilds

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test --tags=widget
```

### Integration Tests
```bash
flutter test integration_test/
```

## 🛠️ Customization

### Add New Product Category
1. Update Products model
2. Add to filter options in ProductsScreen
3. Update database initialization

### Modify Brand Colors
Edit `lib/theme/hf_theme.dart`:
```dart
class HFBrandColors {
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color primaryGold = Color(0xFFD4AF37);
  // ... modify colors
}
```

### Extend Chatbot Capabilities
Update `lib/services/chatbot_service.dart`:
```dart
String _getSystemPrompt() {
  return '''Your enhanced system prompt with new capabilities''';
}
```

## 📦 Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🐛 Troubleshooting

### Database Issues
- Clear app data: `flutter clean`
- Rebuild database: Delete app and reinstall
- Check logs: `flutter logs`

### Chatbot Not Responding
- Verify API key configuration
- Check internet connection
- Review API quota limits
- Check error logs

### Export Not Working
- Ensure file permissions
- Check storage availability
- Verify Excel format
- Check file paths

## 📚 API Documentation

### Product Service
```dart
// Add product
await databaseService.addProduct(product);

// Get product
final product = await databaseService.getProduct(id);

// Get all products
final products = await databaseService.getAllProducts();

// Search products
final results = await databaseService.searchProducts(query);

// Get low stock
final lowStock = await databaseService.getLowStockProducts();
```

### Transaction Service
```dart
// Add transaction
await databaseService.addTransaction(transaction);

// Get transactions
final txns = await databaseService.getAllTransactions(
  transactionType: 'inbound',
  startDate: DateTime(2024, 1, 1),
);
```

### Export Service
```dart
// Export to Excel
final path = await ExcelExportService.exportProductsToExcel(products);
final path = await ExcelExportService.exportTransactionsToExcel(transactions);
```

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/name`
2. Commit changes: `git commit -am 'Add feature'`
3. Push to branch: `git push origin feature/name`
4. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 📞 Support

For issues, questions, or suggestions:
- Create an GitHub issue
- Contact development team
- Check documentation wiki

---

**HF Warehouse** - Professional Clothing Warehouse Management Solution
Built with Flutter | Powered by AI | Designed for Excellence