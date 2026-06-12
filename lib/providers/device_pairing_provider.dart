import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevicePairingProvider extends ChangeNotifier {
  String? _pairedSerial;
  BluetoothDevice? _connectedDevice;
  bool _isConnecting = false;
  
  // Custom UUIDs for Arduino Nano 33 BLE Sense (TinyML Command Service)
  // These should match what is programmed on the Arduino side
  static const String SERVICE_UUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  static const String COMMAND_CHAR_UUID = "19B10001-E8F2-537E-4F6C-D104768A1214";

  DevicePairingProvider() {
    _loadPairedSerial();
  }

  String? get pairedSerial => _pairedSerial;
  bool get isPaired => _pairedSerial != null;
  bool get isConnected => _connectedDevice != null;
  bool get isConnecting => _isConnecting;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> _loadPairedSerial() async {
    final prefs = await SharedPreferences.getInstance();
    _pairedSerial = prefs.getString('paired_serial');
    
    // Auto-reconnect if possible could be added here
    notifyListeners();
  }

  Future<bool> pairDevice(String identifier, {BluetoothDevice? device}) async {
    if (identifier.isEmpty) return false;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paired_serial', identifier);
    _pairedSerial = identifier;
    
    if (device != null) {
      _connectedDevice = device;
      _setupConnectionListener(device);
    }
    
    notifyListeners();
    return true;
  }

  void _setupConnectionListener(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        notifyListeners();
      }
    });
  }

  Future<void> unpairDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paired_serial');
    _pairedSerial = null;
    _connectedDevice = null;
    notifyListeners();
  }

  Future<bool> sendCommandViaBLE(String command) async {
    if (_connectedDevice == null) return false;

    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toUpperCase() == SERVICE_UUID.toUpperCase()) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toUpperCase() == COMMAND_CHAR_UUID.toUpperCase()) {
              // Send the command text as bytes
              await char.write(utf8.encode(command));
              debugPrint("Command sent via BLE: $command");
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("BLE Send Error: $e");
    }
    return false;
  }

  void setConnectedDevice(BluetoothDevice device) {
    _connectedDevice = device;
    _setupConnectionListener(device);
    notifyListeners();
  }
}
