import 'package:cloud_firestore/cloud_firestore.dart';

import 'form_field_types.dart';

class HeaderConfig {
  final String title;
  final String? subtitle;
  final String? titleColorHex;
  final String? subtitleColorHex;
  final double titleFontSize;
  final double subtitleFontSize;
  final DateTime? formStart;
  final DateTime? formEnd;
  final String? bgColorHex;

  const HeaderConfig({
    required this.title,
    this.subtitle,
    this.titleColorHex,
    this.subtitleColorHex,
    this.titleFontSize = 22,
    this.subtitleFontSize = 16,
    this.formStart,
    this.formEnd,
    this.bgColorHex,
  });

  HeaderConfig copyWith({
    String? title,
    String? subtitle,
    String? titleColorHex,
    String? subtitleColorHex,
    double? titleFontSize,
    double? subtitleFontSize,
    DateTime? formStart,
    DateTime? formEnd,
    String? bgColorHex,
  }) {
    return HeaderConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      titleColorHex: titleColorHex ?? this.titleColorHex,
      subtitleColorHex: subtitleColorHex ?? this.subtitleColorHex,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
      formStart: formStart ?? this.formStart,
      formEnd: formEnd ?? this.formEnd,
      bgColorHex: bgColorHex ?? this.bgColorHex,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (titleColorHex != null) 'titleColor': titleColorHex,
    if (subtitleColorHex != null) 'subtitleColor': subtitleColorHex,
    'titleFontSize': titleFontSize,
    'subtitleFontSize': subtitleFontSize,
    if (formStart != null) 'formStart': Timestamp.fromDate(formStart!),
    if (formEnd != null) 'formEnd': Timestamp.fromDate(formEnd!),
    if (bgColorHex != null) 'bgColor': bgColorHex,
  };

  static HeaderConfig fromMap(Map<String, dynamic> m) {
    return HeaderConfig(
      title: (m['title'] ?? '') as String,
      subtitle: m['subtitle'] as String?,
      titleColorHex: m['titleColor'] as String?,
      subtitleColorHex: m['subtitleColor'] as String?,
      titleFontSize: (m['titleFontSize'] ?? 22).toDouble(),
      subtitleFontSize: (m['subtitleFontSize'] ?? 16).toDouble(),
      formStart: (m['formStart'] is Timestamp)
          ? (m['formStart'] as Timestamp).toDate()
          : null,
      formEnd: (m['formEnd'] is Timestamp)
          ? (m['formEnd'] as Timestamp).toDate()
          : null,
      bgColorHex: m['bgColor'] as String?,
    );
  }
}

class FieldProps {
  final String? placeholder;
  final num? min;
  final num? max;
  final List<String>? options;

  const FieldProps({this.placeholder, this.min, this.max, this.options});

  Map<String, dynamic> toMap() => {
    if (placeholder != null) 'placeholder': placeholder,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (options != null) 'options': options,
  };

  static FieldProps fromMap(Map<String, dynamic>? m) {
    if (m == null) return const FieldProps();
    return FieldProps(
      placeholder: m['placeholder'] as String?,
      min: m['min'] as num?,
      max: m['max'] as num?,
      options: (m['options'] is List)
          ? (m['options'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }
}

class FieldDef {
  final String id;
  final FormFieldType type;
  final String label;
  final bool required;
  final FieldProps props;

  const FieldDef({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.props = const FieldProps(),
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': formFieldTypeToString(type),
    'label': label,
    'required': required,
    'props': props.toMap(),
  };

  static FieldDef fromMap(Map<String, dynamic> m) {
    return FieldDef(
      id: m['id'] as String,
      type: formFieldTypeFromString(m['type'] as String),
      label: (m['label'] ?? '') as String,
      required: (m['required'] ?? false) as bool,
      props: FieldProps.fromMap(m['props'] as Map<String, dynamic>?),
    );
  }
}

class Subsection {
  final String id;
  final String title;
  final String? bgColorHex;
  final List<FieldDef> fields;

  final String? titleAlign;
  final String? titleColorHex;
  final double? titleFontSize;

  Subsection({
    required this.id,
    required this.title,
    this.bgColorHex,
    required this.fields,
    this.titleAlign,
    this.titleColorHex,
    this.titleFontSize,
  });

  factory Subsection.fromMap(Map<String, dynamic> m) => Subsection(
    id: m['id'] as String,
    title: m['title'] as String? ?? '',
    bgColorHex: m['bgColorHex'] as String?,
    fields: (m['fields'] as List<dynamic>? ?? const [])
        .map((e) => FieldDef.fromMap(e as Map<String, dynamic>))
        .toList(),

    titleAlign: m['titleAlign'] as String?,
    titleColorHex: m['titleColorHex'] as String?,
    titleFontSize: (m['titleFontSize'] is num)
        ? (m['titleFontSize'] as num).toDouble()
        : (m['titleFontSize'] as double?),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    if (bgColorHex != null) 'bgColorHex': bgColorHex,
    'fields': fields.map((e) => e.toMap()).toList(),

    if (titleAlign != null) 'titleAlign': titleAlign,
    if (titleColorHex != null) 'titleColorHex': titleColorHex,
    if (titleFontSize != null) 'titleFontSize': titleFontSize,
  };
}

extension SectionCopy on Section {
  Section copyWith({
    String? id,
    String? title,
    String? bgColorHex,
    DateTime? dueDate,
    List<Subsection>? children,
    String? titleAlign,
    String? titleColorHex,
    double? titleFontSize,
    bool? visible,
  }) {
    return Section(
      id: id ?? this.id,
      title: title ?? this.title,
      bgColorHex: bgColorHex ?? this.bgColorHex,
      dueDate: dueDate ?? this.dueDate,
      children: children ?? this.children,
      titleAlign: titleAlign ?? this.titleAlign,
      titleColorHex: titleColorHex ?? this.titleColorHex,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      visible: visible ?? this.visible,
    );
  }
}

class Section {
  final String id;
  final String title;
  final String? bgColorHex;
  final DateTime? dueDate;
  final List<Subsection> children;

  final String? titleAlign;
  final String? titleColorHex;
  final double? titleFontSize;
  final bool visible;

  Section({
    required this.id,
    required this.title,
    this.bgColorHex,
    this.dueDate,
    required this.children,
    this.titleAlign,
    this.titleColorHex,
    this.titleFontSize,
    bool? visible,
  }) : visible = visible ?? true;

  factory Section.fromMap(Map<String, dynamic> m) => Section(
    id: m['id'] as String,
    title: m['title'] as String? ?? '',
    bgColorHex: m['bgColorHex'] as String?,
    dueDate: (m['dueDate'] is Timestamp)
        ? (m['dueDate'] as Timestamp).toDate()
        : (m['dueDate'] != null
              ? DateTime.tryParse(m['dueDate'].toString())
              : null),
    children: (m['children'] as List<dynamic>? ?? const [])
        .map((e) => Subsection.fromMap(e as Map<String, dynamic>))
        .toList(),

    titleAlign: m['titleAlign'] as String?,
    titleColorHex: m['titleColorHex'] as String?,
    titleFontSize: (m['titleFontSize'] is num)
        ? (m['titleFontSize'] as num).toDouble()
        : (m['titleFontSize'] as double?),
    visible: (m['visible'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    if (bgColorHex != null) 'bgColorHex': bgColorHex,
    if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
    'children': children.map((e) => e.toMap()).toList(),

    if (titleAlign != null) 'titleAlign': titleAlign,
    if (titleColorHex != null) 'titleColorHex': titleColorHex,
    if (titleFontSize != null) 'titleFontSize': titleFontSize,
    'visible': visible,
  };
}

class FormTemplate {
  final String id;
  final String code; // único visible
  final String groupName;
  final String status; // created|active|pending|delivered|graded|finalized
  final HeaderConfig header;
  final List<Section> sections;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FormTemplate({
    required this.id,
    required this.code,
    required this.groupName,
    required this.status,
    required this.header,
    required this.sections,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  FormTemplate copyWith({
    String? id,
    String? code,
    String? groupName,
    String? status,
    HeaderConfig? header,
    List<Section>? sections,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormTemplate(
      id: id ?? this.id,
      code: code ?? this.code,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      header: header ?? this.header,
      sections: sections ?? this.sections,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'groupName': groupName,
    'status': status,
    'header': header.toMap(),
    'sections': sections.map((s) => s.toMap()).toList(),
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static FormTemplate fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final Timestamp? createdTs = m['createdAt'] as Timestamp?;
    final Timestamp? updatedTs = m['updatedAt'] as Timestamp?;

    return FormTemplate(
      id: d.id,
      code: (m['code'] ?? '') as String,
      groupName: (m['groupName'] ?? '') as String,
      status: (m['status'] ?? 'created') as String,
      header: HeaderConfig.fromMap(m['header'] as Map<String, dynamic>),
      sections: (m['sections'] is List)
          ? (m['sections'] as List)
                .map((e) => Section.fromMap(e as Map<String, dynamic>))
                .toList()
          : [],
      createdBy: (m['createdBy'] ?? '') as String,
      createdAt: createdTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: updatedTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
