import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Блок із повідомленням про помилку / успіх усередині картки.
class StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const StatusBanner(this.message, {super.key, this.isError = true});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.danger : AppColors.ok;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11, color: color, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
