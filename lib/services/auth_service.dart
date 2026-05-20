import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart'; // Added for MediaType
import '../config.dart';

class AuthService {
  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20), // Increased timeout
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'accept': '*/*',
        // Removed hardcoded application/json to let Dio handle it for FormData
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

  // 1b. Verify Email
  Future<String?> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _dio.post('Auth/verify-email', data: {
        'email': email,
        'code': code,
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        return null;
      }
      return "Verification failed";
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
        debugPrint("[DEBUG] Raw Login Response: ${response.data}");
        
        String token = "";
        Map<String, dynamic> userData = {};

        if (response.data is Map) {
          userData = response.data;
          token = userData['token'] ?? userData['Token'] ?? "";
        } else if (response.data is String) {
          token = response.data;
        }

        if (token.isEmpty) return "Invalid response from server";

        // Decode JWT to get info if not provided in JSON body
        final decoded = _decodeToken(token);
        debugPrint("[DEBUG] Decoded JWT for Login: $decoded");
        
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
        var rawId = userData['userId'] ?? userData['id'] ?? userData['Id'] ??
                    decoded['nameid'] ?? 
                    decoded['id'] ?? 
                    decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'];
        int userId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? "1") ?? 1;

        String? profilePicture = userData['imagePath'] ??
                                userData['ImagePath'] ??
                                userData['profilePicture'] ?? 
                                userData['imageUrl'] ??
                                userData['picture'] ?? // Added
                                decoded['imagePath'] ??
                                decoded['profilePicture'] ?? 
                                decoded['imageUrl'];

        await prefs.setString('token', token);
        await prefs.setInt('userId', userId);
        await prefs.setString('fullName', fullName);
        await prefs.setString('email', userEmail);
        
        if (profilePicture != null && profilePicture.isNotEmpty) {
          debugPrint("[DEBUG] Found profile picture during login: $profilePicture");
          await prefs.setString('profilePicture', profilePicture);
        }
        
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
      // We prioritize 'Auth/profile' as it was recently updated in Swagger
      final endpoints = [
        'Auth/profile', 
        'Auth/me', 
        'Auth/details',
        'Auth/user-info',
        'Auth/get-profile',
        if (userId != null) 'Auth/user/$userId',
        if (userId != null) 'Auth/$userId',
        if (userId != null) 'Users/$userId',
      ];
      
      for (var endpoint in endpoints) {
        try {
          debugPrint("[DEBUG] Attempting to fetch profile from: $endpoint");
          final response = await _dio.get(endpoint);
          if (response.statusCode == 200 && response.data != null) {
            // If the response is a string (e.g. error message), skip
            if (response.data is! Map) continue;
            
            final data = response.data as Map<String, dynamic>;
            
            // Standardize key extraction
            final profilePic = data['imagePath'] ?? data['imageUrl'] ?? data['profilePicture'] ?? 
                             data['ProfilePicture'] ?? data['ImagePath'] ?? data['picture'];
            
            final name = data['fullName'] ?? data['FullName'] ?? data['name'] ?? data['Name'];
            
            final prefs = await SharedPreferences.getInstance();
            if (profilePic != null) {
              debugPrint("[DEBUG] Successfully found profile picture at $endpoint: $profilePic");
              await prefs.setString('profilePicture', profilePic);
            }
            if (name != null) {
              await prefs.setString('fullName', name.toString());
            }
            
            return data;
          }
        } catch (e) {
          // Continue to next endpoint
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
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
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      debugPrint("[DEBUG] Starting upload for: ${imageFile.name}");
      
      String mimeType = "image/jpeg";
      if (imageFile.name.toLowerCase().endsWith(".png")) mimeType = "image/png";

      final bytes = await imageFile.readAsBytes();
      debugPrint("[DEBUG] Bytes read: ${bytes.length}");

      final formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
          contentType: MediaType.parse(mimeType),
        ),
      });

      // Using a completely fresh Dio instance just for this request 
      // to bypass any global interceptors or broken headers
      final uploadDio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await uploadDio.post(
        '${AppConfig.apiBaseUrl}Auth/upload-image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'accept': '*/*',
            // DO NOT set Content-Type here, Dio handles boundary automatically
          },
        ),
      );

      debugPrint("[DEBUG] RAW UPLOAD RESPONSE: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          String? url = data['imagePath'] ?? data['imageUrl'] ?? data['profilePicture'];
          if (url != null) return url;
        }
        return "UPLOAD_SUCCESS";
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint("[DEBUG] UPLOAD FAILED - STATUS: ${e.response?.statusCode}");
        debugPrint("[DEBUG] UPLOAD FAILED - DATA: ${e.response?.data}");
        debugPrint("[DEBUG] UPLOAD FAILED - ERROR: ${e.message}");
      } else {
        debugPrint("[DEBUG] UPLOAD FATAL ERROR: $e");
      }
    }
    return null;
  }

  // 6. Update Profile
  Future<bool> updateProfile({required String fullName}) async {
    try {
      // Prioritize Auth/profile as the user mentioned it's the new standard
      final response = await _dio.put('Auth/profile', data: {
        'fullName': fullName,
      });
      if (response.statusCode == 200 || response.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fullName', fullName);
        return true;
      }
    } catch (e) {
      // Fallback to update-profile if Auth/profile failed
      try {
        final response = await _dio.put('Auth/update-profile', data: {
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
