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

  // --- HELPERS ---

  Map<String, dynamic> _decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = parts[1];
      
      // Standard JWT base64url decoding
      String normalized = base64.normalize(payload);
      String decoded = utf8.decode(base64.decode(normalized));
      final decodedMap = json.decode(decoded);
      debugPrint("Decoded JWT: $decodedMap");
      return decodedMap;
    } catch (e) {
      debugPrint("Error decoding token: $e");
      return {};
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

  // 2. Sign In
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
        
        String token = "";
        Map<String, dynamic> userData = {};

        if (response.data is Map) {
          userData = response.data;
          token = userData['token'] ?? "";
        } else if (response.data is String) {
          token = response.data;
        }

        if (token.isEmpty) return "Invalid response from server";

        // Decode JWT to get info if not provided in JSON body
        final decoded = _decodeToken(token);
        
        // Extract fields with multiple possible keys (handling .NET defaults)
        String fullName = userData['fullName'] ?? userData['FullName'] ?? 
                          decoded['unique_name'] ?? 
                          decoded['name'] ?? 
                          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ??
                          "User";
        String userEmail = userData['email'] ?? userData['Email'] ?? 
                           decoded['email'] ?? 
                           decoded['sub'] ?? 
                           decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ??
                           email;
        
        // Extracting userId as String or Int, then parsing
        var rawId = userData['userId'] ?? userData['id'] ?? 
                    decoded['nameid'] ?? 
                    decoded['id'] ?? 
                    decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
        int userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? "1") ?? 1;

        String? profilePicture = userData['profilePicture'] ?? userData['ProfilePicture'] ?? decoded['profilePicture'];

        await prefs.setString('token', token);
        await prefs.setInt('userId', userId);
        await prefs.setString('fullName', fullName);
        await prefs.setString('email', userEmail);
        if (profilePicture != null) await prefs.setString('profilePicture', profilePicture);
        await prefs.setBool('isLoggedIn', true);
        
        return null; 
      }
      return "Login Failed";
    } on DioException catch (e) {
      return e.response?.data?.toString() ?? "Connection Error";
    }
  }

  // 3. Get User Profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      // Try multiple common endpoints as the Swagger might be incomplete
      final endpoints = [
        'Auth/me', 
        'Auth/profile', 
        'Auth/details',
        if (userId != null) 'Auth/user/$userId',
        if (userId != null) 'Auth/$userId',
      ];
      
      for (var endpoint in endpoints) {
        try {
          final response = await _dio.get(endpoint);
          if (response.statusCode == 200 && response.data != null) {
            // If the response is a string (e.g. error message), skip
            if (response.data is! Map) continue;
            return response.data;
          }
        } catch (e) {
          // Continue to next endpoint
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }

  // 4. Change Password
  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      final response = await _dio.put('Auth/change-password', data: {
        'email': email, // Some APIs require email to identify user
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
      if (response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Update failed'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        return {'success': false, 'message': 'The password is incorrect'};
      }
      return {'success': false, 'message': e.message ?? 'Error'};
    }
  }

  // 5. Upload Profile Image
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      
      FormData formData;
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(bytes, filename: fileName),
        });
      } else {
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
        });
      }

      final response = await _dio.post('Auth/upload-image', data: formData);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // If the server returns the URL in the body
        if (response.data != null) {
          if (response.data is Map) {
            return response.data['imageUrl'] ?? response.data['profilePicture'] ?? "UPLOAD_SUCCESS";
          } else if (response.data is String && response.data.toString().startsWith('http')) {
            return response.data.toString();
          }
        }
        
        // If the server returns 200 but no body, it's still a success.
        // We'll return a marker and let the UI handle it (e.g., by refreshing profile)
        return "UPLOAD_SUCCESS";
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
    return null;
  }

  // 6. Update Profile
  Future<bool> updateProfile({required String fullName}) async {
    try {
      final response = await _dio.put('Auth/update-profile', data: {
        'fullName': fullName,
      });
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', fullName);
        return true;
      }
    } catch (e) {
      // Fallback to general profile update
      try {
        final response = await _dio.put('Auth/profile', data: {
          'fullName': fullName,
        });
        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fullName', fullName);
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> bypassLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('token', 'bypass_token'); // Temporary token
    await prefs.setInt('userId', 1); // Default User ID
    await prefs.setString('fullName', 'Demo User');
    await prefs.setString('email', 'demo@example.com');
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
