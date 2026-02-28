import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:collection/collection.dart';

import 'package:intl/intl.dart';
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

class _MyHomePageState extends State<MyHomePage> {
  late final MusicController musicController;
  final currentPlaylist = Playlist(name: 'Main');
  DateTime datetime = DateTime.now();
  String get _timeText => DateFormat('d/MM/y hh:mm:ss').format(datetime);
  List<Scheduler> schedulers = [];
  List<Playlist> playlists = [];
  List<TaskScheduler> taskSchedulers = [];
  static const labelStyle = TextStyle(fontSize: 18, fontWeight: .bold);
  // List<Playlist> playslists = [];
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
  void showScheduleForm() {
    showDialog<Scheduler>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        Music? music;
        DateTime date = DateTime.now();
        TimeOfDay time = TimeOfDay.now();
        final dateController = TextEditingController(
          text: DateFormat.yMd().format(date),
        );
        final timeController = TextEditingController(
          text: time.format(context),
        );
        DateTimeRange period = DateTimeRange(
          start: date.beginningOfDay(),
          end: date.endOfDay(),
        );
        final dateRangeController = TextEditingController(
          text:
              "${DateFormat.yMd().format(period.start)} - ${DateFormat.yMd().format(period.end)}",
        );
        String? intervalMode;
        int? intervalNum;
        Set<int> weeks = {};

        String schedulerMode = 'sekali';
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
                      DropdownMenu<String>(
                        width: 250,
                        initialSelection: schedulerMode,
                        onSelected: (value) => setState(() {
                          schedulerMode = value ?? schedulerMode;
                        }),
                        dropdownMenuEntries:
                            ['sekali', 'interval', 'per minggu', 'per bulan']
                                .map<DropdownMenuEntry<String>>(
                                  (value) => DropdownMenuEntry(
                                    value: value,
                                    label: value,
                                  ),
                                )
                                .toList(),
                      ),
                      Visibility(
                        visible: schedulerMode != 'sekali',
                        child: TextFormField(
                          keyboardType: .datetime,
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
                        visible: schedulerMode == 'interval',
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
                        visible: [
                          'sekali',
                          'per bulan',
                        ].contains(schedulerMode),
                        child: SizedBox(
                          width: 250,
                          child: TextFormField(
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
                        visible: schedulerMode == 'per minggu',
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
                      SizedBox(
                        width: 250,
                        child: TextFormField(
                          keyboardType: .datetime,
                          controller: timeController,
                          decoration: InputDecoration(
                            label: Text(
                              schedulerMode == 'interval'
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
                                timeController.text = time.format(context);
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
                    datetime = datetime.copyWith(
                      hour: time.hour,
                      minute: time.minute,
                      second: 0,
                      microsecond: 0,
                      millisecond: 0,
                    );
                    Scheduler scheduler;
                    if (schedulerMode == 'sekali') {
                      scheduler = Scheduler(
                        music: music!,
                        startPeriod: datetime,
                        endPeriod: datetime,
                        mode: OnceSchedulerMode(datetime: datetime),
                      );
                    } else if (schedulerMode == 'interval') {
                      if (intervalNum == null || intervalMode == null) {
                        return;
                      }
                      scheduler = Scheduler(
                        music: music!,
                        startPeriod: period.start,
                        endPeriod: period.end,
                        mode: IntervalSchedulerMode(
                          startTime: time,
                          intervalMode: intervalMode!,
                          intervalNum: intervalNum!,
                        ),
                      );
                    } else if (schedulerMode == 'per bulan') {
                      scheduler = Scheduler(
                        music: music!,
                        startPeriod: period.start,
                        endPeriod: period.end,
                        mode: MonthSchedulerMode(time: time, day: datetime.day),
                      );
                    } else {
                      scheduler = Scheduler(
                        music: music!,
                        startPeriod: period.start,
                        endPeriod: period.end,
                        mode: WeekSchedulerMode(time: time, weeks: weeks),
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
    ).then((Scheduler? newScheduler) {
      if (newScheduler != null) {
        setState(() {
          schedulers.insert(0, newScheduler);
          taskSchedulers.addAll(newScheduler.generateTask());
        });
      }
    });
  }

  @override
  void dispose() {
    musicController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    final player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);

    musicController = MusicController(player);
    Stream.periodic(Duration(seconds: 1), (i) {
      datetime = datetime.add(Duration(seconds: 1));
      return datetime;
    }).listen(
      (date) => setState(() {
        datetime = date;
        if (datetime.second == 0) {
          checkMusicSchedule();
        }
      }),
    );
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
          schedulers.remove(scheduler);
          scheduler.isExpired = true;
          schedulers.add(scheduler);
        });
      }
    }
  }

  bool isTaskScheduleEmpty(Scheduler scheduler) =>
      taskSchedulers.where((e) => e.scheduler == scheduler).isEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

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
                      child: ListView.separated(
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
                          child: ListView(
                            children: playlists
                                .map<PlaylistCard>(
                                  (playlist) =>
                                      PlaylistCard(playlist: playlist),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text('Time: $_timeText'),
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
                                onPressed: showScheduleForm,
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        SizedBox(
                          height: 200,
                          child: ListView(
                            children: schedulers
                                .map<SchedulerCard>(
                                  (scheduler) =>
                                      SchedulerCard(scheduler: scheduler),
                                )
                                .toList(),
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
