import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import 'storage_service.dart';

/// Service for managing application settings
/// Handles both user preferences and system configuration
class SettingsService extends ChangeNotifier {
  final StorageService _storageService;
  final Logger _logger;

  // Settings keys
  static const String _ollamaUrlKey = 'ollama_url';
  static const String _currentModelKey = 'current_model';
  static const String _temperatureKey = 'temperature';
  static const String _topPKey = 'top_p';
  static const String _topKKey = 'top_k';
  static const String _speechEnabledKey = 'speech_enabled';
  static const String _autoSpeechKey = 'auto_speech';
  static const String _speechLanguageKey = 'speech_language';
  static const String _darkModeKey = 'dark_mode';
  static const String _offlineModeKey = 'offline_mode';
  static const String _loggingLevelKey = 'logging_level';

  // Default values
  static const String _defaultOllamaUrl = 'http://100.64.0.1:11434'; // Default Tailscale IP
  static const double _defaultTemperature = 0.7;
  static const double _defaultTopP = 0.9;
  static const int _defaultTopK = 40;
  static const bool _defaultSpeechEnabled = true;
  static const bool _defaultAutoSpeech = false;
  static const String _defaultSpeechLanguage = 'en-US';
  static const bool _defaultDarkMode = false;
  static const bool _defaultOfflineMode = false;
  static const String _defaultLoggingLevel = 'info';

  // Current values
  String? _ollamaUrl;
  String? _currentModel;
  double _temperature = _defaultTemperature;
  double _topP = _defaultTopP;
  int _topK = _defaultTopK;
  bool _speechEnabled = _defaultSpeechEnabled;
  bool _autoSpeech = _defaultAutoSpeech;
  String _speechLanguage = _defaultSpeechLanguage;
  bool _darkMode = _defaultDarkMode;
  bool _offlineMode = _defaultOfflineMode;
  String _loggingLevel = _defaultLoggingLevel;

  SettingsService({
    required StorageService storageService,
    required Logger logger,
  })  : _storageService = storageService,
        _logger = logger;

  // Getters
  String? get ollamaUrl => _ollamaUrl;
  String? get currentModel => _currentModel;
  double get temperature => _temperature;
  double get topP => _topP;
  int get topK => _topK;
  bool get speechEnabled => _speechEnabled;
  bool get autoSpeech => _autoSpeech;
  String get speechLanguage => _speechLanguage;
  bool get darkMode => _darkMode;
  bool get offlineMode => _offlineMode;
  String get loggingLevel => _loggingLevel;

  /// Initializes settings by loading from storage
  Future<void> initialize() async {
    try {
      _ollamaUrl = _storageService.getSetting(_ollamaUrlKey, defaultValue: _defaultOllamaUrl);
      _currentModel = _storageService.getSetting(_currentModelKey);
      _temperature = _storageService.getSetting(_temperatureKey, defaultValue: _defaultTemperature);
      _topP = _storageService.getSetting(_topPKey, defaultValue: _defaultTopP);
      _topK = _storageService.getSetting(_topKKey, defaultValue: _defaultTopK);
      _speechEnabled = _storageService.getSetting(_speechEnabledKey, defaultValue: _defaultSpeechEnabled);
      _autoSpeech = _storageService.getSetting(_autoSpeechKey, defaultValue: _defaultAutoSpeech);
      _speechLanguage = _storageService.getSetting(_speechLanguageKey, defaultValue: _defaultSpeechLanguage);
      _darkMode = _storageService.getSetting(_darkModeKey, defaultValue: _defaultDarkMode);
      _offlineMode = _storageService.getSetting(_offlineModeKey, defaultValue: _defaultOfflineMode);
      _loggingLevel = _storageService.getSetting(_loggingLevelKey, defaultValue: _defaultLoggingLevel);

      _logger.i('Settings initialized successfully');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to initialize settings', error: error);
      rethrow;
    }
  }

  // Setters with validation and persistence

  /// Sets the Ollama server URL
  Future<void> setOllamaUrl(String url) async {
    if (url.isEmpty) {
      throw ArgumentError('Ollama URL cannot be empty');
    }

    // Basic URL validation
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.hasScheme || !uri.hasAuthority)) {
      throw ArgumentError('Invalid URL format');
    }

    _ollamaUrl = url;
    await _storageService.saveSetting(_ollamaUrlKey, url);
    notifyListeners();
    _logger.i('Ollama URL updated to: $url');
  }

  /// Sets the current LLM model
  Future<void> setCurrentModel(String model) async {
    if (model.isEmpty) {
      throw ArgumentError('Model name cannot be empty');
    }

    _currentModel = model;
    await _storageService.saveSetting(_currentModelKey, model);
    notifyListeners();
    _logger.i('Current model updated to: $model');
  }

  /// Sets the temperature for LLM generation (0.0 - 2.0)
  Future<void> setTemperature(double temperature) async {
    if (temperature < 0.0 || temperature > 2.0) {
      throw ArgumentError('Temperature must be between 0.0 and 2.0');
    }

    _temperature = temperature;
    await _storageService.saveSetting(_temperatureKey, temperature);
    notifyListeners();
    _logger.i('Temperature updated to: $temperature');
  }

  /// Sets the top_p for LLM generation (0.0 - 1.0)
  Future<void> setTopP(double topP) async {
    if (topP < 0.0 || topP > 1.0) {
      throw ArgumentError('Top P must be between 0.0 and 1.0');
    }

    _topP = topP;
    await _storageService.saveSetting(_topPKey, topP);
    notifyListeners();
    _logger.i('Top P updated to: $topP');
  }

  /// Sets the top_k for LLM generation
  Future<void> setTopK(int topK) async {
    if (topK < 1 || topK > 100) {
      throw ArgumentError('Top K must be between 1 and 100');
    }

    _topK = topK;
    await _storageService.saveSetting(_topKKey, topK);
    notifyListeners();
    _logger.i('Top K updated to: $topK');
  }

  /// Enables or disables speech functionality
  Future<void> setSpeechEnabled(bool enabled) async {
    _speechEnabled = enabled;
    await _storageService.saveSetting(_speechEnabledKey, enabled);
    notifyListeners();
    _logger.i('Speech enabled: $enabled');
  }

  /// Enables or disables automatic speech recognition
  Future<void> setAutoSpeech(bool enabled) async {
    _autoSpeech = enabled;
    await _storageService.saveSetting(_autoSpeechKey, enabled);
    notifyListeners();
    _logger.i('Auto speech: $enabled');
  }

  /// Sets the speech recognition language
  Future<void> setSpeechLanguage(String language) async {
    if (language.isEmpty) {
      throw ArgumentError('Speech language cannot be empty');
    }

    _speechLanguage = language;
    await _storageService.saveSetting(_speechLanguageKey, language);
    notifyListeners();
    _logger.i('Speech language updated to: $language');
  }

  /// Enables or disables dark mode
  Future<void> setDarkMode(bool enabled) async {
    _darkMode = enabled;
    await _storageService.saveSetting(_darkModeKey, enabled);
    notifyListeners();
    _logger.i('Dark mode: $enabled');
  }

  /// Enables or disables offline mode
  Future<void> setOfflineMode(bool enabled) async {
    _offlineMode = enabled;
    await _storageService.saveSetting(_offlineModeKey, enabled);
    notifyListeners();
    _logger.i('Offline mode: $enabled');
  }

  /// Sets the logging level
  Future<void> setLoggingLevel(String level) async {
    const validLevels = ['debug', 'info', 'warning', 'error'];
    if (!validLevels.contains(level.toLowerCase())) {
      throw ArgumentError('Invalid logging level. Must be one of: ${validLevels.join(', ')}');
    }

    _loggingLevel = level.toLowerCase();
    await _storageService.saveSetting(_loggingLevelKey, _loggingLevel);
    notifyListeners();
    _logger.i('Logging level updated to: $_loggingLevel');
  }

  /// Resets all settings to default values
  Future<void> resetToDefaults() async {
    _ollamaUrl = _defaultOllamaUrl;
    _currentModel = null;
    _temperature = _defaultTemperature;
    _topP = _defaultTopP;
    _topK = _defaultTopK;
    _speechEnabled = _defaultSpeechEnabled;
    _autoSpeech = _defaultAutoSpeech;
    _speechLanguage = _defaultSpeechLanguage;
    _darkMode = _defaultDarkMode;
    _offlineMode = _defaultOfflineMode;
    _loggingLevel = _defaultLoggingLevel;

    // Save all defaults
    await Future.wait([
      _storageService.saveSetting(_ollamaUrlKey, _ollamaUrl),
      _storageService.deleteSetting(_currentModelKey),
      _storageService.saveSetting(_temperatureKey, _temperature),
      _storageService.saveSetting(_topPKey, _topP),
      _storageService.saveSetting(_topKKey, _topK),
      _storageService.saveSetting(_speechEnabledKey, _speechEnabled),
      _storageService.saveSetting(_autoSpeechKey, _autoSpeech),
      _storageService.saveSetting(_speechLanguageKey, _speechLanguage),
      _storageService.saveSetting(_darkModeKey, _darkMode),
      _storageService.saveSetting(_offlineModeKey, _offlineMode),
      _storageService.saveSetting(_loggingLevelKey, _loggingLevel),
    ]);

    notifyListeners();
    _logger.i('Settings reset to defaults');
  }

  /// Exports all settings as a map
  Map<String, dynamic> exportSettings() {
    return {
      'ollamaUrl': _ollamaUrl,
      'currentModel': _currentModel,
      'temperature': _temperature,
      'topP': _topP,
      'topK': _topK,
      'speechEnabled': _speechEnabled,
      'autoSpeech': _autoSpeech,
      'speechLanguage': _speechLanguage,
      'darkMode': _darkMode,
      'offlineMode': _offlineMode,
      'loggingLevel': _loggingLevel,
    };
  }

  /// Imports settings from a map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings['ollamaUrl'] != null) {
        await setOllamaUrl(settings['ollamaUrl'] as String);
      }
      if (settings['currentModel'] != null) {
        await setCurrentModel(settings['currentModel'] as String);
      }
      if (settings['temperature'] != null) {
        await setTemperature((settings['temperature'] as num).toDouble());
      }
      if (settings['topP'] != null) {
        await setTopP((settings['topP'] as num).toDouble());
      }
      if (settings['topK'] != null) {
        await setTopK(settings['topK'] as int);
      }
      if (settings['speechEnabled'] != null) {
        await setSpeechEnabled(settings['speechEnabled'] as bool);
      }
      if (settings['autoSpeech'] != null) {
        await setAutoSpeech(settings['autoSpeech'] as bool);
      }
      if (settings['speechLanguage'] != null) {
        await setSpeechLanguage(settings['speechLanguage'] as String);
      }
      if (settings['darkMode'] != null) {
        await setDarkMode(settings['darkMode'] as bool);
      }
      if (settings['offlineMode'] != null) {
        await setOfflineMode(settings['offlineMode'] as bool);
      }
      if (settings['loggingLevel'] != null) {
        await setLoggingLevel(settings['loggingLevel'] as String);
      }

      _logger.i('Settings imported successfully');
    } catch (error) {
      _logger.e('Failed to import settings', error: error);
      rethrow;
    }
  }
}