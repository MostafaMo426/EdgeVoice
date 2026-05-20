import 'dart:async';

/// This file handles all data locally in memory for offline development.
/// You can delete this entire file once your SQL Server is back online.
class BypassService {
  static final BypassService _instance = BypassService._internal();
  factory BypassService() => _instance;
  BypassService._internal();

  // --- MOCK DATABASE ---
  final List<Map<String, dynamic>> _rooms = [
    {'id': 1, 'name': 'Living Room', 'userId': 1},
    {'id': 2, 'name': 'Bedroom', 'userId': 1},
    {'id': 3, 'name': 'Kitchen', 'userId': 1},
  ];

  final List<Map<String, dynamic>> _devices = [
    {'id': 1, 'roomId': 1, 'name': 'Lights', 'type': 'Lights', 'status': true},
    {'id': 2, 'roomId': 1, 'name': 'TV', 'type': 'TV', 'status': false},
    {'id': 3, 'roomId': 2, 'name': 'Main Lights', 'type': 'Lights', 'status': true},
    {'id': 4, 'roomId': 2, 'name': 'Fan', 'type': 'Fan', 'status': true},
    {'id': 5, 'roomId': 3, 'name': 'Fridge', 'type': 'Fridge', 'status': true},
    {'id': 6, 'roomId': 3, 'name': 'Air Fryer', 'type': 'Air Fryer', 'status': false},
    {'id': 7, 'roomId': 3, 'name': 'Washing Machine', 'type': 'Washing Machine', 'status': false},
    {'id': 8, 'roomId': 3, 'name': 'Dryer', 'type': 'Dryer', 'status': false},
  ];

  final List<Map<String, dynamic>> _logs = [
    {'id': 1, 'message': 'System started in Bypass Mode', 'createdAt': '2023-10-01 10:00:00', 'userId': 1},
  ];

  final List<Map<String, dynamic>> _commands = [];

  // --- ROOMS ---
  Future<List<dynamic>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rooms;
  }

  Future<bool> addRoom(String name) async {
    final id = _rooms.isEmpty ? 1 : _rooms.last['id'] + 1;
    _rooms.add({'id': id, 'name': name, 'userId': 1});
    return true;
  }

  Future<bool> updateRoom(int id, String name) async {
    int index = _rooms.indexWhere((r) => r['id'] == id);
    if (index != -1) _rooms[index]['name'] = name;
    return true;
  }

  Future<bool> deleteRoom(int id) async {
    _rooms.removeWhere((r) => r['id'] == id);
    _devices.removeWhere((d) => d['roomId'] == id);
    return true;
  }

  // --- DEVICES ---
  Future<List<dynamic>> getRoomDevices(int roomId) async {
    return _devices.where((d) => d['roomId'] == roomId).toList();
  }

  Future<bool> addDevice(int roomId, String name, String type) async {
    final id = _devices.isEmpty ? 1 : _devices.last['id'] + 1;
    _devices.add({'id': id, 'roomId': roomId, 'name': name, 'type': type, 'status': false});
    return true;
  }

  Future<bool> updateDeviceStatus(int id, bool status) async {
    int index = _devices.indexWhere((d) => d['id'] == id);
    if (index != -1) _devices[index]['status'] = status;
    return true;
  }

  Future<bool> deleteDevice(int id) async {
    _devices.removeWhere((d) => d['id'] == id);
    return true;
  }

  // --- LOGS & COMMANDS ---
  Future<List<dynamic>> getLogs() async => _logs;

  Future<bool> addLog(String message) async {
    _logs.insert(0, {
      'id': _logs.length + 1,
      'message': message,
      'createdAt': DateTime.now().toString().split('.')[0],
      'userId': 1
    });
    return true;
  }

  Future<bool> addCommand(String trigger, String action) async {
    _commands.add({'id': _commands.length + 1, 'triggerWord': trigger, 'action': action, 'executed': false});
    return true;
  }

  Future<List<dynamic>> getPendingCommands() async {
    return _commands.where((c) => c['executed'] == false).toList();
  }

  Future<bool> markCommandAsExecuted(int id) async {
    int index = _commands.indexWhere((c) => c['id'] == id);
    if (index != -1) _commands[index]['executed'] = true;
    return true;
  }

  Future<List<dynamic>> getCommands() async => _commands;
}
