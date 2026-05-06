// lib/features/auth/screens/student_register_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../utils/parameters_service.dart';
import '../../../utils/validators.dart';
import '../../user/services/user_service.dart';
import '../../auth/models/user.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _document = TextEditingController();

  // parámetros
  List<Parameter> _campus = [];
  List<Parameter> _docTypes = [];
  List<Parameter> _careers = [];

  String? _selectedCampus;
  String? _selectedDocType;
  String? _selectedCareer;
  int? _semester = 1;

  // ✅ Modalidad (por defecto: presencial)
  String _modality = 'presencial';

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadParameters();
  }

  List<Parameter> _uniqueByValor(List<Parameter> list) {
    final seen = <String>{};
    return list.where((p) => seen.add(p.valor)).toList();
  }

  Future<void> _loadParameters() async {
    try {
      final svc = ParametersService();
      final results = await Future.wait([
        svc.getCampus(),
        svc.getDocumentTypes(),
        svc.getCareers(),
      ]);

      if (!mounted) return;
      setState(() {
        _campus = _uniqueByValor(results[0]);
        _docTypes = _uniqueByValor(results[1]);
        _careers = _uniqueByValor(results[2]);

        // valores por defecto
        if (_docTypes.isNotEmpty) {
          _selectedDocType = _docTypes.any((d) => d.valor == 'CC')
              ? 'CC'
              : _docTypes.first.valor;
        }
      });
    } catch (_) {
      // opcional: snackbar de error
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _document.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ captura dependencias ANTES de await
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final first = _firstName.text.trim();
    final last = _lastName.text.trim();
    final email = _email.text.trim().toLowerCase();
    final doc = _document.text.trim();

    final campus = _selectedCampus ?? '';
    final docType = _selectedDocType;
    final career = _selectedCareer;
    final sem = _semester ?? 1;

    // Reglas
    if (!email.endsWith('@udi.edu.co')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El correo debe ser @udi.edu.co')),
      );
      return;
    }
    if (campus.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona la sede (campus)')),
      );
      return;
    }
    if (docType == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona el tipo de documento')),
      );
      return;
    }
    if (career == null || career.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona tu programa (career)')),
      );
      return;
    }
    if (sem < 1 || sem > 10) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona un semestre válido (1–10)')),
      );
      return;
    }
    // ✅ Modalidad (simple por ser dropdown con valor por defecto)
    if (!['presencial', 'virtual'].contains(_modality)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Selecciona la modalidad')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Unicidad en Firestore
      final userSvc = UserService();

      // 1) Auth: crear con password = documento
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: doc,
      );

      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName('$first $last');

      if (await userSvc.existeDocumento(doc)) {
        await cred.user!.delete();
        throw Exception('El documento ya esta registrado.');
      }

      // 2) Firestore: guardar perfil (👈 añadimos modality)
      final student = UserModel(
        id: uid,
        firstName: first,
        lastName: last,
        institutionalEmail: email,
        role: 'Estudiante',
        semester: sem,
        career: career,
        modality: _modality, // 👈 NUEVO
        campus: campus,
        institution: 'UDI', // fijo e interno
        phones: const [],
        status: 'activo',
        documentType: docType,
        documentNumber: doc,
        photoUrl: null,
        permissions: const ['bitacora.ver'],
      );
      await userSvc.guardarUsuario(student);

      // 3) Verificación por correo (Auth)
      try {
        await cred.user!.sendEmailVerification();
      } catch (_) {}

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada. Revisa tu correo para verificar tu email.',
          ),
        ),
      );

      // salir de la sesión para forzar verificación antes de entrar
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      navigator.pop(); // volver al login
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Registro de estudiante'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(labelText: 'Nombres'),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                        autofillHints: const [AutofillHints.givenName],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Requerido'
                            : null,
                        autofillHints: const [AutofillHints.familyName],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Correo institucional',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!Validators.isValidEmail(v.trim())) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                        autofillHints: const [AutofillHints.email],
                      ),
                      const SizedBox(height: 12),
                      // Tipo de documento
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDocType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de documento',
                        ),
                        items: _docTypes.map((d) {
                          return DropdownMenuItem<String>(
                            value: d.valor,
                            child: Text('${d.etiqueta} - ${d.valor}'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedDocType = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      // Número de documento
                      TextFormField(
                        controller: _document,
                        decoration: const InputDecoration(
                          labelText:
                              'Número de documento (será tu contraseña inicial)',
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                        autofillHints: const [AutofillHints.password],
                      ),
                      const SizedBox(height: 12),
                      // Campus
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCampus,
                        decoration: const InputDecoration(
                          labelText: 'Sede (campus)',
                        ),
                        items: _campus.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.valor,
                            child: Text(c.valor),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedCampus = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      // Career
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCareer,
                        decoration: const InputDecoration(
                          labelText: 'Programa (career)',
                        ),
                        items: _careers.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.valor,
                            child: Text(c.valor),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedCareer = v),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      // Semestre
                      DropdownButtonFormField<int>(
                        initialValue: _semester,
                        decoration: const InputDecoration(
                          labelText: 'Semestre',
                        ),
                        items: List.generate(
                          10,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('Semestre ${i + 1}'),
                          ),
                        ),
                        onChanged: (v) => setState(() => _semester = v),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      // ✅ Modalidad
                      DropdownButtonFormField<String>(
                        initialValue: _modality, // default 'presencial'
                        decoration: const InputDecoration(
                          labelText: 'Modalidad',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'presencial',
                            child: Text('Presencial'),
                          ),
                          DropdownMenuItem(
                            value: 'virtual',
                            child: Text('Virtual'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _modality = v ?? 'presencial'),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _register,
                          icon: const Icon(Icons.person_add),
                          label: _busy
                              ? const Text('Registrando...')
                              : const Text('Crear cuenta'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Institución: UDI • Rol: Estudiante • Permisos iniciales: bitacora.ver',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withValues(alpha: .6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_busy)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: .06),
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
