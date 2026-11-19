import 'package:flutter/material.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/google_sign_in_button.dart';
import '../../core/widgets/status_banner.dart';
import 'data/auth_failure.dart';
import 'data/auth_repository.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Екран входу (email/пароль + Google).
/// Після успішного входу AuthGate сам замінить цей екран на головний.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repo = AuthRepository.instance;

  bool _loading = false; // блокує повторне надсилання
  bool _googleLoading = false;
  String? _error;

  bool get _busy => _loading || _googleLoading;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreen('login');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await AnalyticsService.instance.logLogin('password');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_busy) return;
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await _repo.signInWithGoogle();
      await AnalyticsService.instance.logLogin('google');
    } on AuthFailure catch (e) {
      if (mounted && !e.cancelled) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      subtitle: 'облік продуктів',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вхід до акаунту',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 18),
            if (_error != null) ...[
              StatusBanner(_error!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Електронна пошта',
              hint: 'example@gmail.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !_busy,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Пароль',
              hint: '••••••••',
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !_busy,
              validator: Validators.passwordRequired,
              onFieldSubmitted: (_) => _login(),
              trailingLabel: AppLink(
                'Забули?',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Увійти',
              isLoading: _loading,
              onPressed: _busy ? null : _login,
            ),
            const SizedBox(height: 14),
            const OrDivider(),
            const SizedBox(height: 14),
            GoogleSignInButton(
              isLoading: _googleLoading,
              onPressed: _busy ? null : _loginWithGoogle,
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Немає акаунту? ',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  AppLink(
                    'Зареєструватись',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
