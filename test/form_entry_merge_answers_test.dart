import 'package:campus_trace/features/models/form_entry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormEntry.mergeAnswersFromData', () {
    test('combina mapa answers con claves answers.<campo>', () {
      final data = <String, dynamic>{
        'answers': {
          'a': 'v1',
          'b': 'v2_old',
        },
        'answers.b': 'v2_new',
        'answers.c': 123,
      };

      final merged = FormEntry.mergeAnswersFromData(data);

      expect(merged['a'], 'v1');
      expect(merged['b'], 'v2_new');
      expect(merged['c'], 123);
      expect(merged.length, 3);
    });

    test('funciona cuando solo hay claves answers.<campo>', () {
      final data = <String, dynamic>{
        'answers.x': 'hola',
        'answers.y': null,
      };

      final merged = FormEntry.mergeAnswersFromData(data);

      expect(merged['x'], 'hola');
      expect(merged.containsKey('y'), true);
    });
  });

  group('FormEntry.fromData', () {
    test('lee campos basicos, answers y comentarios', () {
      final data = <String, dynamic>{
        'templateId': 'tmpl1',
        'userId': 'user1',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'answers': {
          'a': 'v1',
        },
        'answers.b': 'v2',
        'comments': {
          'a': 'ok',
        },
        'feedback': 'bien',
        'grade': 4.5,
        'stage': 'graded',
        'gradedAt': Timestamp.fromMillisecondsSinceEpoch(1700000100000),
        'gradedBy': 'teacher1',
      };

      final entry = FormEntry.fromData(id: 'entry1', data: data);

      expect(entry.id, 'entry1');
      expect(entry.templateId, 'tmpl1');
      expect(entry.userId, 'user1');
      expect(entry.createdAt, isA<DateTime>());
      expect(entry.answers['a'], 'v1');
      expect(entry.answers['b'], 'v2');
      expect(entry.comments, isNotNull);
      expect(entry.comments!['a'], 'ok');
      expect(entry.feedback, 'bien');
      expect(entry.grade, 4.5);
      expect(entry.stage, 'graded');
      expect(entry.gradedAt, isA<DateTime>());
      expect(entry.gradedBy, 'teacher1');
    });

    test('tolera ausencia de comentarios y valores nulos', () {
      final data = <String, dynamic>{
        'templateId': 'tmpl2',
        'userId': 'user2',
        'createdAt': Timestamp.fromMillisecondsSinceEpoch(1700000000000),
        'answers.c': 'x',
        'grade': null,
        'gradedAt': null,
      };

      final entry = FormEntry.fromData(id: 'entry2', data: data);

      expect(entry.comments, isNull);
      expect(entry.answers['c'], 'x');
      expect(entry.grade, isNull);
      expect(entry.gradedAt, isNull);
    });
  });
}
