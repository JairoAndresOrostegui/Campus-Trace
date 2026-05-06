import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';
import '../../utils/color_utils.dart';

class PublicTitleWidget extends StatelessWidget {
  const PublicTitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final title =
        ThemeProvider.config?.nombre ?? 'Sistema de seguimiento académico';
    final isWideWeb = kIsWeb && MediaQuery.of(context).size.width >= 900;

    final base = Theme.of(context).textTheme.displaySmall
        ?? Theme.of(context).textTheme.titleLarge;

    final color = parseColor(ThemeProvider.config?.colorTextoTitulo)
        ?? Theme.of(context).colorScheme.primary;

    final fontFamily = ThemeProvider.config?.fuenteTitulos ?? 'Paytone One';

    var style = base?.copyWith(
      fontFamily: fontFamily,
      color: color,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );

    if (isWideWeb) {
      final fs = style?.fontSize ?? 22;
      style = style?.copyWith(fontSize: fs * 1.8);
    }

    return Semantics(
      label: 'Nombre de la institución',
      header: true,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
