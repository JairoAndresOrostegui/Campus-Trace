import 'package:flutter/material.dart';

import '../models/form_template.dart';

class FormHeader extends StatelessWidget {
  final FormTemplate template;

  const FormHeader({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final header = template.header;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            header.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: header.titleFontSize,
              color: (header.titleColorHex != null)
                  ? (parseColorSafe(header.titleColorHex) ?? Colors.black87)
                  : Colors.black87,
            ),
          ),
        ),
        if ((header.subtitle ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.center,
            child: Text(
              header.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: header.subtitleFontSize,
                color: (header.subtitleColorHex != null)
                    ? (parseColorSafe(header.subtitleColorHex) ??
                        Colors.black54)
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ===== Helper de color seguro (hex) =====
Color? parseColorSafe(String? hex) {
  if (hex == null || hex.trim().isEmpty) return null;
  var h = hex.replaceAll('#', '').toUpperCase();
  if (h.length == 6) h = 'FF$h';
  try {
    return Color(int.parse(h, radix: 16));
  } catch (_) {
    return null;
  }
}

