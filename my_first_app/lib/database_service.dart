import 'package:postgres/postgres.dart';

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

class DatabaseService {
  static DatabaseService? _instance;
  late Connection _connection;

  DatabaseService._();

  static Future<DatabaseService> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _connection = await Connection.open(
      Endpoint(
        host: 'localhost',
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
  }

  Future<void> saveUser(User user) async {
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
  }

  Future<User?> getUserByDeviceId(String deviceId) async {
    final result = await _connection.execute(
      Sql.named('SELECT * FROM users WHERE device_id = @device_id'),
      parameters: {'device_id': deviceId},
    );

    if (result.isNotEmpty) {
      final row = result.first;
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
    return null;
  }

  Future<User?> validateLogin(String contact, String password, String deviceId) async {
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
    return null;
  }

  void close() {
    _connection.close();
  }
}