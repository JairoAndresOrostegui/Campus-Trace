import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> fRequestPermission() async {
  final messaging = FirebaseMessaging.instance;

  if (kIsWeb) {
    await messaging.requestPermission();
  } else {
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      // Permiso de notificaciones no concedido;
    }
  }
}

Future<void> saveUserFcmToken({
  required String userId,
  required String token,
}) async {
  final users = FirebaseFirestore.instance.collection('users');

  final dup = await users.where('fcmToken', isEqualTo: token).get();
  for (final d in dup.docs) {
    if (d.id != userId) {
      await d.reference.update({'fcmToken': FieldValue.delete()});
    }
  }

  await users.doc(userId).set({
    'fcmToken': token,
    'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
