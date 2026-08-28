import 'package:campus_trace/auth/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el logo local de Bitácora Pedagógica', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PublicLogoWidget(maxHeight: 64))),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as AssetImage;

    expect(provider.assetName, 'assets/images/bp_logo.png');
    expect(image.height, 64);
    expect(
      find.bySemanticsLabel('Logo de Bitácora Pedagógica'),
      findsOneWidget,
    );
  });
}
