import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:music_player_manager/models/music.dart';
import 'package:uuid/uuid.dart';

abstract class SchedulerMode {
  List<TaskScheduler> generateTask(Scheduler scheduler);
  String get description;
  Map asJson();
}

class OnceSchedulerMode extends SchedulerMode {
  DateTime datetime;
  OnceSchedulerMode({required this.datetime});
  @override
  List<TaskScheduler> generateTask(Scheduler scheduler) {
    if (datetime.isBefore(DateTime.now())) {
      return [];
    }
    return [TaskScheduler(datetime: datetime, schedulerId: scheduler.id)];
  }

  @override
  Map asJson() => {'type': 'once', 'datetime': datetime.toIso8601String()};

  @override
  String get description => DateFormat('dd/MM/yyyy H:mm').format(datetime);
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
  Map asJson() => {
    'type': 'interval',
    'hour': startTime.hour,
    'minute': startTime.minute,
    'intervalMode': intervalMode,
    'intervalNum': intervalNum,
  };

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
      result.add(
        TaskScheduler(datetime: startPeriod, schedulerId: scheduler.id),
      );
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
        result.add(
          TaskScheduler(datetime: startPeriod, schedulerId: scheduler.id),
        );
      }
      startPeriod = startPeriod.add(Duration(days: 1));
    }
    return result;
  }

  @override
  Map asJson() => {
    'type': 'perWeek',
    'hour': time.hour,
    'minute': time.minute,
    'weeks': weeks.toList(),
  };

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
      result.add(
        TaskScheduler(datetime: startPeriod, schedulerId: scheduler.id),
      );
      startPeriod = startPeriod
          .copyWith(day: 4)
          .add(Duration(days: 28))
          .copyWith(day: day);
    }
    return result;
  }

  @override
  Map asJson() => {
    'type': 'perMonth',
    'hour': time.hour,
    'minute': time.minute,
    'day': day,
  };

  @override
  String get description => 'setiap tanggal $day pukul ${time.format24Hour()}';
}

extension TimeOfDayFormat on TimeOfDay {
  String format24Hour() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

enum ChangeMode {
  musicCompleted,
  faded;

  @override
  String toString() => super.toString().split('.').last;
  static ChangeMode fromString(String value) {
    if (value == 'musicCompleted') {
      return musicCompleted;
    } else {
      return faded;
    }
  }

  String humanize() =>
      this == musicCompleted ? 'Tunggu Musik Selesai' : 'langsung';
}

final uuid = Uuid();

class Scheduler {
  String id;
  DateTime startPeriod;
  DateTime endPeriod;
  SchedulerMode mode;
  Duration changeDelay;
  ChangeMode changeMode;
  Music? music;
  int loopCount;
  bool isExpired = false;
  Scheduler({
    required this.startPeriod,
    required this.endPeriod,
    this.changeDelay = const Duration(seconds: 0),
    this.loopCount = 1,
    this.changeMode = .faded,
    this.music,
    required this.mode,
  }) : id = uuid.v4();

  String get description => mode.description;
  List<TaskScheduler> generateTask() {
    return mode.generateTask(this);
  }

  Map asJson() {
    return {
      'startPeriod': startPeriod.toIso8601String(),
      'endPeriod': endPeriod.toIso8601String(),
      'changeDelaySeconds': changeDelay.inSeconds,
      'changeMode': changeMode.toString(),
      'music': music?.asJson(),
      'mode': mode.asJson(),
    };
  }

  factory Scheduler.fromJson(Map json) {
    return Scheduler(
      startPeriod: DateTime.parse(json['startPeriod']),
      endPeriod: DateTime.parse(json['endPeriod']),
      changeDelay: Duration(seconds: json['changeDelaySeconds'] ?? 0),
      changeMode: ChangeMode.fromString(json['changeMode']),
      music: Music.fromJson(json['music']),
      mode: schedulerModeFromJson(json['mode']),
    );
  }

  static SchedulerMode schedulerModeFromJson(Map json) {
    switch (json['type']) {
      case 'once':
        return OnceSchedulerMode(datetime: DateTime.parse(json['datetime']));
      case 'interval':
        return IntervalSchedulerMode(
          startTime: TimeOfDay(hour: json['hour'], minute: json['minute']),
          intervalNum: json['intervalNum'],
          intervalMode: json['intervalMode'],
        );
      case 'perWeek':
        return WeekSchedulerMode(
          weeks: (json['weeks'] as List<int>).toSet(),
          time: TimeOfDay(hour: json['hour'], minute: json['minute']),
        );
      case 'perMonth':
        return MonthSchedulerMode(
          day: json['day'],
          time: TimeOfDay(hour: json['hour'], minute: json['minute']),
        );
      default:
        throw 'not supported scheduler mode ${json['type']}';
    }
  }
}

class TaskScheduler {
  String schedulerId;
  final DateTime datetime;

  TaskScheduler({required this.datetime, required this.schedulerId});

  // Music? get music => scheduler.music;
}

extension DateTimeHelper on DateTime {
  DateTime beginningOfDay() =>
      copyWith(hour: 0, microsecond: 0, minute: 0, second: 0, millisecond: 0);
  DateTime endOfDay() =>
      copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
}
