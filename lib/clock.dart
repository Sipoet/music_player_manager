import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Clock extends StatefulWidget {
  final void Function(DateTime datetime)? onTimeChanged;
  final String format;
  const Clock({
    super.key,
    this.onTimeChanged,
    this.format = 'dd/MM/y hh:mm:ss',
  });

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  DateTime datetime = DateTime.now();
  String get _timeText => DateFormat(widget.format).format(datetime);

  @override
  void initState() {
    Stream.periodic(Duration(seconds: 1), (i) {
      return datetime.add(Duration(seconds: 1));
    }).listen(
      (date) => setState(() {
        datetime = date;
        widget.onTimeChanged?.call(datetime);
      }),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text('Time: $_timeText');
  }
}
