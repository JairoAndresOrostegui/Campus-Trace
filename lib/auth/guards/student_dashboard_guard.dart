import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/student_dashboard_layout.dart';
import '../../../providers/user_provider.dart';
import '../screens/access_denied_page.dart';
import '../screens/login_screen.dart';

class StudentDashboardGuard extends StatelessWidget {
  const StudentDashboardGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) return const LoginScreen();

    final role = user.role.trim().toLowerCase();
    final status = (user.status)!.trim().toLowerCase();
    final isActive = status == 'activo';
    final isAllowed = role == 'estudiante';

    if (!isAllowed || !isActive) return const AccessDeniedPage();

    return const EstudianteDashboardLayout();
  }
}
