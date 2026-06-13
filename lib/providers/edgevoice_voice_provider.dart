import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Conditional import to handle Web/Mobile compilation
import 'package:vosk_flutter_2/vosk_flutter_2.dart' if (dart.library.html) 'vosk_stub.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'device_pairing_provider.dart';

class EdgeVoiceVoiceProvider extends ChangeNotifier {
  // Mobile Offline (Vosk)
  VoskFlutterPlugin? _vosk;
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  // Web Fallback (STT)
  stt.SpeechToText? _webSpeech;

  // final AudioFeedbackService _audioFeedbackService = AudioFeedbackService();
  final ApiService _apiService = ApiService();
  DevicePairingProvider? _pairingProvider;

  bool _isRecording = false;
  bool _isWaitingForServer = false;
  bool _isSpeaking = false;
  bool _isInitializing = false;
  String? _lastTranscription;
  String _realtimeText = "";

  bool get isRecording => _isRecording;
  bool get isWaitingForServer => _isWaitingForServer;
  bool get isSpeaking => _isSpeaking;
  String? get lastTranscription => _lastTranscription;
  String get realtimeText => _realtimeText;

  EdgeVoiceVoiceProvider() {
    _initEngine();
  }

  Future<void> _initEngine() async {
    _isInitializing = true;
    notifyListeners();

    if (kIsWeb) {
      _webSpeech = stt.SpeechToText();
      try {
        bool available = await _webSpeech!.initialize();
        debugPrint("[VOICE] Web STT Initialized: $available");
      } catch (e) {
        debugPrint("[VOICE] Web STT Init Error: $e");
      }
    } else {
      try {
        _vosk = VoskFlutterPlugin.instance();
        // The user must zip their model folder to assets/models/en-us.zip
        final modelPath = await ModelLoader().loadFromAssets('assets/models/en-us.zip');
        _model = await _vosk!.createModel(modelPath);
        _recognizer = await _vosk!.createRecognizer(model: _model!, sampleRate: 16000);
        debugPrint("[VOICE] Vosk Offline Engine Initialized");
      } catch (e) {
        debugPrint("[VOICE] Vosk Init Error: $e");
        _realtimeText = "Vosk model missing or error. Check assets/models/en-us.zip";
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  void updatePairingProvider(DevicePairingProvider provider) {
    _pairingProvider = provider;
  }

  Future<void> startRecording() async {
    if (_isInitializing) return;

    if (kIsWeb) {
      if (_webSpeech == null) return;
      await _webSpeech!.listen(
        onResult: (result) {
          _realtimeText = result.recognizedWords;
          if (result.finalResult) _lastTranscription = result.recognizedWords;
          notifyListeners();
        },
      );
      _isRecording = true;
      notifyListeners();
    } else {
      // Mobile Logic
      if (_model == null) {
        await _initEngine();
        if (_model == null) return;
      }

      if (await Permission.microphone.request().isGranted) {
        try {
          _speechService = await _vosk!.initSpeechService(_recognizer!);
          
          _isRecording = true;
          _lastTranscription = null;
          _realtimeText = "Listening (Offline)...";
          notifyListeners();

          _speechService!.onPartial().listen((partial) {
            try {
              final data = jsonDecode(partial);
              String text = data['partial'] ?? "";
              if (text.isNotEmpty) {
                _realtimeText = text;
                WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
              }
            } catch (e) {
              debugPrint("Vosk Partial Error: $e");
            }
          });

          _speechService!.onResult().listen((result) {
            try {
              final data = jsonDecode(result);
              String text = data['text'] ?? "";
              if (text.isNotEmpty) {
                _lastTranscription = text;
                _realtimeText = text;
                WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
              }
            } catch (e) {
              debugPrint("Vosk Result Error: $e");
            }
          });

          await _speechService!.start();
        } catch (e) {
          debugPrint("Vosk Start Error: $e");
          _isRecording = false;
          notifyListeners();
        }
      }
    }
  }

  Future<void> stopAndProcess() async {
    if (!_isRecording) return;

    if (kIsWeb) {
      await _webSpeech?.stop();
    } else {
      await _speechService?.stop();
    }
    
    _isRecording = false;
    // Prioritize the last formal transcription, fallback to the last partial we heard
    String capturedText = (_lastTranscription ?? _realtimeText).trim();
    
    // Check if the captured text is just the initial placeholder
    if (capturedText.toLowerCase().contains("listening") || capturedText.isEmpty) {
      _lastTranscription = null;
      _realtimeText = "";
      notifyListeners();
      return;
    }

    // 1. Keep the "Captured" text visible for a moment so the user can read it
    _realtimeText = "Captured: $capturedText";
    _lastTranscription = capturedText;
    notifyListeners();
    debugPrint("[VOICE] 📝 CAPTURED TEXT: $capturedText");
    await Future.delayed(const Duration(milliseconds: 2500)); 

    // 2. Process and Interpret
    await _processCommand(capturedText);
  }

  Future<void> _processCommand(String text) async {
    List<String> hardwareCommands = await _translateToHardwareCommands(text);
    _isWaitingForServer = true;
    
    // Show interpreted command
    String displayCmds = hardwareCommands.isEmpty ? "Unknown: $text" : "Interpreted: ${hardwareCommands.join(' ')}";
    _realtimeText = displayCmds;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    debugPrint("[VOICE] ⚙️ $displayCmds");

    // Let the user read the interpretation for 3.5 seconds
    await Future.delayed(const Duration(milliseconds: 3500));

    for (var cmd in hardwareCommands) {
      if (_pairingProvider?.isConnected ?? false) {
        // Await each command to prevent flooding
        debugPrint("[VOICE] 🚀 Sending Interpreted Command: $cmd");
        await _pairingProvider!.sendCommandViaBLE(cmd);
        
        String logDeviceName = "Device ($cmd)";
        if (cmd.contains("R1")) logDeviceName = "Living Lights";
        if (cmd.contains("R2")) logDeviceName = "AC Unit";
        if (cmd.contains("R3")) logDeviceName = "Bedroom Lights";
        if (cmd.contains("R4")) logDeviceName = "Bedroom TV";

        _apiService.addLog("Voice Command: $text -> $logDeviceName");
        
        // Brief pause between sequential commands
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    // Keep visible for 1 more second after sending
    await Future.delayed(const Duration(seconds: 1));
    
    _isWaitingForServer = false;
    _lastTranscription = null;
    notifyListeners();
  }

  Future<List<String>> _translateToHardwareCommands(String text) async {
    text = text.toLowerCase();
    String action = text.contains("off") || text.contains("close") ? "OFF" : "ON";
    
    // PROJECT-SPECIFIC RELAY MAPPING RULES:
    // R1 => Living Room Lights
    // R2 => Living Room AC
    // R3 => Bedroom Lights
    // R4 => Bedroom TV

    // 1. HANDLE GLOBAL MODES (Day/Night)
    if (text.contains("night")) {
      // Night Mode => Everything OFF
      return ["R1OFF", "R2OFF", "R3OFF", "R4OFF"];
    }
    if (text.contains("day") || text.contains("morning")) {
      // Day Mode => Everything ON
      return ["R1ON", "R2ON", "R3ON", "R4ON"];
    }

    // 2. INDIVIDUAL DEVICE MAPPINGS
    if (text.contains("living") && (text.contains("light") || text.contains("lamp"))) return ["R1$action"];
    if (text.contains("living") && (text.contains("ac") || text.contains("air") || text.contains("unit"))) return ["R2$action"];
    if (text.contains("bed") && (text.contains("light") || text.contains("lamp"))) return ["R3$action"];
    if (text.contains("bed") && (text.contains("tv") || text.contains("television"))) return ["R4$action"];
    
    // Default fallback
    if (text.contains("light")) return ["R1$action"];
    if (text.contains("ac") || text.contains("air")) return ["R2$action"];
    if (text.contains("tv") || text.contains("television")) return ["R4$action"];

    return [];
  }

  @override
  void dispose() {
    _speechService?.stop();
    _webSpeech?.stop();
    _recognizer?.dispose();
    _model?.dispose();
    super.dispose();
  }
}
