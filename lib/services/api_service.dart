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
    ));
  }

  // --- ROOMS API ---

  Future<List<dynamic>> getRooms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
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
    try {
      final response = await _dio.put('Rooms/$id', data: {'name': name});
      return response.statusCode == 200;
    } catch (e) {
      print("Error updating room: $e");
      return false;
    }
  }

  Future<bool> deleteRoom(int id) async {
    try {
      final response = await _dio.delete('Rooms/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error deleting room: $e");
      return false;
    }
  }

  Future<List<dynamic>> getRoomDevices(int roomId) async {
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
    try {
      final response = await _dio.post('Devices', data: {
        'name': name,
        'type': type,
        'roomId': roomId,
        'status': false, // Default to OFF
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding device: $e");
      return false;
    }
  }

  Future<bool> deleteDevice(int id) async {
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
      final response = await _dio.put('Devices/$id/toggle');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDeviceStatus(int id, bool isOn) async {
    try {
      final response = await _dio.put('Devices/$id/status', queryParameters: {'isOn': isOn});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- COMMANDS API (Voice/Logs) ---

  Future<bool> addCommand({required String triggerWord, required String action}) async {
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
    try {
      final response = await _dio.get('Commands/pending');
      if (response.statusCode == 200 && response.data is List) return response.data;
    } catch (e) {
      print("Error fetching pending: $e");
    }
    return [];
  }

  Future<bool> markCommandAsExecuted(int id) async {
    try {
      final response = await _dio.put('Commands/$id/executed');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getCommands() async {
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
