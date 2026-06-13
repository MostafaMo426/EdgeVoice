import 'dart:convert';
import 'dart:io';
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
      debugPrint("[VOICE] 🌐 Initializing Web STT Engine...");
      _webSpeech = stt.SpeechToText();
      try {
        bool available = await _webSpeech!.initialize(
          onStatus: (s) => debugPrint("[VOICE] Web STT Status: $s"),
          onError: (e) => debugPrint("[VOICE] Web STT Error: $e"),
        );
        debugPrint("[VOICE] Web STT Available: $available");
      } catch (e) {
        debugPrint("[VOICE] Web STT Init Exception: $e");
      }
    } else {
      try {
        debugPrint("[VOICE] 📱 Initializing Vosk Offline Engine...");
        _vosk = VoskFlutterPlugin.instance();
        
        // 1. Extract model from assets
        // This copies en-us.zip from assets to app documents and unzips it.
        final modelPath = await ModelLoader().loadFromAssets('assets/models/en-us.zip');
        debugPrint("[VOICE] Model base directory: $modelPath");

        // 2. SMART PATH CHECK (Handle nested zip issues)
        String finalModelPath = modelPath;
        // If the user zipped the folder 'en-us' instead of the contents, 
        // the files are in en-us/en-us/.
        Directory dir = Directory(modelPath);
        if (dir.existsSync()) {
          List<FileSystemEntity> entities = dir.listSync();
          // Check if there's only one item and it's a directory named en-us
          if (entities.length == 1 && entities.first is Directory && entities.first.path.endsWith("en-us")) {
             debugPrint("[VOICE] 📂 Detected nested model folder. Adjusting path...");
             finalModelPath = entities.first.path;
          }
        }
        
        debugPrint("[VOICE] Final Model Path used: $finalModelPath");

        // 3. Create Model and Recognizer
        _model = await _vosk!.createModel(finalModelPath);
        _recognizer = await _vosk!.createRecognizer(model: _model!, sampleRate: 16000);
        
        debugPrint("[VOICE] ✅ Vosk Engine Ready for Offline commands");
      } catch (e) {
        debugPrint("[VOICE] ❌ Vosk Fatal Init Error: $e");
        _realtimeText = "Voice Error. Restart App.";
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  void updatePairingProvider(DevicePairingProvider provider) {
    _pairingProvider = provider;
  }

  Future<void> startRecording() async {
    if (_isInitializing) {
      debugPrint("[VOICE] ⏳ Blocked: Engine still initializing...");
      return;
    }

    // RESET ALL STATE FOR A FRESH SESSION
    _lastTranscription = null;
    _realtimeText = "";
    notifyListeners();
    debugPrint("[VOICE] 🎤 Starting fresh session...");

    if (kIsWeb) {
      if (_webSpeech == null) return;
      try {
        _isRecording = true;
        await _webSpeech!.listen(
          onResult: (result) {
            _realtimeText = result.recognizedWords;
            if (result.finalResult) {
               _lastTranscription = result.recognizedWords;
               debugPrint("[VOICE] Web Result: ${result.recognizedWords}");
            }
            notifyListeners();
          },
        );
        notifyListeners();
      } catch (e) {
        debugPrint("[VOICE] Web Listen Error: $e");
        _isRecording = false;
        _realtimeText = "Browser MIC error";
        notifyListeners();
      }
    } else {
      // Mobile Vosk Path
      if (_model == null) {
        await _initEngine();
        if (_model == null) return;
      }

      if (await Permission.microphone.request().isGranted) {
        try {
          debugPrint("[VOICE] 🔊 Starting local speech service...");
          _speechService = await _vosk!.initSpeechService(_recognizer!);
          
          _isRecording = true;
          _lastTranscription = null;
          _realtimeText = "Listening (Offline)...";
          notifyListeners();

          _speechService!.onPartial().listen((partial) {
            try {
              final data = jsonDecode(partial);
              String text = (data['partial'] ?? "").toString().trim();
              if (text.isNotEmpty) {
                _realtimeText = text;
                // Use a safe notification
                if (_isRecording) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
                }
              }
            } catch (e) {
              debugPrint("Vosk Partial Parse Error: $e");
            }
          });

          _speechService!.onResult().listen((result) {
            try {
              final data = jsonDecode(result);
              String text = (data['text'] ?? "").toString().trim();
              if (text.isNotEmpty) {
                debugPrint("[VOICE] 📝 Local Final Result: $text");
                _lastTranscription = text;
                _realtimeText = text;
                WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
              }
            } catch (e) {
              debugPrint("Vosk Result Parse Error: $e");
            }
          });

          await _speechService!.start();
        } catch (e) {
          debugPrint("Vosk runtime error: $e");
          _isRecording = false;
          _realtimeText = "Vosk start failed";
          notifyListeners();
        }
      } else {
        _realtimeText = "Microphone Permission Required";
        notifyListeners();
      }
    }
  }

  Future<void> stopAndProcess() async {
    if (!_isRecording) return;

    debugPrint("[VOICE] 🛑 Stopping microphone...");
    if (kIsWeb) {
      await _webSpeech?.stop();
    } else {
      await _speechService?.stop();
    }
    
    _isRecording = false;
    
    // DELAY: Give the recognizer a moment to emit the final 'onResult'
    await Future.delayed(const Duration(milliseconds: 500));

    // CAPTURE FINAL TEXT
    String capturedText = (_lastTranscription ?? _realtimeText).trim();
    debugPrint("[VOICE] Processing final capture: '$capturedText'");
    
    // Check if the captured text is just the initial placeholder or empty
    if (capturedText.toLowerCase().contains("listening") || capturedText.isEmpty) {
      debugPrint("[VOICE] ⚠️ No valid speech detected. Resetting.");
      _lastTranscription = null;
      _realtimeText = "";
      notifyListeners();
      return;
    }

    // UI Feedback: Show "Captured" for a moment
    _realtimeText = "Captured: $capturedText";
    _lastTranscription = capturedText;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 2000)); 

    // PROCESS COMMAND
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    debugPrint("[VOICE] Interpreted технические codes: ${hardwareCommands.join(' ')}");

    await Future.delayed(const Duration(milliseconds: 2000));

    for (var cmd in hardwareCommands) {
      if (_pairingProvider?.isConnected ?? false) {
        debugPrint("[VOICE] 🚀 BLE SEND: $cmd");
        await _pairingProvider!.sendCommandViaBLE(cmd);
        
        String logDeviceName = "Device ($cmd)";
        if (cmd.contains("R1")) logDeviceName = "Living Lights";
        if (cmd.contains("R2")) logDeviceName = "AC Unit";
        if (cmd.contains("R3")) logDeviceName = "Bedroom Lights";
        if (cmd.contains("R4")) logDeviceName = "Bedroom TV";

        _apiService.addLog("Voice Command: $text -> $logDeviceName");
        
        // Wait between commands
        await Future.delayed(const Duration(milliseconds: 800));
      } else {
        debugPrint("[VOICE] ❌ Cannot send: Arduino not connected");
      }
    }
    
    // Reset screen
    await Future.delayed(const Duration(seconds: 1));
    _isWaitingForServer = false;
    _lastTranscription = null;
    _realtimeText = "";
    notifyListeners();
  }

  Future<List<String>> _translateToHardwareCommands(String text) async {
    text = text.toLowerCase();
    String action = text.contains("off") || text.contains("close") ? "OFF" : "ON";
    
    // GLOBAL MODES
    if (text.contains("night")) return ["R1OFF", "R2OFF", "R3OFF", "R4OFF"];
    if (text.contains("day") || text.contains("morning")) return ["R1ON", "R2ON", "R3ON", "R4ON"];

    // Indivdual relay checks based on mapping:
    // R1: Living Lights
    // R2: AC Unit
    // R3: Bed Lights
    // R4: Bed TV
    
    // SPECIFIC DEVICES (Keyword Priority)
    if (text.contains("living") && (text.contains("light") || text.contains("lamp") || text.contains("bulb"))) return ["R1$action"];
    if (text.contains("ac") || text.contains("air") || text.contains("cool") || (text.contains("living") && text.contains("unit"))) return ["R2$action"];
    if (text.contains("bed") && (text.contains("light") || text.contains("lamp") || text.contains("bulb"))) return ["R3$action"];
    if (text.contains("tv") || text.contains("television") || (text.contains("bed") && text.contains("screen"))) return ["R4$action"];
    
    // Fallbacks (If room not mentioned)
    if (text.contains("light") || text.contains("lamp")) return ["R1$action"];
    if (text.contains("fan") || text.contains("vent")) return ["R2$action"]; // Map R2 for generic climate
    if (text.contains("television")) return ["R4$action"];

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
