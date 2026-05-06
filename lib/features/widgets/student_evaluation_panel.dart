import 'package:flutter/material.dart';

class StudentEvaluationPanel extends StatelessWidget {
  final String? feedback;
  final double? grade;
  final Color primaryColor;

  const StudentEvaluationPanel({
    super.key,
    required this.feedback,
    required this.grade,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Retroalimentación del docente',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            (feedback ?? '').trim().isNotEmpty ? feedback!.trim() : '-',
          ),
          const SizedBox(height: 10),
          const Text(
            'Calificación',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(grade != null ? grade!.toString() : '-'),
        ],
      ),
    );
  }
}

