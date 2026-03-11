import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:music_player_manager/models/music.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';

mixin MusicConverter<T extends StatefulWidget> on State<T> {
  Future<Music> convertFileToMusic(PlatformFile file) async {
    AudioMetadata? tag;
    try {
      tag = readMetadata(File(file.path!), getImage: false);
    } catch (e) {
      debugPrint('failed get audio tag/metadata: ${e.toString()}');
    }

    return Music(
      sourceType: 'deviceFile',
      path: file.path!,
      title: tag?.title ?? file.name,
      artist: tag?.artist,
      album: tag?.album,
      genre: tag?.genres.join(', '),
    );
  }
}
