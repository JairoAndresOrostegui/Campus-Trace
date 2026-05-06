import 'package:flutter/material.dart';

import '../../utils/color_palette_utils.dart' as pal;
import '../models/form_template.dart';
import '../models/form_field_types.dart';
import '../services/form_template_service.dart';

TextAlign _alignFromStr(String? s) {
  switch (s) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    default:
      return TextAlign.left;
  }
}

String _alignToStr(TextAlign a) {
  switch (a) {
    case TextAlign.center:
      return 'center';
    case TextAlign.right:
      return 'right';
    default:
      return 'left';
  }
}

class SectionsEditor extends StatefulWidget {
  final String templateId;
  final List<Section> sections;

  const SectionsEditor({
    super.key,
    required this.templateId,
    required this.sections,
  });

  @override
  State<SectionsEditor> createState() => _SectionsEditorState();
}

class _SectionsEditorState extends State<SectionsEditor> {
  final _svc = FormTemplateService();

  late List<Section> _sections;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sections = List<Section>.from(widget.sections);
  }

  @override
  void didUpdateWidget(covariant SectionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections != widget.sections) {
      _sections = List<Section>.from(widget.sections);
    }
  }

  Future<void> _persist() async {
    setState(() => _saving = true);
    try {
      await _svc.updateSections(widget.templateId, _sections);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ===== helpers UI =====

  Future<DateTime?> _pickDate({DateTime? initial, String? help}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: help,
    );
    return picked;
  }

  Widget _chip(String label, String value) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withValues(alpha: .20)),
        color: c.withValues(alpha: .06),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: TextStyle(color: c, fontWeight: FontWeight.w700),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                color: Colors.black.withValues(alpha: .85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ===== diálogos =====

  Future<void> _addOrEditSection({Section? existing}) async {
    final primary = Theme.of(context).colorScheme.primary;
    final titleCtl = TextEditingController(text: existing?.title ?? '');
    DateTime? due = existing?.dueDate;
    String? hex = existing?.bgColorHex ?? pal.kPastels.first;
    TextAlign align = _alignFromStr(existing?.titleAlign);
    double titleSize = existing?.titleFontSize ?? 16.0;
    String? titleHex = existing?.titleColorHex;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topCenter,
          child: Dialog(
            insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (ctx, setM) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          existing == null
                              ? 'Agregar sección'
                              : 'Editar sección',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleCtl,
                          decoration: const InputDecoration(
                            labelText: 'Título de la sección',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        // ========== NUEVOS CONTROLES DE TÍTULO ==========
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Alineación
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _alignToStr(align),
                                decoration: const InputDecoration(
                                  labelText: 'Alineación del título',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'left',
                                    child: Text('Izquierda'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'center',
                                    child: Text('Centrado'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'right',
                                    child: Text('Derecha'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setM(() => align = _alignFromStr(v));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Color
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                        pal.parseColor(titleHex) ??
                                        Colors.black,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.black.withValues(alpha: .1),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.palette),
                                  label: const Text('Color título'),
                                  onPressed: () async {
                                    final picked = await pal
                                        .showColorSwatchPickerDialog(
                                          context: context,
                                          title: 'Color del título (Sección)',
                                          initialHex: titleHex ?? '#000000',
                                          groupFilter: 'Sólidos',
                                        );
                                    if (picked != null) {
                                      setM(() => titleHex = picked);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Tamaño
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tamaño del título'),
                            Slider(
                              min: 12,
                              max: 28,
                              divisions: 16,
                              value: titleSize,
                              label: titleSize.toStringAsFixed(0),
                              onChanged: (v) => setM(() => titleSize = v),
                            ),
                          ],
                        ),

                        // ===============================================
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.event_available),
                                label: Text(
                                  'Fecha de entrega: ${due == null ? "—" : _fmtDate(due!)}',
                                ),
                                onPressed: () async {
                                  final picked = await _pickDate(
                                    initial: due,
                                    help: 'Fecha de entrega (sección)',
                                  );
                                  if (picked != null) setM(() => due = picked);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Color de fondo',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: pal.kPastels.map((h) {
                            final isSel = h == hex;
                            return GestureDetector(
                              onTap: () => setM(() => hex = h),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: pal.parseColor(h) ?? Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSel
                                        ? primary
                                        : Colors.black.withValues(alpha: .15),
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              icon: const Icon(Icons.check),
                              label: Text(
                                existing == null ? 'Agregar' : 'Guardar',
                              ),
                              onPressed: () {
                                final title = titleCtl.text.trim();
                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('El título es obligatorio'),
                                    ),
                                  );
                                  return;
                                }
                                if (existing == null) {
                                  final s = Section(
                                    id: _svc.newLocalId(),
                                    title: title,
                                    bgColorHex: hex,
                                    dueDate: due,
                                    children: const [],
                                    titleAlign: _alignToStr(align),
                                    titleColorHex: titleHex,
                                    titleFontSize: titleSize,
                                    visible: true, // 👈 nuevo
                                  );
                                  setState(() => _sections.add(s));
                                } else {
                                  final i = _sections.indexWhere(
                                    (x) => x.id == existing.id,
                                  );
                                  if (i >= 0) {
                                    _sections[i] = Section(
                                      id: existing.id,
                                      title: title,
                                      bgColorHex: hex,
                                      dueDate: due,
                                      children: existing.children,
                                      titleAlign: _alignToStr(align),
                                      titleColorHex: titleHex,
                                      titleFontSize: titleSize,
                                      visible: existing.visible, // 👈 conservar
                                    );
                                    setState(() {});
                                  }
                                }
                                Navigator.pop(ctx);
                                _persist();
                              },
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
        );
      },
    );
  }

  Future<void> _addOrEditSubsection({
    required Section parent,
    Subsection? existing,
  }) async {
    final primary = Theme.of(context).colorScheme.primary;
    final titleCtl = TextEditingController(text: existing?.title ?? '');
    String? hex = existing?.bgColorHex ?? pal.kPastels.elementAt(1);
    TextAlign align = _alignFromStr(existing?.titleAlign);
    double titleSize = existing?.titleFontSize ?? 14.0;
    String? titleHex = existing?.titleColorHex;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Dialog(
          insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        existing == null
                            ? 'Agregar subsección'
                            : 'Editar subsección',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtl,
                        decoration: const InputDecoration(
                          labelText: 'Título de la subsección',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _alignToStr(align),
                              decoration: const InputDecoration(
                                labelText: 'Alineación del título',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'left',
                                  child: Text('Izquierda'),
                                ),
                                DropdownMenuItem(
                                  value: 'center',
                                  child: Text('Centrado'),
                                ),
                                DropdownMenuItem(
                                  value: 'right',
                                  child: Text('Derecha'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setM(() => align = _alignFromStr(v));
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color:
                                      pal.parseColor(titleHex) ?? Colors.black,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: .1),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.palette),
                                label: const Text('Color título'),
                                onPressed: () async {
                                  final picked = await pal
                                      .showColorSwatchPickerDialog(
                                        context: context,
                                        title: 'Color del título (Subsección)',
                                        initialHex: titleHex ?? '#000000',
                                        groupFilter: 'Sólidos',
                                      );
                                  if (picked != null) {
                                    setM(() => titleHex = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tamaño del título'),
                          Slider(
                            min: 12,
                            max: 24,
                            divisions: 12,
                            value: titleSize,
                            label: titleSize.toStringAsFixed(0),
                            onChanged: (v) => setM(() => titleSize = v),
                          ),
                        ],
                      ),

                      // =======================
                      const SizedBox(height: 12),
                      const Text(
                        'Color de fondo',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: pal.kPastels.map((h) {
                          final isSel = h == hex;
                          return GestureDetector(
                            onTap: () => setM(() => hex = h),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: pal.parseColor(h) ?? Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSel
                                      ? primary
                                      : Colors.black.withValues(alpha: .15),
                                  width: isSel ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancelar'),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: Text(
                              existing == null ? 'Agregar' : 'Guardar',
                            ),
                            onPressed: () {
                              final title = titleCtl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('El título es obligatorio'),
                                  ),
                                );
                                return;
                              }

                              final si = _sections.indexWhere(
                                (x) => x.id == parent.id,
                              );
                              if (si < 0) return;

                              final current = _sections[si];
                              final children = List<Subsection>.from(
                                current.children,
                              );

                              if (existing == null) {
                                children.add(
                                  Subsection(
                                    id: _svc.newLocalId(),
                                    title: title,
                                    bgColorHex: hex,
                                    fields: const [],
                                    titleAlign: _alignToStr(align),
                                    titleColorHex: titleHex,
                                    titleFontSize: titleSize,
                                  ),
                                );
                              } else {
                                final sxi = children.indexWhere(
                                  (c) => c.id == existing.id,
                                );
                                if (sxi >= 0) {
                                  children[sxi] = Subsection(
                                    id: existing.id,
                                    title: title,
                                    bgColorHex: hex,
                                    fields: existing.fields,
                                    titleAlign: _alignToStr(align),
                                    titleColorHex: titleHex,
                                    titleFontSize: titleSize,
                                  );
                                }
                              }

                              _sections[si] = Section(
                                id: current.id,
                                title: current.title,
                                bgColorHex: current.bgColorHex,
                                dueDate: current.dueDate,
                                children: children,
                                titleAlign: current.titleAlign,
                                titleColorHex: current.titleColorHex,
                                titleFontSize: current.titleFontSize,
                                visible: current.visible,
                              );

                              setState(() {});
                              Navigator.pop(ctx);
                              _persist();
                            },
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
  }

  Future<void> _addOrEditField({
    required Section parent,
    required Subsection sub,
    FieldDef? existing,
  }) async {
    final primary = Theme.of(context).colorScheme.primary;

    final labelCtl = TextEditingController(text: existing?.label ?? '');
    final placeholderCtl = TextEditingController(
      text: existing?.props.placeholder ?? '',
    );
    final minCtl = TextEditingController(
      text: existing?.props.min?.toString() ?? '',
    );
    final maxCtl = TextEditingController(
      text: existing?.props.max?.toString() ?? '',
    );
    final optionsCtl = TextEditingController(
      text: (existing?.props.options ?? const <String>[]).join('\n'),
    );
    bool isRequired = existing?.required ?? false;
    FormFieldType type = existing?.type ?? FormFieldType.shortText;

    bool isSelecty(FormFieldType t) =>
        t == FormFieldType.select ||
        t == FormFieldType.multiSelect ||
        t == FormFieldType.singleChoice ||
        t == FormFieldType.multiChoice;

    bool hasMinMax(FormFieldType t) => t == FormFieldType.number;
    bool hasPlaceholder(FormFieldType t) =>
        t == FormFieldType.shortText ||
        t == FormFieldType.longText ||
        t == FormFieldType.number ||
        t == FormFieldType.date;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Align(
        alignment: Alignment.topCenter,
        child: Dialog(
          insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: StatefulBuilder(
            builder: (ctx, setM) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          existing == null ? 'Agregar campo' : 'Editar campo',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: labelCtl,
                          decoration: const InputDecoration(
                            labelText: 'Etiqueta',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<FormFieldType>(
                          initialValue: type,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de campo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: FormFieldType.shortText,
                              child: Text('Texto corto'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.longText,
                              child: Text('Texto largo'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.number,
                              child: Text('Número'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.date,
                              child: Text('Fecha'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.select,
                              child: Text('Desplegable (una opción)'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.multiSelect,
                              child: Text('Desplegable múltiple'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.singleChoice,
                              child: Text('Opción única (radio)'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.multiChoice,
                              child: Text('Selección múltiple (checklist)'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.trueFalse,
                              child: Text('Verdadero/Falso'),
                            ),
                            DropdownMenuItem(
                              value: FormFieldType.label,
                              child: Text('Etiqueta (solo texto)'),
                            ),
                          ],
                          onChanged: (v) => setM(() => type = v ?? type),
                        ),
                        const SizedBox(height: 12),

                        if (hasPlaceholder(type)) ...[
                          TextField(
                            controller: placeholderCtl,
                            decoration: const InputDecoration(
                              labelText: 'Placeholder (opcional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (hasMinMax(type)) ...[
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: minCtl,
                                  decoration: const InputDecoration(
                                    labelText: 'Mínimo (opcional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: maxCtl,
                                  decoration: const InputDecoration(
                                    labelText: 'Máximo (opcional)',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (isSelecty(type)) ...[
                          TextField(
                            controller: optionsCtl,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: 'Opciones (una por línea)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (type != FormFieldType.label)
                          SwitchListTile(
                            title: const Text('Obligatorio'),
                            value: isRequired,
                            onChanged: (v) => setM(() => isRequired = v),
                            contentPadding: EdgeInsets.zero,
                          ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              icon: const Icon(Icons.check),
                              label: Text(
                                existing == null ? 'Agregar' : 'Guardar',
                              ),
                              onPressed: () {
                                final label = labelCtl.text.trim();
                                if (label.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La etiqueta es obligatoria',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final si = _sections.indexWhere(
                                  (x) => x.id == parent.id,
                                );
                                if (si < 0) return;
                                final currentSec = _sections[si];

                                final sxi = currentSec.children.indexWhere(
                                  (c) => c.id == sub.id,
                                );
                                if (sxi < 0) return;
                                final currentSub = currentSec.children[sxi];

                                final fields = List<FieldDef>.from(
                                  currentSub.fields,
                                );

                                List<String>? opts;
                                if (isSelecty(type)) {
                                  final raw = optionsCtl.text
                                      .split('\n')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                                  opts = raw.isEmpty ? null : raw;
                                }

                                num? nmin = num.tryParse(minCtl.text.trim());
                                num? nmax = num.tryParse(maxCtl.text.trim());

                                final props = FieldProps(
                                  placeholder:
                                      placeholderCtl.text.trim().isEmpty
                                      ? null
                                      : placeholderCtl.text.trim(),
                                  min: nmin,
                                  max: nmax,
                                  options: opts,
                                );

                                if (existing == null) {
                                  fields.add(
                                    FieldDef(
                                      id: _svc.newLocalId(),
                                      type: type,
                                      label: label,
                                      required: (type == FormFieldType.label)
                                          ? false
                                          : isRequired,
                                      props: props,
                                    ),
                                  );
                                } else {
                                  final fi = fields.indexWhere(
                                    (f) => f.id == existing.id,
                                  );
                                  if (fi >= 0) {
                                    fields[fi] = FieldDef(
                                      id: existing.id,
                                      type: type,
                                      label: label,
                                      required: (type == FormFieldType.label)
                                          ? false
                                          : isRequired,
                                      props: props,
                                    );
                                  }
                                }

                                final newSub = Subsection(
                                  id: currentSub.id,
                                  title: currentSub.title,
                                  bgColorHex: currentSub.bgColorHex,
                                  fields: fields,
                                  titleAlign: currentSub.titleAlign,
                                  titleColorHex: currentSub.titleColorHex,
                                  titleFontSize: currentSub.titleFontSize,
                                );

                                final newChildren = List<Subsection>.from(
                                  currentSec.children,
                                );
                                newChildren[sxi] = newSub;

                                _sections[si] = Section(
                                  id: currentSec.id,
                                  title: currentSec.title,
                                  bgColorHex: currentSec.bgColorHex,
                                  dueDate: currentSec.dueDate,
                                  children: newChildren,
                                  titleAlign: currentSec.titleAlign,
                                  titleColorHex: currentSec.titleColorHex,
                                  titleFontSize: currentSec.titleFontSize,
                                  visible: currentSec.visible,
                                );

                                setState(() {});
                                Navigator.pop(ctx);
                                _persist();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ===== UI cards =====

  Widget _sectionCard(Section s) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = pal.parseColor(s.bgColorHex) ?? Colors.white;

    final tAlign = _alignFromStr(s.titleAlign);
    final tColor = pal.parseColor(s.titleColorHex) ?? Colors.black87;
    final tSize = s.titleFontSize ?? 16.0;

    Alignment _a(TextAlign a) {
      switch (a) {
        case TextAlign.center:
          return Alignment.center;
        case TextAlign.right:
          return Alignment.centerRight;
        default:
          return Alignment.centerLeft;
      }
    }

    return Opacity(
      opacity: s.visible ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: .12)),
          color: bg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: _a(tAlign),
                      child: Text(
                        s.title.isEmpty ? 'Sección' : s.title,
                        textAlign: tAlign,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: tSize,
                          color: tColor,
                        ),
                      ),
                    ),
                  ),
                  if (s.dueDate != null) ...[
                    const SizedBox(width: 8),
                    _chip('Entrega', _fmtDate(s.dueDate!)),
                  ],
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: s.visible ? 'Ocultar sección' : 'Mostrar sección',
                    icon: Icon(
                      s.visible ? Icons.visibility : Icons.visibility_off,
                      color: s.visible ? null : Colors.grey,
                    ),
                    onPressed: () {
                      final i = _sections.indexWhere((x) => x.id == s.id);
                      if (i < 0) return;

                      _sections[i] = _sections[i].copyWith(
                        visible: !(_sections[i].visible),
                      );
                      setState(() {});
                      _persist();
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Agregar subsección',
                    icon: const Icon(Icons.add),
                    onPressed: () => _addOrEditSubsection(parent: s),
                  ),
                  IconButton(
                    tooltip: 'Editar sección',
                    icon: const Icon(Icons.edit),
                    onPressed: () => _addOrEditSection(existing: s),
                  ),
                  IconButton(
                    tooltip: 'Eliminar sección',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar sección'),
                          content: const Text(
                            '¿Deseas eliminar esta sección y todo su contenido?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true) {
                        setState(
                          () => _sections.removeWhere((x) => x.id == s.id),
                        );
                        _persist();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (s.children.isEmpty)
                Text(
                  'Sin subsecciones',
                  style: TextStyle(color: Colors.black.withValues(alpha: .6)),
                )
              else
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;

                    // localizar sección
                    final si = _sections.indexWhere((x) => x.id == s.id);
                    if (si < 0) return;
                    final sec = _sections[si];

                    // reordenar subsecciones en una copia
                    final list = List<Subsection>.from(sec.children);
                    final moved = list.removeAt(oldIndex);
                    list.insert(newIndex, moved);

                    // guardar nueva lista
                    _sections[si] = Section(
                      id: sec.id,
                      title: sec.title,
                      bgColorHex: sec.bgColorHex,
                      dueDate: sec.dueDate,
                      children: list,
                      titleAlign: sec.titleAlign,
                      titleColorHex: sec.titleColorHex,
                      titleFontSize: sec.titleFontSize,
                      visible: sec.visible,
                    );

                    setState(() {});
                    _persist();
                  },
                  children: [
                    for (int i = 0; i < s.children.length; i++)
                      KeyedSubtree(
                        key: ValueKey(s.children[i].id),
                        child: _subsectionCard(s, s.children[i], dragIndex: i),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subsectionCard(Section parent, Subsection sub, {int? dragIndex}) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = pal.parseColor(sub.bgColorHex) ?? Colors.white;

    final tAlign = _alignFromStr(sub.titleAlign);
    final tColor = pal.parseColor(sub.titleColorHex) ?? Colors.black87;
    final tSize = sub.titleFontSize ?? 14.0;

    Alignment _a(TextAlign a) {
      switch (a) {
        case TextAlign.center:
          return Alignment.center;
        case TextAlign.right:
          return Alignment.centerRight;
        default:
          return Alignment.centerLeft;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: .10)),
        color: bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dragIndex != null) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ReorderableDragStartListener(
                    index: dragIndex,
                    child: const Icon(Icons.drag_indicator),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Align(
                  alignment: _a(tAlign),
                  child: Text(
                    sub.title.trim().isNotEmpty ? sub.title : 'Subsección',
                    textAlign: tAlign,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: tSize,
                      color: tColor,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Agregar campo',
                icon: const Icon(Icons.add),
                onPressed: () => _addOrEditField(parent: parent, sub: sub),
              ),
              IconButton(
                tooltip: 'Editar subsección',
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    _addOrEditSubsection(parent: parent, existing: sub),
              ),
              IconButton(
                tooltip: 'Eliminar subsección',
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar subsección'),
                      content: const Text(
                        '¿Eliminar esta subsección y sus campos?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final si = _sections.indexWhere((x) => x.id == parent.id);
                    if (si < 0) return;
                    final sec = _sections[si];
                    final children = List<Subsection>.from(sec.children)
                      ..removeWhere((c) => c.id == sub.id);

                    _sections[si] = Section(
                      id: sec.id,
                      title: sec.title,
                      bgColorHex: sec.bgColorHex,
                      dueDate: sec.dueDate,
                      children: children,
                      titleAlign: sec.titleAlign,
                      titleColorHex: sec.titleColorHex,
                      titleFontSize: sec.titleFontSize,
                      visible: sec.visible,
                    );
                    setState(() {});
                    _persist();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (sub.fields.isEmpty)
            Text(
              'Sin campos',
              style: TextStyle(color: Colors.black.withValues(alpha: .6)),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;

                // localizar sección y subsección vigentes
                final si = _sections.indexWhere((x) => x.id == parent.id);
                if (si < 0) return;
                final sec = _sections[si];

                final sxi = sec.children.indexWhere((c) => c.id == sub.id);
                if (sxi < 0) return;
                final subc = sec.children[sxi];

                // reordenar campos en una copia
                final fields = List<FieldDef>.from(subc.fields);
                final moved = fields.removeAt(oldIndex);
                fields.insert(newIndex, moved);

                // reconstruir la subsección con el nuevo orden
                final newSub = Subsection(
                  id: subc.id,
                  title: subc.title,
                  bgColorHex: subc.bgColorHex,
                  fields: fields,

                  // conservar estilo de la subsección
                  titleAlign: subc.titleAlign,
                  titleColorHex: subc.titleColorHex,
                  titleFontSize: subc.titleFontSize,
                );

                // actualizar children de la sección
                final newChildren = List<Subsection>.from(sec.children);
                newChildren[sxi] = newSub;

                // guardar en _sections y persistir
                _sections[si] = Section(
                  id: sec.id,
                  title: sec.title,
                  bgColorHex: sec.bgColorHex,
                  dueDate: sec.dueDate,
                  children: newChildren,

                  // conservar estilo de la sección
                  titleAlign: sec.titleAlign,
                  titleColorHex: sec.titleColorHex,
                  titleFontSize: sec.titleFontSize,
                  visible: sec.visible,
                );

                setState(() {});
                _persist();
              },
              children: [
                for (int i = 0; i < sub.fields.length; i++)
                  Container(
                    key: ValueKey(sub.fields[i].id),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primary.withValues(alpha: .08)),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        // ASA DE ARRASTRE
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ReorderableDragStartListener(
                            index: i,
                            child: const Icon(Icons.drag_indicator),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Icon(
                          _iconForType(sub.fields[i].type),
                          color: primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            '${sub.fields[i].label}  •  ${_labelForType(sub.fields[i].type)}${sub.fields[i].required ? "  (obligatorio)" : ""}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        IconButton(
                          tooltip: 'Editar campo',
                          icon: const Icon(Icons.edit),
                          onPressed: () => _addOrEditField(
                            parent: parent,
                            sub: sub,
                            existing: sub.fields[i],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Eliminar campo',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final f = sub.fields[i];
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar campo'),
                                content: const Text(
                                  '¿Deseas eliminar este campo?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              final si = _sections.indexWhere(
                                (x) => x.id == parent.id,
                              );
                              if (si < 0) return;
                              final sec = _sections[si];
                              final sxi = sec.children.indexWhere(
                                (c) => c.id == sub.id,
                              );
                              if (sxi < 0) return;

                              final subc = sec.children[sxi];
                              final fields = List<FieldDef>.from(subc.fields)
                                ..removeWhere((x) => x.id == f.id);

                              final newSub = Subsection(
                                id: subc.id,
                                title: subc.title,
                                bgColorHex: subc.bgColorHex,
                                fields: fields,
                                titleAlign: subc.titleAlign,
                                titleColorHex: subc.titleColorHex,
                                titleFontSize: subc.titleFontSize,
                              );

                              final newChildren = List<Subsection>.from(
                                sec.children,
                              );
                              newChildren[sxi] = newSub;

                              _sections[si] = Section(
                                id: sec.id,
                                title: sec.title,
                                bgColorHex: sec.bgColorHex,
                                dueDate: sec.dueDate,
                                children: newChildren,
                                titleAlign: sec.titleAlign,
                                titleColorHex: sec.titleColorHex,
                                titleFontSize: sec.titleFontSize,
                                visible: sec.visible,
                              );

                              setState(() {});
                              _persist();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  IconData _iconForType(FormFieldType t) {
    switch (t) {
      case FormFieldType.shortText:
        return Icons.short_text;
      case FormFieldType.longText:
        return Icons.notes;
      case FormFieldType.number:
        return Icons.pin;
      case FormFieldType.date:
        return Icons.event;
      case FormFieldType.select:
        return Icons.arrow_drop_down_circle_outlined;
      case FormFieldType.multiSelect:
        return Icons.list_alt;
      case FormFieldType.singleChoice:
        return Icons.radio_button_checked;
      case FormFieldType.multiChoice:
        return Icons.checklist;
      case FormFieldType.trueFalse:
        return Icons.toggle_on;
      case FormFieldType.label:
        return Icons.title;
    }
  }

  String _labelForType(FormFieldType t) {
    switch (t) {
      case FormFieldType.shortText:
        return 'Texto corto';
      case FormFieldType.longText:
        return 'Texto largo';
      case FormFieldType.number:
        return 'Número';
      case FormFieldType.date:
        return 'Fecha';
      case FormFieldType.select:
        return 'Desplegable';
      case FormFieldType.multiSelect:
        return 'Desplegable múltiple';
      case FormFieldType.singleChoice:
        return 'Opción única';
      case FormFieldType.multiChoice:
        return 'Selección múltiple';
      case FormFieldType.trueFalse:
        return 'Verdadero/Falso';
      case FormFieldType.label:
        return 'Etiqueta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withValues(alpha: .12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secciones',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              if (_sections.isEmpty)
                Text(
                  'Aún no hay secciones. Usa "Agregar sección".',
                  style: TextStyle(color: Colors.black.withValues(alpha: .7)),
                ),

              ..._sections.map(_sectionCard),

              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => _addOrEditSection(),
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar sección'),
                ),
              ),
            ],
          ),
        ),

        if (_saving)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withValues(alpha: .06),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: primary),
                      const SizedBox(height: 8),
                      const Text('Guardando...'),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
