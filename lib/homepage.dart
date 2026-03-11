import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:music_player_manager/modules/app_updater.dart';
import 'package:music_player_manager/clock.dart';
import 'package:music_player_manager/music_card.dart';
import 'package:music_player_manager/modules/music_controller.dart';
import 'package:music_player_manager/music_player.dart';
import 'package:music_player_manager/playlist_card.dart';
import 'package:music_player_manager/scheduler_card.dart';
import 'package:music_player_manager/scheduler_form_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_manager/modules/custom_type.dart';
import 'package:music_player_manager/modules/music_converter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with AppUpdater, WidgetsBindingObserver, MusicConverter<MyHomePage> {
  late final MusicController musicController;

  List<Scheduler> schedulers = [];
  List<Playlist> playlists = [];
  List<TaskScheduler> taskSchedulers = [];

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
    storage
        .getString('repeatMode')
        .then(
          (value) => setState(() {
            if (value != null) {
              musicController.repeatMode = RepeatMode.fromString(value);
            }
          }),
        );
    storage.getStringList('playlists').then((data) {
      if (data == null) return;
      setState(() {
        playlists = data
            .map<Playlist>((json) => Playlist.fromJson(jsonDecode(json)))
            .toList();
      });
      storage.getString('currentPlaylistId').then((playlistId) {
        if (playlistId == null) return;
        setState(() {
          musicController.currentPlaylist =
              playlists.firstWhereOrNull(
                (playlist) => playlist.id == playlistId,
              ) ??
              musicController.currentPlaylist;
          if (musicController.currentPlaylist.currentMusic != null) {
            musicController.setMusic(
              musicController.currentPlaylist.currentMusic!,
            );
          }
        });
      });
    });

    final player = AudioPlayer(playerId: Random(99999).toString());

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);
    musicController = MusicController(player);
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  void setCurrentPlaylist(Playlist playlist) {
    if (playlist.musics.isNotEmpty &&
        musicController.currentPlaylist.id != playlist.id) {
      playlist.currentIndex = 0;
    }
    musicController.currentPlaylist = playlist;
  }

  void addPlaylist() {
    final playlist = Playlist();
    showPlaylistForm(playlist).then((value) {
      if (value != null) {
        setState(() {
          playlists.add(value);
        });
      }
    });
  }

  final _formState = GlobalKey<FormState>();
  Future<Playlist?> showPlaylistForm(Playlist playlist) {
    return showDialog(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        final beforeMusics = playlist.musics;
        final beforeName = playlist.name;
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text('Form Playlist'),
            content: SizedBox(
              width: 350,
              child: Center(
                child: Form(
                  key: _formState,
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: playlist.name,
                        onChanged: (value) => playlist.name = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'harus diisi';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: Text('Nama'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Align(
                        alignment: .topRight,
                        child: IconButton(
                          onPressed: () => addMusic(playlist).then(
                            (val) => setStateDialog(() {
                              playlist.musics;
                            }),
                          ),
                          icon: Icon(Icons.add),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: playlist.musics
                              .map(
                                (music) => MusicCard(
                                  music: music,
                                  controller: musicController,
                                  onDeletePressed: (music, controller) =>
                                      setStateDialog(
                                        () => playlist.removeMusic(music),
                                      ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_formState.currentState?.validate() == true) {
                    navigator.pop(playlist);
                  }
                },
                child: Text('Simpan'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  playlist.musics = beforeMusics;
                  playlist.name = beforeName;
                  navigator.pop();
                },
                child: Text('Batal'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future addMusic(Playlist playlist) async {
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

    for (final file in result.files) {
      final music = await convertFileToMusic(file);
      playlist.addMusic(music);
    }
    setState(() {
      playlist.musics;
    });
    if (musicController.currentMusic == null &&
        musicController.currentPlaylist.currentMusic != null) {
      musicController.setMusic(musicController.currentPlaylist.currentMusic!);
    }
  }

  Future<Scheduler?> showScheduleForm(Scheduler scheduler) {
    return showDialog<Scheduler>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        return SchedulerFormDialog(
          scheduler: scheduler,
          playlists: playlists,
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
    storage.setString('currentPlaylistId', musicController.currentPlaylist.id);
    storage.setString('repeatMode', musicController.repeatMode.toString());
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
        if (scheduler.playlist != null) {
          setState(() {
            setCurrentPlaylist(scheduler.playlist!);
          });
        }
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
    int index = musicController.currentPlaylist.musics.indexOf(music);
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
                              'Antrian Musik: ${musicController.currentPlaylist.name}',
                              style: labelStyle,
                              textAlign: .center,
                            ),
                            IconButton(
                              onPressed: () =>
                                  addMusic(musicController.currentPlaylist),
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
                            itemCount:
                                musicController.currentPlaylist.musics.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return Focus(
                                onFocusChange: (hasFocus) {
                                  // if (hasFocus) {
                                  debugPrint('has focus $hasFocus $index');

                                  // }
                                },
                                child: MusicCard(
                                  controller: musicController,
                                  music: musicController
                                      .currentPlaylist
                                      .musics[index],
                                  onPlayPressed: (music, controller) =>
                                      setState(() {
                                        musicController
                                                .currentPlaylist
                                                .currentIndex =
                                            index;
                                      }),
                                  onDeletePressed: (music, controller) =>
                                      setState(() {
                                        musicController.currentPlaylist
                                            .removeMusicAt(index);
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
                                  onPressed: addPlaylist,
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
                              child: ListView.separated(
                                controller: _playlistScrollController,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemCount: playlists.length,
                                itemBuilder: (context, index) => PlaylistCard(
                                  playlist: playlists[index],
                                  musicController: musicController,
                                  onDeletePressed: (playlist) => setState(() {
                                    playlists.remove(playlist);
                                  }),
                                  onPlayPressed: (playlist) => setState(() {
                                    setCurrentPlaylist(playlist);
                                    if (musicController
                                        .currentPlaylist
                                        .musics
                                        .isEmpty) {
                                      return;
                                    }
                                    musicController.play(
                                      musicController
                                          .currentPlaylist
                                          .currentMusic!,
                                    );
                                  }),
                                  onEditPressed: (playlist) =>
                                      showPlaylistForm(playlist).then((value) {
                                        if (value != null) {
                                          playlists[index] = value;
                                        }
                                      }),
                                ),
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
                        if (datetime.minute % 15 == 0) {
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
                                  Text('Jadwal', style: labelStyle),
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
