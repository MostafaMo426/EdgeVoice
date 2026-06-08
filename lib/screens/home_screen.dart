import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart'; 
import 'logs_screen.dart'; // Import Logs Screen
import 'rooms_screen.dart'; // Import Rooms Screen
import '../services/api_service.dart'; // Import API Service
import '../providers/edgevoice_voice_provider.dart';
import '../config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // --- 1. MASTER STATE ---
  Map<String, bool> deviceStates = {
    'living_lights': true,
    'living_tv': false,
    'bed_lights': true,
    'bed_fan': true,
    'kitchen_lights': false,
    'kitchen_coffee': false,
    'kitchen_fridge': true,
    'air_fryer': false,
    'washing_machine': false,
    'dryer': false,
    'vacuum': true,
    'humidifier': false,
    'front_door': false,
    'ac_unit': true,
  };

  List<dynamic> _rooms = [];
  bool _isLoading = true;

  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadInitialStates();
    _loadProfileImage();
    _startPolling();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _profileImageUrl = prefs.getString('profilePicture');
      });
    }
  }

  // --- REUSABLE UPDATE METHOD ---
  Future<void> _updateDevice(String key, bool state, {bool silent = false}) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    if (deviceStates.containsKey(key)) {
      setState(() {
        deviceStates[key] = state;
      });

      // Find actual device ID if possible and update status via API
      final device = _findDeviceByLegacyKey(key);
      if (device != null) {
        try {
          await apiService.updateDeviceStatus(device['id'], state);
          setState(() {
            device['isOn'] = state;
          device['status'] = state;
          });
        } catch (e) {
          debugPrint("API Error updating device status: $e");
        }
      }

      // Send to API with new format (Commands and Logs)
      String action = state ? "Turn ON" : "Turn OFF";
      try {
        await apiService.addCommand(triggerWord: "Toggle $key", action: "$action $key");
        await apiService.addLog("User turned $key ${state ? 'ON' : 'OFF'}");
      } catch (e) {
        debugPrint("Error syncing logs with server: $e");
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${key.replaceAll('_', ' ')}: ${state ? 'ON' : 'OFF'}"),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 500),
        ));
      }
    }
  }

  // Fallback for dynamic devices not in legacy mapping
  Future<void> _updateDeviceDynamic(dynamic device, bool state) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    try {
      final success = await apiService.updateDeviceStatus(device['id'], state);
      if (success) {
        setState(() {
          device['isOn'] = state;
          device['status'] = state;
          // Also try to update legacy map if it exists
          String? legacyKey = _mapDeviceToLegacyKey("", device['name'] ?? "");
          if (legacyKey != null) deviceStates[legacyKey] = state;
        });
        await apiService.addLog("User turned ${device['name']} ${state ? 'ON' : 'OFF'}");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${device['name']}: ${state ? 'ON' : 'OFF'}"),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 500),
          ));
        }
      }
    } catch (e) {
      debugPrint("Error updating dynamic device: $e");
    }
  }

  String? _mapDeviceToLegacyKey(String roomName, String deviceName) {
    roomName = roomName.toLowerCase();
    deviceName = deviceName.toLowerCase();
    
    if (roomName.contains("living")) {
      if (deviceName.contains("light")) return "living_lights";
      if (deviceName.contains("tv")) return "living_tv";
    } else if (roomName.contains("bed")) {
      if (deviceName.contains("light")) return "bed_lights";
      if (deviceName.contains("fan")) return "bed_fan";
    } else if (roomName.contains("kitchen")) {
      if (deviceName.contains("light")) return "kitchen_lights";
      if (deviceName.contains("coffee")) return "kitchen_coffee";
      if (deviceName.contains("fridge")) return "kitchen_fridge";
    }
    
    // Appliance mappings
    if (deviceName.contains("ac") || deviceName.contains("air")) {
      if (deviceName.contains("fryer")) return "air_fryer";
      return "ac_unit";
    }
    if (deviceName.contains("washer") || deviceName.contains("washing")) return "washing_machine";
    if (deviceName.contains("dryer")) return "dryer";
    if (deviceName.contains("vacuum")) return "vacuum";
    if (deviceName.contains("humidifier")) return "humidifier";
    if (deviceName.contains("door")) return "front_door";
    
    return null;
  }

  dynamic _findDeviceByLegacyKey(String key) {
    for (var room in _rooms) {
      final devices = room['devices'] as List<dynamic>? ?? [];
      for (var device in devices) {
        if (_mapDeviceToLegacyKey(room['name'] ?? "", device['name'] ?? "") == key) {
          return device;
        }
      }
    }
    return null;
  }

  IconData _getRoomIcon(String name) {
    name = name.toLowerCase();
    if (name.contains("living")) return Icons.weekend;
    if (name.contains("bed")) return Icons.bed;
    if (name.contains("kitchen")) return Icons.kitchen;
    if (name.contains("bath")) return Icons.bathtub;
    return Icons.room;
  }

  IconData _getDeviceIcon(String type) {
    switch (type) {
      case "Lights": return Icons.lightbulb_outline;
      case "TV": return Icons.tv;
      case "AC": return Icons.ac_unit;
      case "Curtains": return Icons.curtains;
      case "Fan": return Icons.air;
      case "Door": return Icons.door_front_door;
      case "Coffee Maker": return Icons.coffee;
      case "Fridge": return Icons.kitchen;
      case "Air Fryer": return Icons.outdoor_grill;
      case "Washing Machine":
      case "Washer": return Icons.local_laundry_service;
      case "Dryer": return Icons.dry;
      case "Vacuum": return Icons.cleaning_services;
      case "Humidifier": return Icons.water_drop;
      default: return Icons.device_hub;
    }
  }

  // --- GROUP TOGGLES ---
  void _toggleLights() async {
    // 1. Determine target state (if any light is on, turn all off)
    bool anyOn = false;
    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      if (devices.any((d) => (d['type'] == 'Lights' || (d['name']?.toString().toLowerCase().contains('light') ?? false)) && (d['isOn'] ?? d['status'] ?? false))) {
        anyOn = true;
        break;
      }
    }
    bool target = !anyOn;

    // 2. Update all light devices across all rooms
    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      for (var device in devices) {
        if (device['type'] == 'Lights' || (device['name']?.toString().toLowerCase().contains('light') ?? false)) {
          await _updateDeviceDynamic(device, target);
        }
      }
    }
    _showBulkFeedback("Lights", target);
  }

  void _toggleDoors() async {
    bool anyOpen = false;
    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      if (devices.any((d) => (d['type'] == 'Door' || (d['name']?.toString().toLowerCase().contains('door') ?? false)) && (d['isOn'] ?? d['status'] ?? false))) {
        anyOpen = true;
        break;
      }
    }
    bool target = !anyOpen;

    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      for (var device in devices) {
        if (device['type'] == 'Door' || (device['name']?.toString().toLowerCase().contains('door') ?? false)) {
          await _updateDeviceDynamic(device, target);
        }
      }
    }
    _showBulkFeedback("Doors", target);
  }

  void _toggleClimate() async {
    List<String> climateTypes = ['AC', 'Fan', 'Humidifier'];
    bool anyOn = false;
    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      if (devices.any((d) => (climateTypes.contains(d['type']) || (d['name']?.toString().toLowerCase().contains('ac') ?? false)) && (d['isOn'] ?? d['status'] ?? false))) {
        anyOn = true;
        break;
      }
    }
    bool target = !anyOn;

    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      for (var device in devices) {
        if (climateTypes.contains(device['type']) || (device['name']?.toString().toLowerCase().contains('ac') ?? false)) {
          await _updateDeviceDynamic(device, target);
        }
      }
    }
    _showBulkFeedback("Climate", target);
  }

  void _toggleSecurity() async {
    // Security toggle: If anything is on, turn everything off.
    bool anyOn = false;
    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      if (devices.any((d) => (d['isOn'] ?? d['status'] ?? false))) {
        anyOn = true;
        break;
      }
    }
    bool target = !anyOn;
    
    for (var room in _rooms) {
      final devices = room['devices'] as List? ?? [];
      for (var device in devices) {
        await _updateDeviceDynamic(device, target);
      }
    }
    
    _showBulkFeedback("All Systems", target);
  }

  void _showBulkFeedback(String group, bool state) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$group: ${state ? 'ALL ON / OPEN' : 'ALL OFF / CLOSED'}"),
      backgroundColor: state ? Colors.blue : Colors.redAccent,
      duration: const Duration(seconds: 1),
    ));
  }

  int _selectedIndex = 0;

  // Colors & Data
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color accentCyan = const Color(0xFF00F0FF);
  String livingRoomTemp = "72°F";
  String bedroomTemp = "68°F";
  String acTemp = "68°F";

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialStates() async {
    if (!mounted) return;
    final apiService = Provider.of<ApiService>(context, listen: false);
    setState(() => _isLoading = true);
    try {
      final rooms = await apiService.getRooms();
      List<dynamic> enrichedRooms = [];
      for (var room in rooms) {
        final devices = await apiService.getRoomDevices(room['id']);
        room['devices'] = devices;
        enrichedRooms.add(room);
        
        // Sync legacy deviceStates with API data
        for (var device in devices) {
          String? legacyKey = _mapDeviceToLegacyKey(room['name'] ?? "", device['name'] ?? "");
          if (legacyKey != null) {
            deviceStates[legacyKey] = device['isOn'] ?? device['status'] ?? false;
          }
        }
      }

      // Check for last commands too
      final commands = await apiService.getCommands();
      if (commands.isNotEmpty) {
        for (var cmd in commands) {
          String action = cmd['action'] ?? "";
          bool value = action.toUpperCase().contains("ON");
          for (var key in deviceStates.keys) {
            if (action.contains(key)) deviceStates[key] = value;
          }
        }
      }

      if (mounted) {
        setState(() {
          _rooms = enrichedRooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading initial states: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPolling() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    // Poll for pending commands every 10 seconds (Simulating Notifications)
    while (mounted) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        final pending = await apiService.getPendingCommands();
        if (pending.isNotEmpty && mounted) {
          for (var cmd in pending) {
            String action = cmd['action'] ?? "";
            bool state = action.toUpperCase().contains("ON");
            
            // SILENCED: No longer showing SnackBar notification
            // _showNotification(action, state);
            
            // Sync local state if it matches a legacy key
            if (deviceStates.containsKey(action)) {
              setState(() => deviceStates[action] = state);
            }
            
            await apiService.markCommandAsExecuted(cmd['id']);
          }
        }
      } catch (e) {
        debugPrint("Polling error: $e");
      }
    }
  }

  // --- 2. VOICE LOGIC ---
  void _listen() async {
    final voiceProvider = Provider.of<EdgeVoiceVoiceProvider>(context, listen: false);

    if (!voiceProvider.isRecording) {
      await voiceProvider.startRecording();
    } else {
      await voiceProvider.stopAndProcess();
    }
  }

  // --- NAVIGATION LOGIC ---
  final GlobalKey<LogsScreenState> _logsKey = GlobalKey<LogsScreenState>();
  final GlobalKey<RoomsScreenState> _roomsKey = GlobalKey<RoomsScreenState>();

  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      _loadInitialStates();
    } else if (index == 1) {
      _roomsKey.currentState?.fetchRooms();
    } else if (index == 2) {
      // If switching to Logs tab, trigger refresh
      _logsKey.currentState?.refreshLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, "Home", 0),
            _buildNavItem(Icons.grid_view_rounded, "Rooms", 1),
            _buildNavItem(Icons.insert_chart_outlined_rounded, "Logs", 2),
            _buildNavItem(Icons.settings, "Settings", 3),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeBody(),
          RoomsScreen(key: _roomsKey, isStandalone: false),
          LogsScreen(key: _logsKey, isStandalone: false),
          SettingsScreen(
            isStandalone: false,
            onImageChanged: (source) {
              // Trigger a refresh when settings signals an image change
              _loadProfileImage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildMicHero(), // <--- Updated Mic Widget
              const SizedBox(height: 30),
              _buildAnimatedSection(
                title: "Quick Actions",
                delay: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _QuickActionBtn(icon: Icons.lightbulb_outline, label: "Lights", onTap: _toggleLights),
                    _QuickActionBtn(icon: Icons.door_front_door_outlined, label: "Doors", onTap: _toggleDoors),
                    _QuickActionBtn(icon: Icons.thermostat, label: "Climate", onTap: _toggleClimate),
                    _QuickActionBtn(icon: Icons.shield_outlined, label: "Security", onTap: _toggleSecurity),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildAnimatedSection(
                title: "Rooms",
                delay: 400,
                child: _isLoading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
                      ))
                    : _rooms.isEmpty
                        ? Text("No rooms found. Add them in the Rooms tab.", style: TextStyle(color: Colors.grey[400]))
                        : Column(
                            children: _rooms.asMap().entries.map<Widget>((entry) {
                              final room = entry.value;
                              final roomName = room['name'] ?? "Room";
                              final roomDevices = room['devices'] as List? ?? [];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15.0),
                                child: _buildRoomCard(
                                  roomName,
                                  "${roomDevices.length} devices active",
                                  _getRoomIcon(roomName),
                                  roomDevices.take(3).map<Widget>((device) {
                                    return DeviceToggle(
                                      icon: _getDeviceIcon(device['type'] ?? ""),
                                      label: "${device['name']}\n${(device['isOn'] ?? device['status'] ?? false) ? 'On' : 'Off'}",
                                      isActive: device['isOn'] ?? device['status'] ?? false,
                                      onTap: () {
                                        String? legacyKey = _mapDeviceToLegacyKey(roomName, device['name'] ?? "");
                                        if (legacyKey != null) {
                                          toggleDevice(legacyKey);
                                        } else {
                                          _updateDeviceDynamic(device, !(device['isOn'] ?? device['status'] ?? false));
                                        }
                                      },
                                    );
                                  }),
                                ),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 30),
              _buildAnimatedSection(
                title: "Appliances",
                delay: 600,
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.8,
                  children: [
                    ApplianceCard(
                        name: "Fridge",
                        status: deviceStates['kitchen_fridge']! ? "On" : "Off",
                        value: "4°C", icon: Icons.kitchen,
                        isActive: deviceStates['kitchen_fridge']!,
                        onTap: () => toggleDevice('kitchen_fridge')
                    ),
                    ApplianceCard(
                        name: "Air Fryer",
                        status: deviceStates['air_fryer']! ? "Ready" : "Off",
                        value: "--", icon: Icons.outdoor_grill,
                        isActive: deviceStates['air_fryer']!,
                        onTap: () => toggleDevice('air_fryer')
                    ),
                    ApplianceCard(
                        name: "Washer",
                        status: deviceStates['washing_machine']! ? "Running" : "Off",
                        value: "--", icon: Icons.local_laundry_service,
                        isActive: deviceStates['washing_machine']!,
                        onTap: () => toggleDevice('washing_machine')
                    ),
                    ApplianceCard(
                        name: "Dryer",
                        status: deviceStates['dryer']! ? "Drying" : "Off",
                        value: "--", icon: Icons.dry,
                        isActive: deviceStates['dryer']!,
                        onTap: () => toggleDevice('dryer')
                    ),
                    ApplianceCard(
                        name: "AC Unit",
                        status: deviceStates['ac_unit']! ? "Cooling" : "Off",
                        value: acTemp, icon: Icons.ac_unit,
                        isActive: deviceStates['ac_unit']!,
                        onTap: () => toggleDevice('ac_unit')
                    ),
                    ApplianceCard(
                        name: "Vacuum",
                        status: deviceStates['vacuum']! ? "Cleaning" : "Docked",
                        value: "45%", icon: Icons.cleaning_services,
                        isActive: deviceStates['vacuum']!, isAccent: true,
                        onTap: () => toggleDevice('vacuum')
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTapped(index), // Fixed: Uses the new nav logic
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? accentCyan : Colors.grey, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? accentCyan : Colors.grey, fontSize: 10))
        ],
      ),
    );
  }

  void toggleDevice(String key) {
    _updateDevice(key, !deviceStates[key]!);
  }

  // ... (Keep _buildHeader, _buildMicHero, _buildRoomCard exactly as they were) ...

  Widget _buildMicHero() {
    return Consumer<EdgeVoiceVoiceProvider>(
      builder: (context, voiceProvider, child) {
        final isListening = voiceProvider.isRecording;
        final isProcessing = voiceProvider.isWaitingForServer;
        final isSpeaking = voiceProvider.isSpeaking;
        
        // Update pulse animation based on state
        if (isListening || isSpeaking) {
          if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
        }

        // Determine displayed text
        String mainText = "Touch to Speak";
        String? subText = "Press the button to start";

        if (isListening) {
          mainText = voiceProvider.realtimeText.isEmpty ? "Listening..." : voiceProvider.realtimeText;
          subText = "Recording your voice...";
        } else if (isProcessing) {
          mainText = "Processing...";
          subText = "Executing command...";
        } else if (voiceProvider.lastTranscription != null) {
          mainText = voiceProvider.lastTranscription!;
          subText = "Command detected";
        }

        return GestureDetector(
          onTap: _listen,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
                color: const Color(0xFF161E2E),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isListening ? accentCyan : (isProcessing ? Colors.yellowAccent : (voiceProvider.isSpeaking ? Colors.greenAccent : accentCyan.withValues(alpha: 0.1)))),
                boxShadow: [
                  BoxShadow(
                      color: isListening ? accentCyan.withValues(alpha: 0.2) : (isProcessing ? Colors.yellowAccent.withValues(alpha: 0.2) : accentCyan.withValues(alpha: 0.05)),
                      blurRadius: 30,
                      offset: const Offset(0, 10)
                  ),
                ]
            ),
            child: Column(
              children: [
                ScaleTransition(
                  scale: (isListening || isSpeaking || isProcessing) ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? Colors.redAccent : (isProcessing ? Colors.yellowAccent : (isSpeaking ? Colors.greenAccent : accentCyan)),
                        boxShadow: [
                          BoxShadow(
                            color: isListening ? Colors.redAccent.withValues(alpha: 0.6) : (isProcessing ? Colors.yellowAccent.withValues(alpha: 0.6) : accentCyan.withValues(alpha: 0.6)),
                            blurRadius: (isListening || isSpeaking || isProcessing) ? 50 : 40,
                            spreadRadius: (isListening || isSpeaking || isProcessing) ? 10 : 5
                          ),
                        ]
                    ),
                    child: Icon(
                      isListening ? Icons.stop : (isProcessing ? Icons.sync : (isSpeaking ? Icons.volume_up : Icons.mic)), 
                      color: Colors.black, 
                      size: 40
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (isListening || isSpeaking) ? accentCyan : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    ),
                    child: Text(mainText),
                  ),
                ),
                if (subText != null) ...[
                  const SizedBox(height: 5),
                  Text(subText, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // (Paste the rest of the helper widgets: _buildHeader, _buildRoomCard, etc. from the previous successful code block here. They haven't changed logic, only context)
  Widget _buildAnimatedSection({required String title, required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Helper to format the image URL
    String? fullImageUrl;
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      String path = _profileImageUrl!.replaceAll('\\', '/');
      if (path.startsWith('http')) {
        fullImageUrl = path;
      } else {
        String baseUrl = AppConfig.apiBaseUrl.split('/api/')[0];
        if (!path.startsWith('/')) path = "/$path";
        fullImageUrl = "$baseUrl$path";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: accentCyan.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.home, color: accentCyan, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Smart Home", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("AI Assistant", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            setState(() => _selectedIndex = 3); // Switch to Settings tab
          },
          child: Hero(
            tag: 'profile_pic',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentCyan.withValues(alpha: 0.1),
              ),
              child: ClipOval(
                child: (fullImageUrl != null
                    ? Image.network(
                        fullImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.network(AppConfig.defaultProfilePic, fit: BoxFit.cover),
                      )
                    : Image.network(AppConfig.defaultProfilePic, fit: BoxFit.cover)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(String name, String status, IconData icon, Iterable<Widget> toggles) {
    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: const Color(0xFF0F1115),
      transitionType: ContainerTransitionType.fade,
      closedBuilder: (context, action) => GestureDetector(
        onTap: action,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF263345), borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: accentCyan, size: 24),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(status, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: accentCyan, size: 16)
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: toggles.toList(),
              )
            ],
          ),
        ),
      ),
      openBuilder: (context, action) => _buildRoomDetailsView(name, icon),
    );
  }

  // New detailed room view for morphing
  Widget _buildRoomDetailsView(String roomName, IconData roomIcon) {
    // Find the room index for state management
    int roomIndex = _rooms.indexWhere((r) => r['name'] == roomName);
    if (roomIndex == -1) return const Scaffold(body: Center(child: Text("Room not found")));
    
    final room = _rooms[roomIndex];
    List<dynamic> roomDevices = room['devices'] ?? [];

    return StatefulBuilder(
      builder: (context, setInternalState) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F1115),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(roomName, style: const TextStyle(color: Colors.white)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(roomIcon, color: accentCyan, size: 32),
                    const SizedBox(width: 15),
                    const Text("Active Devices", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: roomDevices.length,
                    itemBuilder: (context, index) {
                      final device = roomDevices[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161E2E),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(_getDeviceIcon(device['type'] ?? ""), color: accentCyan),
                                const SizedBox(width: 15),
                                Text(device['name'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                            Switch(
                              value: device['isOn'] ?? device['status'] ?? false,
                              activeThumbColor: accentCyan,
                              onChanged: (val) async {
                                final apiService = Provider.of<ApiService>(context, listen: false);
                                final success = await apiService.updateDeviceStatus(device['id'], val);
                                if (success) {
                                  // Update both internal state (for immediate UI) 
                                  // and parent state (for consistency)
                                  setInternalState(() {
                                    device['isOn'] = val;
                                    device['status'] = val;
                                  });
                                  setState(() {
                                    String? legacyKey = _mapDeviceToLegacyKey(roomName, device['name'] ?? "");
                                    if (legacyKey != null) deviceStates[legacyKey] = val;
                                  });
                                  apiService.addLog("User turned ${device['name']} ${val ? 'ON' : 'OFF'}");
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

// ==================================================================
//   CUSTOM WIDGETS
// ==================================================================

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: const Color(0xFF00F0FF), size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}

class DeviceToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isText;
  final VoidCallback? onTap;

  const DeviceToggle({super.key, required this.icon, required this.label, required this.isActive, this.isText = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color accentCyan = const Color(0xFF00F0FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          borderRadius: BorderRadius.circular(15),
          border: isActive ? Border.all(color: accentCyan.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? accentCyan : Colors.grey, size: 22),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class TemperatureDisplay extends StatelessWidget {
  final IconData icon;
  final String label;

  const TemperatureDisplay({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final Color accentCyan = const Color(0xFF00F0FF);

    return Container(
      width: 95,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
          color: const Color(0xFF0F1115),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: accentCyan.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: accentCyan.withValues(alpha: 0.1), blurRadius: 8)
          ]
      ),
      child: Column(
        children: [
          Icon(icon, color: accentCyan, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.2, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class ApplianceCard extends StatelessWidget {
  final String name;
  final String status;
  final String value;
  final IconData icon;
  final bool isActive;
  final bool isAccent;
  final bool isStatic;
  final VoidCallback onTap;

  const ApplianceCard({
    super.key,
    required this.name,
    required this.status,
    required this.value,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.isAccent = false,
    this.isStatic = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentCyan = const Color(0xFF00F0FF);

    return GestureDetector(
      onTap: isStatic ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E),
          borderRadius: BorderRadius.circular(25),
          border: isActive ? Border.all(color: accentCyan.withValues(alpha: 0.3)) : Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: isAccent ? accentCyan.withValues(alpha: 0.2) : const Color(0xFF263345),
                  borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, color: isAccent ? accentCyan : (isActive ? accentCyan : Colors.grey)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(status, style: TextStyle(color: isAccent ? accentCyan : (isActive ? Colors.greenAccent : Colors.grey), fontSize: 11)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            )
          ],
        ),
      ),
    );
  }
}


