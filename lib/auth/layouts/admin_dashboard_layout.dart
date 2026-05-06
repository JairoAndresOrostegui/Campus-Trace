import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import 'dashboard_layout.dart';

class AdminDashboardLayout extends StatefulWidget {
  const AdminDashboardLayout({super.key});

  @override
  State<AdminDashboardLayout> createState() => _AdminDashboardLayoutState();
}

class _AdminDashboardLayoutState extends State<AdminDashboardLayout> {
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
    if (!(role == 'administrador')) return;

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
          route: '/admin_bitacora',
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
