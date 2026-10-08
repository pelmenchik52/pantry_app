import '../models/product.dart';

/// Захардкоджені дані (без бекенду, див. завдання 4 методички).
class MockData {
  MockData._();

  static const String userName = 'vladyslav.andreiev.pz.2024';
  static const String userEmail = 'vladyslav.andreiev.pz.2024@lpnu.ua';

  static List<Product> products() => [
        _p('1', 'Гречка', ProductCategory.grains, 'Позиція 1', 2.5, 'кг', 2025, 9, 13),
        _p('2', 'Паприка', ProductCategory.spices, 'Позиція 4', 40, 'г', 2025, 9, 30),
        _p('3', 'Масло вершкове', ProductCategory.dairy, 'Холодильник', 0.4, 'кг', 2025, 10, 5),
        _p('4', 'Борошно пшеничне', ProductCategory.flour, 'Позиція 4', 3, 'кг', 2025, 10, 18),
        _p('5', 'Тунець в олії', ProductCategory.canned, 'Позиція 2', 4, 'шт', 2025, 11, 22),
        _p('6', 'Кава мелена', ProductCategory.drinks, 'Позиція 4', 0.25, 'кг', 2025, 12, 1),
        _p('7', 'Заморожена кукурудза', ProductCategory.frozen, 'Морозилка', 0.8, 'кг', 2026, 1, 15),
        _p('8', 'Чай чорний', ProductCategory.drinks, 'Позиція 3', 50, 'пак', 2026, 2, 28),
        _p('9', 'Рис довгозернистий', ProductCategory.grains, 'Позиція 1', 1.8, 'кг', 2026, 3, 20),
        _p('10', 'Соняшникова олія', ProductCategory.oils, 'Позиція 3', 2, 'л', 2026, 4, 12),
        _p('11', 'Чорний перець', ProductCategory.spices, 'Позиція 4', 80, 'г', 2026, 6, 10),
        _p('12', 'Горошок зелений', ProductCategory.canned, 'Позиція 2', 3, 'шт', 2026, 6, 30),
        _p('13', 'Оливкова олія', ProductCategory.oils, 'Позиція 3', 0.75, 'л', 2026, 9, 1),
        _p('14', 'Квасоля червона', ProductCategory.grains, 'Позиція 1', 0.5, 'кг', 2026, 11, 18),
        _p('15', 'Томати у власному соку', ProductCategory.canned, 'Позиція 2', 6, 'шт', 2027, 1, 6),
        _p('16', 'Цукор білий', ProductCategory.flour, 'Позиція 4', 4, 'кг', 2027, 12, 31),
      ];

  static Product _p(String id, String name, ProductCategory c, String place,
      double qty, String unit, int y, int m, int d) {
    return Product(
      id: id,
      name: name,
      category: c,
      place: place,
      quantity: qty,
      unit: unit,
      expiry: DateTime(y, m, d),
    );
  }
}
