import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/guards/admin_dashboard_guard.dart';
import 'auth/guards/student_dashboard_guard.dart';
import 'auth/guards/teacher_dashboard_guard.dart';
import 'auth/screens/access_denied_page.dart';
import 'auth/screens/login_screen.dart';
import 'features/screens/admin_bitacora_screen.dart';
import 'features/screens/form_builder_screen.dart';
import 'features/screens/form_fill_screen.dart';
import 'profile/screens/profile_screen.dart';
import 'providers/user_provider.dart';
import 'user/screens/admin_users_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de seguimiento academico',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Consumer<UserProvider>(
        builder: (context, usuarioProvider, child) {
          final usuario = usuarioProvider.user;

          if (usuario == null) {
            return const LoginScreen();
          }

          final initialRouteName = _routeByRol(usuario.role);

          return Navigator(
            initialRoute: initialRouteName,
            onGenerateRoute: (settings) {
              Widget page;
              switch (settings.name) {
                case '/profile':
                  page = const ProfileScreen();
                  break;
                case '/logout':
                  page = const _LogoutRedirect();
                  break;
                case '/access_denied':
                  page = const AccessDeniedPage();
                  break;
                case '/admin_dashboard':
                  page = const AdminDashboardGuard();
                  break;
                case '/admin_user':
                  page = const AdminUsersScreen();
                  break;
                case '/admin_bitacora':
                  page = const AdminBitacoraScreen();
                  break;
                case '/teacher_dashboard':
                  page = const TeacherDashboardGuard();
                  break;
                case '/bitacora_teacher':
                  page = const FormBuilderScreen();
                  break;
                case '/student_dashboard':
                  page = const StudentDashboardGuard();
                  break;
                case '/bitacora_student':
                  page = const FormFillScreen();
                  break;
                default:
                  page = const AccessDeniedPage();
                  break;
              }
              return MaterialPageRoute(
                builder: (context) => page,
                settings: settings,
              );
            },
          );
        },
      ),
    );
  }

  String _routeByRol(String? rol) {
    switch (rol) {
      case 'Administrador':
        return '/admin_dashboard';
      case 'Docente':
        return '/teacher_dashboard';
      case 'Estudiante':
        return '/student_dashboard';
      default:
        return '/access_denied';
    }
  }
}

class _LogoutRedirect extends StatefulWidget {
  const _LogoutRedirect();

  @override
  State<_LogoutRedirect> createState() => _LogoutRedirectState();
}

class _LogoutRedirectState extends State<_LogoutRedirect> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_logout);
  }

  Future<void> _logout() async {
    final up = context.read<UserProvider>();
    final navigator = Navigator.of(context);

    try {
      await up.logout();
    } finally {
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
