import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import 'package:music_player_manager/app_updater.dart';
import 'package:music_player_manager/clock.dart';
import 'package:music_player_manager/music_card.dart';
import 'package:music_player_manager/music_controller.dart';
import 'package:music_player_manager/music_player.dart';
import 'package:music_player_manager/playlist_card.dart';
import 'package:music_player_manager/scheduler_card.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with AppUpdater {
  late final MusicController musicController;
  final currentPlaylist = Playlist(name: 'Main');

  List<Scheduler> schedulers = [];
  List<Playlist> playlists = [];
  List<TaskScheduler> taskSchedulers = [];
  final _schedulerScrollController = ScrollController();
  final _musicScrollController = ScrollController();
  final _playlistScrollController = ScrollController();
  static const labelStyle = TextStyle(fontSize: 18, fontWeight: .bold);

  void addMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: .audio,
      withReadStream: true,
      withData: true,
      dialogTitle: 'pilih musik',
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }
    setState(() {
      for (final file in result.files) {
        currentPlaylist.addMusic(
          Music(source: DeviceFileSource(file.path!), title: file.name),
        );
      }
      if (musicController.currentMusic == null) {
        musicController.setMusic(currentPlaylist.currentMusic);
      }
    });
  }

  final _formState = GlobalKey<FormState>();
  Future<Scheduler?> showScheduleForm(Scheduler scheduler) {
    return showDialog<Scheduler>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        Music? music = scheduler.music;
        DateTime datetime = DateTime.now();
        DateTime date = DateTime.now();
        TimeOfDay time = TimeOfDay.now();

        DateTimeRange period = DateTimeRange(
          start: scheduler.startPeriod,
          end: scheduler.endPeriod,
        );
        String? intervalMode;
        int? intervalNum;
        int day = 1;
        Set<int> weeks = {};
        final mode = scheduler.mode;
        EnumSchedulerMode schedulerMode = EnumSchedulerMode.fromMode(mode);
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
        final dateRangeController = TextEditingController(
          text:
              "${DateFormat.yMd().format(period.start)} - ${DateFormat.yMd().format(period.end)}",
        );
        final dateController = TextEditingController(
          text: DateFormat.yMd().format(date),
        );
        final timeController = TextEditingController(
          text: time.format(context),
        );

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Schedule'),
              content: SizedBox(
                width: 320,
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
                              FilePickerResult? result = await FilePicker
                                  .platform
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
                                music = Music(
                                  source: DeviceFileSource(file.path!),
                                  title: file.name,
                                );
                              });
                            },
                            child: Text('pilih musik'),
                          ),
                          Text(music?.title ?? '', overflow: .ellipsis),
                        ],
                      ),
                      Visibility(
                        visible: music == null,
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
                              initialDateRange: period,
                              firstDate: DateTime.now(),
                              currentDate: date,
                              lastDate: DateTime(9999),
                            ).then((pickDate) {
                              if (pickDate != null) {
                                period = pickDate;
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
                                    (value) => DropdownMenuEntry(
                                      value: value,
                                      label: value,
                                    ),
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
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
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
                                  dateController.text = DateFormat.yMd().format(
                                    date,
                                  );
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
                              schedulerMode == .interval
                                  ? 'Mulai Pukul'
                                  : 'Pukul',
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onTap: () {
                            showTimePicker(
                              context: context,
                              initialTime: time,
                            ).then((pickDate) {
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
                    if (music == null) {
                      return;
                    }
                    if (_formState.currentState?.validate() != true) {
                      return;
                    }
                    scheduler.music = music;
                    scheduler.startPeriod = period.start;
                    scheduler.endPeriod = period.end;
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
                      scheduler.mode = WeekSchedulerMode(
                        time: time,
                        weeks: weeks,
                      );
                    }
                    navigator.pop(scheduler);
                  },
                  child: Text('Tambah'),
                ),
                ElevatedButton(
                  onPressed: () => navigator.pop(null),
                  child: Text('batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    musicController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    final player = AudioPlayer(playerId: Random(99999).toString());

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);
    initVersion();
    musicController = MusicController(player);
    super.initState();
  }

  void checkMusicSchedule() {
    for (final (int index, TaskScheduler taskScheduler)
        in taskSchedulers.indexed) {
      if (taskScheduler.datetime.isAfter(DateTime.now())) {
        continue;
      }
      musicController.play(taskScheduler.music);
      taskSchedulers.removeAt(index);
      if (isTaskScheduleEmpty(taskScheduler.scheduler)) {
        setState(() {
          final scheduler = taskScheduler.scheduler;
          expiredScheduler(scheduler);
        });
      }
    }
  }

  void expiredScheduler(Scheduler scheduler) {
    schedulers.remove(scheduler);
    scheduler.isExpired = true;
    schedulers.add(scheduler);
  }

  void removeTaskScheduler(Scheduler scheduler) {
    taskSchedulers.removeWhere((e) => e.scheduler == scheduler);
  }

  bool isTaskScheduleEmpty(Scheduler scheduler) =>
      taskSchedulers.where((e) => e.scheduler == scheduler).isEmpty;
  final _menuController = MenuController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: MenuAnchor(
          controller: _menuController,
          menuChildren: [
            MenuItemButton(
              child: Text('Cek Versi Terbaru'),
              onPressed: () {
                checkUpdate();
                _menuController.close();
              },
            ),
            MenuItemButton(
              child: Text('Tentang'),
              onPressed: () {
                showVersion();
                _menuController.close();
              },
            ),
          ],

          child: IconButton(
            onPressed: () => _menuController.open(),
            icon: Icon(Icons.menu),
          ),
        ),
        title: Text(widget.title),
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(
                height: 600,
                decoration: BoxDecoration(border: BoxBorder.all()),
                child: Column(
                  mainAxisAlignment: .start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 5.0,
                        left: 10,
                        right: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text('Musics', style: labelStyle, textAlign: .center),
                          IconButton(
                            onPressed: addMusic,
                            icon: Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    SizedBox(
                      height: 350,
                      child: Scrollbar(
                        controller: _musicScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.separated(
                          controller: _musicScrollController,
                          itemCount: currentPlaylist.musics.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) => MusicCard(
                            controller: musicController,
                            music: currentPlaylist.musics[index],
                            onPlayPressed: (music, controller) => setState(() {
                              currentPlaylist.currentIndex = index;
                            }),
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    MusicPlayer(
                      controller: musicController,
                      playlist: currentPlaylist,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  Container(
                    height: 270,
                    decoration: BoxDecoration(border: Border.all()),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                            left: 10,
                            right: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Text('Playlist', style: labelStyle),
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        SizedBox(
                          height: 200,
                          child: Scrollbar(
                            thumbVisibility: true,
                            trackVisibility: true,
                            controller: _playlistScrollController,
                            child: ListView(
                              controller: _playlistScrollController,
                              children: playlists
                                  .map<PlaylistCard>(
                                    (playlist) =>
                                        PlaylistCard(playlist: playlist),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Clock(
                    onTimeChanged: (datetime) {
                      if (datetime.second == 0) {
                        checkMusicSchedule();
                      }
                    },
                  ),
                  SizedBox(height: 5),
                  Container(
                    height: 270,
                    decoration: BoxDecoration(border: Border.all()),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 5.0,
                            left: 10,
                            right: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Text('Scheduler', style: labelStyle),
                              IconButton(
                                onPressed: () {
                                  showScheduleForm(
                                    Scheduler(
                                      startPeriod: DateTime.now()
                                          .beginningOfDay(),
                                      endPeriod: DateTime.now().endOfDay(),
                                      mode: OnceSchedulerMode(
                                        datetime: DateTime.now(),
                                      ),
                                    ),
                                  ).then((Scheduler? newScheduler) {
                                    if (newScheduler != null) {
                                      setState(() {
                                        schedulers.insert(0, newScheduler);
                                        taskSchedulers.addAll(
                                          newScheduler.generateTask(),
                                        );
                                      });
                                    }
                                  });
                                },
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        SizedBox(
                          height: 200,
                          child: Scrollbar(
                            thumbVisibility: true,
                            trackVisibility: true,
                            controller: _schedulerScrollController,
                            child: ListView(
                              controller: _schedulerScrollController,
                              children: schedulers
                                  .map<SchedulerCard>(
                                    (scheduler) => SchedulerCard(
                                      scheduler: scheduler,
                                      onEdit: (scheduler) {
                                        final index = schedulers.indexOf(
                                          scheduler,
                                        );
                                        showScheduleForm(scheduler).then((
                                          Scheduler? newScheduler,
                                        ) {
                                          if (newScheduler != null) {
                                            setState(() {
                                              schedulers.setAll(index, [
                                                newScheduler,
                                              ]);
                                              removeTaskScheduler(scheduler);
                                              taskSchedulers.addAll(
                                                scheduler.generateTask(),
                                              );
                                            });
                                          }
                                        });
                                      },
                                      onDelete: (scheduler) => setState(() {
                                        schedulers.remove(scheduler);
                                        removeTaskScheduler(scheduler);
                                      }),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeHelper on DateTime {
  DateTime beginningOfDay() =>
      copyWith(hour: 0, microsecond: 0, minute: 0, second: 0, millisecond: 0);
  DateTime endOfDay() =>
      copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
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
