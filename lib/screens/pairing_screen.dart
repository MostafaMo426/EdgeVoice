import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_pairing_provider.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _serialController = TextEditingController();
  bool _isSubmitting = false;

  final Color accentCyan = const Color(0xFF00F0FF);
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  void _handlePairing() async {
    final serial = _serialController.text.trim();
    if (serial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a serial number")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    final pairingProvider = Provider.of<DevicePairingProvider>(context, listen: false);
    final success = await pairingProvider.pairDevice(serial);
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Device $serial paired successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid serial number format")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gradientStart,
      appBar: AppBar(
        title: const Text("Device Pairing", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
                "Enter Device Serial",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Pair your app with a physical EdgeVoice device (e.g., EV-2026-99)",
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _serialController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Serial Number",
                  labelStyle: TextStyle(color: accentCyan),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: accentCyan),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF161E2E),
                  prefixIcon: Icon(Icons.qr_code_scanner, color: accentCyan),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePairing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("PAIR DEVICE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  "Need help finding your serial number?",
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
