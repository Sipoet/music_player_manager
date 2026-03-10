import 'package:flutter/material.dart';
import 'package:music_player_manager/models/playlist.dart';
export 'package:music_player_manager/models/playlist.dart';
import 'package:file_picker/file_picker.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final bool isPlaylistPlaying;
  final void Function(Playlist playlist)? onPlayPressed;
  final void Function(Playlist playlist)? onEditPressed;
  final void Function(Playlist playlist)? onDeletePressed;
  const PlaylistCard({
    super.key,
    this.onEditPressed,
    this.onPlayPressed,
    this.isPlaylistPlaying = false,
    required this.playlist,
    this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: () => onPlayPressed?.call(playlist),
        icon: Icon(
          Icons.play_circle,
          color: isPlaylistPlaying ? Colors.black : Colors.grey,
        ),
      ),
      title: Text(playlist.name),
      subtitle: Row(
        children: [
          IconButton(
            onPressed: () => onEditPressed?.call(playlist),
            icon: Icon(Icons.edit),
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: () {
          onDeletePressed?.call(playlist);
        },
        icon: Icon(Icons.delete),
      ),
    );
  }

  Future addMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: .audio,
      withReadStream: true,
      withData: true,
      dialogTitle: 'pilih musik',
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }

    for (final file in result.files) {
      playlist.addMusic(
        Music(sourceType: 'deviceFile', path: file.path!, title: file.name),
      );
    }
  }
}
