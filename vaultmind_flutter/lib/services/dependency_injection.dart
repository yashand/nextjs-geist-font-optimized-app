import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

import 'storage_service.dart';
import 'logging_service.dart';
import 'http_service.dart';
import 'llm_service.dart';
import 'chat_service.dart';
import 'speech_service.dart';
import 'settings_service.dart';
import 'connectivity_service.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Sets up all dependency injection for the application
/// This follows clean architecture principles by injecting dependencies
/// and allowing for easy testing and swapping of implementations
Future<void> setupDependencyInjection() async {
  // Core services
  getIt.registerLazySingleton<Logger>(() => Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  ));

  getIt.registerLazySingleton<Dio>(() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Add interceptors for logging and error handling
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: false,
      error: true,
      logPrint: (obj) => getIt<Logger>().d(obj),
    ));
    
    return dio;
  });

  // Storage and logging
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<LoggingService>(() => LoggingService(getIt()));

  // Network services
  getIt.registerLazySingleton<HttpService>(() => HttpService(
    dio: getIt(),
    logger: getIt(),
  ));

  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService(
    logger: getIt(),
  ));

  // Application services
  getIt.registerLazySingleton<SettingsService>(() => SettingsService(
    storageService: getIt(),
    logger: getIt(),
  ));

  getIt.registerLazySingleton<LLMService>(() => LLMService(
    httpService: getIt(),
    settingsService: getIt(),
    connectivityService: getIt(),
    logger: getIt(),
  ));

  getIt.registerLazySingleton<SpeechService>(() => SpeechService(
    settingsService: getIt(),
    logger: getIt(),
  ));

  getIt.registerLazySingleton<ChatService>(() => ChatService(
    llmService: getIt(),
    speechService: getIt(),
    storageService: getIt(),
    logger: getIt(),
  ));

  // Initialize services that need async initialization
  await _initializeServices();
}

/// Initialize services that require async setup
Future<void> _initializeServices() async {
  final logger = getIt<Logger>();
  
  try {
    // Initialize storage service
    await getIt<StorageService>().initialize();
    logger.i('Storage service initialized');

    // Initialize settings service
    await getIt<SettingsService>().initialize();
    logger.i('Settings service initialized');

    // Initialize connectivity service
    await getIt<ConnectivityService>().initialize();
    logger.i('Connectivity service initialized');

    // Initialize speech service
    await getIt<SpeechService>().initialize();
    logger.i('Speech service initialized');

    logger.i('All services initialized successfully');
  } catch (error, stackTrace) {
    logger.e(
      'Failed to initialize services',
      error: error,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Cleans up all registered dependencies
/// Call this when the app is shutting down
Future<void> cleanupDependencyInjection() async {
  final logger = getIt<Logger>();
  
  try {
    // Dispose services that need cleanup
    if (getIt.isRegistered<ChatService>()) {
      getIt<ChatService>().dispose();
    }
    
    if (getIt.isRegistered<SpeechService>()) {
      getIt<SpeechService>().dispose();
    }
    
    if (getIt.isRegistered<ConnectivityService>()) {
      getIt<ConnectivityService>().dispose();
    }

    // Reset GetIt
    await getIt.reset();
    logger.i('Dependency injection cleaned up successfully');
  } catch (error, stackTrace) {
    logger.e(
      'Error during dependency injection cleanup',
      error: error,
      stackTrace: stackTrace,
    );
  }
}