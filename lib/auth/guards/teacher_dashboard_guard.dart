import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/teacher_dashboard_layout.dart';
import '../../../providers/user_provider.dart';
import '../screens/access_denied_page.dart';
import '../screens/login_screen.dart';

class TeacherDashboardGuard extends StatelessWidget {
  const TeacherDashboardGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const LoginScreen();

    final role = user.role.trim().toLowerCase();
    final status = (user.status)!.trim().toLowerCase();
    final isActive = status == 'activo';

    final canAccess = role == 'docente';
    if (!canAccess || !isActive) return const AccessDeniedPage();

    return const DocenteDashboardLayout();
  }
}
