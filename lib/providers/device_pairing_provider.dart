import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevicePairingProvider extends ChangeNotifier {
  String? _pairedSerial;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  final bool _isConnecting = false;
  bool _ignoreNotifications = false;
  Timer? _livelySyncTimer;
  
  // Custom UUIDs for Arduino Nano 33 BLE Sense (TinyML Command Service)
  static const String SERVICE_UUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  static const String COMMAND_CHAR_UUID = "19B10001-E8F2-537E-4F6C-D104768A1214";
  static const String STATUS_CHAR_UUID = "19B10002-E8F2-537E-4F6C-D104768A1214";

  // Stores hardware status: {"R1": true, "R2": false, ...}
  final Map<String, bool> _hardwareDeviceStates = {};
  
  Map<String, bool> get hardwareDeviceStates => _hardwareDeviceStates;

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
      // Trigger immediate sync after pairing
      syncStatusFromBLE();
    }
    
    notifyListeners();
    return true;
  }

  void _setupConnectionListener(BluetoothDevice device) {
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _commandCharacteristic = null;
        _statusCharacteristic = null;
        _hardwareDeviceStates.clear();
        _livelySyncTimer?.cancel();
        notifyListeners();
      } else if (state == BluetoothConnectionState.connected) {
        // Sync status automatically and subscribe to live updates
        Future.delayed(const Duration(seconds: 1), () => _initializeStatusListener());
        _startLivelySync();
      }
    });
    
    // If already connected during setup
    if (device.isConnected) {
      _initializeStatusListener();
      _startLivelySync();
    }
  }

  void _startLivelySync() {
    _livelySyncTimer?.cancel();
    // Heartbeat slowed to 15 seconds to minimize interference with slow hardware
    _livelySyncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_connectedDevice != null && _connectedDevice!.isConnected) {
         _readStatusExplicitly();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initializeStatusListener() async {
    if (_connectedDevice == null) return;

    try {
      debugPrint("[BLE] Starting Service Discovery (nRF Connect Style)...");
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var char in service.characteristics) {
            String charUuid = char.uuid.toString().toLowerCase();
            
            // Cache Command Characteristic
            if (charUuid == COMMAND_CHAR_UUID.toLowerCase()) {
              _commandCharacteristic = char;
              debugPrint("[BLE] CACHED COMMAND CHARACTERISTIC");
            }
            
            // Cache and Setup Status Characteristic
            if (charUuid == STATUS_CHAR_UUID.toLowerCase()) {
              _statusCharacteristic = char;
              debugPrint("[BLE] CACHED STATUS CHARACTERISTIC");

              // 1. Force enable notifications
              try {
                await char.setNotifyValue(true);
                debugPrint("[BLE] NOTIFICATIONS ENABLED");
              } catch (e) {
                debugPrint("[BLE] Notification Enable Error: $e");
              }

              // 2. Continuous Listener
              char.onValueReceived.listen((value) {
                if (value.isNotEmpty && !_ignoreNotifications) {
                  String decoded = utf8.decode(value).trim();
                  debugPrint("[BLE] << NOTIFICATION: $decoded"); 
                  _parseStatusString(decoded);
                  
                  // Safeguard: Only notify if we aren't in a build phase
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    notifyListeners();
                  });
                }
              });

              char.lastValueStream.listen((value) {
                if (value.isNotEmpty && !_ignoreNotifications) {
                   String decoded = utf8.decode(value).trim();
                   debugPrint("[BLE] << STREAM UPDATE: $decoded");
                   _parseStatusString(decoded);
                   
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     notifyListeners();
                   });
                }
              });

              // 3. Initial Read
              List<int> initialValue = await char.read();
              _parseStatusString(utf8.decode(initialValue).trim());
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("[BLE] nRF Sync Error: $e");
    }
  }

  Future<void> _readStatusExplicitly() async {
    if (_connectedDevice == null || _statusCharacteristic == null) return;
    try {
      debugPrint("[BLE] Explicit status poll...");
      List<int> value = await _statusCharacteristic!.read().timeout(const Duration(seconds: 2));
      String decoded = utf8.decode(value).trim();
      debugPrint("[BLE] Explicit Poll Result: $decoded");
      _parseStatusString(decoded);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      debugPrint("[BLE] Explicit Poll Error: $e");
    }
  }

  Future<void> syncStatusFromBLE() async {
    await _initializeStatusListener();
  }

  void _parseStatusString(String status) {
    status = status.toUpperCase().trim();
    debugPrint("[BLE] Parsing Raw String: '$status'");

    // Use a new map to prevent partial updates or lingering old states
    final Map<String, bool> newStates = {};

    // 1. Handle Comma-Separated Formats (e.g., R1=ON,R2=OFF or R1:1,R2:0)
    if (status.contains(",")) {
      final parts = status.split(',');
      for (var part in parts) {
        _processSingleRelayString(part, newStates);
      }
    } else {
      // 2. Handle Single Command or Bitmask
      _processSingleRelayString(status, newStates);
    }

    if (newStates.isNotEmpty) {
      // Merge into master state
      _hardwareDeviceStates.addAll(newStates);
      debugPrint("[BLE] Updated Master Map: $_hardwareDeviceStates");
    }
  }

  void _processSingleRelayString(String part, Map<String, bool> targetMap) {
    String clean = part.trim();
    if (clean.isEmpty) return;

    // A. Key-Value with = or :
    if (clean.contains("=") || clean.contains(":")) {
      final splitter = clean.contains("=") ? "=" : ":";
      final kv = clean.split(splitter);
      if (kv.length >= 2) {
        String key = kv[0].trim();
        if (!key.startsWith("R")) key = "R$key";
        bool isOn = kv[1].contains("ON") || kv[1].trim() == "1";
        targetMap[key] = isOn;
      }
    }
    // B. Compact bitmask (e.g. 1011)
    else if (clean.length == 4 && RegExp(r'^[01]+$').hasMatch(clean)) {
      for (int i = 0; i < 4; i++) {
        targetMap["R${i + 1}"] = clean[i] == '1';
      }
    }
    // C. Single token (e.g. R1ON)
    else if (clean.startsWith("R") && clean.length >= 4) {
      String key = clean.substring(0, 2);
      bool isOn = clean.contains("ON");
      targetMap[key] = isOn;
    }
  }

  Future<void> unpairDevice() async {
    _livelySyncTimer?.cancel();
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
    if (_connectedDevice == null) {
      debugPrint("[BLE] ❌ Send Failed: No device connected.");
      return false;
    }

    try {
      // 1. Ensure we have the command channel
      if (_commandCharacteristic == null) {
        debugPrint("[BLE] 🔍 Command channel not cached. Discovering...");
        await _initializeStatusListener();
      }

      if (_commandCharacteristic != null) {
        debugPrint("[BLE] 🚀 SENDING UTF-8: '$command\\n'");
        final List<int> bytes = utf8.encode("$command\n");
        
        // Optimistic UI Update
        _parseStatusString(command);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });

        // 2. Use confirmed write for reliability (Wait for Arduino ACK)
        await _commandCharacteristic!.write(bytes, withoutResponse: false);
        debugPrint("[BLE] ✅ Command Sent Successfully");

        // 3. Sync Logic (SLOW MODE)
        // Ignore background state changes for 10 seconds
        _ignoreNotifications = true;
        Future.delayed(const Duration(seconds: 10), () => _ignoreNotifications = false);
        
        // Final "Truth Check" at 15 seconds
        Future.delayed(const Duration(seconds: 15), () => _readStatusExplicitly());
        
        return true;
      } else {
        debugPrint("[BLE] ❌ Failed: Command Characteristic (19B10001) not found on device.");
      }
    } catch (e) {
      debugPrint("[BLE] 🛑 Transmission Error: $e");
    }
    return false;
  }

  void setConnectedDevice(BluetoothDevice device) {
    _connectedDevice = device;
    _setupConnectionListener(device);
    notifyListeners();
  }
}
