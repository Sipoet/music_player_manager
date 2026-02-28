import 'package:audioplayers/audioplayers.dart';

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
