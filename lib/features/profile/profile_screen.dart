import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../auth/login_screen.dart';

/// Профіль користувача: особисті дані, зміна пароля, вихід.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController(text: MockData.userName);
  final _email = TextEditingController(text: MockData.userEmail);
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const title = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
    const gap = SizedBox(height: 14);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Назад',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back,
                            size: 18, color: AppColors.muted),
                      ),
                      const Text('Профіль',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // --- Аватар ---
                  AppCard(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.input,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text('👤',
                              style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          MockData.userName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          MockData.userEmail,
                          textAlign: TextAlign.center,
                          style: AppTheme.mono.copyWith(
                              fontSize: 10, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Особисті дані ---
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Особисті дані', style: title),
                        const SizedBox(height: 16),
                        AppTextField(label: 'Ім’я', controller: _name),
                        gap,
                        AppTextField(
                          label: 'Електронна пошта',
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Зберегти',
                          fullWidth: false,
                          onPressed: () => _toast('Дані збережено'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // --- Зміна пароля ---
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Зміна пароля', style: title),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Поточний пароль',
                          hint: '••••••••',
                          controller: _current,
                          obscureText: true,
                        ),
                        gap,
                        AppTextField(
                          label: 'Новий пароль',
                          hint: 'Мінімум 6 символів',
                          controller: _new,
                          obscureText: true,
                        ),
                        gap,
                        AppTextField(
                          label: 'Підтвердження нового пароля',
                          hint: 'Повторіть пароль',
                          controller: _confirm,
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Змінити пароль',
                          fullWidth: false,
                          onPressed: () {
                            _current.clear();
                            _new.clear();
                            _confirm.clear();
                            _toast('Пароль змінено');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  OutlineAppButton(
                    label: 'Вийти з акаунту',
                    fullWidth: true,
                    color: AppColors.danger,
                    borderColor: const Color(0x66E5594F),
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
