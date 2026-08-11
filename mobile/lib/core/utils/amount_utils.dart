import 'package:intl/intl.dart';

int parseAmountToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round();
  return double.parse(value.toString()).round();
}

String formatXaf(int amount) {
  final formatter = NumberFormat('#,##0', 'en_US');
  return formatter.format(amount).replaceAll(',', ' ');
}