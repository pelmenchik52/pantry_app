import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/status_banner.dart';
import 'bloc/auth_bloc.dart';
import 'email_sent_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = context.read<AuthBloc>()..add(const AuthFeedbackCleared());
    AnalyticsService.instance.logScreen('forgot_password');
  }

  @override
  void dispose() {
    _authBloc.add(const AuthFeedbackCleared());
    _email.dispose();
    super.dispose();
  }

  void _send() {
    if (_authBloc.state.isBusy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _authBloc.add(AuthPasswordResetRequested(_email.text));
  }

  @override
  Widget build(BuildContext context) {
    // Лист надіслано → показуємо екран підтвердження.
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => !prev.resetEmailSent && curr.resetEmailSent,
      listener: (context, state) => Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const EmailSentScreen()),
      ),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, auth) => _buildForm(context, auth),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthState auth) {
    final loading = auth.operation == AuthOperation.passwordReset;
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Відновлення пароля',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text(
              'Введіть вашу електронну пошту — ми надішлемо посилання для скидання пароля.',
              style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 14),
            if (auth.error != null) ...[
              StatusBanner(auth.error!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Електронна пошта',
              hint: 'example@gmail.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              enabled: !loading,
              validator: Validators.email,
              onFieldSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Надіслати посилання',
              isLoading: loading,
              onPressed: _send,
            ),
            const SizedBox(height: 14),
            Center(
              child: AppLink('← Назад до входу',
                  onTap: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}
