import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utility functions for various common operations
class AppUtils {
  /// Validates if a string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority;
    } catch (e) {
      return false;
    }
  }

  /// Validates if a string is a valid IP address
  static bool isValidIpAddress(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    try {
      for (final part in parts) {
        final num = int.parse(part);
        if (num < 0 || num > 255) return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Formats duration to human-readable string
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMilliseconds}ms';
    }
  }

  /// Formats bytes to human-readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Truncates text to specified length with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Generates a conversation title from the first message
  static String generateConversationTitle(String firstMessage) {
    final words = firstMessage.trim().split(' ');
    final title = words.take(6).join(' ');
    return truncateText(title, 50);
  }

  /// Debounces function calls
  static void debounce(Function() function, Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, function);
  }

  static Timer? _debounceTimer;

  /// Checks if the current platform supports speech recognition
  static bool get supportsSpeechRecognition {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Checks if the current platform supports camera
  static bool get supportsCamera {
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Gets platform-specific app data directory
  static Future<Directory> getAppDataDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/data/data/com.example.vaultmind/files');
    } else if (Platform.isIOS) {
      return Directory('/var/mobile/Containers/Data/Application/vaultmind');
    } else {
      return Directory.current;
    }
  }

  /// Safely parses JSON string
  static Map<String, dynamic>? safeJsonDecode(String jsonString) {
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to parse JSON: $e');
      return null;
    }
  }

  /// Safely encodes object to JSON string
  static String? safeJsonEncode(dynamic object) {
    try {
      return json.encode(object);
    } catch (e) {
      debugPrint('Failed to encode JSON: $e');
      return null;
    }
  }

  /// Generates a unique ID
  static String generateUniqueId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';
  }

  static int _counter = 0;

  /// Capitalizes the first letter of a string
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Formats a timestamp to relative time (e.g., "2 minutes ago")
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Checks if a string contains only whitespace
  static bool isWhitespace(String text) {
    return text.trim().isEmpty;
  }

  /// Removes all whitespace from a string
  static String removeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), '');
  }

  /// Normalizes whitespace in a string (removes extra spaces)
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Extracts domain from URL
  static String? extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return null;
    }
  }

  /// Checks if running in debug mode
  static bool get isDebugMode => kDebugMode;

  /// Checks if running on mobile platform
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  /// Checks if running on desktop platform
  static bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Gets platform name as string
  static String get platformName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Validates email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Validates phone number format (basic validation)
  static bool isValidPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned.length >= 10 && cleaned.length <= 15;
  }

  /// Calculates percentage
  static double calculatePercentage(double value, double total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  /// Clamps a value between min and max
  static T clamp<T extends num>(T value, T min, T max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Generates a color from a string (for avatars, etc.)
  static int generateColorFromString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return hash & 0xFFFFFF; // Return only RGB components
  }

  /// Formats a number with thousand separators
  static String formatNumber(num number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Gets initials from a name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}

/// Timer utility for cleanup
class Timer {
  Timer(Duration duration, void Function() callback) {
    Future.delayed(duration, callback);
  }

  void cancel() {
    // Implementation would depend on actual timer mechanism
  }
}