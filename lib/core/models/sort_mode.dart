/// Режими сортування списку продуктів.
enum SortMode {
  expiry('За терміном'),
  name('За назвою'),
  category('За категорією');

  const SortMode(this.label);
  final String label;
}
