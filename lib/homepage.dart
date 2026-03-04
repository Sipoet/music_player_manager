import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AppUpdater, WidgetsBindingObserver {
  late final MusicController musicController;
  Playlist currentPlaylist = Playlist(name: 'Main');

  List<Scheduler> schedulers = [];
  List<Playlist> playlists = [];
  List<TaskScheduler> taskSchedulers = [];
  Map<int, FocusNode> focusNodes = {};

  final _schedulerScrollController = ScrollController();
  final _musicScrollController = ScrollController();
  final _playlistScrollController = ScrollController();
  static const labelStyle = TextStyle(fontSize: 18, fontWeight: .bold);
  final storage = SharedPreferencesAsync();
  @override
  void initState() {
    initVersion();
    storage.getStringList('schedulers').then((data) {
      if (data == null) return;
      setState(() {
        schedulers = data
            .map<Scheduler>((json) => Scheduler.fromJson(jsonDecode(json)))
            .toList();
      });

      for (final scheduler in schedulers) {
        taskSchedulers.addAll(scheduler.generateTask());
      }
    });
    storage.getStringList('playlists').then((data) {
      if (data == null) return;
      setState(() {
        playlists = data
            .map<Playlist>((json) => Playlist.fromJson(jsonDecode(json)))
            .toList();
      });
    });
    storage.getString('currentPlaylist').then((data) {
      if (data == null) return;
      setState(() {
        currentPlaylist = Playlist.fromJson(jsonDecode(data));
        if (currentPlaylist.currentMusic != null) {
          musicController.setMusic(currentPlaylist.currentMusic!);
        }
        for (int i = 0; i < currentPlaylist.musics.length; i++) {
          focusNodes[i] = FocusNode();
        }
      });
    });

    final player = AudioPlayer(playerId: Random(99999).toString());

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);
    musicController = MusicController(player);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

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
          Music(sourceType: 'deviceFile', path: file.path!, title: file.name),
        );
      }
      if (musicController.currentMusic == null &&
          currentPlaylist.currentMusic != null) {
        musicController.setMusic(currentPlaylist.currentMusic!);
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

  void saveValue() {
    storage.setStringList(
      'schedulers',
      schedulers
          .map<String>((scheduler) => jsonEncode(scheduler.asJson()))
          .toList(),
    );
    storage.setStringList(
      'playlists',
      playlists
          .map<String>((playlist) => jsonEncode(playlist.asJson()))
          .toList(),
    );
    storage.setString('currentPlaylist', jsonEncode(currentPlaylist.asJson()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == .detached || state == .hidden || state == .paused) {
      saveValue();
    }
  }

  @override
  void dispose() {
    saveValue();
    musicController.dispose();
    _musicScrollController.dispose();
    _playlistScrollController.dispose();
    _schedulerScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();

    debugPrint('dispose');
  }

  void fadeMusic(Duration changeDelay, Music music) {
    musicController.fadeDown(changeDelay).then((volume) {
      musicController.play(music).then((notData) {
        musicController.fadeUp(Duration(seconds: 1)).then((volume) {
          musicController.setVolume(1);
        });
      });
    });
  }

  bool isChecked = false;
  void checkMusicSchedule() {
    if (isChecked) {
      return;
    }
    isChecked = true;
    Future.delayed(Duration.zero, () {
      for (final taskScheduler in taskSchedulers) {
        final scheduler = schedulers.firstWhere(
          (e) => e.id == taskScheduler.schedulerId,
        );
        if (taskScheduler.datetime.isAfter(DateTime.now()) ||
            scheduler.music == null) {
          continue;
        }
        musicController.taskScheduler = taskScheduler;
        debugPrint('run task schedule');
        if (scheduler.changeMode == .faded) {
          if (scheduler.changeDelay.inMilliseconds == 0) {
            musicController.play(scheduler.music!);
          } else {
            fadeMusic(scheduler.changeDelay, scheduler.music!);
          }
          taskScheduler.loopCount -= 1;
        }
        final result = taskSchedulers.remove(taskScheduler);
        debugPrint('result $result');
        if (isTaskScheduleEmpty(scheduler)) {
          setState(() {
            expiredScheduler(scheduler);
          });
        }
      }
    }).whenComplete(
      () => setState(() {
        isChecked = false;
      }),
    );
  }

  void expiredScheduler(Scheduler scheduler) {
    schedulers.remove(scheduler);
    scheduler.isExpired = true;
    schedulers.add(scheduler);
  }

  void removeTaskScheduler(Scheduler scheduler) {
    taskSchedulers.removeWhere((e) => e.schedulerId == scheduler.id);
  }

  void focusOnMusicCard(Music music) {
    int index = currentPlaylist.musics.indexOf(music);
    debugPrint('index: $index');
    if (index >= 0) {
      _musicScrollController.animateTo(
        index * 74,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
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
                            itemBuilder: (context, index) {
                              return Focus(
                                focusNode: focusNodes[index],
                                onFocusChange: (hasFocus) {
                                  // if (hasFocus) {
                                  debugPrint('has focus $hasFocus $index');

                                  // }
                                },
                                child: MusicCard(
                                  controller: musicController,
                                  music: currentPlaylist.musics[index],
                                  onPlayPressed: (music, controller) =>
                                      setState(() {
                                        currentPlaylist.currentIndex = index;
                                      }),
                                  onDeletePressed: (music, controller) =>
                                      setState(() {
                                        currentPlaylist.removeMusicAt(index);
                                      }),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Divider(),
                      SizedBox(
                        height: 150,
                        child: MusicPlayer(
                          controller: musicController,
                          playlist: currentPlaylist,
                          onNextMusic: (music) => focusOnMusicCard(music),
                          onPrevMusic: (music) => focusOnMusicCard(music),
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
                      height: 250,
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
                        if (datetime.second == 1) {
                          checkMusicSchedule();
                        }
                        if (datetime.minute == 0) {
                          saveValue();
                        }
                      },
                    ),
                    SizedBox(height: 5),
                    Expanded(
                      child: Container(
                        // height: 250,
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
                                      .sorted(
                                        (a, b) =>
                                            b.updatedAt.compareTo(a.updatedAt),
                                      )
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
                                                  isChecked = true;
                                                  Future.delayed(
                                                    Duration.zero,
                                                    () {
                                                      removeTaskScheduler(
                                                        scheduler,
                                                      );
                                                      taskSchedulers.addAll(
                                                        scheduler
                                                            .generateTask(),
                                                      );
                                                      setState(() {
                                                        isChecked = false;
                                                      });
                                                    },
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
