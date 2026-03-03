import 'package:audioplayers/audioplayers.dart';

class Music {
  String title;

  String? artist;
  String? album;
  String? genre;
  String path;
  String sourceType;
  Music({
    required this.sourceType,
    required this.path,
    this.artist = '',
    this.title = '',
    this.album,
    this.genre,
  });

  Map asJson() {
    return {
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'sourceType': sourceType,
      'path': path,
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
    );
  }
}
