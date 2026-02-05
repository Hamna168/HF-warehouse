import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/models.dart';
import '../theme/hf_theme.dart';

class ExcelExportService {
  static Future<String> exportProductsToExcel(List<Product> products) async {
    final excelFile = excel_lib.Excel.createExcel();
    final sheet = excelFile['Products'];

    // Simple title
    sheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
        'HF WAREHOUSE - PRODUCTS INVENTORY';

    // Column Headers
    final headers = [
      'SKU',
      'Product Name',
      'Description',
      'Category',
      'Size',
      'Color',
      'Unit Price',
      'Quantity',
      'Reorder Level',
      'Status',
      'Last Updated',
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet
              .cell(
                excel_lib.CellIndex.indexByString(
                  '${String.fromCharCode(65 + i)}3',
                ),
              )
              .value =
          headers[i];
    }

    // Data rows
    for (int rowIdx = 0; rowIdx < products.length; rowIdx++) {
      final product = products[rowIdx];
      final row = rowIdx + 4;

      final values = [
        product.sku,
        product.name,
        product.description,
        product.category,
        product.size,
        product.color,
        product.price.toStringAsFixed(2),
        product.quantity.toString(),
        product.reorderLevel.toString(),
        product.status,
        product.updatedAt.toString().split('.')[0],
      ];

      for (int colIdx = 0; colIdx < values.length; colIdx++) {
        sheet
                .cell(
                  excel_lib.CellIndex.indexByString(
                    '${String.fromCharCode(65 + colIdx)}$row',
                  ),
                )
                .value =
            values[colIdx];
      }
    }

    // Save file
    return await _saveExcelFile(excelFile, 'HF_Warehouse_Inventory.xlsx');
  }

  static Future<String> exportTransactionsToExcel(
    List<InventoryTransaction> transactions,
  ) async {
    final excelFile = excel_lib.Excel.createExcel();
    final sheet = excelFile['Transactions'];

    // Simple title
    sheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
        'HF WAREHOUSE - INVENTORY TRANSACTIONS';

    // Column Headers
    final headers = [
      'Product ID',
      'Transaction Type',
      'Quantity',
      'Reason',
      'Notes',
      'Performed By',
      'Timestamp',
    ];

    for (int i = 0; i < headers.length; i++) {
      sheet
              .cell(
                excel_lib.CellIndex.indexByString(
                  '${String.fromCharCode(65 + i)}3',
                ),
              )
              .value =
          headers[i];
    }

    // Data rows
    for (int rowIdx = 0; rowIdx < transactions.length; rowIdx++) {
      final transaction = transactions[rowIdx];
      final row = rowIdx + 4;

      final values = [
        transaction.productId.toString(),
        transaction.transactionType,
        transaction.quantity.toString(),
        transaction.reason,
        transaction.notes,
        transaction.performedBy,
        transaction.timestamp.toString().split('.')[0],
      ];

      for (int colIdx = 0; colIdx < values.length; colIdx++) {
        sheet
                .cell(
                  excel_lib.CellIndex.indexByString(
                    '${String.fromCharCode(65 + colIdx)}$row',
                  ),
                )
                .value =
            values[colIdx];
      }
    }

    return await _saveExcelFile(excelFile, 'HF_Warehouse_Transactions.xlsx');
  }

  static void _createSummarySheet(
    excel_lib.Sheet sheet,
    List<Product> products,
  ) {
    // Simple title
    sheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
        'HF WAREHOUSE - INVENTORY SUMMARY';

    // Statistics
    int totalQuantity = 0;
    double totalValue = 0;
    int lowStockCount = 0;

    for (final product in products) {
      if (product.status == 'active') {
        totalQuantity += product.quantity;
        totalValue += product.price * product.quantity;
        if (product.quantity <= product.reorderLevel) {
          lowStockCount++;
        }
      }
    }

    final stats = [
      [
        'Total Active Products',
        products.where((p) => p.status == 'active').length.toString(),
      ],
      ['Total Units in Stock', totalQuantity.toString()],
      ['Total Inventory Value', '\$${totalValue.toStringAsFixed(2)}'],
      ['Low Stock Items', lowStockCount.toString()],
      ['Report Generated', DateTime.now().toString().split('.')[0]],
    ];

    for (int i = 0; i < stats.length; i++) {
      final row = i + 3;
      sheet.cell(excel_lib.CellIndex.indexByString('A$row')).value =
          stats[i][0];
      sheet.cell(excel_lib.CellIndex.indexByString('B$row')).value =
          stats[i][1];
    }
  }

  static Future<String> _saveExcelFile(
    excel_lib.Excel excelFile,
    String filename,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    final file = File(filePath);

    final fileBytes = excelFile.encode();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }
}
