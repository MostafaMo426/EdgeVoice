import 'package:flutter/material.dart';
import '../services/voice_command_service.dart';
import '../services/audio_feedback_service.dart';
import '../services/api_service.dart';

class EdgeVoiceVoiceProvider extends ChangeNotifier {
  final VoiceCommandService _voiceService = VoiceCommandService();
  final AudioFeedbackService _audioFeedbackService = AudioFeedbackService();
  final ApiService _apiService = ApiService();

  bool _isRecording = false;
  bool _isWaitingForServer = false;
  bool _isSpeaking = false;

  bool get isRecording => _isRecording;
  bool get isWaitingForServer => _isWaitingForServer;
  bool get isSpeaking => _isSpeaking;

  Future<void> startRecording() async {
    _isRecording = true;
    notifyListeners();
    await _voiceService.startRecording();
  }

  Future<Map<String, dynamic>?> stopAndProcess() async {
    _isRecording = false;
    _isWaitingForServer = true;
    notifyListeners();

    final path = await _voiceService.stopRecording();
    Map<String, dynamic>? result;

    if (path != null) {
      result = await _voiceService.uploadAudio(path);
      _isWaitingForServer = false;
      notifyListeners();

      if (result != null) {
        final String? actionTriggered = result['actionTriggered'];
        final String? aiReply = result['aiReply'];

        if (actionTriggered != null && actionTriggered != "UNKNOWN") {
          await _apiService.addLog("Voice Command Triggered: $actionTriggered");
        }

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
      }
    } else {
      _isWaitingForServer = false;
      notifyListeners();
    }
    return result;
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _audioFeedbackService.dispose();
    super.dispose();
  }
}
