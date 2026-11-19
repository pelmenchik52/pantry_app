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

/// Екран реєстрації з валідацією через Form.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _repo = AuthRepository.instance;

  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  bool get _busy => _loading || _googleLoading;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreen('register');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.signUp(
        email: _email.text,
        password: _password.text,
        displayName: _name.text,
      );
      await AnalyticsService.instance.logSignUp('password');
      // Користувач уже авторизований: AuthGate показує головний екран,
      // а цей екран (поверх нього в стеку) потрібно закрити.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    if (_busy) return;
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await _repo.signInWithGoogle();
      await AnalyticsService.instance.logSignUp('google');
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      if (mounted && !e.cancelled) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      subtitle: 'новий акаунт',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Реєстрація',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 18),
            if (_error != null) ...[
              StatusBanner(_error!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Ім’я',
              hint: 'Ваше ім’я',
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              enabled: !_busy,
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Електронна пошта',
              hint: 'example@gmail.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !_busy,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Пароль',
              hint: 'Мінімум 6 символів',
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.next,
              enabled: !_busy,
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Підтвердження пароля',
              hint: 'Повторіть пароль',
              controller: _confirm,
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !_busy,
              validator: Validators.confirmPassword(() => _password.text),
              onFieldSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Створити акаунт',
              isLoading: _loading,
              onPressed: _busy ? null : _register,
            ),
            const SizedBox(height: 14),
            const OrDivider(),
            const SizedBox(height: 14),
            GoogleSignInButton(
              label: 'Зареєструватись через Google',
              isLoading: _googleLoading,
              onPressed: _busy ? null : _registerWithGoogle,
            ),
            const SizedBox(height: 16),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Вже є акаунт? ',
                      style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  AppLink('Увійти',
                      onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
