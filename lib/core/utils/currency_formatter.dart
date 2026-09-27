import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount, {
    String currency = 'FJD',
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'en_FJ',
      symbol: '$currency ',
      decimalDigits: decimalDigits,
    );

    return formatter.format(amount);
  }
}
