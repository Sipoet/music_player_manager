import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:music_player_manager/models/music.dart';

abstract class SchedulerMode {
  List<TaskScheduler> generateTask(Scheduler scheduler);
  String get description;
}

class OnceSchedulerMode extends SchedulerMode {
  DateTime datetime;
  OnceSchedulerMode({required this.datetime});
  @override
  List<TaskScheduler> generateTask(Scheduler scheduler) {
    if (datetime.isBefore(DateTime.now())) {
      return [];
    }
    return [TaskScheduler(datetime: datetime, scheduler: scheduler)];
  }

  @override
  String get description => DateFormat('dd/MM/yy hh:mm').format(datetime);
}

class IntervalSchedulerMode extends SchedulerMode {
  TimeOfDay startTime;
  String intervalMode;
  int intervalNum;
  IntervalSchedulerMode({
    required this.startTime,
    required this.intervalNum,
    required this.intervalMode,
  });

  Duration get interval {
    if (intervalMode == 'jam') {
      return Duration(hours: intervalNum);
    } else if (intervalMode == 'menit') {
      return Duration(minutes: intervalNum);
    } else {
      return Duration(days: intervalNum);
    }
  }

  @override
  List<TaskScheduler> generateTask(Scheduler scheduler) {
    List<TaskScheduler> result = [];
    final now = DateTime.now();
    DateTime startPeriod = [scheduler.startPeriod, now].max.copyWith(
      hour: startTime.hour,
      minute: startTime.minute,
      second: 0,
      microsecond: 0,
      millisecond: 0,
    );
    while (startPeriod.isBefore(scheduler.endPeriod)) {
      if (startPeriod.isBefore(now)) {
        startPeriod = startPeriod.add(interval);
        continue;
      }
      result.add(TaskScheduler(datetime: startPeriod, scheduler: scheduler));
      startPeriod = startPeriod.add(interval);
    }
    return result;
  }

  @override
  String get description =>
      'setiap $intervalNum $intervalMode mulai pukul ${startTime.format24Hour()}';
}

class WeekSchedulerMode extends SchedulerMode {
  Set<int> weeks;
  TimeOfDay time;
  WeekSchedulerMode({required this.weeks, required this.time});
  @override
  List<TaskScheduler> generateTask(Scheduler scheduler) {
    List<TaskScheduler> result = [];
    final now = DateTime.now();
    DateTime startPeriod = [scheduler.startPeriod, now].max.copyWith(
      hour: time.hour,
      minute: time.minute,
      second: 0,
      microsecond: 0,
      millisecond: 0,
    );
    if (startPeriod.isBefore(now)) {
      startPeriod = startPeriod.add(Duration(days: 1));
    }
    while (startPeriod.isBefore(scheduler.endPeriod)) {
      if (weeks.contains(startPeriod.weekday)) {
        result.add(TaskScheduler(datetime: startPeriod, scheduler: scheduler));
      }
      startPeriod = startPeriod.add(Duration(days: 1));
    }
    return result;
  }

  @override
  String get description =>
      'setiap hari $weekText pukul ${time.format24Hour()}';

  String get weekText {
    final weekNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    return weeks.map<String>((e) => weekNames[e - 1]).join(', ');
  }
}

class MonthSchedulerMode extends SchedulerMode {
  int day;
  TimeOfDay time;

  MonthSchedulerMode({required this.day, required this.time});

  @override
  List<TaskScheduler> generateTask(Scheduler scheduler) {
    List<TaskScheduler> result = [];
    final now = DateTime.now();
    DateTime startPeriod = [scheduler.startPeriod, now].max.copyWith(
      day: day,
      hour: time.hour,
      minute: time.minute,
      second: 0,
      microsecond: 0,
      millisecond: 0,
    );
    if (startPeriod.isBefore(now)) {
      startPeriod = startPeriod
          .copyWith(day: 4, month: now.month, year: now.year)
          .add(Duration(days: 28))
          .copyWith(day: day);
    }

    while (startPeriod.isBefore(scheduler.endPeriod)) {
      result.add(TaskScheduler(datetime: startPeriod, scheduler: scheduler));
      startPeriod = startPeriod
          .copyWith(day: 4)
          .add(Duration(days: 28))
          .copyWith(day: day);
    }
    return result;
  }

  @override
  String get description => 'setiap tanggal $day pukul ${time.format24Hour()}';
}

extension TimeOfDayFormat on TimeOfDay {
  String format24Hour() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

enum ChangeMode { afterPlayedMusic, faded }

class Scheduler {
  DateTime startPeriod;
  DateTime endPeriod;
  SchedulerMode mode;
  Duration? changeDelay;
  ChangeMode changeMode;
  Music? music;
  bool isExpired = false;
  Scheduler({
    required this.startPeriod,
    required this.endPeriod,
    this.changeDelay,
    this.changeMode = .faded,
    this.music,
    required this.mode,
  });

  String get description => mode.description;
  List<TaskScheduler> generateTask() {
    return mode.generateTask(this);
  }
}

class TaskScheduler {
  Scheduler scheduler;
  final DateTime datetime;

  TaskScheduler({required this.datetime, required this.scheduler});

  Music get music => scheduler.music!;
}

extension DateTimeHelper on DateTime {
  DateTime beginningOfDay() =>
      copyWith(hour: 0, microsecond: 0, minute: 0, second: 0, millisecond: 0);
  DateTime endOfDay() =>
      copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
}
