import 'package:bookmark/theme/text_theme.dart';
import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  bool obscureText;
  final Function(String)? onChange;

  CustomTextField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(labelText: hintText),
      style: bodySmall,
      controller: controller,
      obscureText: obscureText,
      onChanged: onChange,
    );
  }
}
