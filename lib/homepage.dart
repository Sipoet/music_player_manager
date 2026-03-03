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
    initVersion();
    final player = AudioPlayer(playerId: Random(99999).toString());

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);
    musicController = MusicController(player);
    super.initState();
  }

  void fadeMusic(Duration changeDelay, Music music) {
    musicController.fadeDown(changeDelay).then((volume) {
      musicController.play(music);
      musicController.fadeUp(Duration(seconds: 3)).then((volume) {
        musicController.setVolume(1);
      });
    });
  }

  bool isChecked = false;
  void checkMusicSchedule() {
    if (isChecked) {
      return;
    }
    isChecked = true;
    for (final taskScheduler in taskSchedulers) {
      final scheduler = schedulers.firstWhere(
        (e) => e.id == taskScheduler.schedulerId,
      );
      if (taskScheduler.datetime.isAfter(DateTime.now()) ||
          scheduler.music == null) {
        continue;
      }
      if (scheduler.changeMode == .faded) {
        if (scheduler.changeDelay == null) {
          musicController.play(scheduler.music!);
        } else {
          fadeMusic(scheduler.changeDelay!, scheduler.music!);
        }
      } else if (scheduler.changeMode == .musicCompleted) {
        musicController.bookNextMusic = scheduler.music;
      }
      final result = taskSchedulers.remove(taskScheduler);
      debugPrint('result $result');
      if (isTaskScheduleEmpty(scheduler)) {
        setState(() {
          expiredScheduler(scheduler);
        });
      }
    }
    isChecked = false;
  }

  void expiredScheduler(Scheduler scheduler) {
    schedulers.remove(scheduler);
    scheduler.isExpired = true;
    schedulers.add(scheduler);
  }

  void removeTaskScheduler(Scheduler scheduler) {
    taskSchedulers.removeWhere((e) => e.schedulerId == scheduler.id);
  }

  double myVolume = 0;
  bool isTaskScheduleEmpty(Scheduler scheduler) =>
      taskSchedulers.where((e) => e.schedulerId == scheduler.id).isEmpty;
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
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Container(
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
                            Text(
                              'List Musik: ${currentPlaylist.name}',
                              style: labelStyle,
                              textAlign: .center,
                            ),
                            IconButton(
                              onPressed: addMusic,
                              icon: Icon(Icons.add),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
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
                              onPlayPressed: (music, controller) =>
                                  setState(() {
                                    currentPlaylist.currentIndex = index;
                                  }),
                            ),
                          ),
                        ),
                      ),
                      const Divider(),
                      SizedBox(
                        height: 150,
                        child: MusicPlayer(
                          controller: musicController,
                          playlist: currentPlaylist,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Container(
                      height: 350,
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
                          Expanded(
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
                      height: 350,
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
                          Expanded(
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
            ),
          ],
        ),
      ),
    );
  }
}
