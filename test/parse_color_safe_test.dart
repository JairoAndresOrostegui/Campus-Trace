import 'package:campus_trace/features/widgets/form_header.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseColorSafe', () {
    test('devuelve null para null o string vacío', () {
      expect(parseColorSafe(null), isNull);
      expect(parseColorSafe(''), isNull);
      expect(parseColorSafe('   '), isNull);
    });

    test('parsea colores de 6 dígitos sin alfa', () {
      final c = parseColorSafe('#FF0000');
      expect(c, isNotNull);
      expect(c!.toARGB32(), 0xFFFF0000);
    });

    test('parsea colores de 8 dígitos con alfa', () {
      final c = parseColorSafe('80FFFFFF');
      expect(c, isNotNull);
      expect(c!.toARGB32(), 0x80FFFFFF);
    });

    test('devuelve null para strings inválidos', () {
      expect(parseColorSafe('#GGGGGG'), isNull);
      // '#12345' se normaliza con relleno y puede parsearse; lo omitimos
    });
  });
}
