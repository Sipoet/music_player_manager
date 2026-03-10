import 'package:flutter/material.dart';
import 'package:music_player_manager/models/playlist.dart';
export 'package:music_player_manager/models/playlist.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_player_manager/music_controller.dart';

class PlaylistCard extends StatefulWidget {
  final Playlist playlist;
  final MusicController musicController;
  final void Function(Playlist playlist)? onPlayPressed;
  final void Function(Playlist playlist)? onEditPressed;
  final void Function(Playlist playlist)? onDeletePressed;
  const PlaylistCard({
    super.key,
    this.onEditPressed,
    this.onPlayPressed,
    required this.musicController,
    required this.playlist,
    this.onDeletePressed,
  });

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  @override
  void initState() {
    widget.musicController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: () => widget.onPlayPressed?.call(widget.playlist),
        icon: Icon(
          Icons.play_circle,
          color: widget.musicController.currentPlaylist.id == widget.playlist.id
              ? Colors.black
              : Colors.grey,
        ),
      ),
      title: Text(widget.playlist.name),
      subtitle: Row(
        children: [
          IconButton(
            onPressed: () => widget.onEditPressed?.call(widget.playlist),
            icon: Icon(Icons.edit),
          ),
        ],
      ),
      trailing: IconButton(
        onPressed: () {
          widget.onDeletePressed?.call(widget.playlist);
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
      widget.playlist.addMusic(
        Music(sourceType: 'deviceFile', path: file.path!, title: file.name),
      );
    }
  }
}
