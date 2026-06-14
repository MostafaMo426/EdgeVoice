import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'device_pairing_provider.dart';

class EdgeVoiceVoiceProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final ApiService _apiService = ApiService();
  DevicePairingProvider? _pairingProvider;

  bool _isRecording = false;
  bool _isWaitingForServer = false;
  bool _isSpeaking = false;
  String? _lastTranscription;
  String _realtimeText = "";

  bool get isRecording => _isRecording;
  bool get isWaitingForServer => _isWaitingForServer;
  bool get isSpeaking => _isSpeaking;
  String? get lastTranscription => _lastTranscription;
  String get realtimeText => _realtimeText;

  EdgeVoiceVoiceProvider() {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize(
        onStatus: (status) => debugPrint('STT Status: $status'),
        onError: (error) => debugPrint('STT Error: $error'),
      );
    } catch (e) {
      debugPrint("STT Init Error: $e");
    }
  }

  void updatePairingProvider(DevicePairingProvider provider) {
    _pairingProvider = provider;
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    bool hasPermission = await Permission.microphone.request().isGranted;
    if (!hasPermission) {
      _realtimeText = "Microphone permission denied";
      notifyListeners();
      return;
    }

    bool available = await _speech.initialize();
    if (available) {
      _isRecording = true;
      _lastTranscription = null;
      _realtimeText = "Listening...";
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _realtimeText = result.recognizedWords;
          if (result.finalResult) {
            _lastTranscription = result.recognizedWords;
          }
          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        localeId: "en-US",
        cancelOnError: false,
      );
    } else {
      _realtimeText = "Speech recognition unavailable";
      notifyListeners();
    }
  }

  Future<void> stopAndProcess() async {
    if (!_isRecording) return;

    await _speech.stop();
    _isRecording = false;
    
    // Brief delay to ensure final result is captured
    await Future.delayed(const Duration(milliseconds: 800));

    String capturedText = (_lastTranscription ?? _realtimeText).trim();
    if (capturedText.isEmpty || capturedText.toLowerCase() == "listening...") {
      _realtimeText = "";
      _lastTranscription = null;
      notifyListeners();
      return;
    }

    _realtimeText = "Captured: $capturedText";
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 2));
    await _processCommand(capturedText);
  }

  Future<void> _processCommand(String text) async {
    List<String> hardwareCommands = await _translateToHardwareCommands(text);
    _isWaitingForServer = true;
    
    if (hardwareCommands.isEmpty) {
      _realtimeText = "Unknown command: $text";
    } else {
      _realtimeText = "Executing: $text";
    }
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 2000));

    for (var cmd in hardwareCommands) {
      if (_pairingProvider?.isConnected ?? false) {
        await _pairingProvider!.sendCommandViaBLE(cmd);
        
        String logDeviceName = "Device ($cmd)";
        if (cmd.contains("R1")) logDeviceName = "Living Lights";
        if (cmd.contains("R2")) logDeviceName = "AC Unit";
        if (cmd.contains("R3")) logDeviceName = "Bedroom Lights";
        if (cmd.contains("R4")) logDeviceName = "Bedroom TV";

        _apiService.addLog("Voice Command: $text -> $logDeviceName");
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    }
    
    _isWaitingForServer = false;
    _lastTranscription = null;
    _realtimeText = "";
    notifyListeners();
  }

  Future<List<String>> _translateToHardwareCommands(String text) async {
    text = text.toLowerCase();
    String action = text.contains("off") || text.contains("close") ? "OFF" : "ON";
    
    if (text.contains("night")) return ["R1OFF", "R2OFF", "R3OFF", "R4OFF"];
    if (text.contains("day") || text.contains("morning")) return ["R1ON", "R2ON", "R3ON", "R4ON"];

    if (text.contains("living")) {
       if (text.contains("light") || text.contains("lamp")) return ["R1$action"];
       if (text.contains("ac") || text.contains("air") || text.contains("unit")) return ["R2$action"];
    } else if (text.contains("bed")) {
       if (text.contains("light") || text.contains("lamp")) return ["R3$action"];
       if (text.contains("tv") || text.contains("television")) return ["R4$action"];
    }

    if (text.contains("light")) return ["R1$action"];
    if (text.contains("ac")) return ["R2$action"];
    if (text.contains("tv")) return ["R4$action"];

    return [];
  }
}
