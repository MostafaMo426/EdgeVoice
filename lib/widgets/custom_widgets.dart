import 'package:flutter/material.dart';

// Reusable Text Field Widget
Widget buildTextField({
  required String label,
  required String hint,
  TextEditingController? controller,
  bool isPassword = false,
  bool isVisible = false,
  VoidCallback? onVisibilityToggle,
  bool isDark = true,
}) {
  final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
  final labelColor = isDark ? Colors.white70 : const Color(0xFF1E293B).withValues(alpha: 0.8);
  final fieldColor = isDark ? const Color(0xFF1E293B) : Colors.white;
  final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF1E293B).withValues(alpha: 0.2);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
          label,
          style: TextStyle(
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w600
          )
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
          filled: true,
          fillColor: fieldColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF1E293B)),
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
