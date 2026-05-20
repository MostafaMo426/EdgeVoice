import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> startRecording() async {
    if (await _recorder.hasPermission()) {
      String? path;
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/voice_cmd.wav';
      }
      
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      );

      await _recorder.start(config, path: path ?? '');
    }
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  Future<Map<String, dynamic>?> uploadAudio(String path) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        final response = await Dio().get(path, options: Options(responseType: ResponseType.bytes));
        bytes = Uint8List.fromList(response.data);
      } else {
        final file = File(path);
        bytes = await file.readAsBytes();
      }
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'command.wav'),
      });

      // Updated to match Swagger: /api/Audio/upload
      final response = await _dio.post(
        'Audio/upload',
        data: formData,
      );

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return response.data;
        } else if (response.data is String) {
          try {
            return jsonDecode(response.data);
          } catch (e) {
            return {'transcription': response.data};
          }
        }
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        debugPrint("Error uploading audio: ${e.response?.statusCode} - ${e.response?.data}");
      } else {
        debugPrint("Error uploading audio: $e");
      }
    }
    return null;
  }

  void dispose() {
    _recorder.dispose();
  }
}
