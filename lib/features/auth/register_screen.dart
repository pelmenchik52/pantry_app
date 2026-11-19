import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/google_sign_in_button.dart';
import '../../core/widgets/status_banner.dart';
import 'bloc/auth_bloc.dart';

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
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>()..add(const AuthFeedbackCleared());
    AnalyticsService.instance.logScreen('register');
  }

  @override
  void dispose() {
    _authBloc.add(const AuthFeedbackCleared());
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // Після успішної реєстрації AuthGate сам показує головний екран
  // і закриває цей екран (див. listener в AuthGate).
  void _register() {
    if (_authBloc.state.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _authBloc.add(AuthSignUpRequested(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    ));
  }

  void _registerWithGoogle() {
    if (_authBloc.state.isBusy) return;
    _authBloc.add(const AuthGoogleSignInRequested(isSignUp: true));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, auth) => _buildForm(context, auth),
    );
  }

  Widget _buildForm(BuildContext context, AuthState auth) {
    final busy = auth.isBusy;
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
            if (auth.error != null) ...[
              StatusBanner(auth.error!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Ім’я',
              hint: 'Ваше ім’я',
              controller: _name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              enabled: !busy,
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
              enabled: !busy,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Пароль',
              hint: 'Мінімум 6 символів',
              controller: _password,
              obscureText: true,
              textInputAction: TextInputAction.next,
              enabled: !busy,
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Підтвердження пароля',
              hint: 'Повторіть пароль',
              controller: _confirm,
              obscureText: true,
              textInputAction: TextInputAction.done,
              enabled: !busy,
              validator: Validators.confirmPassword(() => _password.text),
              onFieldSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Створити акаунт',
              isLoading: auth.operation == AuthOperation.signUp,
              onPressed: busy ? null : _register,
            ),
            const SizedBox(height: 14),
            const OrDivider(),
            const SizedBox(height: 14),
            GoogleSignInButton(
              label: 'Зареєструватись через Google',
              isLoading: auth.operation == AuthOperation.google,
              onPressed: busy ? null : _registerWithGoogle,
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
