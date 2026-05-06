import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import 'dashboard_layout.dart';

class DocenteDashboardLayout extends StatefulWidget {
  const DocenteDashboardLayout({super.key});

  @override
  State<DocenteDashboardLayout> createState() => _DocenteDashboardLayoutState();
}

class _DocenteDashboardLayoutState extends State<DocenteDashboardLayout> {
  List<MenuItemData> _menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildMenu();
  }

  void _buildMenu() {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final role = user.role.trim().toLowerCase();
    if (!(role == 'docente')) return;

    final perms = user.permissions!.map((e) => e.trim().toLowerCase()).toSet();

    final items = <MenuItemData>[
      const MenuItemData(
        label: 'Perfil',
        icon: Icons.person,
        route: '/profile',
      ),
    ];

    if (perms.contains('usuarios.ver')) {
      items.add(
        const MenuItemData(
          label: 'Gestión de usuarios',
          icon: Icons.group,
          route: '/admin_user',
        ),
      );
    }

    if (perms.contains('bitacora.ver')) {
      items.add(
        const MenuItemData(
          label: 'Bitacora',
          icon: Icons.edit_document,
          route: '/bitacora_teacher',
        ),
      );
    }

    setState(() {
      _menuItems = items;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Scaffold(
          body: SafeArea(
            child: Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          ),
        )
        : DashboardLayout(menuItems: _menuItems);
  }
}
