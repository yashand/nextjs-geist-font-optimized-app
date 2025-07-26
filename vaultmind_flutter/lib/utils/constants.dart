/// Utility constants used throughout the VaultMind application
class AppConstants {
  // App Information
  static const String appName = 'VaultMind';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Privacy-Focused AI Assistant';
  
  // Default Ollama Configuration
  static const String defaultOllamaUrl = 'http://100.64.0.1:11434';
  static const int defaultOllamaPort = 11434;
  
  // API Endpoints
  static const String ollamaApiGenerate = '/api/generate';
  static const String ollamaApiTags = '/api/tags';
  static const String ollamaApiPull = '/api/pull';
  static const String ollamaApiDelete = '/api/delete';
  
  // Timeouts (in seconds)
  static const int networkTimeoutSeconds = 30;
  static const int connectionTestTimeoutSeconds = 10;
  static const int speechTimeoutSeconds = 30;
  static const int speechPauseSeconds = 3;
  
  // LLM Parameters
  static const double defaultTemperature = 0.7;
  static const double defaultTopP = 0.9;
  static const int defaultTopK = 40;
  static const double minTemperature = 0.0;
  static const double maxTemperature = 2.0;
  static const double minTopP = 0.0;
  static const double maxTopP = 1.0;
  static const int minTopK = 1;
  static const int maxTopK = 100;
  
  // Speech Recognition
  static const String defaultSpeechLanguage = 'en-US';
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en-US', 'name': 'English (US)'},
    {'code': 'en-GB', 'name': 'English (UK)'},
    {'code': 'es-ES', 'name': 'Spanish'},
    {'code': 'fr-FR', 'name': 'French'},
    {'code': 'de-DE', 'name': 'German'},
    {'code': 'it-IT', 'name': 'Italian'},
    {'code': 'pt-BR', 'name': 'Portuguese (Brazil)'},
    {'code': 'ja-JP', 'name': 'Japanese'},
    {'code': 'ko-KR', 'name': 'Korean'},
    {'code': 'zh-CN', 'name': 'Chinese (Simplified)'},
  ];
  
  // UI Constants
  static const double messageBubbleBorderRadius = 18.0;
  static const double messageBubbleSmallRadius = 4.0;
  static const double avatarRadius = 16.0;
  static const double inputBorderRadius = 24.0;
  static const double cardBorderRadius = 12.0;
  
  // Storage Keys
  static const String conversationsStorageKey = 'conversations';
  static const String settingsStorageKey = 'settings';
  static const String userPreferencesKey = 'user_preferences';
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection error. Please check your internet connection.';
  static const String ollamaConnectionErrorMessage = 'Failed to connect to Ollama. Please check your server settings.';
  static const String speechPermissionErrorMessage = 'Microphone permission is required for voice input.';
  static const String speechNotAvailableErrorMessage = 'Speech recognition is not available on this device.';
  static const String genericErrorMessage = 'An unexpected error occurred. Please try again.';
  
  // Success Messages
  static const String connectionSuccessMessage = 'Successfully connected to Ollama server.';
  static const String settingsSavedMessage = 'Settings saved successfully.';
  static const String conversationDeletedMessage = 'Conversation deleted.';
  static const String allConversationsClearedMessage = 'All conversations cleared.';
  
  // Validation Rules
  static const int maxMessageLength = 10000;
  static const int maxConversationTitleLength = 100;
  static const int minPasswordLength = 8;
  
  // Feature Flags
  static const bool enableVoiceInput = true;
  static const bool enableOfflineMode = true;
  static const bool enableDarkMode = true;
  static const bool enableLogging = true;
  
  // Privacy & Security
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const bool encryptLocalStorage = false; // Would require additional setup
  
  // Performance
  static const int maxStoredConversations = 100;
  static const int maxMessagesPerConversation = 1000;
  static const int maxCachedResponses = 50;
  
  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;
  static const int splashScreenDuration = 2000;
}

/// Regular expressions for validation
class AppRegex {
  static final RegExp urlPattern = RegExp(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
  );
  
  static final RegExp ipAddressPattern = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );
  
  static final RegExp emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  static final RegExp modelNamePattern = RegExp(
    r'^[a-zA-Z0-9_-]+:[a-zA-Z0-9_.-]+$',
  );
}

/// Environment-specific configurations
class AppEnvironment {
  static const bool isDebug = true; // Would be set based on build mode
  static const bool isProduction = false;
  static const bool enableDetailedLogging = isDebug;
  static const bool enablePerformanceMonitoring = isProduction;
}