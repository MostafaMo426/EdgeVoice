import 'package:flutter/material.dart';

// Reusable Text Field Widget
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
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500
          )
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: isPassword ? !isVisible : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          // UPDATED: Reduced vertical padding to make field smaller
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.grey),
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

// Reusable Social Login Section (No changes here, but included for completeness)
class SocialLoginSection extends StatelessWidget {
  final String dividerText;
  const SocialLoginSection({super.key, required this.dividerText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(dividerText, style: const TextStyle(color: Colors.grey)),
            ),
            const Expanded(child: Divider()),
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
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(30),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Image.asset(imagePath, height: 24, width: 24, fit: BoxFit.contain),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
        ],
      ),
    );
  }
}