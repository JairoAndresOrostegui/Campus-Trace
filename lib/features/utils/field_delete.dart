import 'package:flutter/foundation.dart';

/// Token para indicar que un campo debe eliminarse del borrador en Firestore.
/// Se usa con `identical(value, FieldDelete.token)`.
@immutable
class FieldDelete {
  const FieldDelete._();
  static const token = FieldDelete._();
}
