import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:music_player_manager/models/music.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();
mixin MusicConverter<T extends StatefulWidget> on State<T> {
  Future<Music> convertFileToMusic(PlatformFile file) async {
    AudioMetadata? tag;
    try {
      tag = readMetadata(File(file.path!), getImage: false);
    } catch (e) {
      debugPrint('failed get audio tag/metadata: ${e.toString()}');
    }

    return Music(
      sourceType: .deviceFile,
      path: file.path!,
      title: tag?.title ?? file.name,
      artist: tag?.artist,
      album: tag?.album,
      genre: tag?.genres.join(', '),
    );
  }

  Future<File> generateTemporaryFile(String extFile) async {
    final Directory tempDir = await getTemporaryDirectory();
    final path = join(tempDir.path, '${uuid.v4()}.$extFile');
    debugPrint('file output $path');
    return File(path);
  }
}
