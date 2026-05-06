import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/config/theme_config.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'utils/firebase_utils.dart';
import 'utils/push_bootstrap.dart';
import 'utils/push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Handler en segundo plano (Android)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    await ThemeProvider.cargarConfiguracion('UDI_campustrace');
  } catch (e) {
    debugPrint('⚠️ Error al cargar configuración: $e');
    ThemeProvider.config = ThemeConfig.fromMap({});
  }

  await fRequestPermission();

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const PushBootstrap(
        webVapidKey: 'BBMhl7ZfnUKsUYG3eIT0EQOZgLvoQ8vQjfqo06JNdP6ZtLrKjdvUkgFYO6kzmUs57N6zJry-IGRwfiXxBVmPYvg',
        child: AppRouter(),
      ),
    ),
  );
}
