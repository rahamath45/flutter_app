import 'package:postgres/postgres.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

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
}

final _logger = Logger('DatabaseService');

class DatabaseService {
  static DatabaseService? _instance;
  static bool _initialized = false;
  static bool _isWeb = kIsWeb;

  late Connection _connection;

  DatabaseService._();

  static void setWebMode(bool isWeb) {
    _isWeb = isWeb;
  }

  static Future<DatabaseService> getInstance() async {
    _logger.fine('Getting database instance, web: $_isWeb, initialized: $_initialized');
    if (_isWeb) {
      _logger.warning('Database not available in web mode');
      return DatabaseService._();
    }
    if (_instance == null) {
      _instance = DatabaseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  static bool get isInitialized => _initialized;

  Future<void> _init() async {
    _logger.info('Initializing database connection');
    try {
      _connection = await Connection.open(
        Endpoint(
          host: '10.0.2.2',
          database: 'home_remedies',
          username: 'postgres',
          password: 'password',
        ),
      );

      await _connection.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255),
          age INTEGER NOT NULL,
          gender VARCHAR(50) NOT NULL,
          location VARCHAR(255) NOT NULL,
          contact VARCHAR(100) NOT NULL,
          password VARCHAR(255) NOT NULL,
          device_id VARCHAR(255) UNIQUE NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      _initialized = true;
      _logger.info('Database initialized, users table ready');
    } catch (e) {
      _logger.severe('Failed to initialize database: $e');
      _initialized = false;
    }
  }

  Future<void> saveUser(User user) async {
    if (!_initialized) {
      _logger.warning('Database not initialized, skipping save');
      return;
    }
    _logger.fine('Saving user: ${user.contact}');
    try {
      await _connection.execute(
        Sql.named('''
          INSERT INTO users (name, age, gender, location, contact, password, device_id)
          VALUES (@name, @age, @gender, @location, @contact, @password, @device_id)
          ON CONFLICT (device_id) DO UPDATE SET
            name = EXCLUDED.name,
            age = EXCLUDED.age,
            gender = EXCLUDED.gender,
            location = EXCLUDED.location,
            contact = EXCLUDED.contact,
            password = EXCLUDED.password
        '''),
        parameters: {
          'name': user.name,
          'age': user.age,
          'gender': user.gender,
          'location': user.location,
          'contact': user.contact,
          'password': user.password,
          'device_id': user.deviceId,
        },
      );
      _logger.fine('User saved successfully');
    } catch (e) {
      _logger.severe('Failed to save user: $e');
    }
  }

  Future<User?> getUserByDeviceId(String deviceId) async {
    if (!_initialized) {
      _logger.warning('Database not initialized, returning null');
      return null;
    }
    _logger.fine('Fetching user by deviceId: $deviceId');
    try {
      final result = await _connection.execute(
        Sql.named('SELECT * FROM users WHERE device_id = @device_id'),
        parameters: {'device_id': deviceId},
      );

      if (result.isNotEmpty) {
        final row = result.first;
        _logger.fine('User found: ${row[5]}');
        return User(
          id: row[0] as int,
          name: row[1] as String?,
          age: row[2] as int,
          gender: row[3] as String,
          location: row[4] as String,
          contact: row[5] as String,
          password: row[6] as String,
          deviceId: row[7] as String,
        );
      }
      _logger.fine('No user found for deviceId: $deviceId');
    } catch (e) {
      _logger.severe('Failed to get user: $e');
    }
    return null;
  }

  Future<void> deleteUserByDeviceId(String deviceId) async {
    if (!_initialized) {
      _logger.warning('Database not initialized, skipping delete');
      return;
    }
    _logger.fine('Deleting user by deviceId: $deviceId');
    try {
      await _connection.execute(
        Sql.named('DELETE FROM users WHERE device_id = @device_id'),
        parameters: {'device_id': deviceId},
      );
      _logger.fine('User deleted successfully');
    } catch (e) {
      _logger.severe('Failed to delete user: $e');
    }
  }

  Future<User?> validateLogin(String contact, String password, String deviceId) async {
    if (!_initialized) {
      _logger.warning('Database not initialized, returning null');
      return null;
    }
    _logger.fine('Validating login for: $contact');
    try {
      final result = await _connection.execute(
        Sql.named('''
          SELECT * FROM users WHERE contact = @contact AND password = @password
        '''),
        parameters: {'contact': contact, 'password': password},
      );

      if (result.isNotEmpty) {
        final row = result.first;
        await _connection.execute(
          Sql.named('UPDATE users SET device_id = @device_id WHERE contact = @contact'),
          parameters: {'contact': contact, 'device_id': deviceId},
        );
        return User(
          id: row[0] as int,
          name: row[1] as String?,
          age: row[2] as int,
          gender: row[3] as String,
          location: row[4] as String,
          contact: row[5] as String,
          password: row[6] as String,
          deviceId: deviceId,
        );
      }
    } catch (e) {
      _logger.severe('Failed to validate login: $e');
    }
    return null;
  }

  void close() {
    if (!_initialized) return;
    _logger.info('Closing database connection');
    _connection.close();
  }
}