import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Service for monitoring network connectivity
/// Provides real-time connectivity status and network type information
class ConnectivityService extends ChangeNotifier {
  final Logger _logger;
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  bool _isConnected = false;

  ConnectivityService({required Logger logger}) : _logger = logger;

  // Getters
  bool get isConnected => _isConnected;
  ConnectivityResult get connectionStatus => _connectionStatus;
  String get connectionType => _getConnectionTypeString(_connectionStatus);

  /// Initializes the connectivity service and starts monitoring
  Future<void> initialize() async {
    try {
      // Get initial connectivity status
      _connectionStatus = await _connectivity.checkConnectivity();
      _updateConnectionState(_connectionStatus);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionState,
        onError: (error) {
          _logger.e('Connectivity subscription error', error: error);
        },
      );

      _logger.i('Connectivity service initialized with status: $_connectionStatus');
    } catch (error) {
      _logger.e('Failed to initialize connectivity service', error: error);
      rethrow;
    }
  }

  /// Updates the connection state and notifies listeners
  void _updateConnectionState(ConnectivityResult result) {
    final wasConnected = _isConnected;
    
    _connectionStatus = result;
    _isConnected = result != ConnectivityResult.none;

    if (wasConnected != _isConnected) {
      _logger.i('Connectivity changed: ${_isConnected ? 'connected' : 'disconnected'} ($_connectionStatus)');
      notifyListeners();
    }
  }

  /// Gets a human-readable string for connection type
  String _getConnectionTypeString(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  /// Checks current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionState(result);
      return _isConnected;
    } catch (error) {
      _logger.e('Failed to check connectivity', error: error);
      return false;
    }
  }

  /// Returns detailed connectivity information
  Map<String, dynamic> getConnectivityInfo() {
    return {
      'isConnected': _isConnected,
      'connectionType': connectionType,
      'connectionStatus': _connectionStatus.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}