import 'package:campus_trace/auth/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel.fromFirestore', () {
    test('parsea campos básicos y semestre/modality', () {
      final data = <String, dynamic>{
        'firstName': 'Ana',
        'lastName': 'Pérez',
        'institutionalEmail': 'ana@ejemplo.com',
        'semester': '3',
        'role': 'Estudiante',
        'modality': 'Virtual',
        'phones': ['123', '456'],
        'permissions': ['admin'],
      };

      final user = UserModel.fromFirestore(data, 'uid-123');

      expect(user.id, 'uid-123');
      expect(user.firstName, 'Ana');
      expect(user.lastName, 'Pérez');
      expect(user.institutionalEmail, 'ana@ejemplo.com');
      expect(user.semester, 3);
      expect(user.role, 'Estudiante');
      expect(user.modality, 'virtual'); // se normaliza a minúsculas
      expect(user.phones, ['123', '456']);
      expect(user.permissions, ['admin']);
      expect(user.isVirtual, true);
      expect(user.isPresencial, false);
    });

    test('usa valores por defecto seguros cuando faltan campos', () {
      final data = <String, dynamic>{
        // sin firstName, lastName, semester, modality
        'institutionalEmail': 'sin_datos@ejemplo.com',
        'role': 'Docente',
      };

      final user = UserModel.fromFirestore(data, 'uid-456');

      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.institutionalEmail, 'sin_datos@ejemplo.com');
      expect(user.semester, 1); // fallback cuando no se puede parsear
      expect(user.modality, 'presencial'); // fallback por defecto
      expect(user.phones, isEmpty);
      expect(user.permissions, isEmpty);
    });
  });

  group('UserModel.copyWith', () {
    test('crea una copia modificando solo los campos indicados', () {
      final original = UserModel(
        id: 'id1',
        firstName: 'Ana',
        lastName: 'Pérez',
        institutionalEmail: 'ana@ejemplo.com',
        semester: 2,
        role: 'Estudiante',
      );

      final copy = original.copyWith(
        firstName: 'Ana María',
        semester: 3,
      );

      expect(copy.id, 'id1');
      expect(copy.firstName, 'Ana María');
      expect(copy.lastName, 'Pérez');
      expect(copy.institutionalEmail, 'ana@ejemplo.com');
      expect(copy.semester, 3);
      expect(copy.role, 'Estudiante');
    });
  });
}

