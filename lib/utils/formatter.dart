import 'package:intl/intl.dart';

class Formatter {
  static final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _date = DateFormat('dd MMM yyyy', 'id_ID');
  static final _dateShort = DateFormat('dd/MM/yyyy');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');

  static String currency(double amount) => _currency.format(amount);
  static String date(DateTime date) => _date.format(date);
  static String dateShort(DateTime date) => _dateShort.format(date);
  static String monthYear(DateTime date) => _monthYear.format(date);

  static String bulanLabel(String bulan) {
    // bulan format YYYY-MM
    final parts = bulan.split('-');
    if (parts.length != 2) return bulan;
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return _monthYear.format(date);
  }
}
