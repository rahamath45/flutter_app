import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id; // Unique Android ID
  }
}