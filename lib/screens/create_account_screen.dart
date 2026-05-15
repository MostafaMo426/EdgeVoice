import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/custom_widgets.dart';
import '../services/auth_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Colors matching Home Screen
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color sheetColor = const Color(0xFF0F1115); // Darker bottom sheet
  final Color accentCyan = const Color(0xFF00F0FF);

  String? _validateInput() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty || _nameController.text.isEmpty) return "Please fill in all fields";
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return "Please enter a valid email address";
    if (password.length < 6) return "Password must be at least 6 characters";
    if (!password.contains(RegExp(r'[A-Z]'))) return "Password must contain at least one uppercase letter";
    if (password != _confirmController.text.trim()) return "Passwords do not match";
    return null;
  }

  void _handleSignUp() async {
    String? validationError = _validateInput();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    String? errorMessage = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (errorMessage == null) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // Gradient Background
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
            // LAYER 1: Vector
            Positioned(
              top: 0,
              right: 0,
              width: size.width * 0.60,
              child: Opacity(
                opacity: 0.8, // Slightly blend with dark bg
                child: Image.asset('assets/images/Vector.png', fit: BoxFit.fitWidth),
              ),
            ),

            // LAYER 2: Content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // --- HEADER ---
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

                                // --- LOGO SIZE INCREASED HERE (120) ---
                                Image.asset(
                                  'assets/images/Logo.png',
                                  height: 150,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerLeft,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Image.asset('assets/images/rafiki.png', height: 220, fit: BoxFit.contain, alignment: Alignment.centerRight),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- DARK FORM CONTAINER ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                      decoration: BoxDecoration(
                          color: sheetColor, // Dark Background
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))) // Subtle border
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text("Create Account", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                          const SizedBox(height: 30),

                          buildTextField(label: "Full name", hint: "e.g. lucy", controller: _nameController),
                          const SizedBox(height: 20),
                          buildTextField(label: "Email", hint: "example@gmail.com", controller: _emailController),
                          const SizedBox(height: 20),
                          buildTextField(
                              label: "Password",
                              hint: "example_1",
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
                                Text("• At least 6 characters", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                                Text("• At least 1 uppercase letter", style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          buildTextField(
                              label: "Confirm password",
                              hint: "example_1",
                              isPassword: true,
                              isVisible: _isConfirmPasswordVisible,
                              controller: _confirmController,
                              onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible)
                          ),

                          const SizedBox(height: 30),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentCyan, // Cyan Button
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text("Sign up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),

                          const SizedBox(height: 20),
                          const SocialLoginSection(dividerText: "Or sign up with"),
                          const SizedBox(height: 20),

                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                              },
                              child: RichText(
                                text: const TextSpan(
                                  text: "Already have an account? ",
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                  children: [
                                    TextSpan(text: "sign in", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00F0FF))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Back Button Area Overlay
            Positioned(
              top: 0,
              left: 24,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 50,
                    height: 50,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}