import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_player_manager/models/playlist.dart';
import 'package:music_player_manager/models/scheduler.dart';

class MusicController extends ChangeNotifier {
  final AudioPlayer player;

  MusicController(this.player);
  bool get isPause => player.state == PlayerState.paused;
  bool isPlay(Music music) => music.title == currentMusic?.title && isPlaying;
  Music? _currentMusic;
  Playlist _currentPlaylist = Playlist(name: 'Main');
  MusicRepeatMode repeatMode = .all;

  Music? get currentMusic => _currentMusic;
  TaskScheduler? taskScheduler;
  Playlist get currentPlaylist => _currentPlaylist;

  set currentPlaylist(Playlist playlist) {
    _currentPlaylist = playlist;
    notifyListeners();
  }

  @override
  void dispose() async {
    await player.stop();
    await player.dispose();
    super.dispose();
  }

  Future<void> setMusic(Music music) async {
    if (!isPlaying) {
      _currentMusic = music;
    }
    await player.setSource(music.source);
  }

  Future<void> setVolume(double volume) async {
    await player.setVolume(volume);
    notifyListeners();
  }

  Future<void> play(Music music) async {
    _currentMusic = music;
    if (isPlaying) {
      await player.stop();
    }
    await player.play(music.source, position: Duration.zero);
    notifyListeners();
    return;
  }

  Future<double> fadeDown(Duration changeDelay) {
    double volume = player.volume;
    int intervalDown = (changeDelay.inMilliseconds / (volume * 100)).round();
    var timer = Timer.periodic(Duration(milliseconds: intervalDown), (
      duration,
    ) {
      debugPrint('before volume:$volume ${player.volume}');
      volume -= 0.01;
      player.setVolume(volume);
      debugPrint('volume:$volume ${player.volume}');
    });
    return Future.delayed(changeDelay, () {
      timer.cancel();
      return player.volume;
    });
  }

  Future<double> fadeUp(Duration changeDelay) {
    double volume = player.volume;
    int intervalDown = (changeDelay.inMilliseconds / (volume * 100)).round();
    var timer = Timer.periodic(Duration(milliseconds: intervalDown), (
      duration,
    ) {
      debugPrint('before volume:$volume ${player.volume}');
      if (volume < 1) {
        volume += 0.01;
      }
      player.setVolume(volume);
      debugPrint('volume:$volume ${player.volume}');
    });
    return Future.delayed(changeDelay, () {
      timer.cancel();
      return player.volume;
    });
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
