import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/audio_feedback_service.dart';
import '../services/api_service.dart';
import 'device_pairing_provider.dart';

class EdgeVoiceVoiceProvider extends ChangeNotifier {
  // Use dynamic to prevent type-check crashes during hot reload if library isn't linked
  dynamic _speech; 
  final AudioFeedbackService _audioFeedbackService = AudioFeedbackService();
  final ApiService _apiService = ApiService();
  DevicePairingProvider? _pairingProvider;

  bool _isRecording = false;
  bool _isWaitingForServer = false;
  bool _isSpeaking = false;
  String? _lastTranscription;
  String _realtimeText = "";

  // Helper to safely get the speech instance
  stt.SpeechToText? get _speechInstance {
    try {
      _speech ??= stt.SpeechToText();
      return _speech as stt.SpeechToText;
    } catch (e) {
      debugPrint("Could not initialize SpeechToText library: $e");
      return null;
    }
  }

  bool get isRecording => _isRecording;
  bool get isWaitingForServer => _isWaitingForServer;
  bool get isSpeaking => _isSpeaking;
  String? get lastTranscription => _lastTranscription;
  String get realtimeText => _realtimeText;

  void updatePairingProvider(DevicePairingProvider provider) {
    _pairingProvider = provider;
  }

  Future<void> startRecording() async {
    final speech = _speechInstance;
    if (speech == null) {
      _realtimeText = "Voice features unavailable. Please restart the app.";
      notifyListeners();
      return;
    }

    // Reset everything before a new recording
    _lastTranscription = null;
    _realtimeText = "";
    _isWaitingForServer = false;
    _isSpeaking = false;
    
    try {
      if (speech.isListening) return;

      bool available = await speech.initialize(
        onStatus: (status) {
          debugPrint('Speech Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_isRecording) {
              Future.delayed(const Duration(milliseconds: 200), () => stopAndProcess());
            }
          }
        },
        onError: (error) {
          debugPrint('Speech Error: ${error.errorMsg}');
          _isRecording = false;
          notifyListeners();
        },
      );

      if (available) {
        _isRecording = true;
        _lastTranscription = null;
        _realtimeText = "Listening...";
        notifyListeners();

        await speech.listen(
          onResult: (result) {
            _realtimeText = result.recognizedWords;
            if (result.finalResult) {
              _lastTranscription = result.recognizedWords;
            }
            notifyListeners();
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 2), 
          localeId: "en-US", // Force English recognition
        );
      } else {
        _realtimeText = "Speech not available on this device";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error starting speech: $e");
      _realtimeText = "Microphone error. Check permissions.";
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> stopAndProcess() async {
    if (!_isRecording || _speech == null) return;
    
    final speech = _speech as stt.SpeechToText;
    await speech.stop();
    _isRecording = false;
    
    // Capture the text we have so far
    String capturedText = (_lastTranscription ?? _realtimeText).trim();
    if (capturedText == "Processing..." || capturedText == "Listening...") capturedText = "";
    
    // IMMEDIATELY WIPE ALL STATE
    _lastTranscription = null;
    _realtimeText = "";
    _isWaitingForServer = false;
    _isSpeaking = false;
    notifyListeners();

    if (capturedText.isNotEmpty) {
      _isWaitingForServer = true;
      notifyListeners();

      debugPrint("Processing text: $capturedText");
      
      try {
        bool sentViaBle = false;
        
        // AUTOMATIC HYBRID LOGIC
        if (_pairingProvider != null && _pairingProvider!.isConnected) {
          debugPrint("[HYBRID] Connected via BLE. Sending local command...");
          sentViaBle = await _pairingProvider!.sendCommandViaBLE(capturedText);
          if (sentViaBle) {
            await _apiService.addLog("Command sent locally via BLE: $capturedText");
          }
        }

        if (!sentViaBle) {
          debugPrint("[HYBRID] No BLE connection or BLE failed. Sending via Cloud API...");
          await _apiService.executeVoiceCommand(capturedText);
        }
        
        // Short delay to show "Processing" state to user
        await Future.delayed(const Duration(milliseconds: 1500));
        
      } catch (e) {
        debugPrint("Voice Processing Error: $e");
      } finally {
        // FINAL RESET
        _isWaitingForServer = false;
        _isSpeaking = false;
        _lastTranscription = null;
        _realtimeText = "";
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _audioFeedbackService.dispose();
    super.dispose();
  }
}
