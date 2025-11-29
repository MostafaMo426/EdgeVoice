import 'package:flutter/material.dart';
import 'create_account_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                "Logo",
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Create Account Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                  );
                },
                child: const Text("Create Account", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              // Login Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text("Login", style: TextStyle(fontSize: 18)),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}