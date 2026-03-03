import 'package:flutter/material.dart';
import 'package:music_player_manager/models/music.dart';
import 'package:music_player_manager/models/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

class SchedulerFormDialog extends StatefulWidget {
  final Scheduler scheduler;
  final void Function(Scheduler scheduler) onSaved;
  final void Function(Scheduler scheduler) onCancel;
  const SchedulerFormDialog({
    required this.scheduler,
    required this.onSaved,
    required this.onCancel,
    super.key,
  });

  @override
  State<SchedulerFormDialog> createState() => _SchedulerFormDialogState();
}

class _SchedulerFormDialogState extends State<SchedulerFormDialog> {
  Scheduler get scheduler => widget.scheduler;
  DateTime datetime = DateTime.now();
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  EnumSchedulerMode? schedulerMode;
  String? intervalMode;
  int? intervalNum;
  int day = 1;
  Set<int> weeks = {};
  final _formState = GlobalKey<FormState>();
  final dateRangeController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  late DateTimeRange period;
  bool isNewRecord = false;

  @override
  void initState() {
    if (scheduler.music == null) {
      isNewRecord = true;
    }
    period = DateTimeRange(
      start: scheduler.startPeriod,
      end: scheduler.endPeriod,
    );
    final mode = scheduler.mode;
    schedulerMode = EnumSchedulerMode.fromMode(mode);
    if (mode is OnceSchedulerMode) {
      datetime = mode.datetime;
      date = mode.datetime;
      time = TimeOfDay.fromDateTime(datetime);
    } else if (mode is IntervalSchedulerMode) {
      intervalMode = mode.intervalMode;
      intervalNum = mode.intervalNum;
      time = mode.startTime;
    } else if (mode is WeekSchedulerMode) {
      weeks = mode.weeks;
      time = mode.time;
    } else if (mode is MonthSchedulerMode) {
      day = mode.day;
      time = mode.time;
    }
    dateRangeController.text =
        "${DateFormat.yMd().format(period.start)} - ${DateFormat.yMd().format(period.end)}";

    dateController.text = DateFormat.yMd().format(date);
    timeController.text = time.format24Hour();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Jadwal'),
      content: SizedBox(
        width: 390,
        child: Form(
          key: _formState,
          child: Column(
            crossAxisAlignment: .start,
            spacing: 10,
            children: [
              Row(
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles(
                            type: .audio,
                            withReadStream: true,
                            withData: true,
                            dialogTitle: 'pilih musik',
                            allowMultiple: false,
                          );
                      if (result == null) {
                        return;
                      }
                      final file = result.files.first;
                      setState(() {
                        scheduler.music = Music(
                          sourceType: 'deviceFile',
                          path: file.path!,
                          title: file.name,
                        );
                      });
                    },
                    child: Text('pilih musik'),
                  ),
                  SizedBox(
                    width: 240,
                    child: Text(
                      scheduler.music?.title ?? '',
                      maxLines: 2,
                      overflow: .ellipsis,
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: scheduler.music == null,
                child: Text(
                  'Musik harus dipilih',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ),
              DropdownMenu<EnumSchedulerMode>(
                width: 250,
                initialSelection: schedulerMode,
                onSelected: (value) => setState(() {
                  schedulerMode = value ?? schedulerMode;
                }),
                dropdownMenuEntries: EnumSchedulerMode.values
                    .map<DropdownMenuEntry<EnumSchedulerMode>>(
                      (value) => DropdownMenuEntry(
                        value: value,
                        label: value.toString(),
                      ),
                    )
                    .toList(),
              ),
              Row(
                mainAxisAlignment: .start,
                spacing: 10,
                children: [
                  DropdownMenu<ChangeMode>(
                    width: 230,
                    initialSelection: scheduler.changeMode,
                    onSelected: (value) => setState(() {
                      scheduler.changeMode = value ?? scheduler.changeMode;
                    }),
                    label: Text('Mode Ganti'),
                    dropdownMenuEntries: ChangeMode.values
                        .map<DropdownMenuEntry<ChangeMode>>(
                          (value) => DropdownMenuEntry(
                            value: value,
                            label: value.humanize(),
                          ),
                        )
                        .toList(),
                  ),
                  Visibility(
                    visible: scheduler.changeMode == .faded,
                    child: SizedBox(
                      width: 120,
                      child: TextFormField(
                        decoration: InputDecoration(
                          label: Text('fade out(seconds)'),
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          FilteringTextInputFormatter.singleLineFormatter,
                        ],
                        keyboardType: .numberWithOptions(signed: false),
                        initialValue: scheduler.changeDelay?.inSeconds
                            .toString(),
                        validator: (value) {
                          final valNum = int.tryParse(value ?? '');
                          if (valNum == null) {
                            return 'tidak valid';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {
                          final delaySeconds = int.tryParse(value);
                          if (delaySeconds != null) {
                            scheduler.changeDelay = Duration(
                              seconds: delaySeconds,
                            );
                          }
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: schedulerMode != .once,
                child: TextFormField(
                  keyboardType: .datetime,
                  readOnly: true,
                  controller: dateRangeController,
                  decoration: InputDecoration(
                    label: Text('Tanggal Aktif'),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    showDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(
                        start: scheduler.startPeriod,
                        end: scheduler.endPeriod,
                      ),
                      firstDate: DateTime.now(),
                      currentDate: date,
                      lastDate: DateTime(9999),
                    ).then((pickDate) {
                      if (pickDate != null) {
                        scheduler.startPeriod = pickDate.start;
                        scheduler.endPeriod = pickDate.end;
                        dateController.text =
                            "${DateFormat.yMd().format(period.start)} -${DateFormat.yMd().format(period.end)} ";
                      }
                    });
                  },
                ),
              ),
              Visibility(
                visible: schedulerMode == .interval,
                child: Row(
                  children: [
                    DropdownMenu<String>(
                      label: Text('Diulang Setiap'),
                      width: 180,
                      initialSelection: intervalMode,
                      onSelected: (value) => setState(() {
                        intervalMode = value;
                      }),
                      enableFilter: true,
                      dropdownMenuEntries: ['jam', 'menit', 'hari']
                          .map<DropdownMenuEntry<String>>(
                            (value) =>
                                DropdownMenuEntry(value: value, label: value),
                          )
                          .toList(),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        decoration: InputDecoration(
                          label: Text('interval'),
                          border: OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          FilteringTextInputFormatter.singleLineFormatter,
                        ],
                        keyboardType: .numberWithOptions(signed: false),
                        initialValue: intervalNum?.toString(),
                        validator: (value) {
                          final valNum = int.tryParse(value ?? '');
                          if (valNum == null) {
                            return 'tidak valid';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {
                          intervalNum = int.tryParse(value);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: schedulerMode == .once,
                child: SizedBox(
                  width: 250,
                  child: TextFormField(
                    readOnly: true,
                    keyboardType: .datetime,
                    controller: dateController,
                    decoration: InputDecoration(
                      label: Text('Tanggal'),
                      border: OutlineInputBorder(),
                    ),
                    onTap: () {
                      showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        currentDate: date,
                        lastDate: DateTime(9999),
                      ).then((pickDate) {
                        if (pickDate != null) {
                          date = date.copyWith(
                            day: pickDate.day,
                            month: pickDate.month,
                            year: pickDate.year,
                          );
                          dateController.text = DateFormat.yMd().format(date);
                        }
                      });
                    },
                  ),
                ),
              ),

              Visibility(
                visible: schedulerMode == .perWeek,
                child: Wrap(
                  children:
                      [
                            'Senin',
                            'Selasa',
                            'Rabu',
                            'Kamis',
                            'Jumat',
                            'Sabtu',
                            'Minggu',
                          ]
                          .mapIndexed(
                            (index, value) => SizedBox(
                              width: 155,
                              child: CheckboxListTile(
                                title: Text(value),
                                titleAlignment: .center,
                                value: weeks.contains(index + 1),
                                onChanged: (value) {
                                  setState(() {
                                    value == true
                                        ? weeks.add(index + 1)
                                        : weeks.remove(index + 1);
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              Visibility(
                visible: schedulerMode == .perMonth,
                child: SizedBox(
                  width: 120,
                  child: TextFormField(
                    decoration: InputDecoration(
                      label: Text('Setiap Hari'),
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      FilteringTextInputFormatter.singleLineFormatter,
                    ],
                    keyboardType: .numberWithOptions(signed: false),
                    initialValue: day.toString(),
                    validator: (value) {
                      final valNum = int.tryParse(value ?? '');
                      if (valNum == null) {
                        return 'tidak valid';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {
                      day = int.tryParse(value) ?? day;
                    }),
                  ),
                ),
              ),
              SizedBox(
                width: 250,
                child: TextFormField(
                  readOnly: true,
                  keyboardType: .datetime,
                  controller: timeController,
                  decoration: InputDecoration(
                    label: Text(
                      schedulerMode == .interval ? 'Mulai Pukul' : 'Pukul',
                    ),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () {
                    showTimePicker(context: context, initialTime: time).then((
                      pickDate,
                    ) {
                      if (pickDate != null) {
                        time = pickDate;
                        timeController.text = time.format24Hour();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (scheduler.music == null) {
              return;
            }
            if (_formState.currentState?.validate() != true) {
              return;
            }
            if (scheduler.changeMode == .faded &&
                scheduler.changeDelay == null) {
              return;
            }
            if (schedulerMode == .once) {
              datetime = datetime.copyWith(
                hour: time.hour,
                minute: time.minute,
                second: 0,
                microsecond: 0,
                millisecond: 0,
              );
              scheduler.startPeriod = datetime;
              scheduler.endPeriod = datetime;
              scheduler.mode = OnceSchedulerMode(datetime: datetime);
            } else if (schedulerMode == .interval) {
              if (intervalNum == null || intervalMode == null) {
                return;
              }
              scheduler.mode = IntervalSchedulerMode(
                startTime: time,
                intervalMode: intervalMode!,
                intervalNum: intervalNum!,
              );
            } else if (schedulerMode == .perMonth) {
              scheduler.mode = MonthSchedulerMode(time: time, day: day);
            } else {
              scheduler.mode = WeekSchedulerMode(time: time, weeks: weeks);
            }
            widget.onSaved.call(scheduler);
          },
          child: Text(isNewRecord ? 'Tambah' : 'Ubah'),
        ),
        ElevatedButton(
          onPressed: () => widget.onCancel.call(scheduler),
          child: Text('batal'),
        ),
      ],
    );
  }
}

enum EnumSchedulerMode {
  once,
  interval,
  perWeek,
  perMonth;

  @override
  String toString() {
    switch (this) {
      case once:
        return 'sekali';
      case interval:
        return 'interval';
      case perWeek:
        return 'per minggu';
      case perMonth:
        return 'per bulan';
    }
  }

  static EnumSchedulerMode fromMode(SchedulerMode mode) {
    if (mode is OnceSchedulerMode) {
      return once;
    } else if (mode is IntervalSchedulerMode) {
      return interval;
    } else if (mode is WeekSchedulerMode) {
      return perWeek;
    } else if (mode is MonthSchedulerMode) {
      return perMonth;
    } else {
      return once;
    }
  }
}
