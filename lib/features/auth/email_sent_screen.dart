import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/auth_scaffold.dart';

class EmailSentScreen extends StatelessWidget {
  const EmailSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Лист надіслано',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 18),
          const Center(child: Text('📬', style: TextStyle(fontSize: 30))),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Перевірте вашу поштову скриньку. Ми надіслали посилання для скидання пароля.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Не отримали? Перевірте папку «Спам».',
              style: TextStyle(fontSize: 10, color: AppColors.dim),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Повернутись до входу',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}
