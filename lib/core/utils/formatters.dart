import 'package:intl/intl.dart';

/// Formatting helpers used across the app.
/// Keep logic out of widgets and controllers.
class Formatters {
  /// Currency formatter (default: USD).
  /// Tip: pass locale like "en_US" or "en_PK" if you want formatting per region.
  static String currency(
    num value, {
    String symbol = r'$',
    int decimalDigits = 0,
    String? locale,
  }) {
    final format = NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return format.format(value);
  }

  /// Compact currency: $12K, $1.2M
  static String compactCurrency(
    num value, {
    String symbol = r'$',
    String? locale,
    int decimalDigits = 0,
  }) {
    final format = NumberFormat.compactCurrency(
      locale: locale,
      symbol: symbol,
      decimalDigits: decimalDigits,
    );
    return format.format(value);
  }

  /// Number with separators: 12,345
  static String number(num value, {String? locale}) {
    return NumberFormat.decimalPattern(locale).format(value);
  }

  /// Date: 12 Mar 2025
  static String shortDate(DateTime date, {String? locale}) {
    return DateFormat('dd MMM yyyy', locale).format(date);
  }

  /// Date + time: 12 Mar 2025 - 10:30 AM
  static String dateTime(DateTime date, {String? locale}) {
    return DateFormat('dd MMM yyyy - hh:mm a', locale).format(date);
  }

  /// Month + year: March 2025
  static String monthYear(DateTime date, {String? locale}) {
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  /// Only time: 10:30 AM
  static String time(DateTime date, {String? locale}) {
    return DateFormat('hh:mm a', locale).format(date);
  }

  /// "2h ago", "3d ago" - great for dashboard recent activity.
  static String relative(DateTime date, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(date);

    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 2) return '1 min ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 2) return '1 hour ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 2) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return shortDate(date);
  }

  /// Capitalize first letter safely.
  static String capitalize(String text) {
    final t = text.trim();
    if (t.isEmpty) return t;
    return t[0].toUpperCase() + t.substring(1);
  }

  /// Title case (simple): "scope guard" -> "Scope Guard".
  static String titleCase(String text) {
    final t = text.trim();
    if (t.isEmpty) return t;
    return t
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : capitalize(w))
        .join(' ');
  }

  /// Safe int parsing (keeps UI clean).
  static int? tryInt(String? input) {
    if (input == null) return null;
    final t = input.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  /// Safe num parsing.
  static num? tryNum(String? input) {
    if (input == null) return null;
    final t = input.trim();
    if (t.isEmpty) return null;
    return num.tryParse(t);
  }
}
