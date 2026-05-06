import 'package:flutter/material.dart';

/// =====================
/// Paletas unificadas
/// =====================

/// Neutros (negro, blanco, 3 grises: claro, medio, oscuro)
const List<String> kNeutrals = <String>[
  '#000000', // negro
  '#FFFFFF', // blanco
  '#F1F5F9', // gris claro (slate-100)
  '#94A3B8', // gris medio (slate-400)
  '#1F2937', // gris oscuro (gray-800)
];

/// Sólidos para títulos/subtítulos: primarios/secundarios más usados
const List<String> kSolidStrong = <String>[
  '#DC2626', // rojo 600
  '#1D4ED8', // azul 600
  '#16A34A', // verde 600
  '#9333EA', // morado 600
  '#0EA5E9', // celeste 500
  '#D97706', // amber 600
  '#F97316', // naranja 500
  '#0D9488', // teal 600
];

/// Pasteles/soft para fondos de bloques (secciones/subsecciones/header)
const List<String> kPastels = <String>[
  '#F5F9FF', // azul muy suave
  '#ECFEFF', // cian muy suave
  '#F0FDF4', // verde muy suave
  '#FFF7ED', // naranja crema
  '#FDF2F8', // rosa claro
  '#EEF2FF', // violeta muy suave
  '#FFFBEB', // amarillo muy suave
  '#F1F5F9', // gris azulado suave
  '#FAFAF5', // marfil
  '#FEF2F2', // rojo muy suave
];

/// Un mapa por categorías (útil si quieres tabs/filtros)
const Map<String, List<String>> kUnifiedPaletteByGroup = {
  'Neutros': kNeutrals,
  'Sólidos': kSolidStrong,
  'Pasteles': kPastels,
};

/// Flatten único, por si necesitas una lista completa sin duplicados
List<String> kAllSwatches() {
  final set = <String>{};
  for (final g in kUnifiedPaletteByGroup.values) {
    set.addAll(g);
  }
  return set.toList(growable: false);
}

/// =====================
/// Helpers de color
/// =====================

Color? parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  try {
    return Color(int.parse('0x$h'));
  } catch (_) {
    return null;
  }
}

/// =====================
/// Diálogo reutilizable
/// =====================

Future<String?> showColorSwatchPickerDialog({
  required BuildContext context,
  String title = 'Elige un color',
  String? initialHex,
  String? groupFilter,
}) async {
  final primary = Theme.of(context).colorScheme.primary;
  String? selected = initialHex;

  // set inicial (si filtras por grupo; si no, usa todos)
  List<String> current =
      (groupFilter != null && kUnifiedPaletteByGroup.containsKey(groupFilter))
      ? List<String>.from(kUnifiedPaletteByGroup[groupFilter]!)
      : kAllSwatches();

  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Align(
        alignment: Alignment.topCenter,
        child: Dialog(
          insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SafeArea(
            top: true,
            child: StatefulBuilder(
              builder: (ctx, setM) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 720,
                    maxHeight: 560,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título
                        Text(
                          title,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Filtros simples por grupo (opcional)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final entry in kUnifiedPaletteByGroup.entries)
                              ChoiceChip(
                                label: Text(entry.key),
                                selected: current == entry.value,
                                onSelected: (_) {
                                  setM(() {
                                    current = List<String>.from(entry.value);
                                  });
                                },
                              ),
                            ChoiceChip(
                              label: const Text('Todos'),
                              selected: current.length == kAllSwatches().length,
                              onSelected: (_) {
                                setM(() {
                                  current = kAllSwatches();
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Grid responsivo
                        Expanded(
                          child: LayoutBuilder(
                            builder: (ctx, cts) {
                              final w = cts.maxWidth;
                              final cross = w >= 640 ? 8 : (w >= 480 ? 6 : 4);
                              return GridView.builder(
                                itemCount: current.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cross,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1,
                                    ),
                                itemBuilder: (_, i) {
                                  final hex = current[i];
                                  final color = parseColor(hex) ?? Colors.white;
                                  final isSel =
                                      (selected?.toUpperCase() ==
                                      hex.toUpperCase());

                                  return InkWell(
                                    onTap: () => setM(() => selected = hex),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSel
                                              ? primary
                                              : Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                          width: isSel ? 2 : 1,
                                        ),
                                        color: color,
                                      ),
                                      child: Center(
                                        child: Text(
                                          hex.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _legibleOn(color),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Usar color'),
                              onPressed: selected == null
                                  ? null
                                  : () => Navigator.pop(ctx, selected),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

/// Escoge automáticamente un color de texto legible (blanco/negro) sobre un fondo dado
Color _legibleOn(Color bg) {
  // luminancia simple
  return bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
}
