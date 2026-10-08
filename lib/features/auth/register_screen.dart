import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _register() {
    // Без бекенду: після «реєстрації» одразу відкриваємо головний екран.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      subtitle: 'новий акаунт',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Реєстрація',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 18),
          AppTextField(
              label: 'Ім’я', hint: 'Ваше ім’я', controller: _name),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Електронна пошта',
            hint: 'example@gmail.com',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Пароль',
            hint: 'Мінімум 6 символів',
            controller: _password,
            obscureText: true,
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Підтвердження пароля',
            hint: 'Повторіть пароль',
            controller: _confirm,
            obscureText: true,
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Створити акаунт', onPressed: _register),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Вже є акаунт? ',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
                AppLink('Увійти', onTap: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
