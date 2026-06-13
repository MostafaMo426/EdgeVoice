import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:async';
import '../providers/device_pairing_provider.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  List<ScanResult> _scanResults = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;

  final Color accentCyan = const Color(0xFF00F0FF);
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);

  @override
  void initState() {
    super.initState();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (await FlutterBluePlus.isSupported == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bluetooth is not supported on this device")),
        );
      }
      return;
    }

    setState(() => _isScanning = true);
    
    try {
      // For Web security, we MUST provide the service UUID during the scan
      // so the browser allows us to access it later.
      await FlutterBluePlus.startScan(
        withServices: [Guid(DevicePairingProvider.SERVICE_UUID)],
        timeout: const Duration(seconds: 15)
      );
    } catch (e) {
      debugPrint("Error starting scan: $e");
    }

    await Future.delayed(const Duration(seconds: 15));
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  void _openBluetoothSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
  }

  void _connectToDevice(ScanResult result) async {
    final device = result.device;
    setState(() => _isScanning = false);
    await FlutterBluePlus.stopScan();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00F0FF))),
    );

    try {
      await device.connect();
      final pairingProvider = Provider.of<DevicePairingProvider>(context, listen: false);
      await pairingProvider.pairDevice(
        device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString(),
        device: device,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Connected to ${device.platformName.isNotEmpty ? device.platformName : 'EdgeVoice'}")),
        );
        Navigator.pop(context); // Go back to settings
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to connect: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gradientStart,
      appBar: AppBar(
        title: const Text("Device Pairing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Setup EdgeVoice",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildInstructionStep(1, "First, open your Bluetooth from your device settings."),
              _buildInstructionStep(2, "Open your EdgeVoice device and put it in pairing mode."),
              _buildInstructionStep(3, "Connect the device to the app by selecting it from the list below."),
              
              const SizedBox(height: 35),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      onTap: _openBluetoothSettings,
                      icon: Icons.settings_bluetooth,
                      label: "BLUETOOTH",
                      color: Colors.white.withValues(alpha: 0.1),
                      textColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionBtn(
                      onTap: _isScanning ? null : _startScan,
                      icon: _isScanning ? null : Icons.search,
                      label: _isScanning ? "SCANNING..." : "SCAN",
                      color: accentCyan,
                      textColor: Colors.black,
                      isLoading: _isScanning,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              Row(
                children: [
                  const Text(
                    "Found Devices",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 10),
                  if (_isScanning)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00F0FF)),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              
              Expanded(
                child: _scanResults.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bluetooth_searching, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text("No devices found yet.", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                          const SizedBox(height: 8),
                          Text("Try scanning again", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _scanResults.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final result = _scanResults[index];
                        final deviceName = result.device.platformName.isNotEmpty 
                            ? result.device.platformName 
                            : "Unknown Device";
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161E2E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentCyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.bluetooth, color: accentCyan),
                            ),
                            title: Text(deviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(result.device.remoteId.toString(), style: TextStyle(color: Colors.grey[500], fontSize: 12, letterSpacing: 1)),
                            trailing: ElevatedButton(
                              onPressed: () => _connectToDevice(result),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentCyan.withValues(alpha: 0.1),
                                foregroundColor: accentCyan,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: const Text("CONNECT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentCyan.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: accentCyan, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(number.toString(), style: TextStyle(color: accentCyan, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[300], fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required VoidCallback? onTap, IconData? icon, required String label, required Color color, required Color textColor, bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: color == accentCyan ? [
            BoxShadow(color: accentCyan.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: textColor))
            else if (icon != null)
              Icon(icon, color: textColor, size: 20),
            if (icon != null || isLoading) const SizedBox(width: 10),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
