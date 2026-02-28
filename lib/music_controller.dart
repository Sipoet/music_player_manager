import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_player_manager/models/music.dart';

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
