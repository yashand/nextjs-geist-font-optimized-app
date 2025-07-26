import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'llm_service.dart';
import 'speech_service.dart';
import 'storage_service.dart';
import '../models/llm_models.dart';

/// Service for managing chat conversations and interactions
/// Coordinates between LLM, speech, and storage services
class ChatService extends ChangeNotifier {
  final LLMService _llmService;
  final SpeechService _speechService;
  final StorageService _storageService;
  final Logger _logger;

  ChatConversation? _currentConversation;
  List<ChatConversation> _conversations = [];
  bool _isProcessingMessage = false;
  String? _currentRequestId;

  static const String _conversationsKey = 'conversations';

  ChatService({
    required LLMService llmService,
    required SpeechService speechService,
    required StorageService storageService,
    required Logger logger,
  })  : _llmService = llmService,
        _speechService = speechService,
        _storageService = storageService,
        _logger = logger {
    _initializeService();
  }

  // Getters
  ChatConversation? get currentConversation => _currentConversation;
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  bool get isProcessingMessage => _isProcessingMessage;
  List<ChatMessage> get currentMessages => _currentConversation?.messages ?? [];
  bool get canSendMessage => !_isProcessingMessage && _llmService.isConnected;

  /// Initializes the chat service
  void _initializeService() {
    _loadConversations();
    
    // Listen to LLM service changes
    _llmService.addListener(_onLLMServiceChanged);
  }

  /// Handles LLM service state changes
  void _onLLMServiceChanged() {
    notifyListeners();
  }

  /// Loads conversations from storage
  Future<void> _loadConversations() async {
    try {
      final conversationIds = _storageService.getAllChatIds();
      _conversations = [];

      for (final id in conversationIds) {
        final messages = _storageService.getChatMessages(id);
        if (messages.isNotEmpty) {
          final conversation = ChatConversation(
            id: id,
            title: _generateConversationTitle(messages),
            messages: messages.map((msgData) => ChatMessage.fromJson(msgData)).toList(),
          );
          _conversations.add(conversation);
        }
      }

      // Sort conversations by last message time
      _conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      _logger.i('Loaded ${_conversations.length} conversations');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to load conversations', error: error);
    }
  }

  /// Creates a new conversation
  ChatConversation createNewConversation({String? title}) {
    final conversation = ChatConversation(
      title: title ?? 'New Chat',
    );

    _conversations.insert(0, conversation);
    _currentConversation = conversation;
    
    _logger.i('Created new conversation: ${conversation.id}');
    notifyListeners();
    
    return conversation;
  }

  /// Sets the current active conversation
  void setCurrentConversation(String conversationId) {
    final conversation = _conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => createNewConversation(),
    );

    _currentConversation = conversation;
    _logger.i('Switched to conversation: $conversationId');
    notifyListeners();
  }

  /// Sends a text message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Ensure we have a current conversation
    _currentConversation ??= createNewConversation();

    final userMessage = ChatMessage.user(
      text.trim(),
      conversationId: _currentConversation!.id,
    );

    // Add user message
    _addMessage(userMessage);

    // Show loading indicator
    final loadingMessage = ChatMessage.loading(
      conversationId: _currentConversation!.id,
    );
    _addMessage(loadingMessage);

    await _processUserMessage(text.trim(), loadingMessage.id);
  }

  /// Sends a voice message using speech-to-text
  Future<void> sendVoiceMessage() async {
    if (!_speechService.isAvailable) {
      _logger.w('Speech service not available');
      return;
    }

    try {
      await _speechService.startListening(
        onResult: (recognizedText) {
          if (recognizedText.isNotEmpty) {
            sendMessage(recognizedText);
          }
        },
      );
    } catch (error) {
      _logger.e('Failed to start voice message', error: error);
    }
  }

  /// Processes user message and gets LLM response
  Future<void> _processUserMessage(String userText, String loadingMessageId) async {
    _isProcessingMessage = true;
    _currentRequestId = DateTime.now().millisecondsSinceEpoch.toString();
    notifyListeners();

    try {
      // Get conversation context (last few messages for context)
      final context = _buildConversationContext();

      // Send to LLM
      final llmResponse = await _llmService.sendMessage(
        userText,
        conversationId: _currentConversation!.id,
        context: context,
      );

      // Remove loading message and add actual response
      _removeMessage(loadingMessageId);

      if (llmResponse.isError) {
        final errorMessage = ChatMessage.error(
          llmResponse.errorMessage ?? 'Failed to get response',
          conversationId: _currentConversation!.id,
        );
        _addMessage(errorMessage);
      } else {
        final assistantMessage = ChatMessage.assistant(
          llmResponse.content,
          conversationId: _currentConversation!.id,
          llmResponse: llmResponse,
        );
        _addMessage(assistantMessage);

        // Update conversation title if this is the first exchange
        if (_currentConversation!.messages.where((m) => m.isUser).length == 1) {
          await _updateConversationTitle(userText);
        }
      }
    } catch (error) {
      _logger.e('Failed to process user message', error: error);
      
      // Remove loading message and show error
      _removeMessage(loadingMessageId);
      final errorMessage = ChatMessage.error(
        'Failed to send message. Please try again.',
        conversationId: _currentConversation!.id,
      );
      _addMessage(errorMessage);
    } finally {
      _isProcessingMessage = false;
      _currentRequestId = null;
      notifyListeners();
    }
  }

  /// Builds conversation context for LLM
  Map<String, dynamic> _buildConversationContext() {
    const maxContextMessages = 10;
    final recentMessages = _currentConversation!.messages
        .where((m) => m.status != MessageStatus.loading)
        .take(maxContextMessages)
        .map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        })
        .toList();

    return {
      'messages': recentMessages,
      'conversationId': _currentConversation!.id,
    };
  }

  /// Adds a message to the current conversation
  void _addMessage(ChatMessage message) {
    if (_currentConversation == null) return;

    _currentConversation = _currentConversation!.addMessage(message);
    
    // Update conversations list
    final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (index >= 0) {
      _conversations[index] = _currentConversation!;
    }

    // Save to storage
    _saveMessage(message);
    
    notifyListeners();
  }

  /// Removes a message from the current conversation
  void _removeMessage(String messageId) {
    if (_currentConversation == null) return;

    final updatedMessages = _currentConversation!.messages
        .where((m) => m.id != messageId)
        .toList();
    
    _currentConversation = _currentConversation!.copyWith(messages: updatedMessages);
    
    // Update conversations list
    final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (index >= 0) {
      _conversations[index] = _currentConversation!;
    }

    // Update storage
    _saveConversation(_currentConversation!);
    
    notifyListeners();
  }

  /// Saves a message to storage
  Future<void> _saveMessage(ChatMessage message) async {
    try {
      await _storageService.saveChatMessage(
        _currentConversation!.id,
        message.toJson(),
      );
    } catch (error) {
      _logger.e('Failed to save message', error: error);
    }
  }

  /// Saves entire conversation to storage
  Future<void> _saveConversation(ChatConversation conversation) async {
    try {
      // Clear existing messages for this conversation
      await _storageService.deleteChatMessages(conversation.id);
      
      // Save all messages
      for (final message in conversation.messages) {
        await _storageService.saveChatMessage(conversation.id, message.toJson());
      }
    } catch (error) {
      _logger.e('Failed to save conversation', error: error);
    }
  }

  /// Updates conversation title based on first message
  Future<void> _updateConversationTitle(String firstMessage) async {
    if (_currentConversation == null) return;

    final title = _generateTitleFromMessage(firstMessage);
    _currentConversation = _currentConversation!.copyWith(title: title);
    
    // Update conversations list
    final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (index >= 0) {
      _conversations[index] = _currentConversation!;
    }

    notifyListeners();
  }

  /// Generates a conversation title from the first message
  String _generateTitleFromMessage(String message) {
    final words = message.split(' ').take(5).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }

  /// Generates a conversation title from messages
  String _generateConversationTitle(List<Map<String, dynamic>> messages) {
    if (messages.isEmpty) return 'Empty Chat';
    
    final firstUserMessage = messages.firstWhere(
      (msg) => msg['isUser'] == true,
      orElse: () => messages.first,
    );
    
    return _generateTitleFromMessage(firstUserMessage['content'] as String? ?? 'Chat');
  }

  /// Deletes a conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _storageService.deleteChatMessages(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      
      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
      }
      
      _logger.i('Deleted conversation: $conversationId');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to delete conversation', error: error);
    }
  }

  /// Clears all conversations
  Future<void> clearAllConversations() async {
    try {
      for (final conversation in _conversations) {
        await _storageService.deleteChatMessages(conversation.id);
      }
      
      _conversations.clear();
      _currentConversation = null;
      
      _logger.i('Cleared all conversations');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to clear conversations', error: error);
    }
  }

  /// Cancels current message processing
  void cancelCurrentMessage() {
    if (_currentRequestId != null) {
      _llmService.cancelRequest(_currentRequestId);
      _isProcessingMessage = false;
      _currentRequestId = null;
      
      // Remove any loading messages
      if (_currentConversation != null) {
        final updatedMessages = _currentConversation!.messages
            .where((m) => m.status != MessageStatus.loading)
            .toList();
        
        _currentConversation = _currentConversation!.copyWith(messages: updatedMessages);
        _saveConversation(_currentConversation!);
      }
      
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _llmService.removeListener(_onLLMServiceChanged);
    cancelCurrentMessage();
    super.dispose();
  }
}