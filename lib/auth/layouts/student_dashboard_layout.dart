import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import 'dashboard_layout.dart';

class EstudianteDashboardLayout extends StatefulWidget {
  const EstudianteDashboardLayout({super.key});

  @override
  State<EstudianteDashboardLayout> createState() =>
      _EstudianteDashboardLayoutState();
}

class _EstudianteDashboardLayoutState extends State<EstudianteDashboardLayout> {
  List<MenuItemData> _menuItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildMenu();
    _listenNotifications();
  }

  void _listenNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final notif = message.notification;
      if (notif == null) return;
      final titulo = notif.title ?? 'Notificación';
      final cuerpo = notif.body ?? '';
      _showAlert(titulo, cuerpo);
    });
  }

  void _showAlert(String titulo, String cuerpo) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(titulo),
            content: Text(cuerpo),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _buildMenu() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    final perms = user.permissions!.map((e) => e.trim().toLowerCase()).toSet();

    final items = <MenuItemData>[
      const MenuItemData(
        label: 'Perfil',
        icon: Icons.person,
        route: '/profile',
      ),
    ];

    if (perms.contains('bitacora.ver')) {
      items.add(
        const MenuItemData(
          label: 'Bitacora',
          icon: Icons.edit_document,
          route: '/bitacora_student',
        ),
      );
    }

    if (!mounted) return;
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
