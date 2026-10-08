import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Основна кнопка (заливка акцентним кольором).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF1A1208),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Контурна кнопка. [color] дозволяє зробити, наприклад, червону «Вийти».
class OutlineAppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool fullWidth;
  final Color borderColor;

  const OutlineAppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.accent,
    this.borderColor = AppColors.accent,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Текстове посилання акцентного кольору.
class AppLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final double fontSize;

  const AppLink(this.text,
      {super.key, required this.onTap, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, color: AppColors.accent),
      ),
    );
  }
}

/// Квадратна кнопка-іконка (редагувати / видалити / профіль).
class IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;

  const IconSquareButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: size * 0.5, color: AppColors.muted),
        ),
      ),
    );
  }
}
