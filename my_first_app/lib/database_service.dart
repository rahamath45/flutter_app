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
      deviceId: json['device_id'] as String,
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
  static const String _baseUrl = 'https://your-app.up.railway.app';

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  static bool get isInitialized => true; // Always "initialized" with HTTP

  Future<bool> saveUser(User user) async {
    _logger.fine('Saving user via API: ${user.contact}');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/save-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 200) {
        _logger.fine('User saved successfully: ${user.deviceId}');
        return true;
      } else {
        _logger.severe('Failed to save user: ${response.body}');
        return false;
      }
    } catch (e, stack) {
      _logger.severe('Failed to save user: $e', e, stack);
      return false;
    }
  }

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
      }
    } catch (e, stack) {
      _logger.severe('Failed to validate login: $e', e, stack);
    }
    return null;
  }

  void close() {
    // No connection to close with HTTP client
    _logger.info('DatabaseService closed (HTTP mode)');
  }
}
