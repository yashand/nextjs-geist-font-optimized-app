import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import 'http_service.dart';
import 'settings_service.dart';
import 'connectivity_service.dart';
import '../models/llm_models.dart';

/// Service for managing LLM connections and interactions with Ollama
/// Supports offline-first approach with graceful degradation
class LLMService extends ChangeNotifier {
  final HttpService _httpService;
  final SettingsService _settingsService;
  final ConnectivityService _connectivityService;
  final Logger _logger;

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _connectionError;
  List<String> _availableModels = [];
  String? _currentModel;

  // Request management
  final Map<String, CancelToken> _activeRequests = {};

  LLMService({
    required HttpService httpService,
    required SettingsService settingsService,
    required ConnectivityService connectivityService,
    required Logger logger,
  })  : _httpService = httpService,
        _settingsService = settingsService,
        _connectivityService = connectivityService,
        _logger = logger {
    _initializeService();
  }

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get connectionError => _connectionError;
  List<String> get availableModels => List.unmodifiable(_availableModels);
  String? get currentModel => _currentModel;
  bool get hasNetworkConnection => _connectivityService.isConnected;

  /// Initializes the LLM service
  void _initializeService() {
    // Listen to connectivity changes
    _connectivityService.addListener(_onConnectivityChanged);
    
    // Listen to settings changes
    _settingsService.addListener(_onSettingsChanged);
    
    // Initial connection attempt if we have network
    if (_connectivityService.isConnected) {
      _attemptConnection();
    }
  }

  /// Handles connectivity changes
  void _onConnectivityChanged() {
    if (_connectivityService.isConnected && !_isConnected) {
      _logger.i('Network connectivity restored, attempting LLM connection');
      _attemptConnection();
    } else if (!_connectivityService.isConnected) {
      _logger.w('Network connectivity lost, LLM will be unavailable');
      _updateConnectionState(false, error: 'No network connection');
    }
  }

  /// Handles settings changes
  void _onSettingsChanged() {
    final newOllamaUrl = _settingsService.ollamaUrl;
    if (newOllamaUrl != null) {
      _httpService.updateBaseUrl(newOllamaUrl);
      _attemptConnection();
    }
  }

  /// Attempts to connect to Ollama server
  Future<void> _attemptConnection() async {
    if (_isConnecting) return;

    _updateConnectionState(false, isConnecting: true);

    try {
      final ollamaUrl = _settingsService.ollamaUrl;
      if (ollamaUrl == null) {
        throw Exception('Ollama URL not configured');
      }

      _httpService.updateBaseUrl(ollamaUrl);

      // Test connection by fetching available models
      await _fetchAvailableModels();

      _updateConnectionState(true);
      _logger.i('Successfully connected to Ollama at $ollamaUrl');
    } catch (error) {
      _updateConnectionState(false, error: error.toString());
      _logger.e('Failed to connect to Ollama', error: error);
    }
  }

  /// Fetches available models from Ollama
  Future<void> _fetchAvailableModels() async {
    try {
      final response = await _httpService.get('/api/tags');
      
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final models = (data['models'] as List<dynamic>?)
            ?.map((model) => model['name'] as String)
            .toList() ?? [];
        
        _availableModels = models;
        
        // Set current model if not set or if it's not available
        if (_currentModel == null || !_availableModels.contains(_currentModel)) {
          _currentModel = _availableModels.isNotEmpty ? _availableModels.first : null;
        }

        _logger.i('Found ${_availableModels.length} available models: $_availableModels');
      } else {
        throw Exception('Failed to fetch models: ${response.statusCode}');
      }
    } catch (error) {
      _logger.e('Error fetching available models', error: error);
      rethrow;
    }
  }

  /// Sends a chat message to the LLM and returns the response
  Future<LLMResponse> sendMessage(
    String message, {
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    if (!_isConnected || !_connectivityService.isConnected) {
      return LLMResponse.error(
        'LLM service is not available. Please check your connection and try again.',
        isOffline: true,
      );
    }

    if (_currentModel == null) {
      return LLMResponse.error('No LLM model is selected.');
    }

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    _activeRequests[requestId] = _httpService.createCancelToken();

    try {
      _logger.i('Sending message to LLM model: $_currentModel');
      
      final requestBody = {
        'model': _currentModel,
        'prompt': message,
        'stream': false,
        'context': context,
        'options': {
          'temperature': _settingsService.temperature,
          'top_p': _settingsService.topP,
          'top_k': _settingsService.topK,
        },
      };

      final stopwatch = Stopwatch()..start();
      final response = await _httpService.post(
        '/api/generate',
        data: requestBody,
        cancelToken: _activeRequests[requestId],
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        final llmResponse = LLMResponse(
          content: data['response'] as String? ?? '',
          model: _currentModel!,
          conversationId: conversationId,
          context: data['context'] as Map<String, dynamic>?,
          tokenCount: data['total_duration'] != null 
              ? (data['total_duration'] as int) ~/ 1000000 // Convert nanoseconds to estimated tokens
              : null,
          responseTime: stopwatch.elapsed,
        );

        _logger.i(
          'LLM response received in ${stopwatch.elapsedMilliseconds}ms',
          error: {
            'model': _currentModel,
            'responseLength': llmResponse.content.length,
            'tokenCount': llmResponse.tokenCount,
          },
        );

        return llmResponse;
      } else {
        throw Exception('LLM request failed with status: ${response.statusCode}');
      }
    } catch (error) {
      _logger.e('LLM request failed', error: error);
      
      if (error is HttpServiceException) {
        return LLMResponse.error(error.message);
      } else {
        return LLMResponse.error('Failed to get response from LLM. Please try again.');
      }
    } finally {
      _activeRequests.remove(requestId);
    }
  }

  /// Cancels an ongoing LLM request
  void cancelRequest(String? requestId) {
    if (requestId != null && _activeRequests.containsKey(requestId)) {
      _activeRequests[requestId]?.cancel('Request cancelled by user');
      _activeRequests.remove(requestId);
      _logger.i('LLM request cancelled: $requestId');
    }
  }

  /// Cancels all active requests
  void cancelAllRequests() {
    for (final cancelToken in _activeRequests.values) {
      cancelToken.cancel('All requests cancelled');
    }
    _activeRequests.clear();
    _logger.i('All LLM requests cancelled');
  }

  /// Sets the current model to use
  Future<void> setCurrentModel(String model) async {
    if (!_availableModels.contains(model)) {
      throw ArgumentError('Model $model is not available');
    }
    
    _currentModel = model;
    await _settingsService.setCurrentModel(model);
    notifyListeners();
    
    _logger.i('Current LLM model changed to: $model');
  }

  /// Refreshes the connection and available models
  Future<void> refresh() async {
    _logger.i('Refreshing LLM service connection');
    await _attemptConnection();
  }

  /// Updates connection state and notifies listeners
  void _updateConnectionState(bool connected, {bool isConnecting = false, String? error}) {
    _isConnected = connected;
    _isConnecting = isConnecting;
    _connectionError = error;
    notifyListeners();
  }

  /// Tests connection to a specific Ollama URL
  Future<bool> testConnection(String url) async {
    try {
      final originalBaseUrl = _httpService._dio.options.baseUrl;
      _httpService.updateBaseUrl(url);
      
      final response = await _httpService.get('/api/tags', maxRetries: 1);
      _httpService.updateBaseUrl(originalBaseUrl);
      
      return response.statusCode == 200;
    } catch (error) {
      _logger.w('Connection test failed for $url', error: error);
      return false;
    }
  }

  @override
  void dispose() {
    cancelAllRequests();
    _connectivityService.removeListener(_onConnectivityChanged);
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }
}