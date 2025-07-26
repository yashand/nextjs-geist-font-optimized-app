import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../services/chat_service.dart';
import '../../services/llm_service.dart';
import '../../services/speech_service.dart';
import '../../services/connectivity_service.dart';
import '../../models/llm_models.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/connection_status_widget.dart';

/// Main chat screen for interacting with the AI assistant
/// Displays conversation messages and handles user input
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Ensure we have a current conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = context.read<ChatService>();
      if (chatService.currentConversation == null) {
        chatService.createNewConversation();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(theme),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          // Connection status banner
          const ConnectionStatusWidget(),
          
          // Chat messages
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                final messages = chatService.currentMessages;
                
                if (messages.isEmpty) {
                  return _buildEmptyState(theme);
                }

                // Auto-scroll when new messages are added
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatMessageWidget(
                      message: message,
                      isLastMessage: index == messages.length - 1,
                    );
                  },
                );
              },
            ),
          ),
          
          // Chat input
          const ChatInputWidget(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Consumer<ChatService>(
        builder: (context, chatService, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatService.currentConversation?.title ?? 'VaultMind',
                style: theme.textTheme.titleLarge,
              ),
              Consumer<LLMService>(
                builder: (context, llmService, child) {
                  if (llmService.isConnected && llmService.currentModel != null) {
                    return Text(
                      llmService.currentModel!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    );
                  }
                  return Text(
                    'Offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      actions: [
        // Refresh connection
        Consumer<LLMService>(
          builder: (context, llmService, child) {
            return IconButton(
              icon: Icon(llmService.isConnecting 
                  ? Icons.hourglass_empty 
                  : Icons.refresh),
              onPressed: llmService.isConnecting ? null : () {
                llmService.refresh();
              },
              tooltip: 'Refresh connection',
            );
          },
        ),
        
        // Settings
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.go('/settings'),
          tooltip: 'Settings',
        ),
        
        // Menu
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
            tooltip: 'More options',
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Consumer<ChatService>(
        builder: (context, chatService, child) {
          return Column(
            children: [
              // Drawer header
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.psychology_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'VaultMind',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${chatService.conversations.length} conversations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              
              // New conversation
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New Conversation'),
                onTap: () {
                  chatService.createNewConversation();
                  Navigator.of(context).pop();
                },
              ),
              
              const Divider(),
              
              // Conversation list
              Expanded(
                child: ListView.builder(
                  itemCount: chatService.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = chatService.conversations[index];
                    final isSelected = chatService.currentConversation?.id == conversation.id;
                    
                    return ListTile(
                      selected: isSelected,
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(
                        conversation.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${conversation.messageCount} messages',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'delete') {
                            _showDeleteConversationDialog(conversation.id);
                          }
                        },
                      ),
                      onTap: () {
                        chatService.setCurrentConversation(conversation.id);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              
              const Divider(),
              
              // Settings and clear all
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/settings');
                },
              ),
              
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear All Chats'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showClearAllDialog();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.psychology_rounded,
                size: 50,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Welcome to VaultMind',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Your privacy-focused AI assistant powered by Ollama',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Consumer<LLMService>(
              builder: (context, llmService, child) {
                if (!llmService.isConnected) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 32,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI Assistant Offline',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check your Ollama connection in settings',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Text(
                  'Start a conversation by typing a message below',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Refresh Connection'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<LLMService>().refresh();
            },
          ),
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text('Clear Current Chat'),
            onTap: () {
              Navigator.of(context).pop();
              _showClearCurrentChatDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              context.go('/settings');
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConversationDialog(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ChatService>().deleteConversation(conversationId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text('Are you sure you want to delete all conversations? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ChatService>().clearAllConversations();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showClearCurrentChatDialog() {
    final chatService = context.read<ChatService>();
    if (chatService.currentConversation == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Current Chat'),
        content: const Text('Are you sure you want to clear the current conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              chatService.deleteConversation(chatService.currentConversation!.id);
              chatService.createNewConversation();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}