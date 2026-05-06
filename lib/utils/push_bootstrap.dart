import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../utils/push_notifications.dart';
import '../utils/firebase_utils.dart';

class PushBootstrap extends StatefulWidget {
  final Widget child;
  final String? webVapidKey;
  const PushBootstrap({super.key, required this.child, this.webVapidKey});

  @override
  State<PushBootstrap> createState() => _PushBootstrapState();
}

class _PushBootstrapState extends State<PushBootstrap> {
  String? _initedForUserId;

  Future<void> _ensureInitForUser(String userId) async {
    if (_initedForUserId == userId) return;
    _initedForUserId = userId;

    await initializePush(
      webVapidKey: widget.webVapidKey,
      onNewToken: (t) async {
        await saveUserFcmToken(userId: userId, token: t);
        if (mounted) {
          context.read<UserProvider>().updateFcmToken(t);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureInitForUser(user.id);
      });
    }
    return widget.child;
  }
}
