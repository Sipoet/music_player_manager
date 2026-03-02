import 'dart:math';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:music_player_manager/app_updater.dart';
import 'package:music_player_manager/clock.dart';
import 'package:music_player_manager/music_card.dart';
import 'package:music_player_manager/music_controller.dart';
import 'package:music_player_manager/music_player.dart';
import 'package:music_player_manager/playlist_card.dart';
import 'package:music_player_manager/scheduler_card.dart';
import 'package:music_player_manager/scheduler_form_dialog.dart';

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

  Future<Scheduler?> showScheduleForm(Scheduler scheduler) {
    return showDialog<Scheduler>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return SchedulerFormDialog(
          scheduler: scheduler,
          onSaved: (scheduler) => navigator.pop(scheduler),
          onCancel: (scheduler) => navigator.pop(null),
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
    for (final taskScheduler in taskSchedulers) {
      if (taskScheduler.datetime.isAfter(DateTime.now())) {
        continue;
      }
      musicController.play(taskScheduler.music);
      taskSchedulers.remove(taskScheduler);
      Future.delayed(Duration(seconds: 10), () {
        if (isTaskScheduleEmpty(taskScheduler.scheduler)) {
          setState(() {
            final scheduler = taskScheduler.scheduler;
            expiredScheduler(scheduler);
          });
        }
      });
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
                decoration: BoxDecoration(border: BoxBorder.all()),
                child: Column(
                  mainAxisSize: .min,
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
                      height: 250,
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
                    Flexible(
                      child: MusicPlayer(
                        controller: musicController,
                        playlist: currentPlaylist,
                      ),
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

class TestForm extends StatefulWidget {
  const TestForm({super.key});

  @override
  State<TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<TestForm>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const AlertDialog();
  }
}
