import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevicePairingProvider extends ChangeNotifier {
  String? _pairedSerial;
  
  DevicePairingProvider() {
    _loadPairedSerial();
  }

  String? get pairedSerial => _pairedSerial;
  bool get isPaired => _pairedSerial != null;

  String get currentDeviceCommandTopic => 
      "edgevoice/devices/${_pairedSerial ?? 'unpaired'}/commands";

  Future<void> _loadPairedSerial() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedSerial = prefs.getString('paired_serial');
    notifyListeners();
  }

  Future<bool> pairDevice(String serial) async {
    // Basic validation: e.g., EV-2026-99
    if (serial.length < 5) return false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paired_serial', serial);
    _pairedSerial = serial;
    notifyListeners();
    return true;
  }

  Future<void> unpairDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paired_serial');
    _pairedSerial = null;
    notifyListeners();
  }
}
