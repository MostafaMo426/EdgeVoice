import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/audio_feedback_service.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';

class EdgeVoiceVoiceProvider extends ChangeNotifier {
  // Use dynamic to prevent type-check crashes during hot reload if library isn't linked
  dynamic _speech; 
  final AudioFeedbackService _audioFeedbackService = AudioFeedbackService();
  final ApiService _apiService = ApiService();
  final GeminiService _geminiService = GeminiService();

  bool _isRecording = false;
  bool _isWaitingForServer = false;
  bool _isSpeaking = false;
  String? _lastTranscription;
  String? _lastAiResponse;
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
  String? get lastAiResponse => _lastAiResponse;
  String get realtimeText => _realtimeText;

  Future<void> startRecording() async {
    final speech = _speechInstance;
    if (speech == null) {
      _realtimeText = "Voice features unavailable. Please restart the app.";
      notifyListeners();
      return;
    }

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
        _lastAiResponse = null;
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
        );
      } else {
        _realtimeText = "Speech not available on this browser";
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error starting speech: $e");
      _realtimeText = "Microphone error. Check permissions or HTTPS.";
      _isRecording = false;
      notifyListeners();
    }
  }

  Future<void> stopAndProcess() async {
    if (!_isRecording || _speech == null) return;
    
    final speech = _speech as stt.SpeechToText;
    await speech.stop();
    _isRecording = false;
    _isWaitingForServer = true;
    _realtimeText = "Processing...";
    notifyListeners();

    String? text = _lastTranscription ?? _realtimeText;
    if (text == "Processing..." || text == "Listening...") text = "";
    
    if (text.isNotEmpty) {
      debugPrint("Processing text: $text");
      await _apiService.executeVoiceCommand(text);
      String? aiReply = await _geminiService.getAiResponse(text);
      
      _lastAiResponse = aiReply;
      _isWaitingForServer = false;
      notifyListeners();

      if (aiReply != null && aiReply.isNotEmpty) {
        _isSpeaking = true;
        notifyListeners();
        try {
          await _audioFeedbackService.streamSiriResponse(aiReply);
        } catch (e) {
          debugPrint("TTS Error: $e");
        }
        _isSpeaking = false;
        notifyListeners();
      }
    } else {
      _isWaitingForServer = false;
      _realtimeText = "No command detected";
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isRecording && !_isWaitingForServer) {
          _realtimeText = "";
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _audioFeedbackService.dispose();
    super.dispose();
  }
}
