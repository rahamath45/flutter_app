import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ShabdService');

/// Flutter wrapper for the native Shabd SDK (TTS, STT, MT).
///
/// Uses Platform Channels to communicate with the native Android code
/// in MainActivity.kt, which in turn calls the Shabd VoiceAI SDK.
class ShabdService {
  static const MethodChannel _channel = MethodChannel('com.homeremedies/shabd_sdk');

  // Callbacks for STT streaming results
  static Function(String text)? onPartialResult;
  static Function(String text, int segmentIndex)? onFinalResult;
  static Function(String error)? onSTTError;

  /// Must be called once to register STT event listeners.
  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPartialResult':
          final text = call.arguments['text'] as String? ?? '';
          _logger.fine('STT partial: $text');
          onPartialResult?.call(text);
          break;
        case 'onFinalResult':
          final text = call.arguments['text'] as String? ?? '';
          final segmentIndex = call.arguments['segmentIndex'] as int? ?? 0;
          _logger.fine('STT final: $text (segment: $segmentIndex)');
          onFinalResult?.call(text, segmentIndex);
          break;
        case 'onSTTError':
          final error = call.arguments['error'] as String? ?? 'Unknown error';
          _logger.severe('STT error: $error');
          onSTTError?.call(error);
          break;
      }
    });
    _logger.info('ShabdService initialized');
  }

  // ──────────────────────────────────────────────
  // PERMISSIONS
  // ──────────────────────────────────────────────

  /// Request microphone permission at runtime (required for Android 6+).
  /// Returns true if permission is granted.
  static Future<bool> requestMicPermission() async {
    try {
      final result = await _channel.invokeMethod('requestMicPermission');
      final granted = result['granted'] == true;
      _logger.info('Mic permission: ${granted ? "granted" : "denied"}');
      return granted;
    } on PlatformException catch (e) {
      _logger.severe('Failed to request mic permission: ${e.message}');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // TTS (Text-to-Speech) — On Device
  // ──────────────────────────────────────────────

  /// Initialize the TTS engine.
  ///
  /// [licenseKey] — Your Shabd SDK license key.
  /// [language] — Language code (e.g., "hi", "ta", "en").
  /// [gender] — Voice gender ("male" or "female").
  /// [speed] — Speech speed (default: 1.4).
  static Future<bool> initializeTTS({
    required String licenseKey,
    String language = 'hi',
    String gender = 'female',
    double speed = 1.4,
  }) async {
    try {
      final result = await _channel.invokeMethod('initializeTTS', {
        'licenseKey': licenseKey,
        'language': language,
        'gender': gender,
        'speed': speed,
      });
      _logger.info('TTS initialized: $result');
      return result['success'] == true;
    } on PlatformException catch (e) {
      _logger.severe('Failed to initialize TTS: ${e.message}');
      return false;
    }
  }

  /// Convert text to speech and play it.
  ///
  /// Returns the audio data length in bytes.
  static Future<int> synthesizeSpeech(String text) async {
    try {
      final result = await _channel.invokeMethod('synthesizeSpeech', {
        'text': text,
      });
      _logger.info('TTS synthesized: ${result['audioLength']} bytes');
      return result['audioLength'] as int? ?? 0;
    } on PlatformException catch (e) {
      _logger.severe('TTS synthesis failed: ${e.message}');
      return 0;
    }
  }

  // ──────────────────────────────────────────────
  // STT (Speech-to-Text) — On Device
  // ──────────────────────────────────────────────

  /// Initialize the STT engine.
  ///
  /// [licenseKey] — Your Shabd SDK license key.
  /// [language] — Language code (e.g., "hi", "ta", "en").
  /// [sampleRate] — Audio sample rate (default: 16000).
  static Future<bool> initializeSTT({
    required String licenseKey,
    String language = 'hi',
    int sampleRate = 16000,
  }) async {
    try {
      final result = await _channel.invokeMethod('initializeSTT', {
        'licenseKey': licenseKey,
        'language': language,
        'sampleRate': sampleRate,
      });
      _logger.info('STT initialized: $result');
      return result['success'] == true;
    } on PlatformException catch (e) {
      _logger.severe('Failed to initialize STT: ${e.message}');
      return false;
    }
  }

  /// Start listening and transcribing audio from the microphone.
  ///
  /// Results come through [onPartialResult] and [onFinalResult] callbacks.
  /// Make sure to call [initialize()] first to register the callbacks.
  static Future<bool> startListening() async {
    try {
      final result = await _channel.invokeMethod('startListening');
      _logger.info('STT listening started');
      return result['success'] == true;
    } on PlatformException catch (e) {
      _logger.severe('Failed to start listening: ${e.message}');
      return false;
    }
  }

  /// Stop listening and transcribing.
  static Future<bool> stopListening() async {
    try {
      final result = await _channel.invokeMethod('stopListening');
      _logger.info('STT listening stopped');
      return result['success'] == true;
    } on PlatformException catch (e) {
      _logger.severe('Failed to stop listening: ${e.message}');
      return false;
    }
  }

  // ──────────────────────────────────────────────
  // MT (Machine Translation) — Cloud
  // ──────────────────────────────────────────────

  /// Initialize the Machine Translation engine.
  ///
  /// [apiKey] — Your Shabd API key for cloud translation.
  /// [sourceLanguage] — Source language code (e.g., "hi").
  /// [targetLanguage] — Target language code (e.g., "en").
  static Future<bool> initializeMT({
    required String apiKey,
    String sourceLanguage = 'hi',
    String targetLanguage = 'en',
  }) async {
    try {
      final result = await _channel.invokeMethod('initializeMT', {
        'apiKey': apiKey,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      });
      _logger.info('MT initialized: $result');
      return result['success'] == true;
    } on PlatformException catch (e) {
      _logger.severe('Failed to initialize MT: ${e.message}');
      return false;
    }
  }

  /// Translate text from source language to target language.
  ///
  /// Returns the translated text, or null on failure.
  static Future<String?> translate(String text) async {
    try {
      final result = await _channel.invokeMethod('translate', {
        'text': text,
      });
      final translated = result['translatedText'] as String?;
      _logger.info('MT translated: "$text" → "$translated"');
      return translated;
    } on PlatformException catch (e) {
      _logger.severe('Translation failed: ${e.message}');
      return null;
    }
  }
}
