import 'package:cloud_firestore/cloud_firestore.dart';

class FormEntry {
  final String id;
  final String templateId;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic> answers;
  final Map<String, dynamic>? comments;
  final String? feedback;
  final double? grade;
  final String? stage;
  final DateTime? gradedAt;
  final String? gradedBy;

  FormEntry({
    required this.id,
    required this.templateId,
    required this.userId,
    required this.createdAt,
    required this.answers,
    this.comments,
    this.feedback,
    this.grade,
    this.stage,
    this.gradedAt,
    this.gradedBy,
  });

  /// Combina el mapa `answers` (si existe) con las claves planas
  /// `answers.<campo>` de un documento de Firestore.
  ///
  /// En el esquema actual solo se usan las claves planas, pero
  /// dejamos este helper para centralizar la lógica de lectura.
  static Map<String, dynamic> mergeAnswersFromData(
    Map<String, dynamic> data,
  ) {
    final answers = <String, dynamic>{};

    final rawAnswers = data['answers'];
    if (rawAnswers is Map) {
      answers.addAll(Map<String, dynamic>.from(rawAnswers));
    }

    data.forEach((key, value) {
      if (key.startsWith('answers.')) {
        final fieldId = key.substring('answers.'.length);
        answers[fieldId] = value;
      }
    });

    return answers;
  }

  Map<String, Object?> toMap() {
    return {
      'templateId': templateId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      if (comments != null) 'comments': comments,
      if (feedback != null) 'feedback': feedback,
      if (grade != null) 'grade': grade,
      if (stage != null) 'stage': stage,
      if (gradedAt != null) 'gradedAt': Timestamp.fromDate(gradedAt!),
      if (gradedBy != null) 'gradedBy': gradedBy,
    };
  }

  static FormEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return fromData(id: doc.id, data: doc.data()!);
  }

  static FormEntry fromData({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final d = data;
    final answers = mergeAnswersFromData(d);
    final rawCom = d['comments'];
    return FormEntry(
      id: id,
      templateId: d['templateId'] as String,
      userId: d['userId'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      answers: answers,
      comments: (rawCom is Map) ? Map<String, dynamic>.from(rawCom) : null,
      feedback: d['feedback'] as String?,
      grade: (d['grade'] is num) ? (d['grade'] as num).toDouble() : null,
      stage: d['stage'] as String?,
      gradedAt: (d['gradedAt'] is Timestamp)
          ? (d['gradedAt'] as Timestamp).toDate()
          : null,
      gradedBy: d['gradedBy'] as String?,
    );
  }
}
