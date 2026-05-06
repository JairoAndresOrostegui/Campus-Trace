import 'package:flutter/material.dart';
import '../../core/config/theme_config.dart';

class PublicLogoWidget extends StatelessWidget {
  final double? maxHeight; // alto máximo del logo en px

  const PublicLogoWidget({super.key, this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final logoUrl = ThemeProvider.config?.logoUrl;
    if (logoUrl == null || logoUrl.isEmpty) return const SizedBox.shrink();

    final targetHeight = maxHeight ?? 56;

    final Widget image = Image.network(
            logoUrl,
            height: targetHeight,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            loadingBuilder: (ctx, child, progress) =>
                progress == null
                    ? child
                    : const SizedBox(height: 40, width: 40, child: CircularProgressIndicator()),
          );

    return Semantics(
      label: 'Logo de la institución',
      image: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 8),
        child: image,
      ),
    );
  }
}
