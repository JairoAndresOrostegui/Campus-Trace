import 'package:flutter/material.dart';
import '../screens/form_fill_screen.dart';
import '../models/form_template.dart';

class FormTemplateCard extends StatelessWidget {
  final FormTemplate template;

  const FormTemplateCard({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    String fmtDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String chipText(String label, String value) => '$label: $value';

    final start = template.header.formStart != null
        ? fmtDate(template.header.formStart!)
        : '—';
    final end =
        template.header.formEnd != null ? fmtDate(template.header.formEnd!) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FormFillScreen(templateId: template.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: primary.withValues(alpha: .15)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary.withValues(alpha: .06), Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Text(
              (template.header.title.isEmpty)
                  ? 'Sin título'
                  : template.header.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _softChip(
                    context,
                    chipText('Código', template.code.isEmpty ? '—' : template.code),
                  ),
                  _softChip(
                    context,
                    chipText(
                      'Grupo',
                      template.groupName.isEmpty ? '—' : template.groupName,
                    ),
                  ),
                  _softChip(context, chipText('Inicio', start)),
                  _softChip(context, chipText('Fin', end)),
                  _softChip(context, chipText('Estado', template.status.toUpperCase())),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      ),
    );
  }

  Widget _softChip(BuildContext context, String text) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .20)),
        color: c.withValues(alpha: .06),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.black.withValues(alpha: .75)),
      ),
    );
  }
}
