import 'package:flutter/material.dart';

class AdminSectionLabel extends StatelessWidget {
  const AdminSectionLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8E8E93),
            letterSpacing: 0.2));
  }
}

class AdminFormField extends StatelessWidget {
  const AdminFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboard = TextInputType.text,
    this.action = TextInputAction.next,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?) validator;
  final TextInputType keyboard;
  final TextInputAction action;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
          fontSize: 15, color: Color(0xFF000000), fontWeight: FontWeight.w400),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF8E8E93)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF3B30))),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF3B30), fontSize: 11),
      ),
    );
  }
}
