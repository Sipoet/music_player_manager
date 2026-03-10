import 'dart:math';
import 'package:flutter/material.dart';
import 'package:music_player_manager/models/music.dart';
export 'package:music_player_manager/models/music.dart';

class Playlist {
  String name;
  List<Music> musics = [];
  int currentIndex;
  Playlist({this.name = '', this.currentIndex = -1, List<Music>? musics})
    : musics = musics ?? [];

  bool get hasNext => currentIndex + 1 < musics.length;
  bool get hasPrevious => currentIndex > 0;
  Music? get currentMusic {
    if (currentIndex == -1 && musics.isNotEmpty) {
      currentIndex = 0;
    }
    return musics.elementAtOrNull(currentIndex);
  }

  Map asJson() {
    return {
      'name': name,
      'currentIndex': currentIndex,
      'musics': musics.map((music) => music.asJson()).toList(),
    };
  }

  factory Playlist.fromJson(Map json) {
    return Playlist(
      name: json['name'],
      currentIndex: json['currentIndex'],
      musics: (json['musics'] as List)
          .map<Music>((data) => Music.fromJson(data))
          .toList(),
    );
  }

  Future<Music?> next(RepeatMode mode) async {
    if (mode == .one) {
      return currentMusic;
    }
    if (mode == .disabled && !hasNext) {
      return null;
    }
    if (mode == .shuffle) {
      currentIndex = Random().nextInt(musics.length - 1);
    } else if (hasNext) {
      currentIndex += 1;
    } else {
      currentIndex = 0;
    }
    return musics[currentIndex];
  }

  Future<Music?> previous() async {
    if (!hasPrevious) {
      return null;
    }
    currentIndex -= 1;
    final music = musics[currentIndex];
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

enum RepeatMode {
  disabled,
  one,
  all,
  shuffle;

  @override
  String toString() => super.toString().split('.').last;

  static RepeatMode fromString(String value) {
    switch (value.trim()) {
      case 'disabled':
        return disabled;
      case 'one':
        return one;
      case 'all':
        return all;
      case 'shuffle':
        return shuffle;
      default:
        throw '$value is not valid repeat mode';
    }
  }

  String get humanize {
    switch (this) {
      case disabled:
        return 'Tidak berulang';
      case one:
        return 'Berulang 1 musik';
      case all:
        return 'Berulang semua musik';
      case shuffle:
        return 'acak';
    }
  }

  Icon get icon {
    switch (this) {
      case disabled:
        return Icon(Icons.repeat, color: Colors.grey);
      case one:
        return Icon(Icons.repeat_one);
      case all:
        return Icon(Icons.repeat);
      case shuffle:
        return Icon(Icons.shuffle);
    }
  }
}
