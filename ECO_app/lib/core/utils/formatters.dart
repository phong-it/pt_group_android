import 'package:intl/intl.dart';

class Formatters {
  static String money(num value) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'vn₫').format(value);
  }

  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

// static : one for all, one change -> all change
