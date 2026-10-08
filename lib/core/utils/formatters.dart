String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year}';
}

String formatQty(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  var s = v.toStringAsFixed(2);
  s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  return s;
}

/// Крок кнопок «+/−» залежно від одиниці виміру.
double quantityStep(String unit) {
  switch (unit) {
    case 'г':
    case 'мл':
      return 10;
    case 'шт':
    case 'пак':
      return 1;
    default:
      return 0.1;
  }
}
