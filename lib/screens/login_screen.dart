import 'package:flutter/material.dart';
import 'create_account_screen.dart';
import '../widgets/custom_widgets.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;

  void _handleSignIn() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter email and password")));
      return;
    }
    setState(() => _isLoading = true);
    String? errorMessage = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (errorMessage == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green));
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // LAYER 1: Background Vector
          Positioned(
            top: 0,
            right: 0,
            width: size.width * 0.60,
            child: Image.asset(
              'assets/images/Vector.png',
              fit: BoxFit.fitWidth,
            ),
          ),

          // LAYER 2: Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // --- HEADER ROW ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Side
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Invisible Spacer so Logo sits below the Fixed Back Button
                              const SizedBox(height: 60),

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
                        // Right Side
                        Expanded(
                          flex: 6,
                          child: Image.asset(
                            'assets/images/rafiki2.png',
                            height: 220,
                            fit: BoxFit.contain,
                            alignment: Alignment.centerRight,
                          ),
                        ),
                      ],
                    ),
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
                              "Login",
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600)
                          ),
                        ),
                        const SizedBox(height: 30),

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

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: Colors.black,
                                  onChanged: (val) => setState(() => _rememberMe = val!),
                                ),
                                const Text("Remember me", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            TextButton(
                              onPressed: (){},
                              child: const Text("Forget password?", style: TextStyle(color: Colors.black)),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Sign in", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),

                        const SizedBox(height: 20),
                        const SocialLoginSection(dividerText: "Or sign up with"),
                        const SizedBox(height: 20),

                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                                children: [
                                  TextSpan(text: "sign up", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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

          // LAYER 3: FIXED BACK BUTTON
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