import 'package:intl/intl.dart';

class EthiopianCurrencyFormatter {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'am_ET',
    symbol: 'ETB',
    decimalDigits: 2,
  );

  static String format(num value) {
    return _currencyFormatter.format(value);
  }

  static String formatVolume(num value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toString();
  }
}
