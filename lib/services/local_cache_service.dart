import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static const String keyRooms = "cached_rooms";
  static const String keyDevices = "cached_devices";
  static const String keyLogs = "cached_logs";
  static const String keyUser = "cached_user_data";

  // --- USER DATA ---
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUser, jsonEncode(userData));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(keyUser);
    if (data != null) return jsonDecode(data);
    return null;
  }

  // --- ROOMS & DEVICES ---
  Future<void> saveRooms(List<dynamic> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyRooms, jsonEncode(rooms));
  }

  Future<List<dynamic>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(keyRooms);
    if (data != null) return jsonDecode(data);
    return [];
  }

  Future<void> saveDevices(List<dynamic> devices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyDevices, jsonEncode(devices));
  }

  Future<List<dynamic>> getDevices() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(keyDevices);
    if (data != null) return jsonDecode(data);
    return [];
  }

  // --- LOGS (OFFLINE ONLY) ---
  Future<void> addLog(String message) async {
    final prefs = await SharedPreferences.getInstance();
    List<dynamic> logs = await getLogs();
    
    logs.insert(0, {
      "id": DateTime.now().millisecondsSinceEpoch,
      "message": message,
      "timestamp": DateTime.now().toIso8601String(),
    });

    // Keep only last 100 logs to save space
    if (logs.length > 100) logs = logs.sublist(0, 100);
    
    await prefs.setString(keyLogs, jsonEncode(logs));
  }

  Future<List<dynamic>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(keyLogs);
    if (data != null) return jsonDecode(data);
    return [];
  }
}
