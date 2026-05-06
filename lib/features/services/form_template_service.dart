import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/form_template.dart';

class FormTemplateService {
  final _col = FirebaseFirestore.instance.collection('form_templates');

  String _randomCode([int len = 6]) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String> generateUniqueCode() async {
    while (true) {
      final code = _randomCode(6);
      final q = await _col.where('code', isEqualTo: code).limit(1).get();
      if (q.docs.isEmpty) return code;
    }
  }

  Future<String> createTemplate({
    required String createdBy,
    String? initialTitle,
    String? groupName,
    DateTime? formStart,
    DateTime? formEnd,
  }) async {
    final code = await generateUniqueCode();
    final now = DateTime.now();

    final header = HeaderConfig(
      title: initialTitle ?? 'Nuevo formulario',
      subtitle: null,
      titleFontSize: 22,
      subtitleFontSize: 16,
      formStart: formStart,
      formEnd: formEnd,
      titleColorHex: '#0B4BB3',
      subtitleColorHex: '#243B68',
      bgColorHex: '#F5F9FF',
    );

    final data = {
      'code': code,
      'groupName': groupName ?? '',
      'status': 'created',
      'header': header.toMap(),
      'sections': <Map<String, dynamic>>[],
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    };

    final ref = await _col.add(data);
    return ref.id;
  }

  Future<String> duplicateTemplate({
    required String sourceTemplateId,
    required String createdBy,
    String? title,
  }) async {
    final sourceDoc = await _col.doc(sourceTemplateId).get();
    if (!sourceDoc.exists) {
      throw StateError('Template no encontrado');
    }

    final source = FormTemplate.fromDoc(sourceDoc);
    final code = await generateUniqueCode();
    final now = DateTime.now();
    final duplicateTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : source.header.title.trim().isEmpty
        ? 'Copia de formulario'
        : '${source.header.title} (copia)';

    final ref = await _col.add({
      ...source.toMap(),
      'code': code,
      'header': source.header.copyWith(title: duplicateTitle).toMap(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'enrolledUserIds': <String>[],
    });

    return ref.id;
  }

  Future<void> deleteTemplate(String id) async {
    await _col.doc(id).delete();
  }

  Stream<FormTemplate> watchTemplate(String id) {
    return _col.doc(id).snapshots().map((d) {
      if (!d.exists) {
        throw StateError('Template no encontrado');
      }
      return FormTemplate.fromDoc(d);
    });
  }

  Future<void> updateHeader(
    String id,
    HeaderConfig header, {
    String? groupName,
  }) async {
    await _col.doc(id).update({
      'header': header.toMap(),
      if (groupName != null) 'groupName': groupName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGroupAndCode(
    String id, {
    required String code,
    required String groupName,
  }) async {
    await _col.doc(id).update({
      'code': code,
      'groupName': groupName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // sin orderBy (para no exigir índice); ordenamos en memoria
  Stream<List<FormTemplate>> watchTemplatesByUser(String createdBy) {
    return _col.where('createdBy', isEqualTo: createdBy).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map((d) => FormTemplate.fromDoc(d)).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  Future<List<FormTemplate>> fetchTemplatesByUser(String createdBy) async {
    final q = await _col.where('createdBy', isEqualTo: createdBy).get();
    final list = q.docs.map((d) => FormTemplate.fromDoc(d)).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  // Genera un id local (para secciones / subsecciones / campos)
  String newLocalId() => _col.doc().id;

  Future<void> updateSections(String id, List<Section> sections) async {
    await _col.doc(id).update({
      'sections': sections.map((s) => s.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
