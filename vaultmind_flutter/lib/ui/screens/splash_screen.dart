import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../services/llm_service.dart';
import '../../services/connectivity_service.dart';

/// Splash screen that shows during app initialization
/// Handles initial setup and navigation to main app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Start animation
    _animationController.forward();

    // Navigate after delay
    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    // Wait for animation and minimum splash time
    await Future.wait([
      _animationController.forward(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (mounted) {
      context.go('/chat');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon/logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.psychology_rounded,
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App name
                    Text(
                      'VaultMind',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Tagline
                    Text(
                      'Privacy-Focused AI Assistant',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Loading indicator and status
                    _BuildConnectionStatus(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Widget that shows connection status during splash
class _BuildConnectionStatus extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer2<ConnectivityService, LLMService>(
      builder: (context, connectivityService, llmService, child) {
        String statusText;
        Color statusColor;
        Widget statusIcon;

        if (!connectivityService.isConnected) {
          statusText = 'No network connection';
          statusColor = theme.colorScheme.error;
          statusIcon = Icon(
            Icons.wifi_off,
            color: statusColor,
            size: 20,
          );
        } else if (llmService.isConnecting) {
          statusText = 'Connecting to AI...';
          statusColor = theme.colorScheme.onPrimary;
          statusIcon = SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          );
        } else if (llmService.isConnected) {
          statusText = 'Connected';
          statusColor = theme.colorScheme.onPrimary;
          statusIcon = Icon(
            Icons.check_circle,
            color: statusColor,
            size: 20,
          );
        } else {
          statusText = 'Offline mode';
          statusColor = theme.colorScheme.onPrimary.withOpacity(0.7);
          statusIcon = Icon(
            Icons.cloud_off,
            color: statusColor,
            size: 20,
          );
        }

        return Column(
          children: [
            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                statusIcon,
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Loading bar
            if (connectivityService.isConnected && (llmService.isConnecting || !llmService.isConnected))
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}