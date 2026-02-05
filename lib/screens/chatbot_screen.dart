import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../theme/hf_theme.dart';
import '../services/chatbot_service.dart';
import 'app_config.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  late WarehouseChatbotService _chatbotService;
  final List<ChatMessage> _messages = [];
  late ChatUser _currentUser;
  late ChatUser _botUser;
  bool _isInitialized = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
  }

  void _initializeChatbot() {
    _currentUser = ChatUser(id: '1', firstName: 'You', profileImage: null);

    _botUser = ChatUser(id: '2', firstName: 'HF Assistant', profileImage: null);

    // Initialize with your API key
    // Note: In production, store API key securely
    try {
      _chatbotService = WarehouseChatbotService(
        apiKey: AppConfig.GOOGLE_API_KEY,
      );
      _isInitialized = true;

      // Add welcome message
      _addBotMessage(
        'Hello! I\'m your HF Warehouse Assistant. I can help you with:\n\n'
        '📦 Inventory management\n'
        '📊 Warehouse statistics\n'
        '🔄 Stock movements\n'
        '📈 Product analytics\n'
        '🤖 Task automation\n\n'
        'How can I assist you today?',
      );
    } catch (e) {
      _initError = 'Failed to initialize chatbot. Please check your API key.';
      _addBotMessage(
        'Sorry, I\'m unable to connect right now. Please try again later.',
      );
    }
  }

  void _addBotMessage(String text) {
    final message = ChatMessage(
      text: text,
      user: _botUser,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<void> _handleSendPressed(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
    });

    if (!_isInitialized) {
      _addBotMessage('Chatbot is not properly initialized.');
      return;
    }

    // Show loading state
    final loadingMessage = ChatMessage(
      text: 'Processing...',
      user: _botUser,
      createdAt: DateTime.now(),
      isMarkdown: true,
    );

    setState(() {
      _messages.insert(0, loadingMessage);
    });

    try {
      final response = await _chatbotService.sendMessage(message.text);

      // Remove loading message
      setState(() {
        _messages.removeWhere((m) => m.text == 'Processing...');
      });

      _addBotMessage(response);
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m.text == 'Processing...');
      });
      _addBotMessage(
        'Error: Unable to process your message. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HF Warehouse Assistant'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _chatbotService.clearHistory();
              });
              _initializeChatbot();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showChatbotInfo();
            },
          ),
        ],
      ),
      body: _buildChatUI(),
    );
  }

  Widget _buildChatUI() {
    if (_initError != null && !_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: HFBrandColors.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Initialization Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _initError!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _initError = null;
                });
                _initializeChatbot();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DashChat(
      currentUser: _currentUser,
      onSend: _handleSendPressed,
      messages: _messages,
      messageOptions: MessageOptions(
        currentUserContainerColor: HFBrandColors.primaryBlack,
        containerColor: HFBrandColors.lightGray,
        textColor: HFBrandColors.primaryBlack,
        currentUserTextColor: HFBrandColors.accentWhite,
      ),
      inputOptions: InputOptions(
        inputDecoration: InputDecoration(
          hintText: 'Ask about inventory, stock, or warehouse operations...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: HFBrandColors.borderColor),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        inputTextStyle: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  void _showChatbotInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HF Warehouse Assistant'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Capabilities:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '✓ Check inventory levels and product details\n'
                '✓ Generate warehouse reports\n'
                '✓ Identify low stock items\n'
                '✓ Provide reordering recommendations\n'
                '✓ Analyze product performance\n'
                '✓ Log inventory transactions\n'
                '✓ Plan stock movements\n'
                '✓ Answer warehouse questions',
              ),
              const SizedBox(height: 16),
              Text(
                'Example Queries:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '"What products are low on stock?"\n'
                '"Show me inventory summary"\n'
                '"Analyze product performance"\n'
                '"What should I reorder?"\n'
                '"Create a new inventory transaction"',
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
}
