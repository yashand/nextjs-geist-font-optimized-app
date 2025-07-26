import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling all local storage operations
/// Provides both Hive (for complex data) and SharedPreferences (for simple key-value pairs)
class StorageService {
  Box? _chatBox;
  Box? _settingsBox;
  SharedPreferences? _prefs;

  /// Initializes all storage mechanisms
  Future<void> initialize() async {
    // Initialize Hive boxes
    _chatBox = await Hive.openBox('chats');
    _settingsBox = await Hive.openBox('settings');
    
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();
  }

  // Chat related storage
  Future<void> saveChatMessage(String chatId, Map<String, dynamic> message) async {
    final chatMessages = _chatBox?.get(chatId, defaultValue: <Map<String, dynamic>>[]) ?? <Map<String, dynamic>>[];
    chatMessages.add(message);
    await _chatBox?.put(chatId, chatMessages);
  }

  List<Map<String, dynamic>> getChatMessages(String chatId) {
    final messages = _chatBox?.get(chatId, defaultValue: <Map<String, dynamic>>[]) ?? <Map<String, dynamic>>[];
    return List<Map<String, dynamic>>.from(messages);
  }

  Future<void> deleteChatMessages(String chatId) async {
    await _chatBox?.delete(chatId);
  }

  List<String> getAllChatIds() {
    return _chatBox?.keys.cast<String>().toList() ?? [];
  }

  // Settings storage
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }

  // Simple preferences storage
  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }

  /// Clears all stored data (use with caution)
  Future<void> clearAll() async {
    await _chatBox?.clear();
    await _settingsBox?.clear();
    await _prefs?.clear();
  }

  /// Gets the size of stored data for monitoring storage usage
  Map<String, int> getStorageStats() {
    return {
      'chatMessages': _chatBox?.length ?? 0,
      'settings': _settingsBox?.length ?? 0,
      'preferences': _prefs?.getKeys().length ?? 0,
    };
  }
}