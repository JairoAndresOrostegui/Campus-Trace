import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../auth/models/user.dart';
import '../services/profile_service.dart';
import '../utils/profile_image_picker.dart';
import '../widgets/profile_field.dart';
import '../../user/widgets/admin_photo_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  UserModel? userModel;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final provider = Provider.of<UserProvider>(context, listen: false);
    if (mounted) setState(() => userModel = provider.user);
  }

  Future<void> _seleccionarImagenYSubir() async {
    try {
      final (archivoBytes, nombreOriginal) = await pickImage();
      if (archivoBytes == null) return;

      final lower = nombreOriginal.toLowerCase();
      if (!(lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png'))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Solo se permiten imágenes JPG o PNG."),
            ),
          );
        }
        return;
      }

      final url = await _profileService.uploadProfilePhoto(
        Uint8List.fromList(archivoBytes),
        nombreOriginal,
      );

      if (url != null && mounted) {
        final provider = Provider.of<UserProvider>(context, listen: false);
        final usuarioActual = provider.user;
        if (usuarioActual != null) {
          final nuevoUsuario = usuarioActual.copyWith(photoUrl: url);
          provider.setUser(nuevoUsuario);
          setState(() => userModel = nuevoUsuario);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil actualizada")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al subir imagen: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    if (userModel == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("My profile"),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(color: primary),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              children: [
                const SizedBox(height: 20),

                // Foto con borde
                Center(
                  child: Semantics(
                    label: 'Foto de perfil, pulsa para cambiarla',
                    button: true,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF000000,
                            ).withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 132,
                          height: 132,
                          child: ProfilePhotoWidget(
                            imageUrl: userModel!.photoUrl,
                            onTap: _seleccionarImagenYSubir,
                            enableHoverEdit: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Botón editar foto solo en mobile
                if (!kIsWeb)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Semantics(
                        label: 'Botón para cambiar la foto de perfil',
                        button: true,
                        enabled: true,
                        focusable: true,
                        child: TextButton.icon(
                          onPressed: _seleccionarImagenYSubir,
                          icon: Icon(Icons.edit, size: 18, color: primary),
                          label: Text(
                            "Editar foto",
                            style: TextStyle(color: primary),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                _ProfileHeaderCard(user: userModel!),

                const SizedBox(height: 24),

                _ProfileDataCard(user: userModel!),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  final UserModel user;
  const _ProfileHeaderCard({required this.user});

  bool get _esAdminODocente =>
      user.role == 'Administrador' || user.role == 'Docente';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const TextAlign align = TextAlign.center;

    final fullName = '${user.firstName} ${user.lastName}'.trim();

    // Chips dinámicos (evita vacíos; oculta semestre para Admin/Docente)
    final chipsList = <String>[
      if ((user.role).trim().isNotEmpty) user.role,
      if (!_esAdminODocente && (user.semester) > 0) 'Semestre ${user.semester}',
      if ((user.campus ?? '').trim().isNotEmpty) '• ${user.campus!.trim()}',
    ];
    final chips = chipsList.join('  ');

    return Semantics(
      label: 'Información principal del perfil',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: .15)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [primary.withValues(alpha: .06), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              fullName.isEmpty ? '-' : fullName,
              textAlign: align,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                chips,
                textAlign: align,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary.withValues(alpha: .9),
                ),
              ),
            ],
            if ((user.institution ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                user.institution!.trim(),
                textAlign: align,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileDataCard extends StatelessWidget {
  final UserModel user;
  const _ProfileDataCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    String _safe(String? v) => (v ?? '').trim();
    bool _has(String? v) => _safe(v).isNotEmpty;

    final phones = (user.phones ?? [])
        .where((p) => _safe(p).isNotEmpty)
        .toList();

    return Semantics(
      label: 'Datos del perfil',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: .15)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [primary.withValues(alpha: .06), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              label: 'Información',
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Información',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
            ),
            Container(height: 1, color: primary.withValues(alpha: .15)),
            const SizedBox(height: 8),

            if (_has(user.firstName))
              ProfileField(title: "Nombres", value: _safe(user.firstName)),
            if (_has(user.lastName))
              ProfileField(title: "Apellidos", value: _safe(user.lastName)),
            if (_has(user.institutionalEmail))
              ProfileField(
                title: "Correo institucional",
                value: _safe(user.institutionalEmail),
              ),
            if (_has(user.role))
              ProfileField(title: "Rol", value: _safe(user.role)),

            if (user.role == 'Estudiante' && (user.semester) > 0)
              ProfileField(title: "Semestre", value: '${user.semester}'),

            if (user.role == 'Estudiante' && _has(user.career))
              ProfileField(title: "Programa", value: _safe(user.career)),

            if (user.role == 'Estudiante' && _has(user.modality))
              ProfileField(title: "Modalidad", value: _safe(user.modality).toUpperCase()),

            if (_has(user.institution))
              ProfileField(
                title: "Institución",
                value: _safe(user.institution),
              ),
            if (_has(user.campus))
              ProfileField(title: "Sede", value: _safe(user.campus)),
            if (_has(user.documentType))
              ProfileField(
                title: "Tipo de documento",
                value: _safe(user.documentType),
              ),
            if (_has(user.documentNumber))
              ProfileField(
                title: "Número de documento",
                value: _safe(user.documentNumber),
              ),

            // Estado (si viene vacío, no mostrar)
            if (_has(user.status))
              ProfileField(
                title: "Activo",
                value: (_safe(user.status).toLowerCase() == 'activo')
                    ? 'Sí'
                    : 'No',
              ),

            // Teléfonos (solo si hay)
            for (int i = 0; i < phones.length; i++)
              ProfileField(title: "Teléfono ${i + 1}", value: phones[i]),
          ],
        ),
      ),
    );
  }
}
