import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;

  // Colors matching theme
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color sheetColor = const Color(0xFF0F1115);
  final Color accentCyan = const Color(0xFF00F0FF);

  String? _validatePassword(String password) {
    if (password.length < 8) return "Password must be at least 8 characters";
    if (!password.contains(RegExp(r'[a-z]'))) return "Password must contain at least one lowercase letter";
    if (!password.contains(RegExp(r'[A-Z]'))) return "Password must contain at least one uppercase letter";
    if (!password.contains(RegExp(r'[0-9]'))) return "Password must contain at least one number";
    if (!password.contains(RegExp(r'[@$!%*?&]'))) return r"Password must contain at least one special character (@, $, !, %, *, ?, &)";
    return null;
  }

  void _handleResetPassword() async {
    String otp = _otpController.text.trim();
    String password = _passwordController.text.trim();
    String confirm = _confirmPasswordController.text.trim();

    if (otp.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    String? validationError = _validatePassword(password);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: Colors.red));
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    String? error = await _authService.resetPassword(
      email: widget.email,
      token: otp,
      newPassword: password,
    );
    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password reset successful!"), backgroundColor: Colors.green),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
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
                            child: Text("Reset Password", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(height: 20),
                          buildTextField(label: "Verification Code", hint: "Enter Code", controller: _otpController),
                          const SizedBox(height: 20),
                          buildTextField(
                            label: "New Password",
                            hint: "********",
                            isPassword: true,
                            isVisible: _isPasswordVisible,
                            controller: _passwordController,
                            onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible)
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("• At least 8 characters", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                Text("• At least 1 lowercase, 1 uppercase, 1 number", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                Text("• At least 1 symbol (@, \$, !, %, *, ?, &)", style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          buildTextField(
                            label: "Confirm Password",
                            hint: "********",
                            isPassword: true,
                            isVisible: _isConfirmVisible,
                            controller: _confirmPasswordController,
                            onVisibilityToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible)
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentCyan,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text("Update Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
