import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import 'data/auth_repository.dart';
import 'login_screen.dart';

/// Кореневий екран: залежно від стану Firebase Auth показує вхід або головну.
/// Саме тут відновлюється сеанс після перезапуску застосунку.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _repo = AuthRepository.instance;
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    // Побічні ефекти (аналітика, контекст Sentry) — поза build().
    _sub = _repo.authStateChanges().listen((user) {
      AnalyticsService.instance.setUser(user?.uid);
      Sentry.configureScope(
        (scope) => scope.setUser(
          user == null ? null : SentryUser(id: user.uid, email: user.email),
        ),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _repo.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('Відновлення сеансу…',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
          );
        }
        return snapshot.data == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}
