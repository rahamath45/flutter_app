import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class User {
  final int? id;
  final String? name;
  final int age;
  final String gender;
  final String location;
  final String contact;
  final String password;
  final String deviceId;

  User({
    this.id,
    this.name,
    required this.age,
    required this.gender,
    required this.location,
    required this.contact,
    required this.password,
    required this.deviceId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String?,
      age: json['age'] as int,
      gender: json['gender'] as String,
      location: json['location'] as String,
      contact: json['contact'] as String,
      password: json['password'] as String,
      deviceId: json['device_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'location': location,
      'contact': contact,
      'password': password,
      'device_id': deviceId,
    };
  }
}

final _logger = Logger('DatabaseService');

class DatabaseService {
  static DatabaseService? _instance;

  // ⚠️ REPLACE THIS with your actual Railway URL after deployment
  static const String _baseUrl = 'https://flutterapp-production-f4dc.up.railway.app';

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  static bool get isInitialized => true; // Always "initialized" with HTTP

  /// Register a new user (saves all details + device_id)
  Future<bool> saveUser(User user) async {
    _logger.fine('Registering user via API: ${user.contact}');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/save-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        _logger.fine('User registered successfully: ${user.deviceId}');
        return true;
      } else if (response.statusCode == 409) {
        _logger.warning('User already exists: ${user.contact}');
        return false;
      } else {
        _logger.severe('Failed to register user: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      _logger.severe('Failed to register user: $e', e, stack);
      return false;
    }
  }

  /// Get the error message from a failed save attempt
  Future<String?> getSaveErrorMessage(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/save-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        return data['message'] as String?;
      }
    } catch (_) {}
    return null;
  }

  /// Get user by device_id (for auto-login check)
  Future<User?> getUserByDeviceId(String deviceId) async {
    _logger.fine('Fetching user by deviceId: $deviceId');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/user/$deviceId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          _logger.fine('User found for deviceId: $deviceId');
          return User.fromJson(data['user']);
        }
      }
      _logger.fine('No user found for deviceId: $deviceId');
    } catch (e, stack) {
      _logger.severe('Failed to get user: $e', e, stack);
    }
    return null;
  }

  /// Delete user by device_id (kept for admin purposes)
  Future<void> deleteUserByDeviceId(String deviceId) async {
    _logger.fine('Deleting user by deviceId: $deviceId');
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/user/$deviceId'),
      );

      if (response.statusCode == 200) {
        _logger.fine('User deleted successfully');
      } else {
        _logger.warning('Delete response: ${response.body}');
      }
    } catch (e, stack) {
      _logger.severe('Failed to delete user: $e', e, stack);
    }
  }

  /// Validate login credentials (contact + password)
  Future<User?> validateLogin(
    String contact,
    String password,
    String deviceId,
  ) async {
    _logger.fine('Validating login for: $contact');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/validate-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': contact,
          'password': password,
          'device_id': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['user'] != null) {
          _logger.fine('Login validated for: $contact');
          return User.fromJson(data['user']);
        }
      } else if (response.statusCode == 401) {
        _logger.warning('Invalid credentials for: $contact');
      }
    } catch (e, stack) {
      _logger.severe('Failed to validate login: $e', e, stack);
    }
    return null;
  }

  /// Logout: clears device_id without deleting user data
  Future<bool> logout(String deviceId, {String? contact}) async {
    _logger.fine('Logging out device: $deviceId, contact: $contact');
    try {
      final body = <String, dynamic>{'device_id': deviceId};
      if (contact != null) body['contact'] = contact;

      final response = await http.post(
        Uri.parse('$_baseUrl/api/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _logger.fine('Logged out successfully');
        return true;
      } else {
        _logger.warning('Logout response: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      _logger.severe('Failed to logout: $e', e, stack);
      return false;
    }
  }

  void close() {
    // No connection to close with HTTP client
    _logger.info('DatabaseService closed (HTTP mode)');
  }
}
