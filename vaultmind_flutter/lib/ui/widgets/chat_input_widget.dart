import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/chat_service.dart';
import '../../services/speech_service.dart';
import '../../services/llm_service.dart';

/// Widget for chat input with text field and voice recognition
/// Provides interface for sending text and voice messages
class ChatInputWidget extends StatefulWidget {
  const ChatInputWidget({super.key});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  late AnimationController _micAnimationController;
  late Animation<double> _micScaleAnimation;
  late Animation<Color?> _micColorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup microphone animation
    _micAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _micScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _micColorAnimation = ColorTween(
      begin: null,
      end: Colors.red,
    ).animate(CurvedAnimation(
      parent: _micAnimationController,
      curve: Curves.easeInOut,
    ));

    // Listen to speech service changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeechService>().addListener(_onSpeechServiceChanged);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  void _onSpeechServiceChanged() {
    final speechService = context.read<SpeechService>();
    
    if (speechService.isListening) {
      _micAnimationController.repeat(reverse: true);
    } else {
      _micAnimationController.stop();
      _micAnimationController.reset();
    }
    
    // Update text field with recognized text
    if (speechService.partialText.isNotEmpty) {
      _textController.text = speechService.partialText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    } else if (speechService.recognizedText.isNotEmpty && !speechService.isListening) {
      _textController.text = speechService.recognizedText;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer3<ChatService, SpeechService, LLMService>(
            builder: (context, chatService, speechService, llmService, child) {
              return Row(
                children: [
                  // Text input field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: _getHintText(chatService, llmService),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              enabled: !chatService.isProcessingMessage,
                              onSubmitted: (text) => _sendMessage(text, chatService),
                            ),
                          ),
                          
                          // Voice input button
                          if (speechService.isAvailable)
                            _buildVoiceButton(speechService, theme),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Send button
                  _buildSendButton(chatService, theme),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton(SpeechService speechService, ThemeData theme) {
    return AnimatedBuilder(
      animation: _micAnimationController,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: speechService.isListening 
                  ? () => speechService.stopListening()
                  : () => _startVoiceInput(speechService),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Transform.scale(
                  scale: _micScaleAnimation.value,
                  child: Icon(
                    speechService.isListening 
                        ? Icons.mic 
                        : Icons.mic_none,
                    size: 20,
                    color: _micColorAnimation.value ?? 
                           theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ChatService chatService, ThemeData theme) {
    final hasText = _textController.text.trim().isNotEmpty;
    final canSend = hasText && !chatService.isProcessingMessage;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: canSend 
            ? theme.colorScheme.primary 
            : theme.colorScheme.outline.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: canSend ? () => _sendMessage(_textController.text, chatService) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: chatService.isProcessingMessage
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.send,
                    size: 20,
                    color: canSend 
                        ? theme.colorScheme.onPrimary 
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
          ),
        ),
      ),
    );
  }

  String _getHintText(ChatService chatService, LLMService llmService) {
    if (chatService.isProcessingMessage) {
      return 'AI is thinking...';
    } else if (!llmService.isConnected) {
      return 'AI assistant offline - check settings';
    } else {
      return 'Type a message...';
    }
  }

  Future<void> _sendMessage(String text, ChatService chatService) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    // Clear the text field
    _textController.clear();
    
    // Send the message
    await chatService.sendMessage(trimmedText);
    
    // Refocus on the text field
    _focusNode.requestFocus();
  }

  Future<void> _startVoiceInput(SpeechService speechService) async {
    if (!speechService.hasMicrophonePermission) {
      // Request permission first
      final granted = await speechService.requestMicrophonePermission();
      if (!granted) {
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }
    }

    try {
      await speechService.startListening(
        onResult: (recognizedText) {
          if (recognizedText.isNotEmpty) {
            // Auto-send the voice message
            context.read<ChatService>().sendMessage(recognizedText);
          }
        },
        onPartialResult: (partialText) {
          // Show partial result in text field for feedback
          setState(() {
            // The text controller is updated in _onSpeechServiceChanged
          });
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice input failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'VaultMind needs microphone access to enable voice input. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SpeechService>().requestMicrophonePermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}