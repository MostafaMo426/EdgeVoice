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
    // ... same Dio setup ...
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

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
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
      final userId = prefs.getInt('userId') ?? 1;
      print("Fetching rooms for userId: $userId");
      final response = await _dio.get('Rooms', queryParameters: {'userId': userId});
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
      final response = await _dio.post('Rooms', data: {
        'name': name,
        'userId': userId,
      });
      return response.statusCode == 200 || response.statusCode == 201;
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
      final response = await _dio.get('Rooms/$roomId/devices');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching room devices: $e");
    }
    return [];
  }

  // --- DEVICES API ---

  Future<List<dynamic>> getAllDevices() async {
    // Note: getAllDevices isn't explicitly in bypass yet, but we can map it if needed
    try {
      final response = await _dio.get('Devices');
      if (response.statusCode == 200 && response.data is List) {
        return response.data;
      }
    } catch (e) {
      print("Error fetching devices: $e");
    }
    return [];
  }

  Future<bool> addDevice(int roomId, String name, String type) async {
    if (await _isBypass()) return _bypass.addDevice(roomId, name, type);
    try {
      final response = await _dio.post('Devices', data: {
        'name': name,
        'type': type,
        'roomId': roomId,
        'status': false,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding device: $e");
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

  Future<bool> updateDeviceStatus(int id, bool isOn) async {
    if (await _isBypass()) return _bypass.updateDeviceStatus(id, isOn);
    try {
      final response = await _dio.put('Devices/$id/status', data: isOn);
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
