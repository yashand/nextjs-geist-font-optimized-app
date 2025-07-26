import 'package:logger/logger.dart';

/// Centralized logging service for the application
/// Provides structured logging with different levels and error tracking
class LoggingService {
  final Logger _logger;

  LoggingService(this._logger);

  /// Log debug messages (only in debug mode)
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log informational messages
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning messages
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error messages
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical errors
  void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network requests
  void logNetworkRequest(String method, String url, {Map<String, dynamic>? headers, dynamic body}) {
    _logger.d('Network Request: $method $url', error: {
      'headers': headers,
      'body': body,
    });
  }

  /// Log network responses
  void logNetworkResponse(int statusCode, String url, {dynamic body, Duration? duration}) {
    final level = statusCode >= 400 ? Level.error : Level.debug;
    _logger.log(level, 'Network Response: $statusCode $url${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}', error: {
      'statusCode': statusCode,
      'body': body,
    });
  }

  /// Log user actions for analytics and debugging
  void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    _logger.i('User Action: $action', error: parameters);
  }

  /// Log performance metrics
  void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metadata}) {
    _logger.i('Performance: $operation took ${duration.inMilliseconds}ms', error: metadata);
  }

  /// Log LLM interactions
  void logLLMInteraction(String type, {String? model, int? tokenCount, Duration? duration}) {
    _logger.i('LLM Interaction: $type', error: {
      'model': model,
      'tokenCount': tokenCount,
      'duration': duration?.inMilliseconds,
    });
  }

  /// Log speech-to-text events
  void logSpeechEvent(String event, {bool? isListening, String? recognizedText, dynamic error}) {
    _logger.i('Speech Event: $event', error: {
      'isListening': isListening,
      'recognizedText': recognizedText,
      'error': error,
    });
  }

  /// Log connectivity changes
  void logConnectivityChange(String connectionType, bool isConnected) {
    _logger.i('Connectivity Change: $connectionType (${isConnected ? 'connected' : 'disconnected'})');
  }
}