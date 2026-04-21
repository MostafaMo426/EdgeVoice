import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'welcome_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool isStandalone;
  const SettingsScreen({super.key, this.isStandalone = true});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    Widget content = Container(
      color: const Color(0xFF181A20), // Matches Cyberpunk theme
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            "Settings",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_circle, color: Color(0xFF00F0FF), size: 100),
                  const SizedBox(height: 20),
                  const Text("Active Session", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      minimumSize: const Size(200, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      // Perform Logout using our Custom AuthService
                      await authService.signOut();
                      
                      if (context.mounted) {
                        // Return to Welcome Screen
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (isStandalone) {
      return Scaffold(backgroundColor: const Color(0xFF181A20), body: content);
    } else {
      return content;
    }
  }
}
