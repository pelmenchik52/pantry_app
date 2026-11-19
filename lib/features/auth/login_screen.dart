import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/analytics_service.dart';
import '../../core/storage/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/google_sign_in_button.dart';
import '../../core/widgets/status_banner.dart';
import 'bloc/auth_bloc.dart';
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
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Остання використана пошта береться з локального сховища.
    _emailController =
        TextEditingController(text: context.read<AppPreferences>().lastEmail);
    context.read<AuthBloc>().add(const AuthFeedbackCleared());
    AnalyticsService.instance.logScreen('login');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (context.read<AuthBloc>().state.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<AuthBloc>().add(AuthSignInRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ));
  }

  void _loginWithGoogle() {
    if (context.read<AuthBloc>().state.isBusy) return;
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
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
      subtitle: 'облік продуктів',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Вхід до акаунту',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 18),
            if (auth.error != null) ...[
              StatusBanner(auth.error!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Електронна пошта',
              hint: 'example@gmail.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              enabled: !busy,
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
              enabled: !busy,
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
              isLoading: auth.operation == AuthOperation.signIn,
              onPressed: busy ? null : _login,
            ),
            const SizedBox(height: 14),
            const OrDivider(),
            const SizedBox(height: 14),
            GoogleSignInButton(
              isLoading: auth.operation == AuthOperation.google,
              onPressed: busy ? null : _loginWithGoogle,
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
