import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'settings_screen.dart'; 
import 'logs_screen.dart'; // Import Logs Screen
import 'rooms_screen.dart'; // Import Rooms Screen
import '../services/api_service.dart'; // Import API Service

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService(); // Initialize API Service

  // --- 1. MASTER STATE ---
  Map<String, bool> deviceStates = {
    'living_lights': true,
    'living_tv': false,
    'bed_lights': true,
    'bed_fan': true,
    'kitchen_lights': false,
    'kitchen_coffee': false,
    'washer': false,
    'vacuum': true,
    'humidifier': false,
    'front_door': false,
    'ac_unit': true,
  };

  // --- REUSABLE UPDATE METHOD ---
  void _updateDevice(String key, bool state, {bool silent = false}) {
    if (deviceStates.containsKey(key)) {
      setState(() {
        deviceStates[key] = state;
      });

      // Send to API
      _apiService.addCommand(name: key, value: state ? 1 : 0);
      _apiService.addLog("User turned $key ${state ? 'ON' : 'OFF'}");

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("${key.replaceAll('_', ' ')}: ${state ? 'ON' : 'OFF'}"),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 500),
        ));
      }
    }
  }

  // --- GROUP TOGGLES ---
  void _toggleLights() {
    bool anyOn = deviceStates['living_lights']! || deviceStates['bed_lights']! || deviceStates['kitchen_lights']!;
    bool target = !anyOn;
    _updateDevice('living_lights', target, silent: true);
    _updateDevice('bed_lights', target, silent: true);
    _updateDevice('kitchen_lights', target, silent: true);
    _showBulkFeedback("Lights", target);
  }

  void _toggleDoors() {
    bool target = !deviceStates['front_door']!;
    _updateDevice('front_door', target);
  }

  void _toggleClimate() {
    bool anyOn = deviceStates['bed_fan']! || deviceStates['humidifier']! || deviceStates['ac_unit']!;
    bool target = !anyOn;
    _updateDevice('bed_fan', target, silent: true);
    _updateDevice('humidifier', target, silent: true);
    _updateDevice('ac_unit', target, silent: true);
    _showBulkFeedback("Climate", target);
  }

  void _toggleSecurity() {
    // If anything is on, turn EVERYTHING off. Else turn everything on.
    bool anyOn = deviceStates.values.any((val) => val == true);
    bool target = !anyOn;
    
    deviceStates.keys.forEach((key) {
      _updateDevice(key, target, silent: true);
    });
    
    _showBulkFeedback("All Systems", target);
  }

  void _showBulkFeedback(String group, bool state) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$group: ${state ? 'ALL ON / OPEN' : 'ALL OFF / CLOSED'}"),
      backgroundColor: state ? Colors.blue : Colors.redAccent,
      duration: const Duration(seconds: 1),
    ));
  }

  int _selectedIndex = 0;
  bool _isSystemArmed = true;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Tap to Speak";

  // Colors & Data
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color accentCyan = const Color(0xFF00F0FF);
  String livingRoomTemp = "72°F";
  String bedroomTemp = "68°F";
  String acTemp = "68°F";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _startPolling(); // Add polling for "Notifications"
  }

  void _startPolling() async {
    // Poll for pending commands every 10 seconds (Simulating Notifications)
    while (mounted) {
      await Future.delayed(const Duration(seconds: 10));
      final pending = await _apiService.getPendingCommands();
      if (pending.isNotEmpty && mounted) {
        for (var cmd in pending) {
          _showNotification(cmd['name'], cmd['value'] == 1);
          await _apiService.markCommandAsExecuted(cmd['id']);
        }
      }
    }
  }

  void _showNotification(String name, bool state) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.white),
          const SizedBox(width: 10),
          Text("Remote Command: $name is now ${state ? 'ON' : 'OFF'}"),
        ],
      ),
      backgroundColor: Colors.purple,
      behavior: SnackBarBehavior.floating,
    ));
    
    // Update local UI state
    if (deviceStates.containsKey(name)) {
      setState(() => deviceStates[name] = state);
    }
  }

  void _initSpeech() async {
    await _speech.initialize();
    if (mounted) setState(() {});
  }

  // --- 2. VOICE LOGIC (Updated) ---
  void _listen() async {
    if (!_isListening) {
      var status = await Permission.microphone.request();
      if (status.isDenied) return;

      bool available = await _speech.initialize(
        onStatus: (val) {
          // If the phone detects silence or 'done', stop the UI animation
          if (val == 'done' || val == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );

      if (available) {
        setState(() {
          _isListening = true;
          _text = "Listening...";
        });

        _speech.listen(
          // --- MAGIC FIX: Stop automatically after 2 seconds of silence ---
          pauseFor: const Duration(seconds: 2),
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              // If the sentence is final (user stopped talking), run command
              if (val.finalResult) {
                _processVoiceCommand(val.recognizedWords);
                // Optionally clear text after a delay
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _text = "Tap to Speak");
                });
              }
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processVoiceCommand(String command) {
    command = command.toLowerCase();

    // Default to Toggle if user doesn't say "on" or "off"
    bool? targetState;
    if (command.contains("on") || command.contains("start") || command.contains("open")) targetState = true;
    if (command.contains("off") || command.contains("stop") || command.contains("close")) targetState = false;

    // --- SMART COMMAND MATCHING ---
    // Living Room
    if (command.contains("living") && (command.contains("light") || command.contains("lamp"))) {
      _updateDevice('living_lights', targetState ?? !deviceStates['living_lights']!);
    }
    if (command.contains("tv") || command.contains("television")) {
      _updateDevice('living_tv', targetState ?? !deviceStates['living_tv']!);
    }

    // Bedroom
    if (command.contains("bed") && (command.contains("light") || command.contains("lamp"))) {
      _updateDevice('bed_lights', targetState ?? !deviceStates['bed_lights']!);
    }
    if (command.contains("fan") || command.contains("air")) {
      _updateDevice('bed_fan', targetState ?? !deviceStates['bed_fan']!);
    }

    // Kitchen
    if (command.contains("kitchen") && (command.contains("light") || command.contains("lamp"))) {
      _updateDevice('kitchen_lights', targetState ?? !deviceStates['kitchen_lights']!);
    }
    if (command.contains("coffee") || command.contains("brew")) {
      _updateDevice('kitchen_coffee', targetState ?? !deviceStates['kitchen_coffee']!);
    }

    // Appliances
    if (command.contains("vacuum") || command.contains("robot") || command.contains("clean")) {
      _updateDevice('vacuum', targetState ?? !deviceStates['vacuum']!);
    }
    if (command.contains("washer") || command.contains("laundry")) {
      _updateDevice('washer', targetState ?? !deviceStates['washer']!);
    }
    if (command.contains("humidifier")) {
      _updateDevice('humidifier', targetState ?? !deviceStates['humidifier']!);
    }

    // Master Commands
    if (command.contains("all lights on")) _toggleLights();
    if (command.contains("all lights off") || command.contains("turn off everything")) _toggleSecurity();
  }

  void toggleDevice(String key) {
    _updateDevice(key, !deviceStates[key]!);
  }

  // --- NAVIGATION LOGIC ---
  void _onNavItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
          const RoomsScreen(),
          const LogsScreen(),
          const SettingsScreen(),
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
              const Text("Quick Actions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionBtn(icon: Icons.lightbulb_outline, label: "Lights", onTap: _toggleLights),
                  _QuickActionBtn(icon: Icons.door_front_door_outlined, label: "Doors", onTap: _toggleDoors),
                  _QuickActionBtn(icon: Icons.thermostat, label: "Climate", onTap: _toggleClimate),
                  _QuickActionBtn(icon: Icons.shield_outlined, label: "Security", onTap: _toggleSecurity),
                ],
              ),
              const SizedBox(height: 30),
              const Text("Rooms", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildRoomCard(
                  "Living Room", "6 devices active", Icons.weekend,
                  [
                    DeviceToggle(
                      icon: Icons.lightbulb,
                      label: deviceStates['living_lights']! ? "Lights On" : "Lights Off",
                      isActive: deviceStates['living_lights']!,
                      onTap: () => toggleDevice('living_lights'),
                    ),
                    DeviceToggle(
                      icon: Icons.tv,
                      label: deviceStates['living_tv']! ? "TV On" : "TV Off",
                      isActive: deviceStates['living_tv']!,
                      onTap: () => toggleDevice('living_tv'),
                    ),
                    TemperatureDisplay(icon: Icons.thermostat, label: "$livingRoomTemp\nClimate"),
                  ]
              ),
              const SizedBox(height: 15),
              _buildRoomCard(
                  "Bedroom", "3 devices active", Icons.bed,
                  [
                    DeviceToggle(
                      icon: Icons.lightbulb,
                      label: deviceStates['bed_lights']! ? "Lights On" : "Lights Off",
                      isActive: deviceStates['bed_lights']!,
                      onTap: () => toggleDevice('bed_lights'),
                    ),
                    DeviceToggle(
                      icon: Icons.air,
                      label: deviceStates['bed_fan']! ? "Fan On" : "Fan Off",
                      isActive: deviceStates['bed_fan']!,
                      onTap: () => toggleDevice('bed_fan'),
                    ),
                    TemperatureDisplay(icon: Icons.thermostat, label: "$bedroomTemp\nClimate"),
                  ]
              ),
              const SizedBox(height: 15),
              _buildRoomCard(
                  "Kitchen", "4 devices active", Icons.kitchen,
                  [
                    DeviceToggle(
                      icon: Icons.lightbulb,
                      label: deviceStates['kitchen_lights']! ? "Lights On" : "Lights Off",
                      isActive: deviceStates['kitchen_lights']!,
                      onTap: () => toggleDevice('kitchen_lights'),
                    ),
                    DeviceToggle(
                      icon: Icons.coffee,
                      label: deviceStates['kitchen_coffee']! ? "Brewing" : "Coffee Off",
                      isActive: deviceStates['kitchen_coffee']!,
                      onTap: () => toggleDevice('kitchen_coffee'),
                    ),
                    const TemperatureDisplay(icon: Icons.kitchen, label: "Fridge\nOn"),
                  ]
              ),
              const SizedBox(height: 30),
              const Text("Appliances", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 0.8,
                children: [
                  ApplianceCard(
                      name: "AC Unit", 
                      status: deviceStates['ac_unit']! ? "Cooling" : "Off", 
                      value: acTemp, icon: Icons.ac_unit,
                      isActive: deviceStates['ac_unit']!, 
                      onTap: () => toggleDevice('ac_unit')
                  ),
                  ApplianceCard(
                      name: "Washer", status: deviceStates['washer']! ? "Running" : "Off", value: "--", icon: Icons.local_laundry_service,
                      isActive: deviceStates['washer']!, onTap: () => toggleDevice('washer')
                  ),
                  ApplianceCard(
                      name: "Vacuum", status: deviceStates['vacuum']! ? "Cleaning" : "Docked", value: "45%", icon: Icons.cleaning_services,
                      isActive: deviceStates['vacuum']!, isAccent: true, onTap: () => toggleDevice('vacuum')
                  ),
                  ApplianceCard(
                      name: "Humidifier", status: deviceStates['humidifier']! ? "Active" : "Off", value: "52%", icon: Icons.water_drop,
                      isActive: deviceStates['humidifier']!, onTap: () => toggleDevice('humidifier')
                  ),
                ],
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

  // ... (Keep _buildHeader, _buildMicHero, _buildRoomCard, _buildSecurityCard exactly as they were) ...
  // For safety, I will include _buildMicHero again since it had a small update for the listener

  Widget _buildMicHero() {
    return GestureDetector(
      onTap: _listen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
            color: const Color(0xFF161E2E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _isListening ? accentCyan : accentCyan.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                  color: _isListening ? accentCyan.withValues(alpha: 0.2) : accentCyan.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10)
              ),
            ]
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening ? Colors.redAccent : accentCyan,
                  boxShadow: [
                    BoxShadow(color: accentCyan.withValues(alpha: 0.6), blurRadius: 40, spreadRadius: 5),
                  ]
              ),
              child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.black, size: 40),
            ),
            const SizedBox(height: 20),
            Text(_text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 5),
            if(!_isListening)
              Text('Try: "Turn on bedroom lights"', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // (Paste the rest of the helper widgets: _buildHeader, _buildRoomCard, etc. from the previous successful code block here. They haven't changed logic, only context)
  Widget _buildHeader() {
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
        const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('assets/images/rafiki.png'),
        ),
      ],
    );
  }

  Widget _buildRoomCard(String name, String status, IconData icon, List<Widget> toggles) {
    return Container(
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
            children: toggles,
          )
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
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
                child: const Icon(Icons.shield_outlined, color: Colors.white),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("System Armed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("All sensors active", style: TextStyle(color: Colors.blue, fontSize: 12)),
                  ],
                ),
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isSystemArmed,
                  activeThumbColor: Colors.black,
                  activeTrackColor: accentCyan,
                  onChanged: (val) => setState(() => _isSystemArmed = val),
                ),
              )
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _SecurityStatusBtn(
                  icon: Icons.door_back_door,
                  label: "Front Door",
                  status: deviceStates['front_door']! ? "Open" : "Locked",
                  isLocked: !deviceStates['front_door']!,
                  onTap: () => toggleDevice('front_door'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecurityStatusBtn(
                  icon: Icons.videocam,
                  label: "Cameras",
                  status: "3 Active",
                  isLocked: false,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cameras Info"))),
                ),
              ),
            ],
          )
        ],
      ),
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

class _SecurityStatusBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final bool isLocked;
  final VoidCallback onTap;

  const _SecurityStatusBtn({
    required this.icon,
    required this.label,
    required this.status,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDoor = label.contains("Door");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF0F1115), borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF00F0FF), size: 20),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            Text(
              status,
              style: TextStyle(
                color: isDoor ? (isLocked ? Colors.greenAccent : Colors.redAccent) : const Color(0xFF00F0FF),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
