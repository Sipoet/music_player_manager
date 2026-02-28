import 'package:music_player_manager/models/music.dart';
import 'package:music_player_manager/music_controller.dart';

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
