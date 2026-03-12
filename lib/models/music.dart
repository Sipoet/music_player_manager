import 'package:audioplayers/audioplayers.dart';

class Music {
  String title;

  String? artist;
  String? album;
  String? genre;
  String? mimeType;
  String path;
  SourceType sourceType;
  Music({
    required this.sourceType,
    required this.path,
    this.artist = '',
    this.title = '',
    this.mimeType,
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
      case .deviceFile:
        return DeviceFileSource(path, mimeType: mimeType);
      case .remote:
        return UrlSource(path, mimeType: mimeType);
    }
  }

  factory Music.fromJson(Map json) {
    return Music(
      path: json['path'],
      sourceType: SourceType.fromString(json['sourceType']),
      title: json['title'],
      artist: json['artist'],
      album: json['album'],
      genre: json['genre'],
    );
  }
}

enum SourceType {
  deviceFile,
  remote;

  factory SourceType.fromString(String value) {
    switch (value) {
      case 'remote':
        return remote;
      case 'deviceFile':
        return deviceFile;
      default:
        throw '$value not valid source type';
    }
  }
}
