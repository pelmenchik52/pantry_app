import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Круглий аватар: фото за HTTPS-посиланням або емодзі-заглушка.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const UserAvatar({super.key, this.photoUrl, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final fallback = Text('👤', style: TextStyle(fontSize: size * 0.4));
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.input,
        border: Border.all(color: AppColors.border),
      ),
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? fallback
          : Image.network(
              photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
    );
  }
}
