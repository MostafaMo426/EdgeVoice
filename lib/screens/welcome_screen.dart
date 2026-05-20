import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'create_account_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Exact colors from Home Screen
    const Color gradientStart = Color(0xFF1E293B);
    const Color gradientEnd = Color(0xFF5270A1);
    const Color accentCyan = Color(0xFF00F0FF);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // --- LOGO WITH HERO MORPH ---
                Hero(
                  tag: 'app_logo',
                  child: Image.asset(
                    'assets/images/Logo.png',
                    height: 350,
                    width: 350,
                    fit: BoxFit.contain,
                  ),
                ),

                const Spacer(),

                // Create Account Button (OpenContainer Morph)
                OpenContainer(
                  closedElevation: 0,
                  openElevation: 0,
                  closedColor: Colors.transparent,
                  openColor: gradientStart,
                  transitionType: ContainerTransitionType.fadeThrough,
                  closedBuilder: (context, action) => ElevatedButton(
                    onPressed: action,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentCyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Create Account", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  openBuilder: (context, action) => const CreateAccountScreen(),
                ),
                
                const SizedBox(height: 20),

                // Login Button (OpenContainer Morph)
                OpenContainer(
                  closedElevation: 0,
                  openElevation: 0,
                  closedColor: Colors.transparent,
                  openColor: gradientStart,
                  transitionType: ContainerTransitionType.fadeThrough,
                  closedBuilder: (context, action) => OutlinedButton(
                    onPressed: action,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: accentCyan),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  openBuilder: (context, action) => const LoginScreen(),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}