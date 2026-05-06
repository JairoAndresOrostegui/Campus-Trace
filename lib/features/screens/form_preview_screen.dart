import 'package:flutter/material.dart';

import '../../utils/color_utils.dart' as colorx;
import '../models/form_template.dart';
import '../models/form_field_types.dart';
import '../services/form_template_service.dart';

// === helpers de alineación (preview) ===
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

Alignment _boxAlign(TextAlign a) {
  switch (a) {
    case TextAlign.center:
      return Alignment.center;
    case TextAlign.right:
      return Alignment.centerRight;
    default:
      return Alignment.centerLeft;
  }
}

class FormPreviewScreen extends StatelessWidget {
  final String templateId;
  const FormPreviewScreen({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final svc = FormTemplateService();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Previsualización (estudiante)'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: StreamBuilder<FormTemplate>(
          stream: svc.watchTemplate(templateId),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final t = snap.data!;
            final header = t.header;

            final bg =
                colorx.parseColor(header.bgColorHex) ??
                Theme.of(context).colorScheme.surface;
            final titleColor =
                colorx.parseColor(header.titleColorHex) ??
                Theme.of(context).colorScheme.primary;
            final subColor =
                colorx.parseColor(header.subtitleColorHex) ??
                Theme.of(context).colorScheme.secondary;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Encabezado: sólo lectura
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: .12)),
                    color: bg,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        header.title.isEmpty ? 'Sin título' : header.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: header.titleFontSize,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      if ((header.subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          header.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: header.subtitleFontSize,
                            color: subColor,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        runAlignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(
                            context,
                            'Código',
                            t.code.isEmpty ? '—' : t.code,
                          ),
                          _chip(
                            context,
                            'Grupo',
                            t.groupName.isEmpty ? '—' : t.groupName,
                          ),
                          _chip(
                            context,
                            'Inicio',
                            header.formStart == null
                                ? '—'
                                : _fmtDate(header.formStart!),
                          ),
                          _chip(
                            context,
                            'Fin',
                            header.formEnd == null
                                ? '—'
                                : _fmtDate(header.formEnd!),
                          ),
                          _chip(context, 'Estado', t.status.toUpperCase()),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Secciones + subsecciones + campos (solo lectura)
                if (t.sections.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withValues(alpha: .12)),
                    ),
                    child: Text(
                      'Este formulario aún no tiene secciones.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: .7),
                      ),
                    ),
                  )
                else
                  ...t.sections.map((sec) {
                    final secBg = colorx.parseColor(sec.bgColorHex);

                    // Estilo del título de sección
                    final secTitleAlign = _alignFromStr(sec.titleAlign);
                    final secTitleColor =
                        colorx.parseColor(sec.titleColorHex) ?? Colors.black87;
                    final secTitleSize = sec.titleFontSize ?? 16.0;

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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Título de la sección (sin ícono)
                            Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: _boxAlign(secTitleAlign),
                                    child: Text(
                                      sec.title.isEmpty ? 'Sección' : sec.title,
                                      textAlign: secTitleAlign,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: secTitleSize,
                                        color: secTitleColor,
                                      ),
                                    ),
                                  ),
                                ),
                                if (sec.dueDate != null) ...[
                                  const SizedBox(width: 8),
                                  _chip(
                                    context,
                                    'Entrega',
                                    _fmtDate(sec.dueDate!),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),

                            // subsecciones
                            if (sec.children.isEmpty)
                              Text(
                                'Sin subsecciones',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: .6),
                                ),
                              )
                            else
                              ...sec.children.map((sub) {
                                final subBg = colorx.parseColor(sub.bgColorHex);

                                // Estilo del título de subsección
                                final subTitleAlign = _alignFromStr(
                                  sub.titleAlign,
                                );
                                final subTitleColor =
                                    colorx.parseColor(sub.titleColorHex) ??
                                    Colors.black87;
                                final subTitleSize = sub.titleFontSize ?? 14.0;

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
                                        // Título de la subsección (sin ícono)
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Align(
                                                alignment: _boxAlign(
                                                  subTitleAlign,
                                                ),
                                                child: Text(
                                                  sub.title,
                                                  textAlign: subTitleAlign,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: subTitleSize,
                                                    color: subTitleColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
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
                                        ...sub.fields.map(
                                          (f) => _readonlyField(context, f),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========== Helpers UI (solo lectura) ===========

  static String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _chip(BuildContext context, String label, String value) {
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

  Widget _readonlyField(BuildContext context, FieldDef f) {
    switch (f.type) {
      case FormFieldType.shortText:
        return _pad(
          TextFormField(
            enabled: false,
            decoration: InputDecoration(
              labelText: f.label,
              hintText: f.props.placeholder,
              floatingLabelBehavior: FloatingLabelBehavior.always, // 👈
              border: const OutlineInputBorder(),
            ),
            maxLines: 1,
          ),
        );

      case FormFieldType.longText:
        return _pad(
          TextFormField(
            enabled: false,
            decoration: InputDecoration(
              labelText: f.label,
              hintText: f.props.placeholder,
              floatingLabelBehavior: FloatingLabelBehavior.always, // 👈
              border: const OutlineInputBorder(),
            ),
            maxLines: null,
            minLines: 3,
          ),
        );

      case FormFieldType.number:
        return _pad(
          TextFormField(
            enabled: false,
            decoration: InputDecoration(
              labelText: f.label,
              hintText: f.props.placeholder,
              floatingLabelBehavior: FloatingLabelBehavior.always, // 👈
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        );

      case FormFieldType.date:
        return _pad(
          InputDecorator(
            decoration: InputDecoration(
              labelText: f.label,
              border: const OutlineInputBorder(),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18),
                const SizedBox(width: 8),
                Text(f.props.placeholder ?? 'Seleccionar fecha'),
              ],
            ),
          ),
        );

      case FormFieldType.select:
        // select de UNA opción (deshabilitado en preview)
        return _pad(
          DropdownButtonFormField<String>(
            initialValue: null,
            onChanged: null,
            hint: Text(f.props.placeholder ?? 'Selecciona…'), // 👈
            decoration: InputDecoration(
              labelText: f.label,
              border: const OutlineInputBorder(),
            ),
            items: (f.props.options ?? const [])
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
          ),
        );

      case FormFieldType.multiSelect:
      case FormFieldType.multiChoice:
        // usa la misma UI de checkboxes (preview)
        return _pad(_choiceGroup(context, f, multiple: true));

      case FormFieldType.singleChoice:
        // usa UI de "radio" no interactiva
        return _pad(_choiceGroup(context, f, multiple: false));

      case FormFieldType.trueFalse:
        return _pad(
          Row(
            children: [
              Switch(value: false, onChanged: null),
              const SizedBox(width: 8),
              Text(f.label),
            ],
          ),
        );

      case FormFieldType.label:
        return _pad(
          Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        );
    }
  }

  Widget _choiceGroup(
    BuildContext context,
    FieldDef f, {
    required bool multiple,
  }) {
    final opts = f.props.options ?? const <String>[];
    if (opts.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: f.label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          'Sin opciones',
          style: TextStyle(color: Colors.black.withValues(alpha: .6)),
        ),
      );
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: f.label,
        border: const OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: opts.map((o) {
          if (multiple) {
            return CheckboxListTile(
              title: Text(o),
              value: false,
              onChanged: null,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            );
          } else {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.radio_button_off),
              title: Text(o),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _pad(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);
}
