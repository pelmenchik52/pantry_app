import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/data/mock_data.dart';
import '../../core/models/product.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/product_row.dart';
import '../../core/widgets/stat_card.dart';
import '../profile/profile_screen.dart';
import 'product_form.dart';

enum SortMode {
  expiry('За терміном'),
  name('За назвою'),
  category('За категорією');

  const SortMode(this.label);
  final String label;
}

enum _Mode { list, add, edit }

/// Головний екран: статистика, пошук, фільтри та список продуктів.
/// Дані — захардкоджені (MockData), без бекенду.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Product> _products = MockData.products();
  String _query = '';
  ProductCategory? _category;
  SortMode _sort = SortMode.expiry;
  _Mode _mode = _Mode.list;
  Product? _editing;

  // ---------- похідні дані ----------
  List<Product> get _visible {
    final q = _query.toLowerCase().trim();
    final list = _products.where((p) {
      final matchCat = _category == null || p.category == _category;
      final matchQuery = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.place.toLowerCase().contains(q);
      return matchCat && matchQuery;
    }).toList();

    switch (_sort) {
      case SortMode.expiry:
        list.sort((a, b) => a.expiry.compareTo(b.expiry));
      case SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case SortMode.category:
        list.sort((a, b) => a.category.label.compareTo(b.category.label));
    }
    return list;
  }

  int _count(ExpiryStatus s) => _products.where((p) => p.status == s).length;

  // ---------- дії ----------
  void _changeQty(Product p, int dir) {
    final step = quantityStep(p.unit);
    final next = math.max(0, p.quantity + dir * step);
    final rounded = double.parse(next.toStringAsFixed(2));
    _replace(p.copyWith(quantity: rounded));
  }

  void _replace(Product updated) {
    setState(() {
      final i = _products.indexWhere((p) => p.id == updated.id);
      if (i != -1) _products[i] = updated;
    });
  }

    Future<void> _delete(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Видалити продукт?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        content: Text(
          '«${p.name}» буде видалено зі списку.',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        actions: [
          OutlineAppButton(
            label: 'Скасувати',
            color: AppColors.muted,
            borderColor: AppColors.border,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          OutlineAppButton(
            label: 'Видалити',
            color: AppColors.danger,
            borderColor: const Color(0x66E5594F),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _products.removeWhere((x) => x.id == p.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('«${p.name}» видалено')),
    );
  }

  void _submitForm(Product p) {
    setState(() {
      if (_mode == _Mode.edit) {
        final i = _products.indexWhere((x) => x.id == p.id);
        if (i != -1) _products[i] = p;
      } else {
        _products.add(p);
      }
      _mode = _Mode.list;
      _editing = null;
    });
  }

  void _closeForm() => setState(() {
        _mode = _Mode.list;
        _editing = null;
      });

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 18),
                  _buildStats(),
                  const SizedBox(height: 16),
                  if (_mode == _Mode.list)
                    ..._buildListSection()
                  else
                    ProductForm(
                      key: ValueKey(_editing?.id ?? 'new'),
                      initial: _editing,
                      onSubmit: _submitForm,
                      onCancel: _closeForm,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏠 Домашня комора',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'ВІТАЄМО, ${MockData.userName.toUpperCase()} · '
                '${_products.length} ПОЗИЦІЙ',
                overflow: TextOverflow.ellipsis,
                style: AppTheme.mono.copyWith(
                  fontSize: 9,
                  letterSpacing: 1,
                  color: AppColors.dim,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlineAppButton(
          label: '+ Додати',
          onPressed: () => setState(() {
            _editing = null;
            _mode = _Mode.add;
          }),
        ),
        const SizedBox(width: 8),
        IconSquareButton(
          icon: Icons.person_outline,
          tooltip: 'Профіль',
          size: 38,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    const gap = SizedBox(width: 10);
    return Row(
      children: [
        Expanded(child: StatCard(value: _products.length, label: 'Всього')),
        gap,
        Expanded(
          child: StatCard(
              value: _count(ExpiryStatus.ok),
              label: 'Норма',
              color: AppColors.ok),
        ),
        gap,
        Expanded(
          child: StatCard(
              value: _count(ExpiryStatus.soon),
              label: 'Скоро',
              color: AppColors.warn),
        ),
        gap,
        Expanded(
          child: StatCard(
              value: _count(ExpiryStatus.expired),
              label: 'Прострочені',
              color: AppColors.danger),
        ),
      ],
    );
  }

  List<Widget> _buildListSection() {
    final items = _visible;
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Пошук за назвою або місцем...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: InputDecorator(
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SortMode>(
                  isExpanded: true,
                  isDense: true,
                  value: _sort,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(fontSize: 12, color: AppColors.text),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: AppColors.muted),
                  items: [
                    for (final s in SortMode.values)
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? _sort),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          CategoryChip(
            label: 'Всі',
            selected: _category == null,
            onTap: () => setState(() => _category = null),
          ),
          for (final c in ProductCategory.values)
            CategoryChip(
              label: '${c.emoji} ${c.label}',
              selected: _category == c,
              onTap: () => setState(() => _category = c),
            ),
        ],
      ),
      const SizedBox(height: 14),
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (wide) const ProductTableHeader(),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text(
                      'Нічого не знайдено. Змініть запит або фільтр.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                for (final p in items)
                  ProductRow(
                    key: ValueKey(p.id),
                    product: p,
                    wide: wide,
                    onDecrement: () => _changeQty(p, -1),
                    onIncrement: () => _changeQty(p, 1),
                    onEdit: () => setState(() {
                      _editing = p;
                      _mode = _Mode.edit;
                    }),
                    onDelete: () => _delete(p),
                  ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${items.length} з ${_products.length} позицій',
          style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.dim),
        ),
      ),
    ];
  }
}
