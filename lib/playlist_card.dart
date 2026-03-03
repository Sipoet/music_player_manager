import 'package:flutter/material.dart';
import 'package:music_player_manager/models/playlist.dart';
export 'package:music_player_manager/models/playlist.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final void Function(Playlist playlist)? onDeletePressed;
  const PlaylistCard({super.key, required this.playlist, this.onDeletePressed});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(playlist.name),
      trailing: IconButton(
        onPressed: () {
          onDeletePressed?.call(playlist);
        },
        icon: Icon(Icons.delete),
      ),
    );
  }
}
