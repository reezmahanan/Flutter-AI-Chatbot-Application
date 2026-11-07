import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService();
  final AIChatService _chatService = AIChatService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isLoadingHistory = true;

  final List<String> _suggestedPrompts = [
    'Explain quantum computing simply',
    'Write a Flutter counter example',
    'Tips for better productivity',
    'Tell me an interesting science fact',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _chatService.loadMessagesFromFirestore();
    if (mounted) {
      setState(() {
        if (history.isNotEmpty) {
          _messages.addAll(history);
        }
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final aiMessagePlaceholder = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(aiMessagePlaceholder);
      _isLoading = true;
    });

    _scrollToBottom();

    // Persist user message
    _chatService.saveMessage(userMessage);

    // Stream AI response
    final responseBuffer = StringBuffer();
    final aiIndex = _messages.length - 1;

    try {
      final stream = _chatService.sendMessageStream(text);

      await for (final chunk in stream) {
        responseBuffer.write(chunk);
        if (mounted) {
          setState(() {
            _messages[aiIndex] = _messages[aiIndex].copyWith(
              text: responseBuffer.toString(),
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[aiIndex] = _messages[aiIndex].copyWith(
            text: 'Error generating response: $e',
            isError: true,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        // Persist completed AI response
        _chatService.saveMessage(_messages[aiIndex]);
        _scrollToBottom();
      }
    }
  }

  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will remove all current messages from this conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _messages.clear();
      });
      _chatService.resetChatSession();
      await _chatService.clearFirestoreHistory();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ReEz AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Logged in as $displayName',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: _messages.isEmpty ? null : _clearChat,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message Area
            Expanded(
              child: _isLoadingHistory
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isLast = index == _messages.length - 1;
                            return _buildMessageBubble(
                              message,
                              isLastAndLoading: isLast && _isLoading && message.text.isEmpty,
                            );
                          },
                        ),
            ),

            // Suggested prompt chips when starting
            if (_messages.isEmpty && !_isLoadingHistory)
              _buildSuggestionsBar(),

            // Chat Input Area
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Welcome to ReEz AI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything or choose a suggestion below to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestedPrompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _suggestedPrompts[index];
          return ActionChip(
            label: Text(
              prompt,
              style: const TextStyle(fontSize: 12),
            ),
            avatar: const Icon(Icons.auto_awesome, size: 14),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {bool isLastAndLoading = false}) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? theme.colorScheme.primary
                    : (message.isError
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.surfaceContainerHighest),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: isLastAndLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : SelectableText(
                      message.text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: isUser
                            ? theme.colorScheme.onPrimary
                            : (message.isError
                                ? theme.colorScheme.onErrorContainer
                                : theme.colorScheme.onSurface),
                      ),
                    ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) {
                if (!_isLoading) _sendMessage();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            onPressed: _isLoading ? null : () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
