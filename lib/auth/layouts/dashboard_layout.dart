import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/theme_config.dart';
import '../../providers/user_provider.dart';
import '../../utils/color_utils.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

class DashboardLayout extends StatefulWidget {
  final List<MenuItemData> menuItems;
  const DashboardLayout({super.key, required this.menuItems});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  // Fallback si no viene desde ThemeProvider.config?.privacyUrl
  static const String url =
      'https://desarrolloytecnologiasantander.com/politica_privacidad_UDI.html';

  String hoveredRoute = '';
  bool hoveringCerrarSesion = false;
  bool hoveringPrivacy = false;

  Future<void> openPrivacy() async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la política de privacidad.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la política de privacidad.'),
        ),
      );
    }
  }

  void _navegar(String ruta) {
    Navigator.pushNamed(context, ruta);
  }

  Future<void> _cerrarSesion() async {
    final navigator = Navigator.of(context);

    try {
      final userProvider = context.read<UserProvider>();
      final user = userProvider.user;

      if (user != null) {
        await AuthService().logout(user);
        userProvider.clearUser();
      } else {
        await FirebaseAuth.instance.signOut();
      }
    } finally {
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  String _greetingBogota() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  Widget _greetingBanner(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final user = context.read<UserProvider>().user;
    final fullName = user == null
        ? 'usuario'
        : '${user.firstName} ${user.lastName}'.trim();
    final school = ThemeProvider.config?.nombre ?? 'tu institución';
    final greet = _greetingBogota();

    final isWide = MediaQuery.of(context).size.width >= 900 || kIsWeb;
    final fontGeneral = ThemeProvider.config?.fuenteGeneral;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.15)),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [primary.withValues(alpha: 0.06), Colors.white],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Semantics(
          header: true,
          label: '$greet, $fullName, te saluda el sistema de $school',
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isWide ? 20 : 16,
                color: Colors.black87,
                fontFamily: fontGeneral,
              ),
              children: [
                TextSpan(text: '$greet, '),
                TextSpan(
                  text: fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: primary,
                    fontFamily: fontGeneral,
                  ),
                ),
                const TextSpan(text: ', te saluda el sistema de '),
                TextSpan(
                  text: school,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: fontGeneral,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final bg =
        parseColor(ThemeProvider.config?.colorFondo) ??
        theme.colorScheme.surface;
    final fontGeneral = ThemeProvider.config?.fuenteGeneral;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(child: _greetingBanner(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // GRID con Wrap (responsive)
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWeb = kIsWeb;
                  final maxW = constraints.maxWidth;
                  final idealTileW = isWeb ? 200.0 : 170.0;
                  final crossAxisCount = (maxW / idealTileW)
                      .clamp(2, isWeb ? 6 : 4)
                      .floor();
                  final tileW = (maxW / crossAxisCount) - (isWeb ? 22 : 16);
                  final isMobile = MediaQuery.of(context).size.width < 600;
                  final double iconSize = isWeb
                      ? 54
                      : (maxW < 380
                            ? 22
                            : maxW < 600
                            ? 26
                            : 32);

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Wrap(
                        spacing: isWeb ? 20 : 14,
                        runSpacing: isWeb ? 24 : 18,
                        alignment: WrapAlignment.center,
                        children: widget.menuItems.map((item) {
                          final isHovered = hoveredRoute == item.route;
                          return MouseRegion(
                            onEnter: (_) =>
                                setState(() => hoveredRoute = item.route),
                            onExit: (_) => setState(() => hoveredRoute = ''),
                            cursor: SystemMouseCursors.click,
                            child: Semantics(
                              label: item.label,
                              button: true,
                              enabled: true,
                              focusable: true,
                              child: GestureDetector(
                                onTap: () => _navegar(item.route),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOut,
                                  width: tileW,
                                  padding: const EdgeInsets.all(14),
                                  transform: Matrix4.identity()
                                    ..scaleByDouble(
                                      isHovered ? 1.03 : 1.0,
                                      isHovered ? 1.03 : 1.0,
                                      1,
                                      1,
                                    ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: primary.withValues(alpha: 0.15),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        primary.withValues(alpha: 0.06),
                                        Colors.white,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isHovered ? 0.06 : 0.03,
                                        ),
                                        blurRadius: isHovered ? 12 : 6,
                                        offset: Offset(0, isHovered ? 6 : 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: iconSize,
                                        color: primary,
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.center,
                                          child: Text(
                                            item.label,
                                            textAlign: TextAlign.center,
                                            softWrap: false,
                                            maxLines: 1,
                                            style: TextStyle(
                                              fontSize: isMobile ? 14 : 15,
                                              fontWeight: isHovered
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: Colors.black87,
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
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Pie: Política + Cerrar sesión
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Política
                      MouseRegion(
                        onEnter: (_) => setState(() => hoveringPrivacy = true),
                        onExit: (_) => setState(() => hoveringPrivacy = false),
                        cursor: SystemMouseCursors.click,
                        child: Semantics(
                          label:
                              'Política de privacidad (se abrirá en el navegador)',
                          button: true,
                          enabled: true,
                          focusable: true,
                          child: GestureDetector(
                            onTap: openPrivacy,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              transform: Matrix4.identity()
                                ..scaleByDouble(
                                  hoveringPrivacy ? 1.02 : 1.0,
                                  hoveringPrivacy ? 1.02 : 1.0,
                                  1,
                                  1,
                                ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.15),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    primary.withValues(alpha: 0.06),
                                    Colors.white,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: hoveringPrivacy ? 0.06 : 0.03,
                                    ),
                                    blurRadius: hoveringPrivacy ? 12 : 6,
                                    offset: Offset(0, hoveringPrivacy ? 6 : 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 28,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Política de privacidad',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: fontGeneral,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Cerrar sesión
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => hoveringCerrarSesion = true),
                        onExit: (_) =>
                            setState(() => hoveringCerrarSesion = false),
                        cursor: SystemMouseCursors.click,
                        child: Semantics(
                          label: 'Cerrar sesión',
                          button: true,
                          enabled: true,
                          focusable: true,
                          child: GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('¿Deseas cerrar sesión?'),
                                  content: const Text(
                                    'Se cerrará tu sesión actual.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Cerrar sesión'),
                                    ),
                                  ],
                                ),
                              );
                              if (!mounted) return;
                              if (confirm == true) _cerrarSesion();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              transform: Matrix4.identity()
                                ..scaleByDouble(
                                  hoveringCerrarSesion ? 1.02 : 1.0,
                                  hoveringCerrarSesion ? 1.02 : 1.0,
                                  1,
                                  1,
                                ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.15),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    primary.withValues(alpha: 0.06),
                                    Colors.white,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: hoveringCerrarSesion ? 0.06 : 0.03,
                                    ),
                                    blurRadius: hoveringCerrarSesion ? 12 : 6,
                                    offset: Offset(
                                      0,
                                      hoveringCerrarSesion ? 6 : 2,
                                    ),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout, size: 28, color: primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Cerrar sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: fontGeneral,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }
}

class MenuItemData {
  final String label;
  final IconData icon;
  final String route;

  const MenuItemData({
    required this.label,
    required this.icon,
    required this.route,
  });
}
