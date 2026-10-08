enum ProductCategory {
  grains('Крупи та бобові', '🌾'),
  canned('Консерви', '🥫'),
  oils('Олії та соуси', '🫙'),
  flour('Борошно та цукор', '🥖'),
  drinks('Напої', '☕'),
  spices('Спеції', '🌿'),
  dairy('Молочне', '🧈'),
  frozen('Заморозка', '❄️');

  const ProductCategory(this.label, this.emoji);
  final String label;
  final String emoji;
}

enum ExpiryStatus { ok, soon, expired }

const List<String> kUnits = ['кг', 'г', 'л', 'мл', 'шт', 'пак'];

/// Скільки днів до закінчення терміну вважається статусом «Скоро».
const int kSoonDays = 7;

class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final String place;
  final double quantity;
  final String unit;
  final DateTime expiry;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.place,
    required this.quantity,
    required this.unit,
    required this.expiry,
  });

  /// Кількість днів до терміну (від’ємне — прострочено).
  int get daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(expiry.year, expiry.month, expiry.day);
    return exp.difference(today).inDays;
  }

  ExpiryStatus get status {
    final d = daysLeft;
    if (d < 0) return ExpiryStatus.expired;
    if (d <= kSoonDays) return ExpiryStatus.soon;
    return ExpiryStatus.ok;
  }

  Product copyWith({
    String? name,
    ProductCategory? category,
    String? place,
    double? quantity,
    String? unit,
    DateTime? expiry,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      place: place ?? this.place,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiry: expiry ?? this.expiry,
    );
  }
}
