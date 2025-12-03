import 'package:flutter/material.dart';

// Reusable Text Field Widget (Dark Mode Version)
Widget buildTextField({
  required String label,
  required String hint,
  TextEditingController? controller,
  bool isPassword = false,
  bool isVisible = false,
  VoidCallback? onVisibilityToggle
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
          label,
          style: const TextStyle(
              color: Colors.white70, // Lighter text for dark mode
              fontSize: 14,
              fontWeight: FontWeight.w500
          )
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        style: const TextStyle(color: Colors.white), // User typing color
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          filled: true,
          fillColor: const Color(0xFF1E293B), // Dark input background
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Compact height
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none, // Clean look without border lines
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF00F0FF)), // Cyan glow on focus
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: onVisibilityToggle,
          )
              : null,
        ),
      ),
    ],
  );
}

// Reusable Social Login Section
class SocialLoginSection extends StatelessWidget {
  final String dividerText;
  const SocialLoginSection({super.key, required this.dividerText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(dividerText, style: const TextStyle(color: Colors.grey)),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialButton(label: "Google", imagePath: "assets/images/google.png"),
            const SizedBox(width: 20),
            _socialButton(label: "iCloud", imagePath: "assets/images/apple.png"),
          ],
        ),
      ],
    );
  }

  Widget _socialButton({required String label, required String imagePath}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Button Background
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Image.asset(imagePath, height: 24, width: 24, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white, // White text
              )
          ),
        ],
      ),
    );
  }
}