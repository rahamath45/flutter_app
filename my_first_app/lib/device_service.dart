import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static String? _cachedDeviceId;
  static const String _deviceIdKey = 'saved_device_id';

  /// Returns a stable, persistent device ID.
  ///
  /// Priority order:
  /// 1. In-memory cache (fastest)
  /// 2. SharedPreferences (survives app restart)
  /// 3. Platform device info (generated once, then persisted)
  static Future<String> getDeviceId() async {
    // 1. Return cached value if available
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    // 2. Try loading from local storage (survives app restarts)
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(_deviceIdKey);
    if (savedId != null && savedId.isNotEmpty) {
      _cachedDeviceId = savedId;
      return _cachedDeviceId!;
    }

    // 3. Generate a new device ID from platform info
    String deviceId;

    if (kIsWeb) {
      deviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      // Use Android ID — stable across OS updates (unlike fingerprint).
      // Falls back to a generated ID if Android ID is unavailable.
      final androidId = androidInfo.id;
      if (androidId.isNotEmpty) {
        deviceId = androidId;
      } else {
        deviceId = 'android_${DateTime.now().millisecondsSinceEpoch}';
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    }

    // 4. Persist to local storage so it survives restarts
    await prefs.setString(_deviceIdKey, deviceId);
    _cachedDeviceId = deviceId;

    return _cachedDeviceId!;
  }

  /// Clears the persisted device ID (only call on full account deletion).
  static Future<void> clearDeviceId() async {
    _cachedDeviceId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }
}