import 'package:flutter/material.dart';

import '../../core/models/product.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';

/// Форма додавання / редагування продукту (замінює список на головному екрані).
class ProductForm extends StatefulWidget {
  final Product? initial;
  final ValueChanged<Product> onSubmit;
  final VoidCallback onCancel;

  const ProductForm({
    super.key,
    this.initial,
    required this.onSubmit,
    required this.onCancel,
  });

  bool get isEdit => initial != null;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _place;
  late final TextEditingController _qty;
  late final TextEditingController _expiry;
  late ProductCategory _category;
  late String _unit;
  DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _place = TextEditingController(text: p?.place ?? '');
    _qty = TextEditingController(text: p == null ? '' : formatQty(p.quantity));
    _category = p?.category ?? ProductCategory.grains;
    _unit = p?.unit ?? 'кг';
    _expiryDate = p?.expiry;
    _expiry = TextEditingController(
      text: p == null ? '' : formatDate(p.expiry),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _place.dispose();
    _qty.dispose();
    _expiry.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expiry.text = formatDate(picked);
      });
    }
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введіть назву продукту')),
      );
      return;
    }
    final qty = double.tryParse(_qty.text.trim().replaceAll(',', '.')) ?? 1;
    final id = widget.initial?.id ??
        DateTime.now().microsecondsSinceEpoch.toString();

    widget.onSubmit(Product(
      id: id,
      name: name,
      category: _category,
      place: _place.text.trim().isEmpty ? 'Не вказано' : _place.text.trim(),
      quantity: qty,
      unit: _unit,
      expiry: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final gap = const SizedBox(height: 14);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEdit ? 'Редагувати продукт' : 'Новий продукт',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          AppTextField(
            label: 'Назва продукту',
            hint: 'напр. Гречка',
            controller: _name,
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDropdownField<ProductCategory>(
                  label: 'Категорія',
                  value: _category,
                  items: [
                    for (final c in ProductCategory.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Місце зберігання',
                  hint: 'напр. Позиція 1',
                  controller: _place,
                ),
              ),
            ],
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Кількість',
                  controller: _qty,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppDropdownField<String>(
                  label: 'Одиниця виміру',
                  value: _unit,
                  items: [
                    for (final u in kUnits)
                      DropdownMenuItem(value: u, child: Text(u)),
                  ],
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                ),
              ),
            ],
          ),
          gap,
          AppTextField(
            label: 'Термін придатності',
            hint: 'дд.мм.рррр',
            controller: _expiry,
            readOnly: true,
            onTap: _pickDate,
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              PrimaryButton(
                label: widget.isEdit ? 'Зберегти' : 'Додати',
                fullWidth: false,
                onPressed: _submit,
              ),
              const SizedBox(width: 10),
              OutlineAppButton(
                label: 'Скасувати',
                color: AppColors.muted,
                borderColor: AppColors.border,
                onPressed: widget.onCancel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
