import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/llm_models.dart';

/// Widget for displaying individual chat messages
/// Supports both user and assistant messages with different styling
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastMessage ? 80 : 16,
        left: message.isUser ? 40 : 0,
        right: message.isUser ? 0 : 40,
      ),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(theme, false),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                _buildMessageBubble(theme),
                const SizedBox(height: 4),
                _buildMessageInfo(theme),
              ],
            ),
          ),
          
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme, true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, bool isUser) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isUser 
          ? theme.colorScheme.primary 
          : theme.colorScheme.primaryContainer,
      child: Icon(
        isUser ? Icons.person : Icons.psychology,
        size: 18,
        color: isUser 
            ? theme.colorScheme.onPrimary 
            : theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme) {
    if (message.status == MessageStatus.loading) {
      return _buildLoadingBubble(theme);
    }

    if (message.status == MessageStatus.error) {
      return _buildErrorBubble(theme);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser 
            ? theme.colorScheme.primary 
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: message.isUser ? const Radius.circular(4) : null,
          bottomLeft: !message.isUser ? const Radius.circular(4) : null,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            SelectableText(
              message.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: message.isUser 
                    ? theme.colorScheme.onPrimary 
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          
          if (!message.isUser && message.llmResponse != null)
            _buildLLMInfo(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Thinking...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBubble(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content.isNotEmpty 
                  ? message.content 
                  : 'Something went wrong',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLLMInfo(ThemeData theme) {
    final llmResponse = message.llmResponse!;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Text(
            llmResponse.model ?? 'Unknown',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
          if (llmResponse.responseTime != null) ...[
            const SizedBox(width: 8),
            Text(
              '${llmResponse.responseTime!.inMilliseconds}ms',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
          if (llmResponse.tokenCount != null) ...[
            const SizedBox(width: 8),
            Text(
              '${llmResponse.tokenCount} tokens',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInfo(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm').format(message.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        
        if (!message.isUser && message.content.isNotEmpty) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _copyToClipboard(message.content),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.copy,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}