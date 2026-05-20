import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/device_pairing_provider.dart';
import 'pairing_screen.dart';
import 'welcome_screen.dart';
import 'privacy_screen.dart';
import '../config.dart';

class SettingsScreen extends StatefulWidget {
  final bool isStandalone;
  final XFile? profileImage;
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
  final AuthService _authService = AuthService();
  String _userName = "Loading...";
  String _userEmail = "Loading...";
  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('fullName') ?? "User";
      _userEmail = prefs.getString('email') ?? "No Email";
      _profileImageUrl = prefs.getString('profilePicture');
      _isLoadingProfile = false;
    });

    // Optionally refresh from API
    final profile = await _authService.getUserProfile();
    if (profile != null && mounted) {
      final String? apiProfilePic = profile['imagePath'] ?? profile['imageUrl'] ?? profile['profilePicture'] ?? profile['ProfilePicture'];
      
      setState(() {
        _userName = profile['fullName'] ?? profile['FullName'] ?? _userName;
        _userEmail = profile['email'] ?? profile['Email'] ?? _userEmail;
        _profileImageUrl = apiProfilePic ?? _profileImageUrl;
      });
      if (apiProfilePic != null) {
        await prefs.setString('profilePicture', apiProfilePic);
      }
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    print(">>> [UI] Opening Image Source Sheet");
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text("Gallery", style: TextStyle(color: Colors.white)),
              onTap: () async {
                print(">>> [UI] Gallery Tapped");
                Navigator.pop(bottomSheetContext);
                try {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                  );
                  if (pickedFile != null) {
                    print(">>> [UI] Image Selected: ${pickedFile.name}");
                    _uploadImage(pickedFile);
                  } else {
                    print(">>> [UI] Picking Cancelled");
                  }
                } catch (e) {
                  print(">>> [UI] Picking Error: $e");
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text("Camera", style: TextStyle(color: Colors.white)),
              onTap: () async {
                print(">>> [UI] Camera Tapped");
                Navigator.pop(bottomSheetContext);
                try {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1000,
                    maxHeight: 1000,
                  );
                  if (pickedFile != null) {
                    print(">>> [UI] Image Captured: ${pickedFile.name}");
                    _uploadImage(pickedFile);
                  }
                } catch (e) {
                  print(">>> [UI] Camera Error: $e");
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(XFile file) async {
    print(">>> [UI] _uploadImage called for ${file.name}");
    setState(() => _isLoadingProfile = true);
    
    try {
      final result = await _authService.uploadProfileImage(file);
      
      if (!mounted) return;

      if (result != null) {
        String? updatedUrl;
        
        if (result == "UPLOAD_SUCCESS") {
          final profile = await _authService.getUserProfile();
          updatedUrl = profile?['imagePath'] ?? profile?['imageUrl'] ?? profile?['profilePicture'] ?? profile?['ProfilePicture'];
        } else {
          updatedUrl = result;
        }

        if (updatedUrl != null) {
          final refreshedUrl = updatedUrl.contains('?') 
              ? "$updatedUrl&t=${DateTime.now().millisecondsSinceEpoch}" 
              : "$updatedUrl?t=${DateTime.now().millisecondsSinceEpoch}";
              
          setState(() {
            _profileImageUrl = refreshedUrl;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profilePicture', refreshedUrl);
          
          if (widget.onImageChanged != null) {
            widget.onImageChanged!(null);
          }
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated")),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image")),
          );
        }
      }
    } catch (e) {
      debugPrint("[DEBUG] SettingsScreen Upload Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            // 1. Clear local session
                            await _authService.signOut();
                            
                            // 2. Navigate and clear the navigation stack
                            if (context.mounted) {
                              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
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
    // Helper to format the image URL
    String? fullImageUrl;
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      // 1. Convert backslashes to forward slashes
      String path = _profileImageUrl!.replaceAll('\\', '/');
      
      // 2. Remove 'wwwroot/' or 'www/' if the server included it in the path
      if (path.startsWith('wwwroot/')) path = path.substring(8);
      if (path.startsWith('www/')) path = path.substring(4);
      
      if (path.startsWith('http')) {
        fullImageUrl = path;
      } else {
        // 3. Build the base URL (remove /api/ from the end)
        String baseUrl = AppConfig.apiBaseUrl.split('/api/')[0];
        if (baseUrl.endsWith('/')) baseUrl = baseUrl.substring(0, baseUrl.length - 1);
        
        // 4. Ensure path starts with a single /
        if (!path.startsWith('/')) path = "/$path";
        
        fullImageUrl = "$baseUrl$path";
      }
      debugPrint("[DEBUG] Final Profile Image URL: $fullImageUrl");
    }

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
                  Hero(
                    tag: 'profile_pic',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.2),
                      ),
                      child: ClipOval(
                        child: _isLoadingProfile
                            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : (fullImageUrl != null
                                ? Image.network(
                                    fullImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint("Image Load Error: $error for URL: $fullImageUrl");
                                      return Image.network(AppConfig.defaultProfilePic, fit: BoxFit.cover);
                                    },
                                  )
                                : Image.network(AppConfig.defaultProfilePic, fit: BoxFit.cover)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        print(">>> [UI] Edit Button Tapped");
                        _showImageSourceActionSheet(context);
                      },
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Smart Home User", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProfileItem(context, Icons.person_outline, "Name", _userName),
          _buildProfileItem(context, Icons.email_outlined, "Email", _userEmail, canChange: false),
          _buildProfileItem(context, Icons.lock_outline, "Password", "••••••••", isPassword: true),
        ],
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String label, String value, {bool isPassword = false, bool canChange = true}) {
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
          if (canChange)
            TextButton(
              onPressed: () {
                if (isPassword) {
                  _showChangePasswordDialog(context);
                } else {
                  _showEditDialog(context, label, value);
                }
              },
              child: const Text("Change", style: TextStyle(color: Color(0xFF00F0FF))),
            ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    String? errorMessage;
    bool isVerifying = false;
    bool isOldPasswordCorrect = false;

    String? validatePassword(String password) {
      if (password.length < 8) return "Password must be at least 8 characters";
      if (!password.contains(RegExp(r'[a-z]'))) return "Password must contain at least one lowercase letter";
      if (!password.contains(RegExp(r'[A-Z]'))) return "Password must contain at least one uppercase letter";
      if (!password.contains(RegExp(r'[0-9]'))) return "Password must contain at least one number";
      if (!password.contains(RegExp(r'[@$!%*?&]'))) return "Password must contain at least one special character (@, \$, !, %, *, ?, &)";
      return null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text("Change Password", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  enabled: !isOldPasswordCorrect,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Old Password",
                    labelStyle: const TextStyle(color: Colors.grey),
                    errorText: errorMessage,
                    errorStyle: const TextStyle(color: Colors.redAccent),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                if (isOldPasswordCorrect) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "New Password",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("• At least 8 characters", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        Text("• At least 1 lowercase letter", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        Text("• At least 1 uppercase letter", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        Text("• At least 1 number", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        Text("• At least 1 symbol (@, \$, !, %, *, ?, &)", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Confirm New Password",
                      labelStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isVerifying ? null : () async {
                  if (!isOldPasswordCorrect) {
                    setModalState(() {
                      isVerifying = true;
                      errorMessage = null;
                    });
                    
                    // Here we check password by attempting a "change" with same password or a dedicated check endpoint
                    // Since the requirement says "check it from the database", we use our changePassword logic
                    // If it returns "The password is incorrect", we show the alert.
                    final result = await _authService.changePassword(oldPasswordController.text, oldPasswordController.text);
                    
                    setModalState(() {
                      isVerifying = false;
                      if (!mounted) return;
                      if (result['message'] == 'The password is incorrect') {
                        errorMessage = "The password is incorrect";
                      } else {
                        // If it succeeded or returned something else, we consider it "correct" for the UI flow
                        isOldPasswordCorrect = true;
                      }
                    });
                  } else {
                    String? validationError = validatePassword(newPasswordController.text);
                    if (validationError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: Colors.red));
                      return;
                    }

                    if (newPasswordController.text != confirmPasswordController.text) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
                       return;
                    }
                    final result = await _authService.changePassword(oldPasswordController.text, newPasswordController.text);
                    if (!context.mounted) return;
                    if (result['success']) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Password updated successfully")));
                    } else {
                      setModalState(() {
                        errorMessage = result['message'];
                      });
                    }
                  }
                },
                child: isVerifying 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : Text(isOldPasswordCorrect ? "Update" : "Verify"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showEditDialog(BuildContext context, String field, String currentValue) {
    final TextEditingController controller = TextEditingController(text: field == "Password" ? "" : currentValue);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: Text("Change $field", style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  obscureText: field == "Password",
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter new $field",
                    hintStyle: const TextStyle(color: Colors.grey),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                if (isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 15),
                    child: LinearProgressIndicator(color: Color(0xFF00F0FF)),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  if (controller.text.trim().isEmpty) return;

                  setModalState(() => isSaving = true);
                  
                  bool success = false;
                  if (field == "Email") {
                    // Usually email isn't changeable this easily, but if the API supports it:
                    // success = await _authService.updateProfile(email: controller.text.trim());
                  } else if (field == "Name") {
                    success = await _authService.updateProfile(fullName: controller.text.trim());
                  }

                  if (success) {
                    await _loadUserData();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$field updated successfully")),
                    );
                  } else {
                    if (!context.mounted) return;
                    setModalState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to update $field")),
                    );
                  }
                },
                child: const Text("Update"),
              ),
            ],
          );
        }
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
          _buildUpdateItem("Security Patch", "Improved encryption for user data protection.", "1 week ago"),
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
