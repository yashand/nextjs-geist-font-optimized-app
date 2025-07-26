import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/connectivity_service.dart';
import '../../services/llm_service.dart';

/// Widget that displays connection status at the top of the chat screen
/// Shows network and LLM connection status with appropriate colors and icons
class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityService, LLMService>(
      builder: (context, connectivityService, llmService, child) {
        // Don't show anything if everything is connected
        if (connectivityService.isConnected && llmService.isConnected) {
          return const SizedBox.shrink();
        }

        return _buildStatusBanner(context, connectivityService, llmService);
      },
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    ConnectivityService connectivityService,
    LLMService llmService,
  ) {
    final theme = Theme.of(context);
    
    String message;
    Color backgroundColor;
    IconData icon;
    bool showAction = false;

    if (!connectivityService.isConnected) {
      message = 'No internet connection';
      backgroundColor = theme.colorScheme.error;
      icon = Icons.wifi_off;
    } else if (llmService.isConnecting) {
      message = 'Connecting to AI assistant...';
      backgroundColor = theme.colorScheme.tertiary;
      icon = Icons.hourglass_empty;
    } else if (!llmService.isConnected) {
      message = llmService.connectionError ?? 'AI assistant offline';
      backgroundColor = theme.colorScheme.error;
      icon = Icons.psychology_alt;
      showAction = true;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: theme.colorScheme.onError,
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            if (showAction) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _handleRetryAction(context, llmService),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
            
            if (llmService.isConnecting) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onError,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleRetryAction(BuildContext context, LLMService llmService) {
    llmService.refresh();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attempting to reconnect...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}