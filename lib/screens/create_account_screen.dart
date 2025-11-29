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

  // --- UPDATED VALIDATION LOGIC ---
  String? _validateInput() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || _nameController.text.isEmpty) {
      return "Please fill in all fields";
    }

    // Email Check
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return "Please enter a valid email address";
    }

    // Password: Length Check
    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }

    // Password: Uppercase Check
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Password must contain at least one uppercase letter";
    }

    // Password: Number Check (NEW)
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Password must contain at least one number";
    }

    // Password: Special Character Check (NEW)
    // Checks for special symbols like ! @ # $ & * ~
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return "Password must contain at least one special character";
    }

    // Confirm Password Check
    if (password != _confirmController.text.trim()) {
      return "Passwords do not match";
    }

    return null;
  }

  void _handleSignUp() async {
    String? validationError = _validateInput();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError), backgroundColor: Colors.red),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Created! Verification email sent."),
              backgroundColor: Colors.green,
            )
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ------------------------------------------------
          // LAYER 1: Background Vector (Fixed)
          // ------------------------------------------------
          Positioned(
            top: 0,
            right: 0,
            width: size.width * 0.60,
            child: Image.asset(
              'assets/images/Vector.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          // ------------------------------------------------
          // LAYER 2: Scrollable Content
          // ------------------------------------------------
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // --- HEADER ROW ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Side (Logo)
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Invisible Spacer for Fixed Back Button area
                            const SizedBox(height: 50),

                            const SizedBox(height: 20),
                            const Text(
                              "Logo",
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right Side (Illustration)
                      Expanded(
                        flex: 6,
                        child: Image.asset(
                          'assets/images/rafiki.png',
                          height: 220,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- FORM CONTAINER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                              "Create Account",
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600)
                          ),
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

                        // --- UPDATED RULES LIST ---
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("• At least 6 characters", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text("• At least 1 uppercase letter", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text("• At least 1 number", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text("• At least 1 special character", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Sign up", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),

                        const SizedBox(height: 20),
                        const SocialLoginSection(dividerText: "Or sign up with"),
                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "Already have an account? ",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                                children: [
                                  TextSpan(text: "sign in", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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

          // ------------------------------------------------
          // LAYER 3: FIXED BACK BUTTON
          // ------------------------------------------------
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
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}