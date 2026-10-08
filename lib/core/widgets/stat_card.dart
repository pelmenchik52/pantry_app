import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

/// Картка зі статистикою на головному екрані (число + підпис).
class StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    this.color = AppColors.text,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: AppTheme.mono.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppTheme.mono.copyWith(
              fontSize: 9,
              letterSpacing: 1,
              color: AppColors.dim,
            ),
          ),
        ],
      ),
    );
  }
}
