import 'dart:async';

// Stub for Web compilation to prevent ffi-related crashes
class VoskFlutterPlugin {
  static instance() => throw UnsupportedError("Vosk is mobile-only");
  Future<Model> createModel(String path) => Future.error("Stub");
  Future<Recognizer> createRecognizer({required Model model, required int sampleRate}) => Future.error("Stub");
  Future<SpeechService> initSpeechService(Recognizer recognizer) => Future.error("Stub");
}

class ModelLoader {
  Future<String> loadFromAssets(String path) => Future.value("");
}

class Model {
  void dispose() {}
}

class Recognizer {
  int get id => 0;
  int get sampleRate => 16000;
  void dispose() {}
}

class SpeechService {
  Stream<String> onPartial() => const Stream.empty();
  Stream<String> onResult() => const Stream.empty();
  Future<void> start() async {}
  Future<void> stop() async {}
  void dispose() {}
}
