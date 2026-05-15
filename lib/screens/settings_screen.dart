import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../providers/device_pairing_provider.dart';
import 'pairing_screen.dart';
import 'welcome_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isStandalone;
  final File? profileImage;
  final Function(ImageSource?)? onImageChanged;

  const SettingsScreen({
    super.key,
    this.isStandalone = true,
    this.profileImage,
    this.onImageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text("Gallery", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                widget.onImageChanged?.call(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text("Camera", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                widget.onImageChanged?.call(ImageSource.camera);
              },
            ),
            if (widget.profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("Remove Picture", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onImageChanged?.call(null);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    const Color gradientStart = Color(0xFF1E293B);
    const Color gradientEnd = Color(0xFF5270A1);
    const Color accentCyan = Color(0xFF00F0FF);

    Widget content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Settings",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. YOUR PROFILE ---
                    _buildAnimatedSection(
                      title: "Your Profile",
                      delay: 100,
                      child: _buildProfileCard(context, accentCyan),
                    ),
                    const SizedBox(height: 25),

                    // --- 2. DEVICE SETTINGS ---
                    _buildAnimatedSection(
                      title: "Device Settings",
                      delay: 200,
                      child: _buildDeviceSettingsCard(accentCyan),
                    ),
                    const SizedBox(height: 25),

                    // --- 3. NOTIFICATIONS ---
                    _buildAnimatedSection(
                      title: "Notifications",
                      delay: 300,
                      child: _buildNotificationCard(accentCyan),
                    ),
                    const SizedBox(height: 25),

                    // --- 4. PRIVACY ---
                    _buildAnimatedSection(
                      title: "EdgeVoice Privacy",
                      delay: 400,
                      child: _buildPrivacyButton(context),
                    ),
                    const SizedBox(height: 40),

                    // --- LOGOUT BUTTON ---
                    _buildAnimatedSection(
                      title: "",
                      delay: 500,
                      child: Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text(
                            "Log Out",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: () async {
                            await authService.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                (route) => false,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Bottom padding for navigation bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(body: content);
    } else {
      return content;
    }
  }

  Widget _buildAnimatedSection({required String title, required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Interval(delay / 1000, 1.0, curve: Curves.easeOutQuart),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: accent.withValues(alpha: 0.2),
                    backgroundImage: widget.profileImage != null
                        ? FileImage(widget.profileImage!)
                        : const NetworkImage("https://i.pravatar.cc/150?u=edgevoice_user") as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Alex Johnson", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Age: 28", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProfileItem(context, Icons.email_outlined, "Email", "alex.j@edgevoice.ai"),
          _buildProfileItem(context, Icons.lock_outline, "Password", "••••••••", isPassword: true),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String label, String value, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showEditDialog(context, label, value),
            child: const Text("Change", style: TextStyle(color: Color(0xFF00F0FF))),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String field, String currentValue) {
    final TextEditingController controller = TextEditingController(text: field == "Password" ? "" : currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text("Change $field", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: field == "Password",
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement actual API update logic
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$field updated (Simulation)")),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSettingsCard(Color accent) {
    return Consumer<DevicePairingProvider>(
      builder: (context, pairingProvider, child) {
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              if (pairingProvider.isPaired)
                _buildDeviceItem(
                  Icons.settings_input_antenna,
                  "Paired Device",
                  pairingProvider.pairedSerial!,
                  accent,
                  onTrailingTap: () => pairingProvider.unpairDevice(),
                  trailingIcon: Icons.link_off,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "No physical device paired.",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              const Divider(color: Colors.white10, height: 25),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PairingScreen()),
                  );
                },
                icon: Icon(Icons.add_circle_outline, color: accent),
                label: Text(pairingProvider.isPaired ? "Pair Different Device" : "Pair New Device", style: TextStyle(color: accent)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceItem(IconData icon, String name, String status, Color accent, {VoidCallback? onTrailingTap, IconData? trailingIcon}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: accent),
      title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 15)),
      subtitle: Text(status, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
      trailing: IconButton(
        icon: Icon(trailingIcon ?? Icons.arrow_forward_ios, color: Colors.grey, size: 18),
        onPressed: onTrailingTap,
      ),
    );
  }

  Widget _buildNotificationCard(Color accent) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildUpdateItem("Firmware v2.4.0", "New voice triggers and improved latency.", "2 days ago"),
          const Divider(color: Colors.white10, height: 25),
          _buildUpdateItem("Security Patch", "Updated encryption for local bypass mode.", "1 week ago"),
        ],
      ),
    );
  }

  Widget _buildUpdateItem(String title, String desc, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 5),
        Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildPrivacyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Privacy Policy & Local Processing",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
