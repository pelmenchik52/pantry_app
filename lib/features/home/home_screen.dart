import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/analytics_service.dart';
import '../../core/models/product.dart';
import '../../core/models/sort_mode.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/category_chip.dart';
import '../../core/widgets/product_row.dart';
import '../../core/widgets/stat_card.dart';
import '../auth/bloc/auth_bloc.dart';
import '../profile/profile_screen.dart';
import 'bloc/products_bloc.dart';
import 'product_form.dart';

enum _Mode { list, add, edit }

/// Головний екран: статистика, пошук, фільтри та список продуктів.
/// Дані й фільтри беруться зі стану [ProductsBloc]; у самому віджеті
/// лишається лише стан інтерфейсу (відкрита форма).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  _Mode _mode = _Mode.list;
  Product? _editing;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreen('home');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- дії (кожна просто надсилає подію в BLoC) ----------
  ProductsBloc get _bloc => context.read<ProductsBloc>();

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

    _bloc.add(ProductDeleted(p.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('«${p.name}» видалено')),
    );
  }

  void _submitForm(Product p) {
    _bloc.add(_mode == _Mode.edit ? ProductUpdated(p) : ProductAdded(p));
    setState(() {
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
    // Помилки збереження (з відкотом списку) показуємо snackbar-ом.
    return BlocListener<ProductsBloc, ProductsState>(
      listenWhen: (prev, curr) =>
          curr.error != null &&
          prev.error != curr.error &&
          curr.status != ProductsStatus.failure,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(state.error!))),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
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
                    _buildListSection()
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
              BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (prev, curr) => prev.user != curr.user,
                builder: (context, auth) =>
                    BlocBuilder<ProductsBloc, ProductsState>(
                  buildWhen: (prev, curr) =>
                      prev.products.length != curr.products.length,
                  builder: (context, state) => Text(
                    'ВІТАЄМО, '
                    '${(auth.user?.greetingName ?? 'користувач').toUpperCase()}'
                    ' · ${state.products.length} ПОЗИЦІЙ',
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.mono.copyWith(
                      fontSize: 9,
                      letterSpacing: 1,
                      color: AppColors.dim,
                    ),
                  ),
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
    return BlocBuilder<ProductsBloc, ProductsState>(
      buildWhen: (prev, curr) => prev.products != curr.products,
      builder: (context, state) => Row(
        children: [
          Expanded(
              child: StatCard(value: state.products.length, label: 'Всього')),
          gap,
          Expanded(
            child: StatCard(
                value: state.count(ExpiryStatus.ok),
                label: 'Норма',
                color: AppColors.ok),
          ),
          gap,
          Expanded(
            child: StatCard(
                value: state.count(ExpiryStatus.soon),
                label: 'Скоро',
                color: AppColors.warn),
          ),
          gap,
          Expanded(
            child: StatCard(
                value: state.count(ExpiryStatus.expired),
                label: 'Прострочені',
                color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection() {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        switch (state.status) {
          case ProductsStatus.initial:
          case ProductsStatus.loading:
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            );
          case ProductsStatus.failure:
            return _buildLoadError(state);
          case ProductsStatus.success:
            return _buildLoaded(state);
        }
      },
    );
  }

  Widget _buildLoadError(ProductsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text(
              state.error ?? 'Сталася помилка.',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            OutlineAppButton(
              label: 'Спробувати ще раз',
              onPressed: () => _bloc.add(const ProductsLoadRequested()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(ProductsState state) {
    final items = state.visibleProducts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (v) => _bloc.add(ProductsQueryChanged(v)),
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
                    value: state.sort,
                    dropdownColor: AppColors.surface,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.text),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.muted),
                    items: [
                      for (final s in SortMode.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (v) {
                      if (v != null) _bloc.add(ProductsSortChanged(v));
                    },
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
              selected: state.category == null,
              onTap: () => _bloc.add(const ProductsCategoryChanged(null)),
            ),
            for (final c in ProductCategory.values)
              CategoryChip(
                label: '${c.emoji} ${c.label}',
                selected: state.category == c,
                onTap: () => _bloc.add(ProductsCategoryChanged(c)),
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
                      onDecrement: () =>
                          _bloc.add(ProductQuantityChanged(p.id, -1)),
                      onIncrement: () =>
                          _bloc.add(ProductQuantityChanged(p.id, 1)),
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
            '${items.length} з ${state.products.length} позицій',
            style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.dim),
          ),
        ),
      ],
    );
  }
}
