import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/form_entry.dart';
import '../models/form_template.dart';
import '../utils/field_delete.dart';

class DraftEntry {
  final Map<String, dynamic>? answers;
  final Map<String, dynamic>? comments;
  final bool? locked;
  final String? stage; // 'draft' | 'submitted' | 'reviewing' | 'graded'
  final String? feedback;
  final double? grade;

  DraftEntry({
    this.answers,
    this.comments,
    this.locked,
    this.stage,
    this.feedback,
    this.grade,
  });
}

class FormEntryService {
  final _db = FirebaseFirestore.instance;

  String _draftDocId(String userId, String templateId) =>
      '${userId}__$templateId';

  /// Normaliza un valor de borrador antes de guardarlo en Firestore.
  /// - `FieldDelete.token` => cadena vacía (campo limpiado por el estudiante)
  /// - `DateTime` => ISO8601
  /// - resto => tal cual
  static dynamic normalizeDraftFieldValue(dynamic value) {
    if (identical(value, FieldDelete.token)) {
      return '';
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  Future<DraftEntry> getDraft({
    required String userId,
    required String templateId,
  }) async {
    final doc = await _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(userId, templateId))
        .get();

    if (!doc.exists) {
      return DraftEntry(
        answers: {},
        comments: {},
        locked: false,
        stage: 'draft',
        feedback: null,
        grade: null,
      );
    }

    final data = doc.data()!;

    // answers: tomamos solo las claves planas "answers.campo"
    final answersMap = <String, dynamic>{};
    data.forEach((key, value) {
      if (key.startsWith('answers.')) {
        final fid = key.substring('answers.'.length);
        if (value is Timestamp) {
          answersMap[fid] = value.toDate().toIso8601String();
        } else {
          answersMap[fid] = value;
        }
      }
    });

    // comments
    Map<String, dynamic>? commentsMap;
    final rawCom = data['comments'];
    if (rawCom is Map) {
      commentsMap = Map<String, dynamic>.from(rawCom);
    } else {
      commentsMap = <String, dynamic>{};
    }

    final locked = (data['locked'] == true);
    final stage =
        (data['stage'] as String?) ?? (locked ? 'submitted' : 'draft');
    final feedback = data['feedback'] as String?;
    final grade =
        (data['grade'] is num) ? (data['grade'] as num).toDouble() : null;

    return DraftEntry(
      answers: answersMap,
      comments: commentsMap,
      locked: locked,
      stage: stage,
      feedback: feedback,
      grade: grade,
    );
  }

  Future<void> saveDraftFull({
    required String userId,
    required String templateId,
    required Map<String, dynamic> answers,
  }) async {
    final ref = _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(userId, templateId));

    final payload = <String, dynamic>{
      'userId': userId,
      'templateId': templateId,
      'locked': false,
      'updatedAt': FieldValue.serverTimestamp(),
      // limpiamos el mapa antiguo "answers" y usamos solo claves punteadas
      'answers': FieldValue.delete(),
    };

    answers.forEach((key, value) {
      final normalized = normalizeDraftFieldValue(value);
      payload['answers.$key'] = normalized;
    });

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> updateDraftField({
    required String userId,
    required String templateId,
    required String fieldId,
    required dynamic value,
  }) async {
    final docRef = _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(userId, templateId));

    final finalVal = normalizeDraftFieldValue(value);

    await docRef.set({
      'userId': userId,
      'templateId': templateId,
      'locked': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'answers.$fieldId': finalVal, // deep-merge por clave punteada
      'stage': 'draft',
    }, SetOptions(merge: true));
  }

  Future<void> enrollWithCode({
    required String userId,
    required String formCode,
  }) async {
    final q = await _db
        .collection('form_templates')
        .where('code', isEqualTo: formCode)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('No existe una plantilla con ese código.');
    }

    final tempDoc = q.docs.first;
    final templateId = tempDoc.id;

    final enrRef = _db
        .collection('users')
        .doc(userId)
        .collection('enrollments')
        .doc(templateId);

    await _db.runTransaction((tx) async {
      tx.set(enrRef, {
        'templateId': templateId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.update(tempDoc.reference, {
        'enrolledUserIds': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Stream<List<FormTemplate>> watchTemplatesForStudent(String userId) {
    return _db
        .collection('form_templates')
        .where('enrolledUserIds', arrayContains: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FormTemplate.fromDoc(d)).toList());
  }

  Future<String> submitEntry({
    required String userId,
    required String templateId,
    required Map<String, dynamic> answers,
  }) async {
    final ref = _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(userId, templateId));

    final now = DateTime.now();

    final payload = <String, dynamic>{
      'templateId': templateId,
      'userId': userId,
      'createdAt': Timestamp.fromDate(now),
      // solo usamos la representación con claves punteadas
      'answers': FieldValue.delete(),
      'stage': 'submitted',
      'locked': true,
      'lockedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    answers.forEach((key, value) {
      final normalized = normalizeDraftFieldValue(value);
      payload['answers.$key'] = normalized;
    });

    await ref.set(payload, SetOptions(merge: true));

    return ref.id;
  }

  Stream<List<FormEntry>> watchMyEntries({
    required String userId,
    String? templateId,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection('form_entries_drafts')
        .where('userId', isEqualTo: userId)
        .where('locked', isEqualTo: true);

    if (templateId != null) {
      q = q.where('templateId', isEqualTo: templateId);
    }

    return q.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) =>
                FormEntry.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>),
          )
          .toList(),
    );
  }

  Future<void> setDraftLocked({
    required String userId,
    required String templateId,
    required bool locked,
  }) async {
    await _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(userId, templateId))
        .set(
      {
        'locked': locked,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

class EnrollmentInfo {
  final String userId;
  final DateTime? enrolledAt;
  EnrollmentInfo({required this.userId, this.enrolledAt});
}

class UserBasic {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? modality;
  UserBasic({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.modality,
  });
}

extension TeacherQueries on FormEntryService {
  Stream<List<FormEntry>> streamEntriesForTemplate(String templateId) {
    return _db
        .collection('form_entries_drafts')
        .where('templateId', isEqualTo: templateId)
        .where('locked', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => FormEntry.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }

  Stream<List<EnrollmentInfo>> streamEnrollmentsForTemplate(String templateId) {
    return _db
        .collectionGroup('enrollments')
        .where('templateId', isEqualTo: templateId)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) {
            final parentUserId = d.reference.parent.parent?.id ?? '';
            final data = d.data();
            final ts = data['createdAt'];
            DateTime? at;
            if (ts is Timestamp) at = ts.toDate();
            return EnrollmentInfo(userId: parentUserId, enrolledAt: at);
          }).toList();
        });
  }

  Future<Map<String, UserBasic>> fetchUsersBasicByIds(List<String> ids) async {
    final Map<String, UserBasic> out = {};
    if (ids.isEmpty) return out;

    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final slice = ids.sublist(
        i,
        (i + chunkSize > ids.length) ? ids.length : i + chunkSize,
      );
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: slice)
          .get();

      for (final d in snap.docs) {
        final data = d.data();
        out[d.id] = UserBasic(
          id: d.id,
          firstName: (data['firstName'] ?? '') as String,
          lastName: (data['lastName'] ?? '') as String,
          email: (data['institutionalEmail'] ?? '') as String,
          modality: (data['modality'] as String?) ?? 'presencial',
        );
      }
    }

    return out;
  }

  Future<void> updateCommentField({
    required String studentId,
    required String templateId,
    required String fieldId,
    required String? comment,
    required String teacherId,
  }) async {
    final ref = _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(studentId, templateId));

    final patch = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'stage': 'reviewing',
    };

    if (comment == null || comment.trim().isEmpty) {
      patch['comments.$fieldId'] = FieldValue.delete();
    } else {
      patch['comments.$fieldId'] = comment.trim();
    }

    await ref.set(patch, SetOptions(merge: true));
  }

  Future<void> saveFeedbackAndGrade({
    required String studentId,
    required String templateId,
    String? feedback,
    double? grade,
    required String teacherId,
  }) async {
    final ref = _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(studentId, templateId));

    final cleanFeedback = feedback?.trim();
    final hasFeedback = cleanFeedback != null && cleanFeedback.isNotEmpty;

    await ref.set({
      'feedback': hasFeedback ? cleanFeedback : FieldValue.delete(),
      'grade': grade ?? FieldValue.delete(),
      'gradedAt': FieldValue.serverTimestamp(),
      'gradedBy': teacherId,
      'stage': grade != null ? 'graded' : 'reviewing',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unlockSubmission({
    required String studentId,
    required String templateId,
  }) async {
    final ref = _db
        .collection('form_entries_drafts')
        .doc(_draftDocId(studentId, templateId));

    await ref.set({
      'locked': false,
      'stage': 'draft',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
