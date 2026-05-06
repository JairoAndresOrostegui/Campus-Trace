import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../models/form_template.dart';
import '../models/form_field_types.dart';
import '../services/form_template_service.dart';
import '../services/form_entry_service.dart';
import '../widgets/form_header.dart';
import '../widgets/student_actions_bar.dart';
import '../widgets/student_evaluation_panel.dart';
import 'form_fill_list_screen.dart';
import '../utils/field_delete.dart';
import 'form_responses_screen.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FormFillScreen extends StatefulWidget {
  final String? templateId;

  final bool reviewMode;
  final String? reviewStudentId;

  const FormFillScreen({
    super.key,
    this.templateId,
    this.reviewMode = false,
    this.reviewStudentId,
  });

  @override
  State<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  final _tmplSvc = FormTemplateService();
  final _entrySvc = FormEntryService();

  // Estado de la edición
  final Map<String, TextEditingController> _textCtrls = {};
  final Map<String, dynamic> _values = {};
  bool _sending = false;

  // Borrador
  bool _draftLoading = false;
  bool _draftLoadedOnce = false;
  bool _locked = false;

  // Comentarios por campo (docente)
  final Map<String, TextEditingController> _commentCtrls = {};

  // Evaluación (docente)
  String? _stage; // 'draft' | 'submitted' | 'reviewing' | 'graded'
  String? _feedback; // retroalimentación global
  double? _grade; // calificación

  // Controllers para feedback/calificación (evita perder valores al reentrar)
  final _feedbackCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.templateId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDraftOnce();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    for (final c in _commentCtrls.values) {
      c.dispose();
    }
    _feedbackCtrl.dispose();
    _gradeCtrl.dispose();
    super.dispose();
  }

  // ========= Borrador: cargar/guardar =========

  Future<void> _loadDraftOnce() async {
    if (_draftLoadedOnce) return;

    final currentUid = context.read<UserProvider>().user!.id;
    final targetUid = widget.reviewMode
        ? (widget.reviewStudentId ?? '')
        : currentUid;

    setState(() => _draftLoading = true);
    try {
      final draft = await _entrySvc.getDraft(
        userId: targetUid,
        templateId: widget.templateId!,
      );
      if (!mounted) return;

      _values.clear();
      if (draft.answers != null) _values.addAll(draft.answers!);

      // Rehidratar comentarios en controladores
      if (draft.comments != null) {
        draft.comments!.forEach((fid, txt) {
          _commentCtrls[fid] = TextEditingController(
            text: txt?.toString() ?? '',
          );
          _values['__comment__$fid'] = txt?.toString() ?? '';
        });
      }

      _feedback = draft.feedback;
      _grade = draft.grade;
      _stage = draft.stage;
      _locked = draft.locked == true;

      // Rellenar controllers de evaluación
      _feedbackCtrl.text = _feedback ?? '';
      _gradeCtrl.text = (_grade != null) ? _grade!.toString() : '';

      _draftLoadedOnce = true;

      setState(() {}); // rehacer UI
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _draftLoading = false);
    }
  }

  Future<void> _saveAllDraftNow(FormTemplate template) async {
    final uid = context.read<UserProvider>().user!.id;

    // Normaliza fechas a ISO para almacenar
    final toSave = <String, dynamic>{};
    _values.forEach((k, v) {
      if (v is DateTime) {
        toSave[k] = v.toIso8601String();
      } else {
        toSave[k] = v;
      }
    });

    // Confirmación
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Guardar progreso'),
        content: const Text('¿Deseas guardar tu progreso hasta ahora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _entrySvc.saveDraftFull(
        userId: uid,
        templateId: template.id,
        answers: toSave,
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Progreso guardado')),
      );
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  // Guardar un único campo (trigger en blur o cambio) — SOLO estudiante
  Future<void> _saveOneField({
    required String fieldId,
    required dynamic value,
  }) async {
    if (_locked || widget.templateId == null) return;
    if (widget.reviewMode) return; // el docente NO autoguarda campos del alumno
    final uid = context.read<UserProvider>().user!.id;

    // Fechas a ISO; para números vacíos/strings vacíos, eliminamos el campo
    dynamic finalVal = value;
    if (value is DateTime) finalVal = value.toIso8601String();

    final shouldDelete =
        (finalVal == null) ||
        (finalVal is String && finalVal.trim().isEmpty) ||
        (finalVal is List && finalVal.isEmpty);

    await _entrySvc.updateDraftField(
      userId: uid,
      templateId: widget.templateId!,
      fieldId: fieldId,
      value: shouldDelete ? FieldDelete.token : finalVal,
    );
  }

  // ========= Guardado docente (comentarios + feedback + calificación) =========
  Future<void> _saveReviewAll() async {
    if (!widget.reviewMode || widget.templateId == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final teacherId = context.read<UserProvider>().user!.id;
    final studentId = widget.reviewStudentId!;
    final templateId = widget.templateId!;

    // Construir lote de futuros: comentarios por campo + feedback/grade.
    final futures = <Future<void>>[];

    // 1) comentarios por campo (vacío => borrar la clave)
    _commentCtrls.forEach((fid, ctrl) {
      final txt = ctrl.text.trim();
      futures.add(
        _entrySvc.updateCommentField(
          studentId: studentId,
          templateId: templateId,
          fieldId: fid,
          comment: txt.isEmpty ? null : txt,
          teacherId: teacherId,
        ),
      );
    });

    // 2) feedback y calificación
    final fb = _feedbackCtrl.text.trim();
    final gr = num.tryParse(_gradeCtrl.text.trim())?.toDouble();

    futures.add(
      _entrySvc.saveFeedbackAndGrade(
        studentId: studentId,
        templateId: templateId,
        feedback: fb.isEmpty ? null : fb,
        grade: gr,
        teacherId: teacherId,
      ),
    );

    try {
      await Future.wait(futures);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Revisión guardada')),
      );
      // Refrescar cache local (para que se vea en el bloque del estudiante si corresponde)
      setState(() {
        _feedback = fb.isEmpty ? null : fb;
        _grade = gr;
        _stage = (gr != null) ? 'graded' : 'reviewing';
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    }
  }

  // ========= Envío final (estudiante) =========
  Future<void> _submit({required FormTemplate template}) async {
    if (_locked) return;

    // Validación
    final missing = <String>[];
    for (final sec in _sectionsToShow(template)) {
      for (final sub in sec.children) {
        for (final f in sub.fields) {
          if (f.type == FormFieldType.label) continue;
          if (f.required == true) {
            final v = _values[f.id];
            final ok = switch (f.type) {
              FormFieldType.shortText ||
              FormFieldType.longText => (v is String && v.trim().isNotEmpty),
              FormFieldType.number =>
                (v is num) || (v is String && v.trim().isNotEmpty),
              FormFieldType.date =>
                (v is DateTime) ||
                    (v is String && DateTime.tryParse(v) != null),
              FormFieldType.select => (v is String && v.isNotEmpty),
              FormFieldType.multiSelect ||
              FormFieldType.multiChoice => (v is List && v.isNotEmpty),
              FormFieldType.singleChoice => (v is String && v.isNotEmpty),
              FormFieldType.trueFalse => (v is bool),
              FormFieldType.label => true,
            };
            if (!ok) missing.add(f.label);
          }
        }
      }
    }

    if (missing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completa los campos requeridos: ${missing.join(', ')}',
          ),
        ),
      );
      return;
    }

    // Normaliza fechas a ISO
    final answers = <String, dynamic>{};
    _values.forEach((k, v) {
      if (v is DateTime) {
        answers[k] = v.toIso8601String();
      } else {
        answers[k] = v;
      }
    });

    setState(() => _sending = true);
    try {
      final uid = context.read<UserProvider>().user!.id;
      await _entrySvc.submitEntry(
        userId: uid,
        templateId: template.id,
        answers: answers,
      );
      await _entrySvc.setDraftLocked(
        userId: uid,
        templateId: template.id,
        locked: true,
      );

      if (!mounted) return;

      _locked = true;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('¡Envío registrado!')),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ========= Helpers =========

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _asDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Iterable<Section> _sectionsToShow(FormTemplate t) {
    return widget.reviewMode ? t.sections : t.sections.where((s) => s.visible);
  }

  // Rehidrata controladores de texto si hay valores en _values.
  void _hydrateTextControllerIfNeeded(String fieldId, dynamic raw) {
    final c = _textCtrls[fieldId];
    if (c == null) return;
    if (raw is String) {
      if (c.text.isEmpty) c.text = raw;
    } else if (raw is num) {
      if (c.text.isEmpty) c.text = raw.toString();
    }
  }

  // ========= UI Campos =========
  Widget _buildField(
    FormFieldType t,
    String fieldId,
    String label,
    FieldProps p, {
    required bool enabled,
  }) {
    final current = _values[fieldId];

    switch (t) {
      case FormFieldType.shortText:
        _textCtrls[fieldId] ??= TextEditingController();
        _hydrateTextControllerIfNeeded(fieldId, current);
        final w = Focus(
          onFocusChange: (has) async {
            if (!has) {
              _values[fieldId] = _textCtrls[fieldId]!.text;
              await _saveOneField(fieldId: fieldId, value: _values[fieldId]);
            }
          },
          child: TextFormField(
            controller: _textCtrls[fieldId],
            enabled: enabled,
            decoration: InputDecoration(
              labelText: label,
              hintText: p.placeholder,
              border: const OutlineInputBorder(),
            ),
            maxLines: 1,
            onChanged: (v) => _values[fieldId] = v,
            onEditingComplete: () async {
              _values[fieldId] = _textCtrls[fieldId]!.text;
              await _saveOneField(fieldId: fieldId, value: _values[fieldId]);
            },
          ),
        );
        return _withTeacherComment(t, fieldId, w, label);

      case FormFieldType.longText:
        _textCtrls[fieldId] ??= TextEditingController();
        _hydrateTextControllerIfNeeded(fieldId, current);
        final w2 = Focus(
          onFocusChange: (has) async {
            if (!has) {
              _values[fieldId] = _textCtrls[fieldId]!.text;
              await _saveOneField(fieldId: fieldId, value: _values[fieldId]);
            }
          },
          child: TextFormField(
            controller: _textCtrls[fieldId],
            enabled: enabled,
            decoration: InputDecoration(
              labelText: label,
              hintText: p.placeholder,
              border: const OutlineInputBorder(),
            ),
            maxLines: null,
            minLines: 3,
            onChanged: (v) => _values[fieldId] = v,
            onEditingComplete: () async {
              _values[fieldId] = _textCtrls[fieldId]!.text;
              await _saveOneField(fieldId: fieldId, value: _values[fieldId]);
            },
          ),
        );
        return _withTeacherComment(t, fieldId, w2, label);

      case FormFieldType.number:
        _textCtrls[fieldId] ??= TextEditingController();
        _hydrateTextControllerIfNeeded(fieldId, current);
        final w3 = Focus(
          onFocusChange: (has) async {
            if (!has) {
              final raw = _textCtrls[fieldId]!.text.trim();
              final n = num.tryParse(raw);
              _values[fieldId] = raw.isEmpty ? null : (n ?? raw);
              await _saveOneField(fieldId: fieldId, value: _values[fieldId]);
            }
          },
          child: TextFormField(
            controller: _textCtrls[fieldId],
            enabled: enabled,
            decoration: InputDecoration(
              labelText: label,
              hintText: p.placeholder,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = num.tryParse(v.trim());
              _values[fieldId] = (v.trim().isEmpty) ? null : (n ?? v.trim());
            },
            onEditingComplete: () async {
              final raw = _textCtrls[fieldId]!.text.trim();
              final n = num.tryParse(raw);
              _values[fieldId] = raw.isEmpty ? null : (n ?? raw);
              await _saveOneField(fieldId: fieldId, value: _values[fieldId]);
            },
          ),
        );
        return _withTeacherComment(t, fieldId, w3, label);

      case FormFieldType.date:
        final dt = _asDate(current);
        final dateText = (dt != null)
            ? _fmtDate(dt)
            : (p.placeholder ?? 'Seleccionar fecha');
        final w4 = InkWell(
          onTap: enabled
              ? () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dt ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 5),
                    helpText: label,
                  );
                  if (picked != null) {
                    setState(() => _values[fieldId] = picked);
                    await _saveOneField(fieldId: fieldId, value: picked);
                  }
                }
              : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18),
                const SizedBox(width: 8),
                Text(dateText),
              ],
            ),
          ),
        );
        return _withTeacherComment(t, fieldId, w4, label);

      case FormFieldType.select:
        final opts = p.options ?? const <String>[];
        final sel = (current is String) ? current : null;
        final w5 = DropdownButtonFormField<String>(
          initialValue: sel,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: opts
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: enabled
              ? (v) async {
                  setState(() => _values[fieldId] = v);
                  await _saveOneField(fieldId: fieldId, value: v);
                }
              : null,
        );
        return _withTeacherComment(t, fieldId, w5, label);

      case FormFieldType.multiSelect:
      case FormFieldType.multiChoice:
        final opts = p.options ?? const <String>[];
        final sel = ((current is List ? current.cast<String>() : <String>[])
            .toSet());
        final w6 = InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: opts.map((o) {
              final checked = sel.contains(o);
              return CheckboxListTile(
                value: checked,
                onChanged: enabled
                    ? (v) async {
                        setState(() {
                          if (v == true) {
                            sel.add(o);
                          } else {
                            sel.remove(o);
                          }
                          _values[fieldId] = sel.toList();
                        });
                        await _saveOneField(
                          fieldId: fieldId,
                          value: _values[fieldId],
                        );
                      }
                    : null,
                title: Text(o),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        );
        return _withTeacherComment(t, fieldId, w6, label);

      case FormFieldType.singleChoice:
        final opts = p.options ?? const <String>[];
        final sel = (current is String) ? current : null;
        final w7 = InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: opts.map((o) {
              final checked = sel == o;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                onTap: enabled
                    ? () async {
                        setState(() => _values[fieldId] = o);
                        await _saveOneField(fieldId: fieldId, value: o);
                      }
                    : null,
                leading: Icon(
                  checked ? Icons.radio_button_checked : Icons.radio_button_off,
                ),
                title: Text(o),
              );
            }).toList(),
          ),
        );
        return _withTeacherComment(t, fieldId, w7, label);

      case FormFieldType.trueFalse:
        final v = (current is bool) ? current : false;
        final w8 = Row(
          children: [
            Switch(
              value: v,
              onChanged: enabled
                  ? (val) async {
                      setState(() => _values[fieldId] = val);
                      await _saveOneField(fieldId: fieldId, value: val);
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        );
        return _withTeacherComment(t, fieldId, w8, label);

      case FormFieldType.label:
        // Mostrar etiqueta tal cual
        return Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
    }
  }
  /// Envuelve cada campo con el área de comentario del docente.
  /// En modo docente (`reviewMode = true`) el comentario es editable.
  /// En modo estudiante se muestra solo en lectura si existe.
  Widget _withTeacherComment(
    FormFieldType t,
    String fieldId,
    Widget fieldWidget,
    String label,
  ) {
    if (t == FormFieldType.label) {
      return fieldWidget;
    }

    final commentKey = '__comment__$fieldId';
    final existing = (_values[commentKey] ?? '').toString();

    if (widget.reviewMode) {
      final ctrl = _commentCtrls.putIfAbsent(
        fieldId,
        () => TextEditingController(text: existing),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldWidget,
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Comentario del docente',
              border: OutlineInputBorder(),
            ),
            maxLines: null,
            onChanged: (v) => _values[commentKey] = v,
            // NO autoguardamos; lo hace el botón "Guardar revisión"
          ),
        ],
      );
    }

    // Modo estudiante: solo mostrar si hay comentario
    if (existing.trim().isEmpty) {
      return fieldWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldWidget,
        const SizedBox(height: 6),
        Text(
          existing,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.black.withValues(alpha: .7),
          ),
        ),
      ],
    );
  }

  // ========= Exportar a PDF =========
  Future<void> _exportPdf(FormTemplate t) async {
    // 1) Cargar fuentes desde assets (no dependen de red)
    final fReg = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
    );
    final fBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
    );
    final fIt = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Italic.ttf'),
    );
    final fBI = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-BoldItalic.ttf'),
    );

    // 2) Documento con tema global (¡evita que algún Text quede sin fuente!)
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fReg,
        bold: fBold,
        italic: fIt,
        boldItalic: fBI,
      ),
    );

    if (!mounted) return;

    // === trae borrador/valores como ya lo haces ===
    final currentUid = context.read<UserProvider>().user!.id;
    final targetUid = widget.reviewMode
        ? (widget.reviewStudentId ?? currentUid)
        : currentUid;
    final draft = await _entrySvc.getDraft(userId: targetUid, templateId: t.id);

    String _fmtDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String _fmt(dynamic v, FormFieldType type) {
      if (v == null) return '—';
      switch (type) {
        case FormFieldType.date:
          final dt = (v is DateTime) ? v : DateTime.tryParse(v.toString());
          return (dt == null) ? v.toString() : _fmtDate(dt);
        case FormFieldType.trueFalse:
          if (v is bool) return v ? 'Sí' : 'No';
          return v.toString();
        case FormFieldType.multiChoice:
        case FormFieldType.multiSelect:
          if (v is List) return v.join(', ');
          return v.toString();
        default:
          return v.toString();
      }
    }

    pw.Widget _kv(String k, String v) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$k: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.TextSpan(text: v, style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );

    // 3) Construir contenido
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Header
          widgets.add(
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  t.header.title,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: t.header.titleFontSize.toDouble(),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((t.header.subtitle ?? '').trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text(
                      t.header.subtitle!,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: t.header.subtitleFontSize.toDouble(),
                      ),
                    ),
                  ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Template: ${t.id}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Usuario: $targetUid',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
              ],
            ),
          );

          // Solo secciones visibles para alumno; todas para docente
          final pdfSections = widget.reviewMode
              ? t.sections
              : t.sections.where((s) => s.visible);
          for (final sec in pdfSections) {
            widgets.add(pw.SizedBox(height: 12));
            if (sec.title.trim().isNotEmpty) {
              widgets.add(
                pw.Text(
                  sec.title,
                  style: pw.TextStyle(
                    fontSize: (sec.titleFontSize ?? 16).toDouble(),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              );
              widgets.add(pw.SizedBox(height: 6));
            }

            if (sec.children.isEmpty) {
              widgets.add(
                pw.Text(
                  'Sin subsecciones',
                  style: const pw.TextStyle(fontSize: 11),
                ),
              );
              continue;
            }

            for (final sub in sec.children) {
              widgets.add(pw.SizedBox(height: 6));
              if (sub.title.trim().isNotEmpty) {
                widgets.add(
                  pw.Text(
                    sub.title,
                    style: pw.TextStyle(
                      fontSize: (sub.titleFontSize ?? 14).toDouble(),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
                widgets.add(pw.SizedBox(height: 4));
              }

              if (sub.fields.isEmpty) {
                widgets.add(
                  pw.Text(
                    'Sin campos',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                );
                continue;
              }

              for (final f in sub.fields) {
                if (f.type == FormFieldType.label) {
                  widgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        f.label,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                  continue;
                }

                final ans = draft.answers?[f.id];
                widgets.add(_kv(f.label, _fmt(ans, f.type)));

                final com = draft.comments?[f.id];
                if (com != null && com.toString().trim().isNotEmpty) {
                  widgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text(
                        'Comentario del docente: ${com.toString()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          }

          // Bloque evaluación global
          if ((draft.feedback != null && draft.feedback!.trim().isNotEmpty) ||
              draft.grade != null) {
            widgets.add(pw.SizedBox(height: 12));
            widgets.add(pw.Divider());
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.Text(
                'Evaluación',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));
            if (draft.feedback != null && draft.feedback!.trim().isNotEmpty) {
              widgets.add(_kv('Retroalimentación', draft.feedback!.trim()));
            }
            if (draft.grade != null) {
              widgets.add(_kv('Calificación', draft.grade!.toString()));
            }
          }

          return widgets;
        },
      ),
    );

    // 4) Intentar imprimir; si el popup lo bloquea, ofrecer descarga
    try {
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e, st) {
      // Fallback: descarga el PDF
      // (en web abre el diálogo de descarga)
      // También verás el error real en la consola.
      // ignore: avoid_print
      print('Printing/layoutPdf error: $e\n$st');
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'formulario-${t.id}.pdf',
      );
    }
  }

  // ========= UI: lista / llenado =========

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final uid = context.read<UserProvider>().user!.id;

    // ===== Modo LISTA =====
    if (widget.templateId == null) {
      return FormFillListScreen(uid: uid);
    }

    // ===== Modo LLENADO / REVISIÓN =====
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.reviewMode ? 'Revisión del envío' : 'Llenar formulario',
        ),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!widget.reviewMode) ...[
            IconButton(
              tooltip: 'Refrescar',
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                setState(() {
                  _draftLoadedOnce = false;
                  _draftLoading = true;
                });
                await _loadDraftOnce();
              },
            ),
            IconButton(
              tooltip: 'Mis envíos',
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FormResponsesScreen(
                      templateId: widget.templateId!,
                      userId: uid,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<FormTemplate>(
          stream: _tmplSvc.watchTemplate(widget.templateId!),
          builder: (context, snap) {
            if (!snap.hasData || _draftLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final t = snap.data!;
            final enabled = !_locked && !widget.reviewMode;
            final showEvalToStudent =
                !widget.reviewMode &&
                (_stage == 'graded' ||
                    _grade != null ||
                    ((_feedback ?? '').trim().isNotEmpty));

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header
                    FormHeader(template: t),
                    const SizedBox(height: 16),

                    if (t.sections.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primary.withValues(alpha: .12),
                          ),
                        ),
                        child: Text(
                          'Este formulario aún no tiene secciones.',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: .7),
                          ),
                        ),
                      )
                    else
                      ..._sectionsToShow(t).map((sec) {
                        final secBg = parseColorSafe(sec.bgColorHex);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: primary.withValues(alpha: .12),
                            ),
                            color: secBg ?? Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (sec.title.trim().isNotEmpty) ...[
                                  Align(
                                    alignment: switch (sec.titleAlign) {
                                      'center' => Alignment.center,
                                      'right' => Alignment.centerRight,
                                      _ => Alignment.centerLeft,
                                    },
                                    child: Text(
                                      sec.title,
                                      textAlign: switch (sec.titleAlign) {
                                        'center' => TextAlign.center,
                                        'right' => TextAlign.right,
                                        _ => TextAlign.left,
                                      },
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: sec.titleFontSize ?? 16,
                                        color: (sec.titleColorHex != null)
                                            ? (parseColorSafe(
                                                    sec.titleColorHex,
                                                  ) ??
                                                  Colors.black87)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (sec.children.isEmpty)
                                  Text(
                                    'Sin subsecciones',
                                    style: TextStyle(
                                      color: Colors.black.withValues(alpha: .6),
                                    ),
                                  )
                                else
                                  ...sec.children.map((sub) {
                                    final subBg = parseColorSafe(
                                      sub.bgColorHex,
                                    );
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primary.withValues(alpha: .10),
                                        ),
                                        color: subBg ?? Colors.white,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (sub.title.trim().isNotEmpty) ...[
                                            Align(
                                              alignment: switch (sub
                                                  .titleAlign) {
                                                'center' => Alignment.center,
                                                'right' =>
                                                  Alignment.centerRight,
                                                _ => Alignment.centerLeft,
                                              },
                                              child: Text(
                                                sub.title,
                                                textAlign: switch (sub
                                                    .titleAlign) {
                                                  'center' => TextAlign.center,
                                                  'right' => TextAlign.right,
                                                  _ => TextAlign.left,
                                                },
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize:
                                                      sub.titleFontSize ?? 14,
                                                  color:
                                                      (sub.titleColorHex !=
                                                          null)
                                                      ? (parseColorSafe(
                                                              sub.titleColorHex,
                                                            ) ??
                                                            Colors.black87)
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                          ],
                                          if (sub.fields.isEmpty)
                                            Text(
                                              'Sin campos',
                                              style: TextStyle(
                                                color: Colors.black.withValues(
                                                  alpha: .6,
                                                ),
                                              ),
                                            )
                                          else
                                            ...sub.fields.map((f) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: _buildField(
                                                  f.type,
                                                  f.id,
                                                  f.label,
                                                  f.props,
                                                  enabled:
                                                      enabled &&
                                                      f.type !=
                                                          FormFieldType.label,
                                                ),
                                              );
                                            }),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        );
                      }),

                    // ====== BLOQUE DOCENTE: Retroalimentación + Calificación (editable) ======
                    if (widget.reviewMode) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: .12),
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
                              controller: _feedbackCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Escribe tu retroalimentación…',
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
                              controller: _gradeCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                                    onPressed: () => _exportPdf(t),
                                  ),
                                  FilledButton.icon(
                                    icon: const Icon(Icons.save),
                                    label: const Text('Guardar revisión'),
                                    onPressed: _saveReviewAll,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                                        // ====== BLOQUE ESTUDIANTE: ver feedback/nota cuando está disponible ======
                    if (showEvalToStudent) ...[ 
                      const SizedBox(height: 12),
                      StudentEvaluationPanel(
                        feedback: _feedback,
                        grade: _grade,
                        primaryColor: primary,
                      ),
                    ],
const SizedBox(height: 8),

                    // Barra de acciones (solo estudiante)
                    if (!widget.reviewMode)
                      StudentActionsBar(
                        sending: _sending,
                        locked: _locked,
                        onExportPdf: () => _exportPdf(t),
                        onSaveDraft: () => _saveAllDraftNow(t),
                        onSubmit: () => _submit(template: t),
                      ),
                  ],
                ),
                if (!widget.reviewMode)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: 'saveDraftTop',
                      onPressed: _locked ? null : () => _saveAllDraftNow(t),
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar progreso'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}


