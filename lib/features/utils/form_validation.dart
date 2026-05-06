import '../models/form_field_types.dart';
import '../models/form_template.dart';

/// Devuelve la lista de etiquetas de campos requeridos que
/// no están completos para un estudiante.
///
/// Solo considera secciones visibles (`section.visible == true`)
/// y omite campos de tipo `label`.
List<String> findMissingRequiredFields(
  FormTemplate template,
  Map<String, dynamic> values,
) {
  final missing = <String>[];

  for (final sec in template.sections.where((s) => s.visible)) {
    for (final sub in sec.children) {
      for (final f in sub.fields) {
        if (f.type == FormFieldType.label) continue;
        if (f.required == true) {
          final v = values[f.id];
          final ok = switch (f.type) {
            FormFieldType.shortText ||
            FormFieldType.longText =>
              (v is String && v.trim().isNotEmpty),
            FormFieldType.number =>
              (v is num) || (v is String && v.trim().isNotEmpty),
            FormFieldType.date =>
              (v is DateTime) ||
                  (v is String && DateTime.tryParse(v) != null),
            FormFieldType.select => (v is String && v.isNotEmpty),
            FormFieldType.multiSelect || FormFieldType.multiChoice =>
              (v is List && v.isNotEmpty),
            FormFieldType.singleChoice => (v is String && v.isNotEmpty),
            FormFieldType.trueFalse => (v is bool),
            FormFieldType.label => true,
          };
          if (!ok) missing.add(f.label);
        }
      }
    }
  }

  return missing;
}

