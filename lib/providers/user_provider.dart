import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/models/user.dart';
import '../auth/services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  void updateFcmToken(String token) {
    if (_user == null) return;
    if (_user!.fcmToken == token) return;
    _user = _user!.copyWith(fcmToken: token);
    notifyListeners();
  }

  Future<void> logout() async {
    final currentUser = _user;

    try {
      if (currentUser != null) {
        await AuthService().logout(currentUser);
      } else {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // ignorar errores de logout para no bloquear la UI
    } finally {
      clearUser();
    }
  }
}
