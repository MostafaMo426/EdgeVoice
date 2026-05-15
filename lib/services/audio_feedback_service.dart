import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import '../config.dart';

class AudioFeedbackService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  
  // ElevenLabs Configuration
  final String _apiKey = AppConfig.elevenLabsApiKey;
  final String _voiceId = AppConfig.elevenLabsVoiceId;

  Future<void> streamSiriResponse(String text) async {
    try {
      final response = await _dio.post(
        'https://api.elevenlabs.io/v1/text-to-speech/$_voiceId',
        data: {
          "text": text,
          "model_id": "eleven_monolingual_v1",
          "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.75
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'xi-api-key': _apiKey,
            'Content-Type': 'application/json',
            'Accept': 'audio/mpeg',
          },
        ),
      );

      if (response.statusCode == 200) {
        final Uint8List audioBytes = Uint8List.fromList(response.data);
        await _audioPlayer.play(BytesSource(audioBytes));
      }
    } catch (e) {
      print("Error in ElevenLabs TTS: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
