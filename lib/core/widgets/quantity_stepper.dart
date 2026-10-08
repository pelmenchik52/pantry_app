import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Лічильник кількості:  −  2.5 кг  +
class QuantityStepper extends StatelessWidget {
  final String text;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const QuantityStepper({
    super.key,
    required this.text,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(symbol: '−', onTap: onDecrement),
        Container(
          constraints: const BoxConstraints(minWidth: 62),
          alignment: Alignment.center,
          child: Text(
            text,
            style: AppTheme.mono.copyWith(fontSize: 12),
          ),
        ),
        _StepButton(symbol: '+', onTap: onIncrement),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final String symbol;
  final VoidCallback onTap;

  const _StepButton({required this.symbol, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: Text(
            symbol,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}
