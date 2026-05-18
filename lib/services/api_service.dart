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
          print("🌐 API Request: ${options.method} ${options.baseUrl}${options.path}");
          if (options.queryParameters.isNotEmpty) print("❓ Query: ${options.queryParameters}");
          if (options.data != null) print("📦 Body: ${options.data}");
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print("✅ API Response [${response.statusCode}]: ${response.requestOptions.path}");
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) async {
        if (kDebugMode) {
          print("❌ API Error [${e.response?.statusCode}]: ${e.requestOptions.path}");
          print("💬 Message: ${e.message}");
          if (e.type == DioExceptionType.connectionError) {
            print("⚠️ Network/CORS Error: If you are on Web, the server might be blocking the request.");
            print("🔗 Target URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}");
          }
          if (e.response?.data != null) print("📄 Data: ${e.response?.data}");
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
              print("Refresh token failed: $refreshError");
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
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      print("Fetching rooms for userId: $userId");
      // Updated to match Swagger: /api/Rooms/my-rooms
      // We pass userId just in case, though token usually handles it
      final response = await _dio.get('Rooms/my-rooms', queryParameters: userId != null ? {'userId': userId} : null);
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching rooms: $e");
    }
    return [];
  }

  Future<bool> addRoom(String name) async {
    if (await _isBypass()) return _bypass.addRoom(name);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 1;
      print("Adding room '$name' for userId: $userId");
      
      // Try /api/Rooms/add first
      try {
        final response = await _dio.post('Rooms/add', data: {
          'name': name,
          'userId': userId,
        });
        if (response.statusCode == 200 || response.statusCode == 201) return true;
      } catch (e) {
        print("Failed to add room via Rooms/add: $e");
      }

      // Fallback: Try just /api/Rooms
      final response2 = await _dio.post('Rooms', data: {
        'name': name,
        'userId': userId,
      });
      return response2.statusCode == 200 || response2.statusCode == 201;
    } catch (e) {
      print("Error adding room: $e");
      return false;
    }
  }

  Future<bool> updateRoom(int id, String name) async {
    if (await _isBypass()) return _bypass.updateRoom(id, name);
    try {
      final response = await _dio.put('Rooms/$id', data: {'name': name});
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating room: $e");
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    if (await _isBypass()) return _bypass.deleteRoom(id);
    try {
      final response = await _dio.delete('Rooms/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error deleting room: $e");
      return false;
    }
  }

  Future<List<dynamic>> getRoomDevices(int roomId) async {
    if (await _isBypass()) return _bypass.getRoomDevices(roomId);
    try {
      // Fetch all devices. Removing userId parameter to avoid 500 if backend doesn't support it for this endpoint.
      final response = await _dio.get('Devices');
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).where((d) => 
          (d['roomId'] == roomId || d['RoomId'] == roomId)
        ).toList();
      }
    } catch (e) {
      print("Error fetching room devices: $e");
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
      print("Error fetching all devices: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getDeviceById(int id) async {
    try {
      final response = await _dio.get('Devices/$id');
      if (response.statusCode == 200) return response.data;
    } catch (e) {
      print("Error fetching device $id: $e");
    }
    return null;
  }

  Future<bool> addDevice(int roomId, String name, String type) async {
    if (await _isBypass()) return _bypass.addDevice(roomId, name, type);
    
    final payload = {
      'name': name,
      'type': type,
      'roomId': roomId,
      'isOn': false,
      'status': false,
    };

    try {
      // Try 1: Normal post
      final response = await _dio.post('Devices', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) return true;
    } catch (e) {
      print("Error adding device (Try 1): $e");
      // Try 2: With id: 0 (some .NET backends require this for auto-increment fields)
      try {
        payload['id'] = 0;
        final response = await _dio.post('Devices', data: payload);
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e2) {
        print("Error adding device (Try 2): $e2");
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
      print("Error deleting device: $e");
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

      // 2. Try generic PUT
      final response = await _dio.put('Devices/$id', data: {
        'id': id,
        'isOn': isOn,
        'status': isOn,
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error updating device status: $e");
      return false;
    }
  }

  // --- VOICE COMMANDS API ---

  Future<List<dynamic>> getVoiceCommands() async {
    try {
      final response = await _dio.get('VoiceCommands');
      if (response.statusCode == 200 && response.data is List) return response.data;
    } catch (e) {
      print("Error fetching voice commands: $e");
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
      print("Error fetching pending: $e");
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
      print("Error fetching commands: $e");
    }
    return [];
  }

  // --- LOGS ---

  Future<bool> addLog(String message) async {
    if (await _isBypass()) return _bypass.addLog(message);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId') ?? 1;

      final response = await _dio.post('Logs', data: {
        "message": message,
        "userId": userId,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding log: $e");
      return false;
    }
  }

  Future<List<dynamic>> getLogs() async {
    if (await _isBypass()) return _bypass.getLogs();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      
      final response = await _dio.get('Logs', queryParameters: {'userId': userId});
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching logs: $e");
    }
    return [];
  }
}
