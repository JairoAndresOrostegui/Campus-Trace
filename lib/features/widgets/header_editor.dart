import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../utils/color_utils.dart' as colorx;
import '../../utils/color_palette_utils.dart' as pal;

import '../models/form_template.dart';
import '../services/form_template_service.dart';

class HeaderEditor extends StatefulWidget {
  final String templateId;
  final FormTemplate template;

  const HeaderEditor({
    super.key,
    required this.templateId,
    required this.template,
  });

  @override
  State<HeaderEditor> createState() => _HeaderEditorState();
}

class _HeaderEditorState extends State<HeaderEditor> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _groupCtrl = TextEditingController();
  final _titleColorCtrl = TextEditingController();
  final _subtitleColorCtrl = TextEditingController();
  final _bgColorCtrl = TextEditingController();
  double _titleSize = 22;
  double _subtitleSize = 16;
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  late final FormTemplateService _svc;

  @override
  void initState() {
    super.initState();
    _svc = FormTemplateService();
    _hydrate();
  }

  void _hydrate() {
    final h = widget.template.header;
    _titleCtrl.text = h.title;
    _subtitleCtrl.text = h.subtitle ?? '';
    _groupCtrl.text = widget.template.groupName;
    _titleColorCtrl.text = h.titleColorHex ?? '#0B4BB3';
    _subtitleColorCtrl.text = h.subtitleColorHex ?? '#243B68';
    _bgColorCtrl.text = h.bgColorHex ?? '#F5F9FF';
    _titleSize = h.titleFontSize;
    _subtitleSize = h.subtitleFontSize;
    _start = h.formStart;
    _end = h.formEnd;
  }

  @override
  void didUpdateWidget(covariant HeaderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.template.id != widget.template.id ||
        oldWidget.template.updatedAt != widget.template.updatedAt) {
      _hydrate();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _groupCtrl.dispose();
    _titleColorCtrl.dispose();
    _subtitleColorCtrl.dispose();
    _bgColorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _start ?? now;
    final initialEnd = _end ?? now.add(const Duration(days: 7));

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Rango de fechas del formulario',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: Theme.of(ctx).colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _start = DateTime(range.start.year, range.start.month, range.start.day);
        _end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
      });
    }
  }

  Future<void> _save() async {
    // Validaciones antes de cualquier await
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El título es obligatorio')));
      return;
    }
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona fechas de inicio y fin')),
      );
      return;
    }
    if (_end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha fin debe ser posterior al inicio'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final header = widget.template.header.copyWith(
        title: title,
        subtitle: _subtitleCtrl.text.trim().isEmpty
            ? null
            : _subtitleCtrl.text.trim(),
        titleColorHex: _titleColorCtrl.text.trim().isEmpty
            ? null
            : _titleColorCtrl.text.trim(),
        subtitleColorHex: _subtitleColorCtrl.text.trim().isEmpty
            ? null
            : _subtitleColorCtrl.text.trim(),
        titleFontSize: _titleSize,
        subtitleFontSize: _subtitleSize,
        formStart: _start,
        formEnd: _end,
        bgColorHex: _bgColorCtrl.text.trim().isEmpty
            ? null
            : _bgColorCtrl.text.trim(),
      );
      await _svc.updateHeader(
        widget.templateId,
        header,
        groupName: _groupCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Encabezado guardado')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseColor({
    required String titleText,
    required String currentHex,
    required List<String> swatches,
    required void Function(String hex) onPicked,
  }) async {
    final primary = Theme.of(context).colorScheme.primary;
    String selected = currentHex;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topCenter,
          child: Dialog(
            insetPadding: const EdgeInsets.fromLTRB(16, 86, 16, 16),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (ctx, setMState) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          titleText,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Chips de la paleta recibida
                        Wrap(
                          alignment: WrapAlignment.center,
                          runAlignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: swatches.map((hex) {
                            final color =
                                colorx.parseColor(hex) ?? Colors.white;
                            final isSel =
                                selected.toUpperCase() == hex.toUpperCase();
                            return GestureDetector(
                              onTap: () => setMState(() => selected = hex),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel
                                        ? primary
                                        : Colors.black.withValues(alpha: .15),
                                    width: isSel ? 2.2 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: selected,
                                decoration: const InputDecoration(
                                  labelText: 'HEX personalizado (ej. #0B4BB3)',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) => selected = v.trim(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                onPicked(selected);
                              },
                              child: const Text('Usar'),
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

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().user!;
    final role = (user.role).toLowerCase();
    final isDocente =
        role == 'docente' || role == 'administrador' || role == 'superadmin';

    final bg =
        colorx.parseColor(_bgColorCtrl.text.trim()) ??
        Theme.of(context).colorScheme.surface;
    final titleColor =
        colorx.parseColor(_titleColorCtrl.text.trim()) ??
        Theme.of(context).colorScheme.primary;
    final subColor =
        colorx.parseColor(_subtitleColorCtrl.text.trim()) ??
        Theme.of(context).colorScheme.secondary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        ),
        color: bg,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Vista
          Text(
            _titleCtrl.text.isEmpty ? 'Sin título' : _titleCtrl.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _titleSize,
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          if (_subtitleCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _subtitleCtrl.text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: _subtitleSize, color: subColor),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(
                'Código',
                widget.template.code.isEmpty ? '—' : widget.template.code,
              ),
              _chip(
                'Grupo',
                widget.template.groupName.isEmpty
                    ? '—'
                    : widget.template.groupName,
              ),
              _chip('Inicio', _start == null ? '—' : _fmtDate(_start!)),
              _chip('Fin', _end == null ? '—' : _fmtDate(_end!)),
              _chip('Estado', widget.template.status.toUpperCase()),
            ],
          ),
          if (isDocente) ...[
            const Divider(height: 24),
            // Controles
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subtítulo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _groupCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de grupo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Colores con paleta
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _colorBox(titleColor),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _titleColorCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Color título (#HEX)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.palette),
                      label: const Text('Elegir color'),
                      onPressed: () async {
                        final picked = await pal.showColorSwatchPickerDialog(
                          context: context,
                          title: 'Color para el título',
                          initialHex: _titleColorCtrl.text.trim().isEmpty
                              ? '#000000'
                              : _titleColorCtrl.text.trim(),
                        );
                        if (picked != null && mounted) {
                          setState(() => _titleColorCtrl.text = picked);
                        }
                      },
                    ),
                  ],
                ),

                _colorRow(
                  labelHex: 'Color subtítulo (#HEX)',
                  preview: subColor,
                  controller: _subtitleColorCtrl,
                  onPick: () => _chooseColor(
                    titleText: 'Color del subtítulo',
                    currentHex: _subtitleColorCtrl.text.trim().isEmpty
                        ? '#243B68'
                        : _subtitleColorCtrl.text.trim(),
                    swatches: pal.kSolidStrong,
                    onPicked: (hex) {
                      final h = hex.startsWith('#')
                          ? hex.toUpperCase()
                          : '#${hex.toUpperCase()}';
                      setState(() => _subtitleColorCtrl.text = h);
                    },
                  ),
                ),
                _colorRow(
                  labelHex: 'Fondo header (#HEX)',
                  preview: bg,
                  controller: _bgColorCtrl,
                  onPick: () => _chooseColor(
                    titleText: 'Color de fondo del encabezado',
                    currentHex: _bgColorCtrl.text.trim().isEmpty
                        ? '#F5F9FF'
                        : _bgColorCtrl.text.trim(),
                    swatches: pal.kPastels,
                    onPicked: (hex) {
                      final h = hex.startsWith('#')
                          ? hex.toUpperCase()
                          : '#${hex.toUpperCase()}';
                      setState(() => _bgColorCtrl.text = h);
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Tamaño título'),
                      Slider(
                        min: 14,
                        max: 32,
                        divisions: 18,
                        value: _titleSize,
                        label: _titleSize.toStringAsFixed(0),
                        onChanged: (v) => setState(() => _titleSize = v),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Tamaño subtítulo'),
                      Slider(
                        min: 10,
                        max: 28,
                        divisions: 18,
                        value: _subtitleSize,
                        label: _subtitleSize.toStringAsFixed(0),
                        onChanged: (v) => setState(() => _subtitleSize = v),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.event),
                  label: const Text('Rango de fechas'),
                ),

                // ❌ Eliminado: botón "Generar código & grupo"
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save),
                  label: _saving
                      ? const Text('Guardando...')
                      : const Text('Guardar encabezado'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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

  Widget _colorRow({
    required String labelHex,
    required Color preview,
    required TextEditingController controller,
    required VoidCallback onPick,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _colorBox(preview),
        const SizedBox(width: 8),
        SizedBox(
          width: 170,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: labelHex,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.palette),
          label: const Text('Colores'),
        ),
      ],
    );
  }

  Widget _colorBox(Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: .1)),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
