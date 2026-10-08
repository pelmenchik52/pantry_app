import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_buttons.dart';
import 'quantity_stepper.dart';

Color statusColor(ExpiryStatus s) {
  switch (s) {
    case ExpiryStatus.ok:
      return AppColors.ok;
    case ExpiryStatus.soon:
      return AppColors.warn;
    case ExpiryStatus.expired:
      return AppColors.danger;
  }
}

/// Пропорції колонок таблиці (спільні для шапки та рядків).
class _Cols {
  static const int name = 3, category = 3, qty = 3, expiry = 3, place = 2;
  static const double actions = 72;
}

/// Шапка таблиці (показується лише на широких екранах).
class ProductTableHeader extends StatelessWidget {
  const ProductTableHeader({super.key});

  Widget _h(String t, int flex) => Expanded(
        flex: flex,
        child: Text(
          t,
          style: AppTheme.mono.copyWith(
            fontSize: 9,
            letterSpacing: 1,
            color: AppColors.dim,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _h('ПРОДУКТ', _Cols.name),
          _h('КАТЕГОРІЯ', _Cols.category),
          _h('КІЛЬКІСТЬ', _Cols.qty),
          _h('ТЕРМІН', _Cols.expiry),
          _h('МІСЦЕ', _Cols.place),
          const SizedBox(width: _Cols.actions),
        ],
      ),
    );
  }
}

/// Рядок / картка продукту у списку.
class ProductRow extends StatelessWidget {
  final Product product;
  final bool wide;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductRow({
    super.key,
    required this.product,
    required this.wide,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _dot() => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: statusColor(product.status),
        ),
      );

  Widget _name() => Row(
        children: [
          _dot(),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              product.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      );

  Widget _category() => Text(
        '${product.category.emoji} ${product.category.label}',
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      );

  Widget _qty() => QuantityStepper(
        text: '${formatQty(product.quantity)} ${product.unit}',
        onDecrement: onDecrement,
        onIncrement: onIncrement,
      );

  Widget _expiry({CrossAxisAlignment align = CrossAxisAlignment.start}) {
    final color = statusColor(product.status);
    final days = product.daysLeft;
    final sub = days < 0 ? 'прострочено ${-days}д' : 'ще ${days}д';
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatDate(product.expiry),
          style: AppTheme.mono.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          sub,
          style: AppTheme.mono.copyWith(
            fontSize: 9,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _place() => Text(
        product.place,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: AppColors.muted),
      );

  Widget _actions() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconSquareButton(
            icon: Icons.edit_outlined,
            tooltip: 'Редагувати',
            size: 28,
            onPressed: onEdit,
          ),
          const SizedBox(width: 6),
          IconSquareButton(
            icon: Icons.close,
            tooltip: 'Видалити',
            size: 28,
            onPressed: onDelete,
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(flex: _Cols.name, child: _name()),
            Expanded(flex: _Cols.category, child: _category()),
            Expanded(
              flex: _Cols.qty,
              child: Align(alignment: Alignment.centerLeft, child: _qty()),
            ),
            Expanded(flex: _Cols.expiry, child: _expiry()),
            Expanded(flex: _Cols.place, child: _place()),
            SizedBox(
              width: _Cols.actions,
              child: Align(alignment: Alignment.centerRight, child: _actions()),
            ),
          ],
        ),
      );
    }

    // Компактний вигляд для вузьких екранів (мобільний браузер).
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _name()),
              _actions(),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _category()),
              _place(),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _qty(),
              _expiry(align: CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }
}
