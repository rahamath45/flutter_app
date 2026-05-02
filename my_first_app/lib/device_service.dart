import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceService {
  static String? _cachedDeviceId;

  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    if (kIsWeb) {
      _cachedDeviceId = 'web_${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceId!;
    }

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      // Use fingerprint (includes device model + build) for a truly unique ID
      // Build.ID is just the ROM build ID and can be the same across devices
      _cachedDeviceId = androidInfo.fingerprint;
    } else {
      // For other platforms, use a generated ID
      _cachedDeviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
    }

    return _cachedDeviceId!;
  }
}