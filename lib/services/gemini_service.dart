import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';

class GeminiService {
  final Dio _dio = Dio();
  final String _apiKey = AppConfig.geminiApiKey;

  Future<String?> getAiResponse(String prompt) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        },
      );

      if (response.statusCode == 200) {
        final candidates = response.data['candidates'] as List;
        if (candidates.isNotEmpty) {
          final text = candidates[0]['content']['parts'][0]['text'];
          return text;
        }
      }
    } catch (e) {
      debugPrint("Error calling Gemini: $e");
    }
    return null;
  }
}
