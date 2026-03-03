import 'package:audioplayers/audioplayers.dart';

class Music {
  String title;

  String? artist;
  String? album;
  String? genre;
  String path;
  int loopCount;
  int playedCount;
  String sourceType;
  Music({
    required this.sourceType,
    required this.path,
    this.loopCount = 1,
    this.artist = '',
    this.title = '',
    this.album,
    this.genre,
  }) : playedCount = loopCount;

  Map asJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'sourceType': sourceType,
      'path': path,
      'loopCount': loopCount,
    };
  }

  Source get source {
    switch (sourceType) {
      case 'deviceFile':
        return DeviceFileSource(path);
      case 'remote':
        return UrlSource(path);
      default:
        throw 'unsupported source type $sourceType';
    }
  }

  factory Music.fromJson(Map json) {
    return Music(
      path: json['path'],
      sourceType: json['sourceType'],
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      genre: json['genre'],
      loopCount: json['loopCount'] ?? 1,
    );
  }
}
