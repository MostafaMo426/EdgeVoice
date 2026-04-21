import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
      },
    ));

    // Allow self-signed certificates for Ngrok (Only on Mobile/Desktop)
    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    // --- ADDED: INTERCEPTOR TO ATTACH TOKEN ---
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

  // --- COMMANDS ---

  // Updated to match the backend dev's new format
  Future<bool> addCommand({required String triggerWord, required String action}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 1;

      final response = await _dio.post('/Commands', data: {
        "triggerWord": triggerWord,
        "action": action,
        "userId": userId
      });
      
      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      print("Error adding command: $e");
      return false;
    }
  }

  Future<List<dynamic>> getPendingCommands() async {
    try {
      final response = await _dio.get('/Commands/pending');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching pending: $e");
    }
    return [];
  }

  Future<bool> markCommandAsExecuted(int id) async {
    try {
      final response = await _dio.put('/Commands/$id/executed');
      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getCommands() async {
    try {
      final response = await _dio.get('/Commands');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching commands: $e");
    }
    return [];
  }

  // --- LOGS ---

  Future<bool> addLog(String message) async {
    try {
      final response = await _dio.post('/Logs', data: {"message": message});
      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getLogs() async {
    try {
      final response = await _dio.get('/Logs');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching logs: $e");
    }
    return [];
  }
}
