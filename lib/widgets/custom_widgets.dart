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