import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'accept': '*/*',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ));

    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

  // 1. Sign Up
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dio.post('Auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
      }
      return "Error: ${response.statusCode}";
    } on DioException catch (e) {
      return e.response?.data?.toString() ?? e.message;
    }
  }

  // 2. Sign In (Updated with Token Storage)
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('Auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        
        // Ensure response data is a Map
        if (response.data is! Map) {
          return "Invalid server response (HTML)";
        }

        // SAVE TOKEN AND USER ID
        String token = response.data['token'] ?? "";
        String refreshToken = response.data['refreshToken'] ?? "";
        int userId = response.data['userId'] ?? 1; // Default to 1 if not provided
        
        await prefs.setString('token', token);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setInt('userId', userId);
        await prefs.setBool('isLoggedIn', true);
        
        print("Login Success! Token saved.");
        return null; 
      }
      return "Login Failed";
    } on DioException catch (e) {
      return e.response?.data?.toString() ?? "Connection Error";
    }
  }

  Future<void> bypassLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('token', 'bypass_token'); // Temporary token
    await prefs.setInt('userId', 1); // Default User ID
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
