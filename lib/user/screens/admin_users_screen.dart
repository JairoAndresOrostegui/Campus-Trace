import 'dart:ui' show ImageFilter; // <- para el blur del overlay
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../utils/snackbar_utils.dart';
import '../../auth/models/user.dart';
import '../services/user_service.dart';
import '../widgets/admin_photo_widget.dart';
import '../widgets/admin_user_form_widget.dart';
import '../../../providers/user_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _busquedaController = TextEditingController();
  String _textoBusqueda = '';
  List<UserModel> usuarios = [];
  bool isLoading = true;

  // Overlay de proceso (eliminar)
  bool _busy = false;
  final Set<String> _sendingAccessLinks = <String>{};

  String nombreCompleto = '';
  bool esSuperadminActual = false;
  List<String> funcionalidadesActual = [];
  late String institutionId;
  late String campusId;

  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _verificarPermisos();
    _cargarUsuarios();
    _busquedaController.addListener(() {
      setState(() {
        _textoBusqueda = _busquedaController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _verificarPermisos() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user!;
    esSuperadminActual =
        user.role == 'Administrador' ||
        user.role == 'Superadmin' ||
        (user.permissions ?? []).contains('superadmin');
    funcionalidadesActual = user.permissions ?? [];
    nombreCompleto = '${user.firstName} ${user.lastName}';
    institutionId = user.institution ?? '';
    campusId = user.campus ?? '';
  }

  Future<void> _cargarUsuarios() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      usuarios = await _userService.obtenerTodos(
        institutionId: institutionId,
        campusId: campusId,
        includeAllCampuses:
            esSuperadminActual ||
            Provider.of<UserProvider>(context, listen: false).user?.role ==
                'Docente',
        includeAllInstitutions: esSuperadminActual,
      );
    } catch (e) {
      // ignore
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final logged = context.watch<UserProvider>().user!;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        backgroundColor: Colors.white,
        foregroundColor: primary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      floatingActionButton:
          (esSuperadminActual ||
              funcionalidadesActual.contains('usuarios.crear'))
          ? FloatingActionButton(
              onPressed: () => _mostrarFormulario(),
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: primary.withValues(alpha: .15),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                primary.withValues(alpha: .06),
                                Colors.white,
                              ],
                            ),
                          ),
                          child: TextField(
                            controller: _busquedaController,
                            decoration: InputDecoration(
                              hintText: 'Buscar usuario...',
                              prefixIcon: Icon(Icons.search, color: primary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: usuarios.isEmpty
                            ? const Center(
                                child: Text('No hay usuarios disponibles'),
                              )
                            : ListView.builder(
                                itemCount: usuarios.length,
                                itemBuilder: (context, index) {
                                  final user = usuarios[index];
                                  final fullName =
                                      '${user.firstName} ${user.lastName}'
                                          .toLowerCase();
                                  final correo = user.institutionalEmail
                                      .toLowerCase();

                                  if (_textoBusqueda.isNotEmpty &&
                                      !fullName.contains(_textoBusqueda) &&
                                      !correo.contains(_textoBusqueda)) {
                                    return const SizedBox.shrink();
                                  }

                                  final puedeEditar =
                                      esSuperadminActual ||
                                      funcionalidadesActual.contains(
                                        'usuarios.editar',
                                      );
                                  final puedeEliminar =
                                      esSuperadminActual ||
                                      funcionalidadesActual.contains(
                                        'usuarios.eliminar',
                                      );

                                  // No permitir que un admin se elimine a sí mismo
                                  final isSelf = logged.id == user.id;
                                  final isAdminUser =
                                      user.role == 'Administrador';
                                  final loggedIsTeacher =
                                      logged.role == 'Docente';
                                  final canManageThisUser =
                                      !(loggedIsTeacher && isAdminUser);
                                  final puedeEditarEste =
                                      puedeEditar && canManageThisUser;
                                  final puedeEnviarEnlace = puedeEditarEste;
                                  final puedeEliminarEste =
                                      puedeEliminar &&
                                      canManageThisUser &&
                                      !(isSelf && isAdminUser);
                                  final hasMobileActions =
                                      puedeEditarEste ||
                                      puedeEnviarEnlace ||
                                      puedeEliminarEste;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: primary.withValues(alpha: .15),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            primary.withValues(alpha: .06),
                                            Colors.white,
                                          ],
                                        ),
                                      ),
                                      child: ListTile(
                                        leading: Semantics(
                                          label: 'Foto de perfil',
                                          enabled: true,
                                          focusable: true,
                                          child: ProfilePhotoWidget(
                                            imageUrl: user.photoUrl ?? '',
                                            enableHoverEdit: false,
                                            radius: 24,
                                            iconSize: 48,
                                          ),
                                        ),
                                        title: Text(
                                          '${user.firstName} ${user.lastName}',
                                        ),
                                        subtitle: Text(
                                          '${user.institutionalEmail} • ${(user.status ?? '').toUpperCase()}  • ${user.modality.toUpperCase()}',
                                        ),
                                        trailing: isMobile
                                            ? (hasMobileActions
                                                  ? PopupMenuButton<String>(
                                                      tooltip:
                                                          'Acciones del usuario',
                                                      onSelected: (action) {
                                                        if (action == 'edit') {
                                                          _mostrarFormulario(
                                                            usuario: user,
                                                          );
                                                        } else if (action ==
                                                            'access') {
                                                          _enviarEnlaceAcceso(
                                                            user,
                                                          );
                                                        } else if (action ==
                                                            'delete') {
                                                          _eliminarUsuario(
                                                            user,
                                                          );
                                                        }
                                                      },
                                                      itemBuilder: (_) => [
                                                        if (puedeEditarEste)
                                                          const PopupMenuItem(
                                                            value: 'edit',
                                                            child: Text(
                                                              'Editar',
                                                            ),
                                                          ),
                                                        if (puedeEnviarEnlace)
                                                          const PopupMenuItem(
                                                            value: 'access',
                                                            child: Text(
                                                              'Enviar enlace de acceso',
                                                            ),
                                                          ),
                                                        if (puedeEliminarEste)
                                                          const PopupMenuItem(
                                                            value: 'delete',
                                                            child: Text(
                                                              'Eliminar',
                                                            ),
                                                          ),
                                                      ],
                                                    )
                                                  : null)
                                            : Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (puedeEnviarEnlace)
                                                    IconButton(
                                                      tooltip:
                                                          'Enviar enlace de acceso',
                                                      onPressed:
                                                          _sendingAccessLinks
                                                              .contains(user.id)
                                                          ? null
                                                          : () =>
                                                                _enviarEnlaceAcceso(
                                                                  user,
                                                                ),
                                                      icon:
                                                          _sendingAccessLinks
                                                              .contains(user.id)
                                                          ? const SizedBox.square(
                                                              dimension: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            )
                                                          : const Icon(
                                                              Icons
                                                                  .mark_email_read_outlined,
                                                              color:
                                                                  Colors.blue,
                                                            ),
                                                    ),
                                                  if (puedeEditarEste)
                                                    IconButton(
                                                      tooltip: 'Editar',
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.green,
                                                      ),
                                                      onPressed: () =>
                                                          _mostrarFormulario(
                                                            usuario: user,
                                                          ),
                                                    ),
                                                  if (puedeEliminarEste)
                                                    IconButton(
                                                      tooltip: 'Eliminar',
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          _eliminarUsuario(
                                                            user,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                        onTap: () => _mostrarFormulario(
                                          usuario: user,
                                          soloLectura: !puedeEditarEste,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),

          // ===== Overlay de proceso (eliminar): gris + blur + spinner grande color tema =====
          if (_busy) ...[
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
    );
  }

  Future<void> _eliminarUsuario(UserModel usuario) async {
    final logged = Provider.of<UserProvider>(context, listen: false).user!;
    final isSelf = logged.id == usuario.id;
    final isAdminUser = usuario.role == 'Administrador';
    final loggedIsTeacher = logged.role == 'Docente';

    if (loggedIsTeacher && isAdminUser) {
      if (mounted) {
        mostrarSnack(
          context,
          'Un docente no puede eliminar usuarios Administrador.',
        );
      }
      return;
    }

    if (isSelf && isAdminUser) {
      if (mounted) {
        mostrarSnack(
          context,
          'No puedes eliminar tu propio usuario de Administrador.',
        );
      }
      return;
    }

    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${usuario.firstName} ${usuario.lastName}?\n'
          'Esta acción eliminará su cuenta del sistema y no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    setState(() => _busy = true);
    try {
      await _userService.registrarHistorial(
        usuario: usuario,
        accion: 'eliminado',
        realizadoPor: nombreCompleto,
      );
      await _userService.eliminar(usuario);
      await _cargarUsuarios();

      if (mounted) mostrarSnack(context, 'Usuario eliminado correctamente');
    } catch (e) {
      if (mounted) mostrarSnack(context, 'Error al eliminar usuario: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enviarEnlaceAcceso(UserModel usuario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar enlace de acceso'),
        content: Text(
          'Se enviará un correo a ${usuario.institutionalEmail} para configurar o recuperar su acceso.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sendingAccessLinks.add(usuario.id));
    try {
      await _userService.enviarEnlaceAcceso(usuario.id);
      if (mounted) {
        mostrarSnack(context, 'Enlace enviado a ${usuario.institutionalEmail}');
      }
    } catch (e) {
      if (mounted) {
        mostrarSnack(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _sendingAccessLinks.remove(usuario.id));
      }
    }
  }

  void _mostrarFormulario({
    UserModel? usuario,
    bool soloLectura = false,
  }) async {
    final bool? resultado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminUserFormWidget(
        usuario: usuario,
        soloLectura: soloLectura,
        onSuccess: () {},
      ),
    );

    if (resultado == true) {
      if (!mounted) return;
      await _cargarUsuarios();
      if (mounted) {
        mostrarSnack(context, 'Usuario guardado con éxito');
      }
    }
  }
}
