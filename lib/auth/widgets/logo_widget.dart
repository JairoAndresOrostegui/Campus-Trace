import 'package:flutter/material.dart';

class PublicLogoWidget extends StatelessWidget {
  final double? maxHeight; // alto máximo del logo en px

  const PublicLogoWidget({super.key, this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final targetHeight = maxHeight ?? 56;

    return Semantics(
      label: 'Logo de Bitácora Pedagógica',
      image: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 8),
        child: Image.asset(
          'assets/images/bp_logo.png',
          height: targetHeight,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
