import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:taskswiper/service/voice_service.dart';
import 'package:taskswiper/service/command_parser.dart';
import 'package:taskswiper/service/task_ai_handler.dart';
import 'package:taskswiper/service/database_service.dart';

/// A floating button that triggers voice command listening
/// Shows visual feedback when listening
/// 
/// Usage:
/// ```dart
/// VoiceCommandButton(
///   db: locator<DatabaseService>(),
///   parentContext: context,
/// )
/// ```
class VoiceCommandButton extends StatefulWidget {
  final DatabaseService db;
  final BuildContext parentContext;

  const VoiceCommandButton({
    Key? key,
    required this.db,
    required this.parentContext,
  }) : super(key: key);

  @override
  State<VoiceCommandButton> createState() => _VoiceCommandButtonState();
}

class _VoiceCommandButtonState extends State<VoiceCommandButton> {
  final VoiceService _voice = VoiceService();
  bool _isListening = false;
  bool _isAvailable = true;
  bool _isChecking = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    // Don't check permission at init - wait for user to tap the button
    // This prevents premature permission prompts
  }

  @override
  void dispose() {
    _voice.stopListening();
    super.dispose();
  }

  Future<void> _requestPermissionAndListen() async {
    // Explicitly request microphone permission first
    setState(() => _isChecking = true);
    
    // Always request permission explicitly - don't rely on speech_to_text
    final status = await Permission.microphone.request();
    
    setState(() => _isChecking = false);
    
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        setState(() => _permissionDenied = true);
        // Show a dialog that forces user to go to settings
        showDialog(
          context: widget.parentContext,
          builder: (context) => AlertDialog(
            title: const Text('Microphone Permission Required'),
            content: const Text('Voice commands need microphone access. Please enable it in Settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Open app settings
                  AppSettings.openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      } else {
        // Just denied this time, can try again
        setState(() => _permissionDenied = false);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          const SnackBar(
            content: Text('Please allow microphone access to use voice commands'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    // Permission granted, now check if speech recognition is available
    final isAvailable = await _voice.isAvailable;
    
    if (!isAvailable) {
      setState(() => _permissionDenied = false);
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        const SnackBar(
          content: Text('Voice recognition not available on this device'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    // Everything is ready - start listening
    setState(() => _permissionDenied = false);
    await _startListening();
  }

  Future<void> _startListening() async {
    setState(() => _isListening = true);

    try {
      // Create parser and handler
      final parser = CommandParser();
      final handler = TaskAiHandler(
        voice: _voice,
        parser: parser,
        db: widget.db,
        context: widget.parentContext,
      );
      
      await handler.handleVoiceCommand();
    } catch (e) {
      await _voice.speak("Sorry, something went wrong. Please try again.");
    } finally {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return FloatingActionButton(
        onPressed: null,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    if (_permissionDenied) {
      return FloatingActionButton(
        onPressed: _requestPermissionAndListen,
        backgroundColor: Colors.orange,
        child: Icon(Icons.mic_off, color: Colors.white),
        tooltip: 'Tap to enable microphone permission',
      );
    }

    // Normal state - blue button, prompts for permission when tapped
    return FloatingActionButton(
      onPressed: _isListening ? null : _requestPermissionAndListen,
      backgroundColor: _isListening ? Colors.red : Colors.blue,
      child: _isListening
          ? Icon(Icons.mic, color: Colors.white)
          : Icon(Icons.mic_none, color: Colors.white),
      tooltip: _permissionDenied ? 'Enable microphone' : 'Voice Command',
    );
  }
}
