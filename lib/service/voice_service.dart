import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// Service for handling voice input and output
/// Works completely offline
class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  String? _lastResult;
  bool _permissionRequested = false;
  
  /// Check if speech recognition is available
  Future<bool> get isAvailable async {
    // First check microphone permission
    if (!await _checkMicrophonePermission()) {
      return false;
    }
    
    // Then check if speech recognition is available
    return await _speech.initialize();
  }

  /// Check and request microphone permission
  Future<bool> _checkMicrophonePermission() async {
    // Check current permission status
    final status = await Permission.microphone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // If not granted and not yet requested, request it
    if (!status.isPermanentlyDenied && !_permissionRequested) {
      _permissionRequested = true;
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    // If permanently denied, user needs to go to settings
    return false;
  }

  /// Start listening for voice input
  /// Returns the recognized text or null if failed
  Future<String?> listen() async {
    if (_isListening) return null;
    
    // Check microphone permission
    if (!await _checkMicrophonePermission()) {
      return null;
    }
    
    // Check if speech is initialized
    if (!await _speech.initialize()) {
      return null;
    }
    
    _isListening = true;
    _lastResult = null;
    
    try {
      await _speech.listen(
        onResult: (result) {
          _lastResult = result.recognizedWords;
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 5),
        listenMode: stt.ListenMode.confirmation,
      );
      
      // Wait for listening to complete
      await Future.delayed(Duration(seconds: 11));
      
      return _lastResult?.isNotEmpty == true ? _lastResult : null;
    } catch (e) {
      return null;
    } finally {
      _isListening = false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Speak text using text-to-speech
  /// Handles long text by splitting into chunks
  Future<void> speak(String text, {Duration? pauseBetweenChunks}) async {
    if (text.isEmpty) return;
    
    // Split long text into chunks (TTS has character limits)
    final chunks = _splitText(text, 200);
    
    for (final chunk in chunks) {
      await _tts.speak(chunk);
      if (pauseBetweenChunks != null) {
        await Future.delayed(pauseBetweenChunks);
      }
    }
  }

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Split text into chunks of maximum length
  List<String> _splitText(String text, int maxLength) {
    final chunks = <String>[];
    final sentences = text.split(RegExp(r'[.!?]'));
    String current = '';
    
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isEmpty) continue;
      
      if (current.length + trimmed.length + 1 > maxLength) {
        chunks.add(current);
        current = trimmed;
      } else {
        current += (current.isEmpty ? '' : '. ') + trimmed;
      }
    }
    
    if (current.isNotEmpty) {
      chunks.add(current);
    }
    
    return chunks;
  }
}
