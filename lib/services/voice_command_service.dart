import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';

class VoiceCommandService {
  final AudioRecorder _recorder = AudioRecorder();
  final Dio _dio = Dio(); 

  VoiceCommandService() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.headers = {
      'accept': '*/*',
      'ngrok-skip-browser-warning': 'true',
    };

    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/voice_cmd.raw';
      
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      await _recorder.start(config, path: path);
    }
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  Future<Map<String, dynamic>?> uploadAudio(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      final formData = FormData.fromMap({
        'audio': MultipartFile.fromBytes(bytes, filename: 'command.raw'),
      });

      // Using AppConfig.apiBaseUrl + 'command'
      final response = await _dio.post(
        'command',
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("Error uploading audio: $e");
    }
    return null;
  }

  void dispose() {
    _recorder.dispose();
  }
}
