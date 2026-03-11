import 'package:intl/intl.dart';

extension DateTimeHelper on DateTime {
  DateTime beginningOfDay() =>
      copyWith(hour: 0, microsecond: 0, minute: 0, second: 0, millisecond: 0);
  DateTime endOfDay() =>
      copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);

  String format({String pattern = 'dd/MM/y H:mm'}) =>
      DateFormat(pattern).format(this);
}
