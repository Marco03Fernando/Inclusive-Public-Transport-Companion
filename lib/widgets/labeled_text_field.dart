import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    this.initialValue,
    this.controller,
    this.obscureText = false,
  });

  final String label;
  final String? initialValue;
  final TextEditingController? controller;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(hintText: initialValue),
          style: TextStyle(fontSize: 14, color: palette.text),
        ),
      ],
    );
  }
}

class LabeledTextArea extends StatelessWidget {
  const LabeledTextArea({super.key, required this.label, this.placeholder, this.controller});

  final String label;
  final String? placeholder;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: placeholder),
          style: TextStyle(fontSize: 14, color: palette.text),
        ),
      ],
    );
  }
}
