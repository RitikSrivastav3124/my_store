import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  static String format(num value) => _formatter.format(value);
}
