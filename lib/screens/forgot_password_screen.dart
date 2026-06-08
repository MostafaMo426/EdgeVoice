import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import '../services/auth_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Colors matching Login Screen
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color sheetColor = const Color(0xFF0F1115);
  final Color accentCyan = const Color(0xFF00F0FF);

  void _handleForgotPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your email")));
      return;
    }

    setState(() => _isLoading = true);
    String? error = await _authService.forgotPassword(email);
    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reset code sent to your email"), backgroundColor: Colors.green),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen(email: email)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              width: size.width * 0.60,
              child: Opacity(
                opacity: 0.8,
                child: Image.asset('assets/images/Vector.png', fit: BoxFit.fitWidth),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.arrow_back, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Hero(
                                  tag: 'app_logo',
                                  child: Image.asset(
                                    'assets/images/Logo.png',
                                    height: 150,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Hero(
                              tag: 'auth_image',
                              child: Image.asset('assets/images/rafiki2.png', height: 220, fit: BoxFit.contain, alignment: Alignment.centerRight),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: size.height * 0.6,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      decoration: BoxDecoration(
                          color: sheetColor,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text("Forgot Password", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Enter your email to receive a password reset code.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          buildTextField(label: "Email", hint: "example@gmail.com", controller: _emailController),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleForgotPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentCyan,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text("Send Code", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
