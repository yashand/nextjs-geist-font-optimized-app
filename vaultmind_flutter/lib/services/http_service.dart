import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Custom exception for HTTP service errors
class HttpServiceException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const HttpServiceException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => 'HttpServiceException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// HTTP service with retry logic, error handling, and network connectivity awareness
class HttpService {
  final Dio _dio;
  final Logger _logger;

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  HttpService({
    required Dio dio,
    required Logger logger,
  }) : _dio = dio, _logger = logger;

  /// Makes a GET request with retry logic and error handling
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = _maxRetries,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'GET $path',
      maxRetries: maxRetries,
    );
  }

  /// Makes a POST request with retry logic and error handling
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = _maxRetries,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'POST $path',
      maxRetries: maxRetries,
    );
  }

  /// Makes a PUT request with retry logic and error handling
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = _maxRetries,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'PUT $path',
      maxRetries: maxRetries,
    );
  }

  /// Makes a DELETE request with retry logic and error handling
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    int maxRetries = _maxRetries,
  }) async {
    return _executeWithRetry<T>(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'DELETE $path',
      maxRetries: maxRetries,
    );
  }

  /// Executes HTTP request with retry logic and comprehensive error handling
  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() request,
    String operationName,
    {required int maxRetries}
  ) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        final stopwatch = Stopwatch()..start();
        final response = await request();
        stopwatch.stop();

        _logger.d('$operationName completed successfully in ${stopwatch.elapsedMilliseconds}ms');
        return response;
      } catch (error) {
        attempt++;
        lastException = _handleError(error, operationName, attempt, maxRetries);

        if (attempt <= maxRetries && _shouldRetry(error)) {
          _logger.w('$operationName failed (attempt $attempt/$maxRetries), retrying in ${_retryDelay.inSeconds}s...');
          await Future.delayed(_retryDelay * attempt); // Exponential backoff
        } else {
          break;
        }
      }
    }

    throw lastException!;
  }

  /// Handles and categorizes different types of errors
  Exception _handleError(dynamic error, String operationName, int attempt, int maxRetries) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          _logger.e('$operationName timeout (attempt $attempt/$maxRetries)', error: error);
          return HttpServiceException(
            'Request timeout. Please check your internet connection.',
            originalError: error,
          );

        case DioExceptionType.connectionError:
          _logger.e('$operationName connection error (attempt $attempt/$maxRetries)', error: error);
          return HttpServiceException(
            'Connection failed. Please check your internet connection and try again.',
            originalError: error,
          );

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          _logger.e('$operationName bad response $statusCode (attempt $attempt/$maxRetries)', error: error);
          
          return HttpServiceException(
            _getStatusCodeMessage(statusCode),
            statusCode: statusCode,
            originalError: error,
          );

        case DioExceptionType.cancel:
          _logger.i('$operationName was cancelled');
          return HttpServiceException(
            'Request was cancelled.',
            originalError: error,
          );

        case DioExceptionType.unknown:
          _logger.e('$operationName unknown error (attempt $attempt/$maxRetries)', error: error);
          return HttpServiceException(
            'An unexpected error occurred. Please try again.',
            originalError: error,
          );

        default:
          _logger.e('$operationName unhandled DioException (attempt $attempt/$maxRetries)', error: error);
          return HttpServiceException(
            'Network request failed. Please try again.',
            originalError: error,
          );
      }
    } else if (error is SocketException) {
      _logger.e('$operationName socket error (attempt $attempt/$maxRetries)', error: error);
      return HttpServiceException(
        'Network connection error. Please check your internet connection.',
        originalError: error,
      );
    } else {
      _logger.e('$operationName unexpected error (attempt $attempt/$maxRetries)', error: error);
      return HttpServiceException(
        'An unexpected error occurred. Please try again.',
        originalError: error,
      );
    }
  }

  /// Determines if an error is retryable
  bool _shouldRetry(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          // Retry on server errors (5xx) but not client errors (4xx)
          return statusCode != null && statusCode >= 500;
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
        default:
          return false;
      }
    }
    
    if (error is SocketException) {
      return true;
    }
    
    return false;
  }

  /// Gets user-friendly message for HTTP status codes
  String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input and try again.';
      case 401:
        return 'Authentication required. Please check your credentials.';
      case 403:
        return 'Access denied. You don\'t have permission to access this resource.';
      case 404:
        return 'Resource not found. The requested service may be unavailable.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Request timeout. Please try again.';
      default:
        return 'Request failed${statusCode != null ? ' with status $statusCode' : ''}. Please try again.';
    }
  }

  /// Creates a cancel token for cancelling requests
  CancelToken createCancelToken() => CancelToken();

  /// Updates the base URL for the HTTP client
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
    _logger.i('HTTP service base URL updated to: $baseUrl');
  }

  /// Updates timeout configurations
  void updateTimeouts({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (connectTimeout != null) _dio.options.connectTimeout = connectTimeout;
    if (receiveTimeout != null) _dio.options.receiveTimeout = receiveTimeout;
    if (sendTimeout != null) _dio.options.sendTimeout = sendTimeout;
    
    _logger.i('HTTP service timeouts updated');
  }
}