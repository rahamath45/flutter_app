import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'database_service.dart';
import 'device_service.dart';
import 'shabd_service.dart';

export 'database_service.dart' show User;

final _logger = Logger('HomeRemediesApp');

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

void main() async {
  _setupLogging();
  _logger.info('Application starting...');

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Shabd SDK Platform Channel listeners
  ShabdService.initialize();

  // Pre-initialize the database so writes are ready on first use
  try {
    await DatabaseService.getInstance();
  } catch (e, stack) {
    _logger.severe('Database pre-initialization failed: $e', e, stack);
  }
  runApp(const HomeRemediesApp());
}

class HomeRemediesApp extends StatelessWidget {
  const HomeRemediesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Remedies',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// SPLASH SCREEN — checks auto-login
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    _logger.info('Checking auto-login...');
    try {
      final deviceId = await DeviceService.getDeviceId();
      _logger.fine('Device ID retrieved: $deviceId');
      final dbService = await DatabaseService.getInstance();
      final user = await dbService.getUserByDeviceId(deviceId);

      if (!mounted) return;

      if (user != null) {
        _logger.info('Auto-login success for user: ${user.name}');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RecordingPage(user: user)),
        );
      } else {
        _logger.info('No active session found, showing login page');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      _logger.severe('Auto-login failed: $e');
      // If database fails, go to login page
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_hospital_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Home Remedies',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN PAGE — Contact + Password only
// ============================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    _logger.info('Login attempt started');
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final deviceId = await DeviceService.getDeviceId();
        final dbService = await DatabaseService.getInstance();

        final user = await dbService.validateLogin(
          _contactController.text.trim(),
          _passwordController.text,
          deviceId,
        );

        if (!mounted) return;

        if (user != null) {
          _logger.info('Login successful for: ${user.contact}');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => RecordingPage(user: user)),
          );
        } else {
          _logger.warning('Login failed: invalid credentials');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid contact number or password. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        _logger.severe('Login failed: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.local_hospital_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Home Remedies',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back! Sign in to continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Contact field
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your contact number';
                      }
                      if (value.trim().length < 7) {
                        return 'Please enter a valid contact number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Sign In button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign Up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToRegister,
                        child: Text(
                          'Sign Up',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REGISTER PAGE — Full user details
// ============================================================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedGender = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  Future<void> _register() async {
    _logger.info('Registration attempt started');
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final deviceId = await DeviceService.getDeviceId();
        final dbService = await DatabaseService.getInstance();

        final user = User(
          name: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          location: _locationController.text.trim(),
          contact: _contactController.text.trim(),
          password: _passwordController.text,
          deviceId: deviceId,
        );

        final saved = await dbService.saveUser(user);
        if (saved) {
          _logger.info('User registered successfully: ${user.contact}');
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! You are now logged in.'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to the main app page after successful registration
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => RecordingPage(user: user)),
            (route) => false, // Remove all previous routes
          );
        } else {
          _logger.warning('Registration failed');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'An account with this contact number already exists. Please login instead.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        _logger.severe('Registration failed: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sign Up',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in your details to create an account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Age
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age *',
                      prefixIcon: const Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your age';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 1 || age > 120) {
                        return 'Please enter a valid age';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Gender *',
                      prefixIcon: const Icon(Icons.wc),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    items: _genders.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select your gender';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location *',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contact
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      labelText: 'Contact Number *',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your contact number';
                      }
                      if (value.trim().length < 7) {
                        return 'Please enter a valid contact number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 4) {
                        return 'Password must be at least 4 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Register button
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.app_registration),
                    label: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have an account? Sign In
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RECORDING PAGE — Main app page after login
// ============================================================
class RecordingPage extends StatefulWidget {
  final User user;

  const RecordingPage({super.key, required this.user});

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  static const String _shabdApiKey = 'a32b5865-fe64-4b13-8ee8-9037c5ea07c6';

  bool _isRecording = false;
  bool _isSDKReady = false;
  bool _isInitializing = false;
  int _recordingSeconds = 0;
  String _transcribedText = '';
  String _partialText = '';
  Timer? _timer;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  Future<void> _initializeSDK() async {
    setState(() => _isInitializing = true);

    // Register STT callbacks
    ShabdService.onPartialResult = (text) {
      if (mounted) {
        setState(() => _partialText = text);
      }
    };

    ShabdService.onFinalResult = (text, segmentIndex) {
      if (mounted) {
        setState(() {
          if (text.isNotEmpty) {
            _transcribedText += '${_transcribedText.isEmpty ? '' : ' '}$text';
          }
          _partialText = '';
        });
      }
    };

    ShabdService.onSTTError = (error) {
      _logger.severe('STT Error: $error');
    };

    // Initialize STT with English — use API key as license key
    try {
      final sttReady = await ShabdService.initializeSTT(
        licenseKey: _shabdApiKey,
        language: 'en',
      );

      if (mounted) {
        setState(() {
          _isSDKReady = sttReady;
          _isInitializing = false;
          _statusMessage = sttReady ? 'Ready to record' : 'Ready (STT unavailable)';
        });
      }

      _logger.info('Shabd STT initialized: $sttReady');
    } catch (e) {
      _logger.severe('SDK initialization error: $e');
      if (mounted) {
        setState(() {
          _isSDKReady = false;
          _isInitializing = false;
          _statusMessage = 'SDK error: $e';
        });
      }
    }
  }

  /// Logout: clears device_id (does NOT delete user data), navigates to LoginPage
  Future<void> _logout() async {
    _logger.info('Logout initiated for user: ${widget.user.contact}');

    // Stop recording if active
    if (_isRecording) {
      await _stopRecording();
    }

    try {
      final deviceId = await DeviceService.getDeviceId();
      final dbService = await DatabaseService.getInstance();
      await dbService.logout(deviceId, contact: widget.user.contact);
      _logger.info('User logged out successfully (data preserved)');
    } catch (e) {
      _logger.severe('Logout failed: $e');
    }

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false, // Remove all routes
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      // Request mic permission first (required on Android 6+)
      final hasPermission = await ShabdService.requestMicPermission();
      _logger.info('Mic permission result: $hasPermission');

      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required. Please allow it.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Re-initialize if SDK wasn't ready
      if (!_isSDKReady) {
        _logger.info('SDK not ready, attempting re-initialization...');
        await _initializeSDK();
      }

      // Start recording — even if SDK init failed, we start the UI
      bool sttStarted = false;
      if (_isSDKReady) {
        sttStarted = await ShabdService.startListening();
        _logger.info('STT startListening result: $sttStarted');
      } else {
        _logger.warning('SDK not ready, recording without STT');
      }

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
          _partialText = '';
          if (!sttStarted) {
            _statusMessage = 'Recording (STT unavailable)';
          }
        });
        _startTimer();
      }
    } catch (e) {
      _logger.severe('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _timer = null;
    await ShabdService.stopListening();
    if (mounted) {
      setState(() {
        _isRecording = false;
        // Append any remaining partial text
        if (_partialText.isNotEmpty) {
          _transcribedText += '${_transcribedText.isEmpty ? '' : ' '}$_partialText';
          _partialText = '';
        }
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording || !mounted) {
        timer.cancel();
        return;
      }
      setState(() => _recordingSeconds++);
      // Auto-stop at 15 minutes
      if (_recordingSeconds >= 900) {
        _stopRecording();
        timer.cancel();
      }
    });
  }

  void _clearTranscript() {
    setState(() {
      _transcribedText = '';
      _partialText = '';
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _transcribedText +
        (_partialText.isNotEmpty ? '${_transcribedText.isEmpty ? '' : ' '}\u200b$_partialText...' : '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Remedy'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (_transcribedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearTranscript,
              tooltip: 'Clear transcript',
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Namaste! I am gathering home remedies for everyday health issues. Your help would mean a lot. Just tap the mic and record the remedies you know (up to 15 minutes at once).',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome${widget.user.name != null ? ', ${widget.user.name}' : ''}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Transcribed text area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isRecording
                        ? Theme.of(context).colorScheme.primary.withAlpha(128)
                        : Theme.of(context).colorScheme.outline.withAlpha(51),
                    width: _isRecording ? 2 : 1,
                  ),
                ),
                child: displayText.isEmpty
                    ? Center(
                        child: Text(
                          _isInitializing
                              ? 'Initializing speech engine...'
                              : _isRecording
                                  ? 'Listening... speak now'
                                  : 'Tap the mic button to start recording.\nYour speech will appear here.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(153),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SingleChildScrollView(
                        reverse: true,
                        child: Text(
                          displayText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Recording timer
            if (_isRecording) ...[
              Text(
                _formatDuration(_recordingSeconds),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recording...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            if (!_isRecording && !_isInitializing)
              Text(
                _statusMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 16),

            // Mic button
            GestureDetector(
              onTap: _isInitializing ? null : _toggleRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isInitializing
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : _isRecording
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!_isInitializing)
                      BoxShadow(
                        color: (_isRecording
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary)
                            .withAlpha(77),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: _isInitializing
                    ? const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isInitializing
                  ? 'Setting up...'
                  : _isRecording
                      ? 'Tap to stop'
                      : 'Tap to record',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Max: 15 minutes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(153),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
