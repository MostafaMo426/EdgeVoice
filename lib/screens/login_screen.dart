import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'create_account_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
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

  // Colors
  final Color gradientStart = const Color(0xFF1E293B);
  final Color gradientEnd = const Color(0xFF5270A1);
  final Color sheetColor = const Color(0xFFECF1F9); // Light Background
  final Color darkBlue = const Color(0xFF1E293B);
  final Color accentCyan = const Color(0xFF00F0FF);

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
      if(mounted) {
        // Fetch full profile to ensure we have the imagePath from the database
        await _authService.getUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
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

                                // --- LOGO WITH HERO MORPH ---
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
                          border: Border(top: BorderSide(color: darkBlue.withValues(alpha: 0.1)))
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkBlue)),
                          ),
                          const SizedBox(height: 30),

                          buildTextField(label: "Email", hint: "example@gmail.com", controller: _emailController, isDark: false),
                          const SizedBox(height: 20),
                          buildTextField(
                              label: "Password",
                              hint: "example_1",
                              isPassword: true,
                              isVisible: _isPasswordVisible,
                              controller: _passwordController,
                              onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              isDark: false
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: darkBlue,
                                    checkColor: Colors.white,
                                    side: BorderSide(color: darkBlue.withValues(alpha: 0.5)),
                                    onChanged: (val) => setState(() => _rememberMe = val!),
                                  ),
                                  Text("Remember me", style: TextStyle(color: darkBlue.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                                  );
                                },
                                child: Text("Forget password?", style: TextStyle(color: darkBlue, fontWeight: FontWeight.w600)),
                              )
                            ],
                          ),
                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: darkBlue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Sign in", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),

                          const SizedBox(height: 20),
                          Center(
                            child: OpenContainer(
                              closedElevation: 0,
                              openElevation: 0,
                              closedColor: Colors.transparent,
                              openColor: gradientStart,
                              transitionType: ContainerTransitionType.fade,
                              closedBuilder: (context, action) => GestureDetector(
                                onTap: action,
                                child: RichText(
                                  text: TextSpan(
                                    text: "Don't have an account? ",
                                    style: TextStyle(color: darkBlue.withValues(alpha: 0.6), fontSize: 14),
                                    children: [
                                      TextSpan(text: "sign up", style: TextStyle(fontWeight: FontWeight.bold, color: darkBlue)),
                                    ],
                                  ),
                                ),
                              ),
                              openBuilder: (context, action) => const CreateAccountScreen(),
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