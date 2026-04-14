import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://bodathedev-001-site1.ltempurl.com/api";

  // --- COMMANDS ---

  /// Adds a new command to the system
  Future<bool> addCommand({required String name, required int value}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/commands'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "name": name,
          "value": value,
          "isExecuted": false,
        }),
      );
      print("POST Command: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding command: $e");
      return false;
    }
  }

  /// Fetches all commands
  Future<List<dynamic>> getCommands() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commands'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching commands: $e");
    }
    return [];
  }

  /// Fetches pending commands (Simulates "Notifications")
  Future<List<dynamic>> getPendingCommands() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commands/pending'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching pending commands: $e");
    }
    return [];
  }

  /// Marks a command as executed
  Future<bool> markCommandAsExecuted(int id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/commands/$id/executed'),
        headers: {'accept': '*/*'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error marking command as executed: $e");
      return false;
    }
  }

  // --- LOGS ---

  /// Adds a new log message
  Future<bool> addLog(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logs'),
        headers: {
          'accept': '*/*',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "message": message,
          "timestamp": DateTime.now().toIso8601String()
        }),
      );
      print("POST Log: ${response.statusCode}");
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error adding log: $e");
      return false;
    }
  }

  /// Fetches all logs
  Future<List<dynamic>> getLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching logs: $e");
    }
    return [];
  }
}
