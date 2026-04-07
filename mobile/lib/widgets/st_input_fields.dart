import 'package:flutter/material.dart';
import '../constants/st_style.dart';

class UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const UnderlineField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 10),
          child: Icon(icon, color: ST.outlineVariant, size: 20),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: ST.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ST.outlineVariant.withOpacity(0.7), fontSize: 15),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ST.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.only(bottom: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class UnderlinePasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const UnderlinePasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 10),
          child: Icon(Icons.lock_outline, color: ST.outlineVariant, size: 20),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 15, color: ST.onSurface),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: ST.outlineVariant.withOpacity(0.7), fontSize: 15),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ST.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.only(bottom: 10),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ST.outlineVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FormLabel extends StatelessWidget {
  final String label;
  const FormLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Bernard MT Condensed',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 2,
        color: ST.outline,
      ),
    );
  }
}

class FormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const FormFieldWidget({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: ST.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: ST.outlineVariant, fontSize: 14),
          prefixIcon: Icon(icon, color: ST.outlineVariant, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class FormPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const FormPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: ST.onSurface),
        decoration: InputDecoration(
          hintText: '••••••••••••',
          hintStyle: TextStyle(color: ST.outlineVariant, fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline, color: ST.outlineVariant, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: ST.outlineVariant,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
