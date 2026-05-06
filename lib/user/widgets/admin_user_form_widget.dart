import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:ui' show ImageFilter; // <- para el blur del overlay

import '../../auth/models/user.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/parameters_service.dart';
import '../../profile/services/profile_service.dart';
import '../services/user_service.dart';
import 'admin_user_form_body.dart';

class AdminUserFormWidget extends StatefulWidget {
  final UserModel? usuario;
  final bool soloLectura;
  final void Function() onSuccess;

  const AdminUserFormWidget({
    super.key,
    this.usuario,
    this.soloLectura = false,
    required this.onSuccess,
  });

  @override
  State<AdminUserFormWidget> createState() => _AdminUserFormWidgetState();
}

class _AdminUserFormWidgetState extends State<AdminUserFormWidget> {
  final _formKey = GlobalKey<FormState>();

  // Controllers obligatorios
  late TextEditingController nombres;
  late TextEditingController apellidos;
  late TextEditingController correoInstitucional;

  // Documento
  late TextEditingController documento; // documentNumber
  List<Parameter> _documentTypes = [];
  String? _selectedDocumentType;

  // Rol y semestre
  List<Parameter> _roles = [];
  String _rol = 'Estudiante';
  int? _semester = 1;

  // Modalidad
  String _modality = 'presencial';

  // Campos opcionales
  late TextEditingController institucion; // institution
  late TextEditingController
  sede; // campus (controller se mantiene, pero UI será dropdown)
  late TextEditingController carreraCtl; // career (UI dropdown)
  late TextEditingController telefonos; // lista separada por coma

  // Campus / Careers desde parameters
  List<Parameter> _campus = [];
  String? _selectedCampus;

  List<Parameter> _careers = [];
  String? _selectedCareer;

  // Estado
  String _status = 'activo'; // activo | inactivo

  // Permisos
  List<String> funcionalidades = [];
  List<Parameter> _allPermissions = [];

  // Foto
  String? fotoUrl;
  Uint8List? _pickedImageBytes;

  // Flags
  bool _isLoading = true; // carga de parámetros
  bool esSuperadminActual = false;
  bool _saving = false; // spinner guardando

  // === Helper para evitar duplicados por valor ===
  List<Parameter> _uniqueByValor(List<Parameter> list) {
    final seen = <String>{};
    return list.where((p) => seen.add(p.valor)).toList();
  }

  Future<void> _loadAllParameters() async {
    try {
      await Future.wait([
        _loadDocumentTypes(),
        _loadRoles(),
        _loadPermissions(),
        _loadCampus(),
        _loadCareers(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    final userLogged = context.read<UserProvider>().user!;
    _modality = (widget.usuario?.modality ?? 'presencial');

    nombres = TextEditingController(text: u?.firstName ?? '');
    apellidos = TextEditingController(text: u?.lastName ?? '');
    correoInstitucional = TextEditingController(
      text: u?.institutionalEmail ?? '',
    );
    documento = TextEditingController(text: u?.documentNumber ?? '');

    // valores iniciales
    fotoUrl = u?.photoUrl;
    funcionalidades = List<String>.from(u?.permissions ?? []);
    _status = (u?.status ?? 'activo');

    esSuperadminActual = (userLogged.permissions ?? []).contains('superadmin');

    institucion = TextEditingController(
      text: esSuperadminActual
          ? (u?.institution ?? '')
          : (userLogged.institution ?? ''),
    );
    sede = TextEditingController(
      text: esSuperadminActual ? (u?.campus ?? '') : (userLogged.campus ?? ''),
    );
    carreraCtl = TextEditingController(text: u?.career ?? '');
    telefonos = TextEditingController(text: (u?.phones ?? []).join(', '));

    _rol = u?.role ?? 'Estudiante';
    _semester = (_rol == 'Estudiante')
        ? (u?.semester ?? 1)
        : 0; // default 0 si no es estudiante

    _selectedDocumentType = u?.documentType;

    // Preasignar campus/career seleccionados con lo que tenga el usuario
    _selectedCampus = u?.campus ?? sede.text;
    _selectedCareer = (u?.career != null && u!.career!.isNotEmpty)
        ? u.career
        : null;

    _loadAllParameters();
  }

  Future<void> _loadPermissions() async {
    try {
      final permissions = await ParametersService().getPermissions();
      if (mounted) {
        setState(() {
          _allPermissions = _uniqueByValor(permissions);
          funcionalidades = List<String>.from(
            widget.usuario?.permissions ?? funcionalidades,
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDocumentTypes() async {
    try {
      final types = await ParametersService().getDocumentTypes();
      if (mounted) {
        setState(() {
          _documentTypes = _uniqueByValor(types);
          _selectedDocumentType =
              widget.usuario?.documentType ?? _selectedDocumentType;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRoles() async {
    try {
      final logged = context.read<UserProvider>().user!;
      final roles = await ParametersService().getRoles();
      final visibleRoles = logged.role == 'Docente'
          ? roles.where((role) => role.valor != 'Administrador').toList()
          : roles;
      if (mounted) {
        setState(() {
          _roles = _uniqueByValor(visibleRoles);
          _rol =
              widget.usuario?.role ??
              (_roles.isNotEmpty ? _roles.first.valor : 'Estudiante');
          // Ajuste del semestre cuando cambia el rol de entrada
          _semester = (_rol == 'Estudiante') ? (_semester ?? 1) : 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCampus() async {
    try {
      final campuses = await ParametersService().getCampus();
      if (mounted) {
        setState(() {
          _campus = _uniqueByValor(campuses);
          // Si el campus actual no está en la lista, dejamos _selectedCampus como null
          if (!_campus.any((c) => c.valor == _selectedCampus)) {
            _selectedCampus = null;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCareers() async {
    try {
      final careers = await ParametersService().getCareers();
      if (mounted) {
        setState(() {
          _careers = _uniqueByValor(careers);
          if (!_careers.any((c) => c.valor == _selectedCareer)) {
            _selectedCareer = null;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    nombres.dispose();
    apellidos.dispose();
    correoInstitucional.dispose();
    documento.dispose();
    institucion.dispose();
    sede.dispose();
    carreraCtl.dispose();
    telefonos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final esNuevo = widget.usuario == null;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile
                ? double.infinity
                : MediaQuery.of(context).size.width * 0.55,
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: .15)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primary.withValues(alpha: .06), Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF000000).withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdminUserFormBody(
                            usuario: widget.usuario,
                            soloLectura: widget.soloLectura,
                            esSuperadminActual: esSuperadminActual,
                            fotoUrl: fotoUrl,
                            onPickPhoto: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (picked != null) {
                                final bytes = await picked.readAsBytes();
                                setState(() {
                                  _pickedImageBytes = bytes;
                                  fotoUrl = null;
                                });
                              }
                            },
                            modality: _modality,
                            onModalityChanged: (v) => setState(() {
                              _modality = (v ?? _modality);
                            }),

                            // requeridos
                            nombres: nombres,
                            apellidos: apellidos,
                            correoInstitucional: correoInstitucional,

                            // documento
                            documento: documento,
                            documentTypes: _documentTypes,
                            selectedDocumentType: _selectedDocumentType,
                            onDocumentTypeChanged: (newValue) {
                              setState(() => _selectedDocumentType = newValue);
                            },

                            // rol y semestre
                            rol: _rol,
                            roles: _roles,
                            onRolChanged: (newValue) => setState(() {
                              _rol = newValue ?? _rol;
                              // si cambia a no-estudiante, semestre = 0 oculto
                              if (_rol != 'Estudiante') {
                                _semester = 0;
                                _selectedCareer =
                                    ""; // vacía para no estudiantes
                                carreraCtl.text = "";
                              } else {
                                // estudiante: si semestre estaba 0, colócalo en 1 por defecto
                                if (_semester == null || _semester == 0) {
                                  _semester = 1;
                                }
                              }
                            }),
                            semester: _semester,
                            onSemesterChanged: (val) =>
                                setState(() => _semester = val ?? _semester),

                            // opcionales
                            institucion: institucion,
                            sede: sede,
                            carrera: carreraCtl,
                            telefonos: telefonos,

                            // campus/careers (nuevos)
                            campusOptions: _campus,
                            selectedCampus: _selectedCampus,
                            onCampusChanged: (val) => setState(() {
                              _selectedCampus = val;
                              sede.text = val ?? sede.text;
                            }),
                            careerOptions: _careers,
                            selectedCareer: _selectedCareer,
                            onCareerChanged: (val) => setState(() {
                              _selectedCareer = val;
                              carreraCtl.text = val ?? "";
                            }),

                            // estado
                            status: _status,
                            onStatusChanged: (val) =>
                                setState(() => _status = val ?? _status),

                            // permisos
                            funcionalidades: funcionalidades,
                            allPermissions: _allPermissions,
                            onFuncionalidadChanged: (permiso, isChecked) {
                              setState(() {
                                if (isChecked == true) {
                                  if (!funcionalidades.contains(permiso)) {
                                    funcionalidades.add(permiso);
                                  }
                                } else {
                                  funcionalidades.remove(permiso);
                                }
                              });
                            },

                            esNuevo: esNuevo,
                          ),

                          if (!widget.soloLectura)
                            Semantics(
                              label: 'Botón para guardar usuario',
                              enabled: true,
                              focusable: true,
                              button: true,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: (_isLoading || _saving)
                                      ? null
                                      : _guardarUsuario,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Guardar'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ===== Overlay de carga/guardado: gris + blur + spinner grande color tema =====
              if (_isLoading || _saving) ...[
                Positioned.fill(
                  child: AbsorbPointer(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                color: primary,
                                strokeWidth: 6,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) setState(() => _saving = true);

    final userProvider = context.read<UserProvider>();
    final usuarioLogueado = userProvider.user!;
    final esNuevo = widget.usuario == null;

    if (usuarioLogueado.role == 'Docente' &&
        (widget.usuario?.role == 'Administrador' || _rol == 'Administrador')) {
      if (mounted) setState(() => _saving = false);
      _showError('Un docente no puede crear ni modificar usuarios Administrador.');
      return;
    }

    final emailTrim = correoInstitucional.text.trim().toLowerCase();
    if (!emailTrim.endsWith('@udi.edu.co')) {
      if (mounted) setState(() => _saving = false);
      _showError('El correo debe ser @udi.edu.co.');
      return;
    }

    if (documento.text.trim().length < 6) {
      if (mounted) setState(() => _saving = false);
      _showError('El documento debe tener al menos 6 caracteres.');
      return;
    }

    final service = UserService();
    final excludeId = widget.usuario?.id;

    if (await service.existeCorreoInstitucional(
      correoInstitucional.text.trim(),
      excluirId: excludeId,
    )) {
      if (mounted) setState(() => _saving = false);
      _showError('El correo institucional ya está registrado.');
      return;
    }

    if (await service.existeDocumento(
      documento.text.trim(),
      excluirId: excludeId,
    )) {
      if (mounted) setState(() => _saving = false);
      _showError('El documento ya está registrado.');
      return;
    }

    String? nuevaFotoUrl;

    // Reglas solicitadas:
    // - Semestre: solo Estudiante; otros = 0
    final rolActual = _rol;
    final semesterForSave = (rolActual == 'Estudiante') ? (_semester ?? 1) : 0;

    // - Career: solo Estudiante; otros = ""
    final careerForSave = (rolActual == 'Estudiante')
        ? (_selectedCareer ?? "")
        : "";

    // - Campus: dropdown; si no es superadmin no se permite editar (se conserva logged.campus)
    final campusForSave = esSuperadminActual
        ? (_selectedCampus ?? sede.text.trim())
        : (usuarioLogueado.campus ?? '');

    final nuevoUsuario = UserModel(
      id: widget.usuario?.id ?? '',
      firstName: nombres.text.trim(),
      lastName: apellidos.text.trim(),
      institutionalEmail: correoInstitucional.text.trim(),
      role: rolActual,
      semester: semesterForSave,
      career: careerForSave,
      modality: _modality,
      campus: campusForSave,
      institution: esSuperadminActual
          ? institucion.text.trim()
          : (usuarioLogueado.institution ?? ''),
      phones: telefonos.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      status: _status,
      documentType: _selectedDocumentType ?? 'CC',
      documentNumber: documento.text.trim(),
      photoUrl: fotoUrl,
      permissions: funcionalidades,
      fcmToken: widget.usuario?.fcmToken,
    );

    try {
      if (esNuevo) {
        final uid = await service.crearUsuarioDesdeAdmin(
          email: nuevoUsuario.institutionalEmail,
          password: nuevoUsuario.documentNumber ?? documento.text.trim(),
          nombres: nuevoUsuario.firstName,
          apellidos: nuevoUsuario.lastName,
          rol: nuevoUsuario.role,
          documento: nuevoUsuario.documentNumber ?? '',
        );

        if (_pickedImageBytes != null) {
          nuevaFotoUrl = await ProfileService().uploadProfilePhoto(
            Uint8List.fromList(_pickedImageBytes!),
            'profile_$uid.png',
          );
        }

        final usuarioConUid = nuevoUsuario.copyWith(
          id: uid,
          photoUrl: nuevaFotoUrl ?? nuevoUsuario.photoUrl,
        );

        await service.guardarUsuario(usuarioConUid);
        await service.registrarHistorial(
          usuario: usuarioConUid,
          accion: 'creado',
          realizadoPor:
              '${usuarioLogueado.firstName} ${usuarioLogueado.lastName}',
        );
      } else {
        if (_pickedImageBytes != null) {
          nuevaFotoUrl = await ProfileService().uploadProfilePhoto(
            Uint8List.fromList(_pickedImageBytes!),
            'profile_${nuevoUsuario.id}.png',
          );
        }

        final usuarioEditado = nuevoUsuario.copyWith(
          photoUrl: nuevaFotoUrl ?? nuevoUsuario.photoUrl,
        );

        await service.guardarUsuario(usuarioEditado);
        await service.registrarHistorial(
          usuario: usuarioEditado,
          accion: 'editado',
          realizadoPor:
              '${usuarioLogueado.firstName} ${usuarioLogueado.lastName}',
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) Navigator.of(context).pop(false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Validación'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
