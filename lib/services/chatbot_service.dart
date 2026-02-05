import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/models.dart';
import 'database_service.dart';

class WarehouseChatbotService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final DatabaseService _dbService = DatabaseService();
  List<Content> _conversationHistory = [];

  WarehouseChatbotService({required String apiKey}) {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
      systemInstruction: Content.system(_getSystemPrompt()),
    );
    _initializeChat();
  }

  void _initializeChat() {
    _chatSession = _model.startChat(history: _conversationHistory);
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      final response = await _chatSession.sendMessage(
        Content.text(userMessage),
      );

      final assistantMessage = response.text ?? 'No response generated';

      _conversationHistory.add(Content.text(userMessage));
      _conversationHistory.add(Content.model([TextPart(assistantMessage)]));

      return assistantMessage;
    } catch (e) {
      print('Chatbot Error: $e');
      return 'Error: Unable to process your request. Please try again.';
    }
  }

  String _getSystemPrompt() {
    return '''You are an intelligent warehouse management assistant for HF Warehouse (a clothing warehouse business). 
Your role is to help warehouse staff and managers with:

1. INVENTORY MANAGEMENT
   - Check product availability and stock levels
   - Suggest reordering for low stock items
   - Track inventory movements and transactions
   - Identify slow-moving inventory

2. WAREHOUSE OPERATIONS
   - Help plan stock movements between locations
   - Optimize warehouse space usage
   - Generate reports on warehouse efficiency
   - Identify bottlenecks in operations

3. DATA ANALYTICS
   - Provide insights on sales trends
   - Analyze product performance
   - Suggest inventory optimization strategies
   - Generate actionable recommendations

4. AUTOMATION TASKS
   - Create product entries
   - Log inventory transactions
   - Generate inventory reports
   - Schedule routine maintenance checks

You have access to the warehouse database and can provide real-time information about:
- Product details (SKU, name, quantity, price, category, size, color)
- Inventory transactions (inbound, outbound, adjustments)
- Stock movements between locations
- Warehouse statistics and metrics

Guidelines:
- Be concise but thorough in your responses
- Always provide actionable insights
- When suggesting actions, explain the reasoning
- Use data to support your recommendations
- For complex tasks, break them down into steps
- Maintain a professional but friendly tone
- If you don't have specific data, offer to help gather it

For task automation, support common warehouse operations like:
- Adding new products: Provide product details in structured format
- Creating stock movements: Confirm source and destination
- Generating reports: Specify report type and date range
- Updating inventory: Confirm quantities and reasons''';
  }

  Future<String> getInventorySummary() async {
    final stats = await _dbService.getWarehouseStats();
    final lowStockProducts = await _dbService.getLowStockProducts();

    return '''WAREHOUSE INVENTORY SUMMARY:
    
Total Active Products: ${stats['totalProducts']}
Total Units in Stock: ${stats['totalQuantity']}
Total Inventory Value: \$${stats['totalValue'].toStringAsFixed(2)}
Low Stock Items: ${stats['lowStockCount']}

${lowStockProducts.isNotEmpty ? 'LOW STOCK ALERTS:\n' + lowStockProducts.map((p) => '- ${p.name} (${p.quantity}/${p.reorderLevel})').join('\n') : 'No low stock items.'}''';
  }

  Future<String> generateProductRecommendations() async {
    final lowStockProducts = await _dbService.getLowStockProducts();

    if (lowStockProducts.isEmpty) {
      return 'All products are well-stocked. No reordering needed at this time.';
    }

    String recommendations = 'REORDERING RECOMMENDATIONS:\n\n';
    for (final product in lowStockProducts) {
      final shortage = product.reorderLevel - product.quantity;
      recommendations +=
          '• ${product.name} (SKU: ${product.sku})\n  Current: ${product.quantity} units\n  Reorder Level: ${product.reorderLevel}\n  Recommended Order: ${shortage + 50} units\n\n';
    }

    return recommendations;
  }

  Future<String> analyzeProductPerformance() async {
    final allProducts = await _dbService.getAllProducts();

    final highValue =
        allProducts.where((p) => (p.price * p.quantity) > 1000).toList()..sort(
          (a, b) => (b.price * b.quantity).compareTo(a.price * a.quantity),
        );

    final lowMovement = allProducts
        .where((p) => p.quantity > p.reorderLevel * 2)
        .toList();

    String analysis = 'PRODUCT PERFORMANCE ANALYSIS:\n\n';
    analysis += 'HIGH VALUE ITEMS (Top 5):\n';
    for (int i = 0; i < (highValue.length > 5 ? 5 : highValue.length); i++) {
      final p = highValue[i];
      analysis +=
          '${i + 1}. ${p.name} - \$${(p.price * p.quantity).toStringAsFixed(2)}\n';
    }

    analysis += '\nSLOW-MOVING INVENTORY:\n';
    if (lowMovement.isNotEmpty) {
      for (
        int i = 0;
        i < (lowMovement.length > 5 ? 5 : lowMovement.length);
        i++
      ) {
        final p = lowMovement[i];
        analysis +=
            '• ${p.name} - ${p.quantity} units (Excess: ${p.quantity - p.reorderLevel})\n';
      }
    } else {
      analysis += 'No slow-moving inventory detected.\n';
    }

    return analysis;
  }

  void clearHistory() {
    _conversationHistory.clear();
    _initializeChat();
  }

  List<Content> getConversationHistory() {
    return List.from(_conversationHistory);
  }
}
