import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

import 'ui/app.dart';
import 'services/dependency_injection.dart';
import 'services/logging_service.dart';
import 'services/storage_service.dart';

/// Entry point of the VaultMind application
/// Initializes all necessary services and dependencies before starting the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging service first
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  try {
    // Initialize Hive for local storage
    await Hive.initFlutter();
    logger.i('Hive initialized successfully');

    // Setup dependency injection
    await setupDependencyInjection();
    logger.i('Dependency injection setup completed');

    // Initialize storage service
    final storageService = getIt<StorageService>();
    await storageService.initialize();
    logger.i('Storage service initialized');

    // Start the application
    runApp(const VaultMindApp());
    logger.i('VaultMind application started successfully');
  } catch (error, stackTrace) {
    logger.e(
      'Failed to initialize VaultMind application',
      error: error,
      stackTrace: stackTrace,
    );
    
    // Show error in a basic app if initialization fails
    runApp(MaterialApp(
      title: 'VaultMind - Error',
      home: Scaffold(
        appBar: AppBar(title: const Text('VaultMind - Initialization Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize VaultMind',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}