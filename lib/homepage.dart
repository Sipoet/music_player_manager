import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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

  void showScheduleForm() {
    showDialog(
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Schedule'),
              content: Column(
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
                  TextFormField(
                    keyboardType: .datetime,
                    controller: dateController,
                    decoration: InputDecoration(label: Text('Tanggal')),
                    onTap: () {
                      showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        currentDate: date,
                        lastDate: DateTime(2999),
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
                  TextFormField(
                    keyboardType: .datetime,
                    controller: timeController,
                    decoration: InputDecoration(label: Text('Tanggal')),
                    onTap: () {
                      showTimePicker(context: context, initialTime: time).then((
                        pickDate,
                      ) {
                        if (pickDate != null) {
                          time = pickDate;
                          timeController.text = time.format(context);
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    if (music == null) {
                      return;
                    }
                    datetime = datetime.copyWith(
                      hour: time.hour,
                      minute: time.minute,
                      second: 0,
                      microsecond: 0,
                      millisecond: 0,
                    );
                    final scheduler = Scheduler(
                      music: music!,
                      startPeriod: date,
                      endPeriod: date,
                      time: time,
                      repeatMode: .none,
                    );
                    schedulers.add(scheduler);
                    taskSchedulers.add(
                      TaskScheduler(
                        datetime: datetime,
                        music: music!,
                        scheduler: scheduler,
                      ),
                    );
                    navigator.pop();
                  },
                  child: Text('Tambah'),
                ),
                ElevatedButton(
                  onPressed: () => navigator.pop(),
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
    final player = AudioPlayer();

    // Set the release mode to keep the source after playback has completed.
    player.setReleaseMode(ReleaseMode.stop);

    musicController = MusicController(player);
    Stream timer = Stream.periodic(Duration(seconds: 1), (i) {
      datetime = datetime.add(Duration(seconds: 1));
      return datetime;
    });

    Stream.periodic(Duration(minutes: 1), (i) {
      return DateTime.now();
    }).listen((onData) {
      checkMusicSchedule();
    });
    timer.listen(
      (date) => setState(() {
        datetime = date;
      }),
    );
    super.initState();
  }

  void checkMusicSchedule() {
    for (final (int index, TaskScheduler taskScheduler)
        in taskSchedulers.indexed) {
      if (taskScheduler.datetime.isBefore(DateTime.now())) {
        musicController.play(taskScheduler.music);
        taskSchedulers.removeAt(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          children: [
            Container(
              child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                //
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                // action in the IDE, or press "p" in the console), to see the
                // wireframe for each widget.
                mainAxisAlignment: .center,
                children: [
                  Text('Musics', style: labelStyle),
                  Expanded(
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
                  MusicPlayer(
                    controller: musicController,
                    playlist: currentPlaylist,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
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
                        ...playlists.map<PlaylistCard>(
                          (playlist) => PlaylistCard(playlist: playlist),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text('Time: $_timeText'),
                  SizedBox(height: 5),
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
                              Text('Scheduler', style: labelStyle),
                              IconButton(
                                onPressed: showScheduleForm,
                                icon: Icon(Icons.add),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        ...schedulers.map<SchedulerCard>(
                          (scheduler) => SchedulerCard(scheduler: scheduler),
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
      floatingActionButton: FloatingActionButton(
        onPressed: addMusic,
        tooltip: 'add Music',
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum RepeatMode { none, hourly, daily, weekly, monthly }

class Scheduler {
  Set<int>? weeks;
  TimeOfDay? time;
  Duration? timeInterval;
  DateTime? startPeriod;
  DateTime? endPeriod;
  RepeatMode? repeatMode;
  Music music;
  Scheduler({
    this.time,
    this.startPeriod,
    this.endPeriod,
    required this.music,
    this.repeatMode = .none,
  });
}

class TaskScheduler {
  Scheduler scheduler;
  final DateTime datetime;
  Music music;
  TaskScheduler({
    required this.datetime,
    required this.music,
    required this.scheduler,
  });
}

class SchedulerCard extends StatelessWidget {
  final Scheduler scheduler;
  const SchedulerCard({super.key, required this.scheduler});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(scheduler.music.title),
      subtitle: Text(
        "${scheduler.repeatMode} - ${scheduler.time?.format(context)}",
      ),
    );
  }
}

class MusicPlayer extends StatefulWidget {
  final MusicController controller;
  final Playlist playlist;
  const MusicPlayer({
    super.key,
    required this.controller,
    required this.playlist,
  });

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  MusicController get controller => widget.controller;
  AudioPlayer get player => widget.controller.player;
  Music? get music => widget.controller.currentMusic;
  Playlist get playlist => widget.playlist;
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';
  @override
  void initState() {
    controller.addListener(() {
      setState(() {});
    });
    player.getDuration().then(
      (value) => setState(() {
        _duration = value;
      }),
    );
    player.getCurrentPosition().then(
      (value) => setState(() {
        _position = value;
      }),
    );
    _initStreams();
    super.initState();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _position = Duration.zero;
        if (playlist.hasNext) {
          playlist.next(controller);
        }
      });
    });

    _playerStateChangeSubscription = player.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: .spaceAround,
          spacing: 15,
          children: [
            IconButton(
              onPressed: playlist.hasPrevious
                  ? () => playlist.previous(controller)
                  : null,
              icon: Icon(Icons.skip_previous),
            ),
            IconButton(
              onPressed: () {
                controller.playOrPause().whenComplete(() {
                  setState(() {});
                });
              },
              icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              onPressed: () => setState(() {
                controller.stop();
              }),
              icon: Icon(Icons.stop),
            ),
            IconButton(
              onPressed: playlist.hasNext
                  ? () => playlist.next(controller)
                  : null,
              icon: Icon(Icons.skip_next),
            ),
          ],
        ),
        Slider(
          onChanged: (value) async {
            final duration = await controller.player.getDuration();
            if (duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            controller.seek(Duration(milliseconds: position.round()));
          },
          value:
              (_position != null &&
                  _duration != null &&
                  _position!.inMilliseconds > 0 &&
                  _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
              ? _durationText
              : '',
          style: const TextStyle(fontSize: 16.0),
        ),
      ],
    );
  }
}

class MusicCard extends StatefulWidget {
  final Music music;
  final void Function(Music music, MusicController controller)? onPlayPressed;
  final MusicController controller;
  const MusicCard({
    super.key,
    this.onPlayPressed,
    required this.music,
    required this.controller,
  });

  @override
  State<MusicCard> createState() => _MusicCardState();
}

class _MusicCardState extends State<MusicCard> {
  MusicController get controller => widget.controller;
  Music get music => widget.music;
  @override
  void initState() {
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: controller.isPlay(music)
          ? IconButton(
              onPressed: () => setState(() {
                controller.pause();
              }),
              icon: Icon(Icons.pause),
            )
          : IconButton(
              onPressed: () => setState(() {
                controller.play(music);
                widget.onPlayPressed?.call(music, controller);
              }),
              icon: Icon(Icons.play_arrow),
            ),
      title: Text(music.title),
      subtitle: Text(music.artist ?? ''),
    );
  }
}

class MusicController extends ChangeNotifier {
  final AudioPlayer player;

  MusicController(this.player);
  bool get isPause => player.state == PlayerState.paused;
  bool isPlay(Music music) => music.title == currentMusic?.title && isPlaying;
  Music? currentMusic;
  @override
  void dispose() async {
    await player.stop();
    await player.dispose();
    super.dispose();
  }

  Future<void> setMusic(Music music) async {
    await player.setSource(music.source);
    currentMusic = music;
  }

  Future<void> play(Music music) async {
    currentMusic = music;
    await player.play(music.source, position: Duration.zero);
    notifyListeners();
    return;
  }

  Future<void> pause() async {
    await player.pause();
    notifyListeners();
    return;
  }

  Future<void> seek(Duration duration) async {
    await player.seek(duration);
    notifyListeners();
    return;
  }

  Future<void> playOrPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await resume();
    }

    notifyListeners();
    return;
  }

  Future<void> resume() async {
    await player.resume();
    notifyListeners();
  }

  void stop() async {
    await player.pause();
    await player.seek(Duration.zero);
    notifyListeners();
  }

  bool get isPlaying => player.state == PlayerState.playing;
}

class Playlist {
  String name;
  List<Music> musics = [];
  int currentIndex;
  Playlist({this.name = '', this.currentIndex = -1, List<Music>? musics})
    : musics = musics ?? [];

  bool get hasNext => currentIndex + 1 < musics.length;
  bool get hasPrevious => currentIndex > 0;
  Future<Music?> next(MusicController controller) async {
    if (!hasNext) {
      return null;
    }
    currentIndex += 1;
    final music = musics[currentIndex];
    await controller.play(music);
    return music;
  }

  Music get currentMusic => musics[currentIndex];

  Future<Music?> previous(MusicController controller) async {
    if (!hasPrevious) {
      return null;
    }
    currentIndex -= 1;
    final music = musics[currentIndex];
    await controller.play(music);
    return music;
  }

  void addMusic(Music music) {
    musics.add(music);
    if (currentIndex <= -1) {
      currentIndex = 0;
    }
  }

  void removeMusic(Music music) {
    musics.remove(music);
    if (musics.isEmpty) {
      currentIndex = -1;
    }
  }

  void removeMusicAt(int index) {
    musics.removeAt(index);
    if (musics.isEmpty) {
      currentIndex = -1;
    }
  }
}

class Music {
  String title;
  Source source;
  String? artist;
  String? album;
  String? genre;
  String url;
  Music({
    required this.source,
    this.artist = '',
    this.title = '',
    this.url = '',
    this.album,
    this.genre,
  });
}

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  const PlaylistCard({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
