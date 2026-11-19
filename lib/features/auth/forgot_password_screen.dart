import 'package:flutter/material.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../../core/widgets/status_banner.dart';
import 'data/auth_failure.dart';
import 'data/auth_repository.dart';
import 'email_sent_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _repo = AuthRepository.instance;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreen('forgot_password');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.sendPasswordResetEmail(email: _email.text);
      await AnalyticsService.instance.logEvent('password_reset_requested');
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const EmailSentScreen()),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            if (_error != null) ...[
              StatusBanner(_error!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Електронна пошта',
              hint: 'example@gmail.com',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              enabled: !_loading,
              validator: Validators.email,
              onFieldSubmitted: (_) => _send(),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Надіслати посилання',
              isLoading: _loading,
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
