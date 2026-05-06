import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../app.dart';
import '../../../providers/user_provider.dart';
import '../../core/config/theme_config.dart';
import '../../utils/color_utils.dart';
import '../../utils/validators.dart';
import '../services/auth_service.dart';
import '../widgets/logo_widget.dart';
import '../widgets/title_widget.dart';
import '../widgets/reset_password_dialog.dart';
import 'student_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Colores desde el theme/config (azules UDI)
    final primary = theme.colorScheme.primary;
    final labelColor = parseColor(ThemeProvider.config?.colorLabel) ?? primary;
    final fontGeneral = ThemeProvider.config?.fuenteGeneral;

    // Estilos consistentes
    final containerRadius = BorderRadius.circular(16);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primary.withValues(alpha: 0.25)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primary, width: 1.4),
    );

    return Scaffold(
      backgroundColor:
          parseColor(ThemeProvider.config?.colorFondo) ??
          theme.colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Encabezado responsivo SIN LayoutBuilder (compatible con IntrinsicHeight)
                      // Encabezado responsivo
                      Builder(
                        builder: (ctx) {
                          final useCompactHeader =
                              MediaQuery.of(ctx).size.width < 820;

                          if (useCompactHeader) {
                            // Pantallas chicas: logo arriba, título abajo
                            return const Padding(
                              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PublicLogoWidget(maxHeight: 56),
                                  SizedBox(height: 8),
                                  PublicTitleWidget(),
                                ],
                              ),
                            );
                          } else {
                            // Pantallas anchas: logo a la derecha, título a la izquierda o centrado
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 16.0,
                                bottom: 8.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: PublicTitleWidget(),
                                    ),
                                  ),
                                  const PublicLogoWidget(maxHeight: 56),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tarjeta login con degradé
                      Expanded(
                        child: Align(
                          alignment: const Alignment(0, -0.60),
                          child: SizedBox(
                            width: isMobile ? double.infinity : 520,
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: containerRadius,
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primary.withValues(alpha: 0.06),
                                    Colors.white,
                                  ],
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Email
                                        Semantics(
                                          label:
                                              'Campo para correo electrónico',
                                          hint:
                                              'Ingrese su correo institucional',
                                          textField: true,
                                          enabled: true,
                                          focusable: true,
                                          child: TextFormField(
                                            controller: _emailController,
                                            decoration: InputDecoration(
                                              labelText: 'Correo electrónico',
                                              labelStyle: TextStyle(
                                                color: labelColor,
                                                fontFamily: fontGeneral,
                                              ),
                                              border: inputBorder,
                                              enabledBorder: inputBorder,
                                              focusedBorder: focusedBorder,
                                              prefixIcon: Icon(
                                                Icons.email,
                                                color: primary,
                                              ),
                                              isDense: true,
                                            ),
                                            style: TextStyle(
                                              fontFamily: fontGeneral,
                                            ),
                                            textInputAction:
                                                TextInputAction.next,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Este campo es obligatorio';
                                              }
                                              if (!Validators.isValidEmail(
                                                value,
                                              )) {
                                                return 'Ingrese un correo válido';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Password
                                        Semantics(
                                          label: 'Campo para contraseña',
                                          hint: 'Ingrese su contraseña',
                                          textField: true,
                                          enabled: true,
                                          focusable: true,
                                          child: TextFormField(
                                            controller: _passwordController,
                                            obscureText: _obscure,
                                            decoration: InputDecoration(
                                              labelText: 'Contraseña',
                                              labelStyle: TextStyle(
                                                color: labelColor,
                                                fontFamily: fontGeneral,
                                              ),
                                              border: inputBorder,
                                              enabledBorder: inputBorder,
                                              focusedBorder: focusedBorder,
                                              prefixIcon: Icon(
                                                Icons.lock,
                                                color: primary,
                                              ),
                                              suffixIcon: Semantics(
                                                label: _obscure
                                                    ? 'Mostrar contraseña'
                                                    : 'Ocultar contraseña',
                                                button: true,
                                                child: IconButton(
                                                  icon: Icon(
                                                    _obscure
                                                        ? Icons.visibility
                                                        : Icons.visibility_off,
                                                  ),
                                                  onPressed: () => setState(
                                                    () => _obscure = !_obscure,
                                                  ),
                                                ),
                                              ),
                                              isDense: true,
                                            ),
                                            style: TextStyle(
                                              fontFamily: fontGeneral,
                                            ),
                                            textInputAction:
                                                TextInputAction.done,
                                            validator: (value) =>
                                                (value == null || value.isEmpty)
                                                ? 'Ingrese su contraseña'
                                                : null,
                                            onFieldSubmitted: (_) =>
                                                _iniciarSesion(),
                                          ),
                                        ),
                                        const SizedBox(height: 24),

                                        // Botón login
                                        Semantics(
                                          label: 'Botón para iniciar sesión',
                                          button: true,
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primary,
                                                foregroundColor: Colors.white,
                                                minimumSize:
                                                    const Size.fromHeight(48),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                              onPressed: _loading
                                                  ? null
                                                  : _iniciarSesion,
                                              child: _loading
                                                  ? const SizedBox(
                                                      height: 22,
                                                      width: 22,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : Text(
                                                      'Iniciar sesión',
                                                      style: TextStyle(
                                                        fontFamily: fontGeneral,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),

                                        // Recuperar contraseña
                                        Semantics(
                                          label:
                                              'Botón para recuperar contraseña',
                                          button: true,
                                          child: TextButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) =>
                                                    const ResetPasswordDialog(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: primary,
                                            ),
                                            child: Text(
                                              '¿Olvidaste tu contraseña?',
                                              style: TextStyle(
                                                fontFamily: fontGeneral,
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Registrarse
                                        Semantics(
                                          label: 'Botón para registrarse',
                                          button: true,
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const StudentRegisterScreen(),
                                                ),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: primary,
                                            ),
                                            child: Text(
                                              'Registrarse',
                                              style: TextStyle(
                                                fontFamily: fontGeneral,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_loading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(color: primary.withValues(alpha: 0.08)),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = context.read<UserProvider>();
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      final user = await AuthService().loginWithEmailAndPassword(
        email,
        password,
      );

      if (!mounted) return;

      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        setState(() => _loading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo obtener el usuario de Auth.'),
          ),
        );
        return;
      }

      if (!fbUser.emailVerified) {
        setState(() => _loading = false);

        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Verifica tu correo'),
            content: const Text(
              'Te enviamos un enlace de verificación a tu correo. '
              'Debes verificar tu email antes de ingresar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await fbUser.sendEmailVerification();
                    if (mounted) {
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Enlace reenviado.')),
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      Navigator.pop(context);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo reenviar el enlace.'),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Reenviar'),
              ),
            ],
          ),
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      try {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(fbUser.uid);
        final snap = await docRef.get();
        final already = (snap.data()?['welcomeSent'] ?? false) == true;

        if (!already) {
          final enviarBienvenida = FirebaseFunctions.instance.httpsCallable(
            'enviarCorreoBienvenida',
          );
          await enviarBienvenida.call({
            'email': user!.institutionalEmail,
            'nombres': user.firstName,
            'apellidos': user.lastName,
            'documento': user.documentNumber ?? '',
            'portalUrl': 'https://bitacorapedagogica.com/',
          });

          await docRef.set({'welcomeSent': true}, SetOptions(merge: true));
        }
      } catch (_) {
        // Si falla, no bloquea el login
      }

      userProvider.setUser(user!);

      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const AppRouter()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Evita el diálogo (usa messenger capturado para no tocar context con await)
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }
}
