import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

import 'settings_service.dart';

/// Service for handling speech-to-text functionality
/// Provides voice recognition with permission handling and error management
class SpeechService extends ChangeNotifier {
  final SettingsService _settingsService;
  final Logger _logger;
  final SpeechToText _speechToText = SpeechToText();

  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedText = '';
  String _partialText = '';
  double _confidenceLevel = 0.0;
  List<LocaleName> _availableLocales = [];
  String? _errorMessage;

  SpeechService({
    required SettingsService settingsService,
    required Logger logger,
  })  : _settingsService = settingsService,
        _logger = logger;

  // Getters
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable && _settingsService.speechEnabled;
  String get recognizedText => _recognizedText;
  String get partialText => _partialText;
  double get confidenceLevel => _confidenceLevel;
  List<LocaleName> get availableLocales => List.unmodifiable(_availableLocales);
  String? get errorMessage => _errorMessage;
  bool get hasMicrophonePermission => _hasMicrophonePermission;

  bool _hasMicrophonePermission = false;

  /// Initializes the speech service
  Future<void> initialize() async {
    try {
      // Check microphone permission
      _hasMicrophonePermission = await _checkMicrophonePermission();
      
      if (!_hasMicrophonePermission) {
        _logger.w('Microphone permission not granted');
        return;
      }

      // Initialize speech to text
      _isAvailable = await _speechToText.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: true,
      );

      if (_isAvailable) {
        // Get available locales
        _availableLocales = await _speechToText.locales();
        _logger.i('Speech service initialized with ${_availableLocales.length} locales');
      } else {
        _logger.w('Speech to text not available on this device');
      }
    } catch (error) {
      _logger.e('Failed to initialize speech service', error: error);
      _errorMessage = 'Failed to initialize speech recognition';
    }

    notifyListeners();
  }

  /// Checks and requests microphone permission
  Future<bool> _checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      
      if (status == PermissionStatus.granted) {
        return true;
      } else if (status == PermissionStatus.denied) {
        final result = await Permission.microphone.request();
        return result == PermissionStatus.granted;
      } else {
        return false;
      }
    } catch (error) {
      _logger.e('Error checking microphone permission', error: error);
      return false;
    }
  }

  /// Starts listening for speech input
  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!isAvailable) {
      _errorMessage = 'Speech recognition is not available';
      notifyListeners();
      return;
    }

    if (_isListening) {
      _logger.w('Already listening for speech');
      return;
    }

    try {
      _clearState();
      
      await _speechToText.listen(
        onResult: (result) => _onSpeechResult(result, onResult, onPartialResult),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _settingsService.speechLanguage,
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );

      _isListening = true;
      _logger.i('Started listening for speech');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to start listening', error: error);
      _errorMessage = 'Failed to start speech recognition';
      notifyListeners();
    }
  }

  /// Stops listening for speech input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _logger.i('Stopped listening for speech');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to stop listening', error: error);
    }
  }

  /// Cancels current speech recognition
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      _clearState();
      _logger.i('Cancelled speech recognition');
      notifyListeners();
    } catch (error) {
      _logger.e('Failed to cancel listening', error: error);
    }
  }

  /// Handles speech recognition results
  void _onSpeechResult(
    SpeechRecognitionResult result,
    Function(String)? onResult,
    Function(String)? onPartialResult,
  ) {
    _recognizedText = result.recognizedWords;
    _confidenceLevel = result.confidence;

    if (result.finalResult) {
      _partialText = '';
      _logger.i('Final speech result: "$_recognizedText" (confidence: ${_confidenceLevel.toStringAsFixed(2)})');
      onResult?.call(_recognizedText);
    } else {
      _partialText = _recognizedText;
      _logger.d('Partial speech result: "$_partialText"');
      onPartialResult?.call(_partialText);
    }

    notifyListeners();
  }

  /// Handles speech recognition errors
  void _onSpeechError(SpeechRecognitionError error) {
    _logger.e('Speech recognition error: ${error.errorMsg}');
    _errorMessage = _getSpeechErrorMessage(error.errorMsg);
    _isListening = false;
    notifyListeners();
  }

  /// Handles speech recognition status changes
  void _onSpeechStatus(String status) {
    _logger.d('Speech status: $status');
    
    switch (status) {
      case 'listening':
        _isListening = true;
        _errorMessage = null;
        break;
      case 'notListening':
        _isListening = false;
        break;
      case 'done':
        _isListening = false;
        break;
    }

    notifyListeners();
  }

  /// Gets user-friendly error message for speech errors
  String _getSpeechErrorMessage(String errorMsg) {
    if (errorMsg.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (errorMsg.contains('permission')) {
      return 'Microphone permission is required for speech recognition.';
    } else if (errorMsg.contains('audio')) {
      return 'Audio input error. Please check your microphone.';
    } else if (errorMsg.contains('recognition')) {
      return 'Could not recognize speech. Please try speaking more clearly.';
    } else {
      return 'Speech recognition failed. Please try again.';
    }
  }

  /// Clears current speech state
  void _clearState() {
    _recognizedText = '';
    _partialText = '';
    _confidenceLevel = 0.0;
    _errorMessage = null;
  }

  /// Requests microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      _hasMicrophonePermission = status == PermissionStatus.granted;
      
      if (_hasMicrophonePermission) {
        // Reinitialize if permission was just granted
        await initialize();
      }
      
      notifyListeners();
      return _hasMicrophonePermission;
    } catch (error) {
      _logger.e('Failed to request microphone permission', error: error);
      return false;
    }
  }

  /// Gets information about current speech locale
  LocaleName? getCurrentLocale() {
    try {
      return _availableLocales.firstWhere(
        (locale) => locale.localeId == _settingsService.speechLanguage,
      );
    } catch (e) {
      return _availableLocales.isNotEmpty ? _availableLocales.first : null;
    }
  }

  /// Checks if a specific locale is supported
  bool isLocaleSupported(String localeId) {
    return _availableLocales.any((locale) => locale.localeId == localeId);
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechToText.cancel();
    }
    super.dispose();
  }
}