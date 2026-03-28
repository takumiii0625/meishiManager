import 'package:flutter/material.dart';

// ----------------------------------------------------------------
// 管理画面共通カラー定数
// ----------------------------------------------------------------
class AdminColors {
  static const primary      = Color(0xFF4361EE);
  static const primaryLight = Color(0xFFEEF1FD);
  static const bg           = Color(0xFFFFFFFF);
  static const border       = Color(0xFFE8EAF0);
  static const textMain     = Color(0xFF1A1F36);
  static const textSub      = Color(0xFF9396A5);
  static const textMid      = Color(0xFF6B6F82);
  static const green        = Color(0xFF1A8C4E);
  static const greenBg      = Color(0xFFE6F9EE);
  static const amber        = Color(0xFFB07D00);
  static const amberBg      = Color(0xFFFFF8E6);
  static const red          = Color(0xFFE53E3E);
  static const redBg        = Color(0xFFFFF5F5);
  static const purple       = Color(0xFF7C3AED);
  static const purpleBg     = Color(0xFFF3EEFF);
}

// ----------------------------------------------------------------
// 管理画面共通フォームウィジェット
// ----------------------------------------------------------------
class AdminFormField extends StatelessWidget {
  const AdminFormField(
    this.label,
    this.controller, {
    super.key,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMid)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13, color: AdminColors.textMain),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.primary)),
              filled: true,
              fillColor: AdminColors.bg,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDropdownField extends StatelessWidget {
  const AdminDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textMid)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            style:
                const TextStyle(fontSize: 13, color: AdminColors.textMain),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AdminColors.primary)),
              filled: true,
              fillColor: AdminColors.bg,
            ),
            items: options.entries
                .map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
