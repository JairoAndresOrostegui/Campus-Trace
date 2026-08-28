import 'package:flutter/material.dart';

import '../models/form_template.dart';

class TemplatePickerBar extends StatelessWidget {
  const TemplatePickerBar({
    super.key,
    required this.templates,
    required this.selectedId,
    required this.onPick,
    required this.onCreateNew,
    this.onDuplicate,
    this.onDelete,
  });

  final List<FormTemplate> templates;
  final String? selectedId;
  final VoidCallback onPick;
  final Future<void> Function() onCreateNew;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    FormTemplate? selected;
    for (final item in templates) {
      if (item.id == selectedId) {
        selected = item;
        break;
      }
    }
    final hasSelection = selected != null;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: .15)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [primary.withValues(alpha: .06), Colors.white],
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_open, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasSelection
                              ? selected.header.title
                              : 'Selecciona una plantilla…',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasSelection)
                          Text(
                            '#${selected.code}  •  '
                            '${selected.groupName.isEmpty ? "—" : selected.groupName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withValues(alpha: .6),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.search, color: primary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (onDuplicate != null) ...[
          IconButton.filledTonal(
            tooltip: 'Duplicar plantilla',
            onPressed: onDuplicate,
            icon: const Icon(Icons.copy),
          ),
          const SizedBox(width: 8),
        ],
        if (onDelete != null) ...[
          IconButton.filledTonal(
            tooltip: 'Eliminar plantilla',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
          const SizedBox(width: 8),
        ],
        FilledButton.icon(
          onPressed: onCreateNew,
          icon: const Icon(Icons.add),
          label: const Text('Crear nuevo'),
        ),
      ],
    );
  }
}
