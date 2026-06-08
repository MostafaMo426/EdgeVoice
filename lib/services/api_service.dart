import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'bypass_service.dart'; // Import the bypass service

class ApiService {
  late final Dio _dio;
  final BypassService _bypass = BypassService();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    ));

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
        if (kDebugMode) {
          debugPrint("🌐 API Request: ${options.method} ${options.baseUrl}${options.path}");
          if (options.queryParameters.isNotEmpty) debugPrint("❓ Query: ${options.queryParameters}");
          if (options.data != null) debugPrint("📦 Body: ${options.data}");
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint("✅ API Response [${response.statusCode}]: ${response.requestOptions.path}");
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          debugPrint("❌ API Error [${e.response?.statusCode}]: ${e.requestOptions.path}");
          debugPrint("💬 Message: ${e.message}");
          if (e.type == DioExceptionType.connectionError) {
            debugPrint("⚠️ Network/CORS Error: If you are on Web, the server might be blocking the request.");
            debugPrint("🔗 Target URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}");
          }
          if (e.response?.data != null) debugPrint("📄 Data: ${e.response?.data}");
        }
        
        if (e.response?.statusCode == 401) {
          // Token expired, attempt refresh
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refreshToken');
          
          if (refreshToken != null) {
            try {
              // Assuming a refresh endpoint exists
              final refreshResponse = await _dio.post('Auth/refresh', data: {
                'token': prefs.getString('token'),
                'refreshToken': refreshToken,
              });
              
              if (refreshResponse.statusCode == 200) {
                final newToken = refreshResponse.data['token'];
                await prefs.setString('token', newToken);
                
                // Retry the original request
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(e.requestOptions);
                return handler.resolve(response);
              }
            } catch (refreshError) {
              debugPrint("Refresh token failed: $refreshError");
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> _isBypass() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') == 'bypass_token';
  }

  // --- ROOMS API ---

  Future<List<dynamic>> getRooms() async {
    if (await _isBypass()) return _bypass.getRooms();
    try {
      // Updated to match Swagger: /api/Rooms/my-rooms has no parameters
      final response = await _dio.get('Rooms/my-rooms');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
    }
    return [];
  }

  Future<bool> addRoom(String name) async {
    if (await _isBypass()) return _bypass.addRoom(name);
    try {
      // Updated to match Swagger RoomRequest: only 'name' is allowed
      try {
        final response = await _dio.post('Rooms/add', data: {
          'name': name,
        });
        if (response.statusCode == 200 || response.statusCode == 201) return true;
      } catch (e) {
        debugPrint("Failed to add room via Rooms/add: $e");
      }

      // Fallback: Try just /api/Rooms
      final response2 = await _dio.post('Rooms', data: {
        'name': name,
      });
      return response2.statusCode == 200 || response2.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding room: $e");
      return false;
    }
  }

  Future<bool> updateRoom(int id, String name) async {
    if (await _isBypass()) return _bypass.updateRoom(id, name);
    try {
      final response = await _dio.put('Rooms/$id', data: {'name': name});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error updating room: $e");
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    if (await _isBypass()) return _bypass.deleteRoom(id);
    try {
      final response = await _dio.delete('Rooms/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error deleting room: $e");
      return false;
    }
  }

  Future<List<dynamic>> getRoomDevices(int roomId) async {
    if (await _isBypass()) return _bypass.getRoomDevices(roomId);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      Response response;
      try {
        // Try fetching all devices first
        response = await _dio.get('Devices');
      } catch (e) {
        // Fallback: Try with userId if the server requires it
        response = await _dio.get('Devices', queryParameters: {'userId': userId});
      }

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).where((d) => 
          (d['roomId'] == roomId || d['RoomId'] == roomId)
        ).toList();
      }
    } catch (e) {
      debugPrint("Error fetching room devices: $e");
    }
    return [];
  }

  // --- DEVICES API ---

  Future<List<dynamic>> getAllDevices() async {
    try {
      // Removing userId parameter as it might cause 500 on some backend implementations of /Devices
      final response = await _dio.get('Devices');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Error fetching all devices: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getDeviceById(int id) async {
    try {
      final response = await _dio.get('Devices/$id');
      if (response.statusCode == 200) return response.data;
    } catch (e) {
      debugPrint("Error fetching device $id: $e");
    }
    return null;
  }

  Future<bool> addDevice(int roomId, String name, String type) async {
    if (await _isBypass()) return _bypass.addDevice(roomId, name, type);
    
    // Updated to match Swagger Device schema: removed 'status', only sending allowed fields
    final payload = {
      'name': name,
      'type': type,
      'roomId': roomId,
      'isOn': false,
    };

    try {
      // Try 1: Normal post
      final response = await _dio.post('Devices', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) return true;
    } catch (e) {
      debugPrint("Error adding device (Try 1): $e");
      // Try 2: With id: 0 (some .NET backends require this for auto-increment fields if strict)
      try {
        payload['id'] = 0;
        final response = await _dio.post('Devices', data: payload);
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e2) {
        debugPrint("Error adding device (Try 2): $e2");
      }
    }
    return false;
  }

  Future<bool> updateDevice(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('Devices/$id', data: data);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteDevice(int id) async {
    if (await _isBypass()) return _bypass.deleteDevice(id);
    try {
      final response = await _dio.delete('Devices/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error deleting device: $e");
      return false;
    }
  }

  Future<bool> toggleDevice(int id) async {
    try {
      final response = await _dio.put('Devices/toggle/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDeviceStatus(int id, bool isOn) async {
    if (await _isBypass()) return _bypass.updateDeviceStatus(id, isOn);
    try {
      // 1. Try PATCH update-status
      try {
        final response = await _dio.patch('Devices/$id/update-status', data: isOn);
        if (response.statusCode == 200 || response.statusCode == 204) return true;
      } catch (_) {}

      // 2. Try generic PUT (Match Swagger Device schema, removed 'status')
      final response = await _dio.put('Devices/$id', data: {
        'id': id,
        'isOn': isOn,
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error updating device status: $e");
      return false;
    }
  }

  // --- VOICE COMMANDS API ---

  Future<List<dynamic>> getVoiceCommands() async {
    try {
      final response = await _dio.get('VoiceCommands');
      if (response.statusCode == 200 && response.data is List) return response.data;
    } catch (e) {
      debugPrint("Error fetching voice commands: $e");
    }
    return [];
  }

  Future<bool> addVoiceCommand(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('VoiceCommands', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getVoiceCommandById(int id) async {
    try {
      final response = await _dio.get('VoiceCommands/$id');
      if (response.statusCode == 200) return response.data;
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<bool> updateVoiceCommand(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('VoiceCommands/$id', data: data);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteVoiceCommand(int id) async {
    try {
      final response = await _dio.delete('VoiceCommands/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> executeVoiceCommand(String word) async {
    try {
      final response = await _dio.get('VoiceCommands/execute/$word');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- COMMANDS API ---

  Future<bool> addCommand({required String triggerWord, required String action}) async {
    if (await _isBypass()) return _bypass.addCommand(triggerWord, action);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 1;

      final response = await _dio.post('Commands', data: {
        "triggerWord": triggerWord,
        "action": action,
        "userId": userId
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getPendingCommands() async {
    if (await _isBypass()) return _bypass.getPendingCommands();
    try {
      final response = await _dio.get('Commands/pending');
      if (response.statusCode == 200 && response.data is List) return response.data;
    } catch (e) {
      debugPrint("Error fetching pending: $e");
    }
    return [];
  }

  Future<bool> markCommandAsExecuted(int id) async {
    if (await _isBypass()) return _bypass.markCommandAsExecuted(id);
    try {
      final response = await _dio.put('Commands/$id/executed');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getCommands() async {
    if (await _isBypass()) return _bypass.getCommands();
    try {
      final response = await _dio.get('Commands');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Error fetching commands: $e");
    }
    return [];
  }

  // --- LOGS ---

  Future<bool> addLog(String message) async {
    if (await _isBypass()) return _bypass.addLog(message);
    try {
      // The Log schema in Swagger uses 'id', 'message', 'userId', 'deviceName', 'source', 'timestamp'
      // Only 'message' and optionally 'userId', 'deviceName', 'source' should be sent.
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      final response = await _dio.post('Logs', data: {
        "message": message,
        if (userId != null) "userId": userId,
        "timestamp": DateTime.now().toIso8601String(),
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding log: $e");
      return false;
    }
  }

  Future<List<dynamic>> getLogs() async {
    if (await _isBypass()) return _bypass.getLogs();
    try {
      // Swagger /api/Logs GET has no parameters.
      final response = await _dio.get('Logs');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      debugPrint("Error fetching logs: $e");
    }
    return [];
  }

  // --- AUDIO API ---

  Future<bool> uploadAudio(File audioFile) async {
    try {
      String fileName = audioFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(audioFile.path, filename: fileName),
      });

      final response = await _dio.post('Audio/upload', data: formData);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error uploading audio: $e");
      return false;
    }
  }

  Future<bool> controlAudio(String keyword, String source) async {
    try {
      final response = await _dio.put('Audio/control', data: {
        'keyword': keyword,
        'source': source,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error controlling audio: $e");
      return false;
    }
  }
}
