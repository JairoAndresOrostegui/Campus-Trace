class UserModel {
  final String id;
  final String firstName; // nombres (requerido)
  final String lastName; // apellidos (requerido)
  final String institutionalEmail; // correo institucional (requerido, login)
  final String role; // rol (requerido)
  final int semester; // semestre (requerido)

  /// modalidad del programa: 'presencial' | 'virtual'
  /// Por compatibilidad, default 'presencial' si no viene en Firestore.
  final String modality;

  final String? career; // carrera
  final String? campus; // campus
  final String? institution; // institución
  final List<String>? phones; // teléfonos
  final String? status; // estado
  final String? fcmToken; // fcmToken
  final String? documentType; // tipo de documento
  final String? documentNumber; // número de documento
  final String? photoUrl; // Url de la foto
  final List<String>? permissions; // Permisos

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.institutionalEmail,
    required this.semester,
    required this.role,
    this.modality = 'presencial',
    this.career,
    this.campus,
    this.institution,
    this.phones,
    this.status,
    this.fcmToken,
    this.documentType,
    this.documentNumber,
    this.photoUrl,
    this.permissions,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> map, String id) {
    int _parseSemester(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 1;
      return 1;
    }

    String _parseModality(dynamic v) {
      final s = (v ?? '').toString().toLowerCase().trim();
      if (s == 'virtual' || s == 'presencial') return s;
      return 'presencial'; // fallback seguro
    }

    return UserModel(
      id: id,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      institutionalEmail: map['institutionalEmail'] ?? '',
      semester: _parseSemester(map['semester']),
      role: map['role'] ?? '',
      modality: _parseModality(map['modality']),
      career: map['career'],
      campus: map['campus'],
      institution: map['institution'],
      phones: List<String>.from(map['phones'] ?? const []),
      status: map['status'],
      fcmToken: map['fcmToken'],
      documentType: map['documentType'],
      documentNumber: map['documentNumber'],
      photoUrl: map['photoUrl'],
      permissions: List<String>.from(map['permissions'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'institutionalEmail': institutionalEmail,
      'semester': semester,
      'role': role,
      'modality': modality,
      'career': career,
      'campus': campus,
      'institution': institution,
      'phones': phones,
      'status': status,
      'fcmToken': fcmToken,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'photoUrl': photoUrl,
      'permissions': permissions,
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? institutionalEmail,
    int? semester,
    String? role,
    String? modality,
    String? career,
    String? campus,
    String? institution,
    List<String>? phones,
    String? status,
    List<String>? permissions,
    String? fcmToken,
    String? documentType,
    String? documentNumber,
    String? photoUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      institutionalEmail: institutionalEmail ?? this.institutionalEmail,
      semester: semester ?? this.semester,
      role: role ?? this.role,
      modality: modality ?? this.modality,
      career: career ?? this.career,
      campus: campus ?? this.campus,
      institution: institution ?? this.institution,
      phones: phones ?? this.phones,
      status: status ?? this.status,
      fcmToken: fcmToken ?? this.fcmToken,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      permissions: permissions ?? this.permissions,
    );
  }

  bool get isPresencial => modality.toLowerCase() == 'presencial';
  bool get isVirtual => modality.toLowerCase() == 'virtual';
}
