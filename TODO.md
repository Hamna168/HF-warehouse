# TODO List for Fixing Product Form and Adding Tables

## 1. Implement AddProductScreen Form
- [x] Create a StatefulWidget for AddProductScreen with form fields for all Product model fields (sku, name, description, category, size, color, price, quantity, reorderLevel, status)
- [x] Add TextFormFields with controllers and validation
- [x] Add submit button that creates Product object, calls provider.addProduct(), and navigates back

## 2. Replace ProductsScreen ListView with DataTable
- [x] Replace ListView.builder with DataTable widget
- [x] Define DataColumn for each product field (SKU, Name, Description, Category, Size, Color, Price, Quantity, Reorder Level, Status)
- [x] Populate DataRow for each product in filteredProducts

## 3. Replace TransactionsScreen ListView with DataTable
- [x] Replace ListView.builder with DataTable widget
- [x] Define DataColumn for transaction fields (ID, Product ID, Type, Quantity, Reason, Notes, Performed By, Timestamp)
- [x] Populate DataRow for each transaction

## 4. Replace StockMovementsScreen ListView with DataTable
- [x] Replace ListView.builder with DataTable widget
- [x] Define DataColumn for movement fields (ID, Product ID, Quantity Moved, From Location, To Location, Status, Moved By, Created At, Completed At)
- [x] Populate DataRow for each movement

## 5. Testing
- [ ] Run the app and test adding a product via the form
- [ ] Verify products appear in the table on ProductsScreen
- [ ] Check tables on Transactions and StockMovements screens display data correctly
