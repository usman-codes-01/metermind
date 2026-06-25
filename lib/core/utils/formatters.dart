/// Formatting helpers so rupees and units look identical everywhere.
class Fmt {
  Fmt._();

  /// 9168 -> "9,168" (Pakistani/Indian short grouping kept simple as thousands).
  static String thousands(num value) {
    final isNeg = value < 0;
    final digits = value.abs().round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }

    return '${isNeg ? '-' : ''}$buffer';
  }

  /// 48217 -> "48,217" (the cumulative meter total).
  static String meter(int value) => thousands(value);

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// DateTime(2026, 6, 15) -> "15 Jun 2026".
  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// DateTime(2026, 6, 15) -> "15 Jun" (compact, for axis labels).
  static String dateShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// 40.0 -> "40", 49.5 -> "49.5" (drop the trailing ".0").
  static String perDay(double value) {
    final rounded = (value * 10).round() / 10;
    return rounded == rounded.roundToDouble()
        ? rounded.round().toString()
        : rounded.toString();
  }
}
