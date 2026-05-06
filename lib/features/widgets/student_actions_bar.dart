import 'package:flutter/material.dart';

class StudentActionsBar extends StatelessWidget {
  final bool sending;
  final bool locked;
  final VoidCallback onExportPdf;
  final VoidCallback onSaveDraft;
  final VoidCallback onSubmit;

  const StudentActionsBar({
    super.key,
    required this.sending,
    required this.locked,
    required this.onExportPdf,
    required this.onSaveDraft,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exportar PDF'),
          onPressed: onExportPdf,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Guardar progreso'),
          onPressed: locked ? null : onSaveDraft,
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: (sending || locked) ? null : onSubmit,
          icon: const Icon(Icons.send),
          label: sending
              ? const Text('Enviando...')
              : const Text('Enviar'),
        ),
      ],
    );
  }
}

