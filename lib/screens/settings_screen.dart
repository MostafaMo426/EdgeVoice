import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart'; // Make sure to import your Welcome Screen

class SettingsScreen extends StatelessWidget {
  final bool isStandalone;
  const SettingsScreen({super.key, this.isStandalone = true});

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      color: const Color(0xFF181A20),
      child: Column(
        children: [
          AppBar(
            title: const Text("Settings", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // Remove back button
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isStandalone) {
      return Scaffold(body: content);
    } else {
      return content;
    }
  }
}
