import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../auth/models/user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  /// Obtener todos los usuarios desde la colección 'users'
  Future<List<UserModel>> obtenerTodos({
    required String institutionId,
    required String campusId,
    bool includeAllCampuses = false,
    bool includeAllInstitutions = false,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection('users');
    if (!includeAllInstitutions) {
      query = query.where('institution', isEqualTo: institutionId);
    }
    if (!includeAllCampuses) {
      query = query.where('campus', isEqualTo: campusId);
    }
    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> obtenerDocentes({
    String? institutionId,
    String? campusId,
  }) async {
    Query<Map<String, dynamic>> query = _db
        .collection('users')
        .where('role', isEqualTo: 'Docente');

    if (institutionId != null && institutionId.trim().isNotEmpty) {
      query = query.where('institution', isEqualTo: institutionId.trim());
    }
    if (campusId != null && campusId.trim().isNotEmpty) {
      query = query.where('campus', isEqualTo: campusId.trim());
    }

    final snapshot = await query.get();
    final docentes = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
        .where((u) => (u.status ?? '').toLowerCase() == 'activo')
        .toList();

    docentes.sort((a, b) {
      final an = '${a.firstName} ${a.lastName}'.toLowerCase();
      final bn = '${b.firstName} ${b.lastName}'.toLowerCase();
      return an.compareTo(bn);
    });

    return docentes;
  }

  /// Obtener usuario por ID
  Future<UserModel?> obtenerPorId({
    required String uid,
    required String institutionId,
    required String campusId,
  }) async {
    final doc = await _db
        .collection('users')
        .where(FieldPath.documentId, isEqualTo: uid)
        .where('institution', isEqualTo: institutionId)
        .where('campus', isEqualTo: campusId)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) return null;
    return UserModel.fromFirestore(doc.docs.first.data(), doc.docs.first.id);
  }

  /// Guardar o actualizar un usuario en Firestore
  Future<void> guardarUsuario(UserModel usuario) async {
    if (usuario.id.trim().isEmpty) {
      throw Exception('El ID del usuario no puede estar vacío');
    }
    await _db
        .collection('users')
        .doc(usuario.id)
        .set(usuario.toMap(), SetOptions(merge: true));
  }

  /// Generar un nuevo UID local (no para Auth, solo ID de Firestore)
  Future<String> generarNuevoUid() async {
    final docRef = _db.collection('users').doc();
    return docRef.id;
  }

  /// Crea el usuario en Authentication y Firestore mediante una sola función.
  /// La contraseña se define desde el enlace personal enviado por correo.
  Future<String> crearUsuarioDesdeAdmin({required UserModel usuario}) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'crearUsuarioDesdeAdmin',
    );
    final result = await callable.call({'user': usuario.toMap()});
    final data = Map<String, dynamic>.from(result.data as Map);

    if (data['exito'] != true) {
      throw Exception('No se pudo crear el usuario');
    }
    return data['uid'] as String;
  }

  /// Sincroniza el usuario en Authentication y Firestore. Cuando cambia el
  /// correo, también envía al nuevo correo un enlace para configurar acceso.
  Future<bool> actualizarUsuarioDesdeAdmin(UserModel usuario) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'actualizarUsuarioDesdeAdmin',
    );
    final result = await callable.call({
      'uid': usuario.id,
      'user': usuario.toMap(),
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['exito'] != true) {
      throw Exception('No se pudo actualizar el usuario');
    }
    return data['enlaceEnviado'] == true;
  }

  Future<void> enviarEnlaceAcceso(String uid) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'enviarEnlaceAcceso',
    );
    final result = await callable.call({'uid': uid});
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['enviado'] != true) {
      throw Exception('No se pudo enviar el enlace de acceso');
    }
  }

  /// Eliminar usuario de Firebase Auth vía Cloud Function
  Future<void> eliminarUsuarioAuth(String uid) async {
    final callable = FirebaseFunctions.instance.httpsCallable(
      'eliminarUsuarioAuth',
    );
    final result = await callable.call({'uid': uid});

    if (result.data['success'] != true) {
      throw Exception('No se pudo eliminar el usuario en Auth');
    }
  }

  /// Eliminar usuario completamente del sistema (Auth + Firestore)
  Future<void> eliminar(UserModel usuario) async {
    await eliminarUsuarioAuth(usuario.id);
    await _db.collection('users').doc(usuario.id).delete();
  }

  /// Registrar historial de acciones del usuario
  Future<void> registrarHistorial({
    required UserModel usuario,
    required String accion,
    required String realizadoPor,
  }) async {
    await _db.collection('user_history').add({
      'usuarioId': usuario.id,
      'nombres': usuario.firstName,
      'apellidos': usuario.lastName,
      'rol': usuario.role,
      'accion': accion,
      'realizadoPor': realizadoPor,
      'institution': usuario.institution,
      'campus': usuario.campus,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // ================== VALIDACIONES DE UNICIDAD ==================

  Future<bool> existeCorreoInstitucional(
    String email, {
    String? excluirId,
  }) async {
    final snap = await _db
        .collection('users')
        .where('institutionalEmail', isEqualTo: email.trim())
        .limit(5)
        .get();

    if (snap.docs.isEmpty) return false;
    if (excluirId == null) return true;
    return snap.docs.any((d) => d.id != excluirId);
  }

  Future<bool> existeDocumento(String documento, {String? excluirId}) async {
    final snap = await _db
        .collection('users')
        .where('documentNumber', isEqualTo: documento.trim())
        .limit(5)
        .get();

    if (snap.docs.isEmpty) return false;
    if (excluirId == null) return true;
    return snap.docs.any((d) => d.id != excluirId);
  }
}
