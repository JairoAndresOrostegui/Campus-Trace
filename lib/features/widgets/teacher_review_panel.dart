import 'package:flutter/material.dart';

class TeacherReviewPanel extends StatelessWidget {
  final TextEditingController feedbackController;
  final TextEditingController gradeController;
  final VoidCallback onSaveReview;
  final VoidCallback onExportPdf;
  final Color primaryColor;

  const TeacherReviewPanel({
    super.key,
    required this.feedbackController,
    required this.gradeController,
    required this.onSaveReview,
    required this.onExportPdf,
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
            'Retroalimentación',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: feedbackController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Escribe tu retroalimentación.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Calificación',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: gradeController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              hintText: 'Ej: 4.7',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exportar PDF'),
                  onPressed: onExportPdf,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar revisión'),
                  onPressed: onSaveReview,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

