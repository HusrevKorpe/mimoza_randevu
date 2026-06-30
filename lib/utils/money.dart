import 'package:intl/intl.dart';

/// Turkish Lira money helpers — single source for amount display + parsing.
///
/// Display uses tr_TR grouping ("." thousands, "," decimals): whole amounts
/// render without kuruş (₺1.500), fractional ones with two digits (₺1.500,50).
/// Parsing is tolerant of barber-typed input: "." is treated as a thousands
/// separator and dropped, "," as the decimal point — so "1.500" → 1500 and
/// "1.500,50" → 1500.5.

final NumberFormat _whole = NumberFormat('#,##0', 'tr_TR');
final NumberFormat _withCents = NumberFormat('#,##0.00', 'tr_TR');

/// Format [value] as Turkish Lira, e.g. `₺1.500` or `₺1.500,50`.
String formatTRY(double value) {
  final hasCents = value != value.roundToDouble();
  final body = (hasCents ? _withCents : _whole).format(value);
  return '₺$body';
}

/// Parse a user-typed amount into a positive double, or null if it isn't a
/// usable number. "." is a thousands separator (dropped), "," the decimal.
double? parseAmount(String raw) {
  final cleaned = raw
      .replaceAll('₺', '')
      .replaceAll(' ', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}
