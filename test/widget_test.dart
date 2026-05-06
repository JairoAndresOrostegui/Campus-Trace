import 'package:campus_trace/app.dart';
import 'package:campus_trace/auth/screens/login_screen.dart';
import 'package:campus_trace/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AppRouter muestra LoginScreen cuando no hay usuario',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(),
        child: const AppRouter(),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
