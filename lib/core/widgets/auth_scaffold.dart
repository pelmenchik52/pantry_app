import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Спільний каркас екранів авторизації: логотип + картка по центру.
class AuthScaffold extends StatelessWidget {
  final String? subtitle;
  final Widget child;

  const AuthScaffold({super.key, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 26)),
                  const SizedBox(height: 8),
                  const Text(
                    'Домашня комора',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!.toUpperCase(),
                      style: AppTheme.mono.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.5,
                        color: AppColors.dim,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppCard(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
