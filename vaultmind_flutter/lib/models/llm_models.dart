import 'package:uuid/uuid.dart';

/// Response from LLM service
class LLMResponse {
  final String content;
  final String? model;
  final String? conversationId;
  final Map<String, dynamic>? context;
  final int? tokenCount;
  final Duration? responseTime;
  final bool isError;
  final bool isOffline;
  final String? errorMessage;

  const LLMResponse({
    required this.content,
    this.model,
    this.conversationId,
    this.context,
    this.tokenCount,
    this.responseTime,
    this.isError = false,
    this.isOffline = false,
    this.errorMessage,
  });

  /// Creates an error response
  factory LLMResponse.error(String message, {bool isOffline = false}) {
    return LLMResponse(
      content: '',
      isError: true,
      isOffline: isOffline,
      errorMessage: message,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'model': model,
      'conversationId': conversationId,
      'context': context,
      'tokenCount': tokenCount,
      'responseTime': responseTime?.inMilliseconds,
      'isError': isError,
      'isOffline': isOffline,
      'errorMessage': errorMessage,
    };
  }

  /// Creates from JSON
  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      content: json['content'] as String? ?? '',
      model: json['model'] as String?,
      conversationId: json['conversationId'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      tokenCount: json['tokenCount'] as int?,
      responseTime: json['responseTime'] != null 
          ? Duration(milliseconds: json['responseTime'] as int)
          : null,
      isError: json['isError'] as bool? ?? false,
      isOffline: json['isOffline'] as bool? ?? false,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? conversationId;
  final MessageStatus status;
  final LLMResponse? llmResponse;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.conversationId,
    this.status = MessageStatus.sent,
    this.llmResponse,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Creates a user message
  factory ChatMessage.user(String content, {String? conversationId}) {
    return ChatMessage(
      content: content,
      isUser: true,
      conversationId: conversationId,
    );
  }

  /// Creates an assistant message
  factory ChatMessage.assistant(
    String content, {
    String? conversationId,
    LLMResponse? llmResponse,
  }) {
    return ChatMessage(
      content: content,
      isUser: false,
      conversationId: conversationId,
      llmResponse: llmResponse,
    );
  }

  /// Creates a loading message
  factory ChatMessage.loading({String? conversationId}) {
    return ChatMessage(
      content: '',
      isUser: false,
      conversationId: conversationId,
      status: MessageStatus.loading,
    );
  }

  /// Creates an error message
  factory ChatMessage.error(String error, {String? conversationId}) {
    return ChatMessage(
      content: error,
      isUser: false,
      conversationId: conversationId,
      status: MessageStatus.error,
    );
  }

  /// Creates a copy with updated fields
  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    LLMResponse? llmResponse,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      conversationId: conversationId,
      status: status ?? this.status,
      llmResponse: llmResponse ?? this.llmResponse,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'conversationId': conversationId,
      'status': status.index,
      'llmResponse': llmResponse?.toJson(),
    };
  }

  /// Creates from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      conversationId: json['conversationId'] as String?,
      status: MessageStatus.values[json['status'] as int? ?? 0],
      llmResponse: json['llmResponse'] != null
          ? LLMResponse.fromJson(json['llmResponse'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Status of a chat message
enum MessageStatus {
  sent,
  loading,
  delivered,
  error,
}

/// Chat conversation model
class ChatConversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;
  final Map<String, dynamic>? metadata;

  ChatConversation({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        lastMessageAt = lastMessageAt ?? DateTime.now(),
        messages = messages ?? [];

  /// Creates a copy with updated fields
  ChatConversation copyWith({
    String? title,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return ChatConversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Adds a message to the conversation
  ChatConversation addMessage(ChatMessage message) {
    final updatedMessages = List<ChatMessage>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      lastMessageAt: message.timestamp,
    );
  }

  /// Updates a message in the conversation
  ChatConversation updateMessage(String messageId, ChatMessage updatedMessage) {
    final updatedMessages = messages.map((msg) {
      return msg.id == messageId ? updatedMessage : msg;
    }).toList();
    
    return copyWith(messages: updatedMessages);
  }

  /// Gets the last message
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Gets the message count
  int get messageCount => messages.length;

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'metadata': metadata,
    };
  }

  /// Creates from JSON
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastMessageAt: DateTime.parse(json['lastMessageAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
          ?.map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}