import 'package:flutter/material.dart';
import 'package:music_player_manager/models/music.dart';
export 'package:music_player_manager/models/music.dart';
import 'package:music_player_manager/modules/music_controller.dart';

class MusicCard extends StatefulWidget {
  final Music music;
  final void Function(Music music, MusicController controller)? onPlayPressed;
  final void Function(Music music, MusicController controller)? onDeletePressed;
  final MusicController controller;
  const MusicCard({
    super.key,
    this.onPlayPressed,
    this.onDeletePressed,
    required this.music,
    required this.controller,
  });

  @override
  State<MusicCard> createState() => _MusicCardState();
}

class _MusicCardState extends State<MusicCard> {
  MusicController get controller => widget.controller;
  Music get music => widget.music;
  @override
  void initState() {
    controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.onPlayPressed == null
          ? null
          : controller.isPlay(music)
          ? IconButton(
              onPressed: () => setState(() {
                controller.pause();
              }),
              icon: Icon(Icons.pause),
            )
          : IconButton(
              onPressed: () => setState(() {
                controller.play(music);
                controller.taskScheduler = null;
                widget.onPlayPressed!.call(music, controller);
              }),
              icon: Icon(Icons.play_arrow),
            ),
      title: Text(music.title),
      subtitle: Text(music.artist ?? ''),
      trailing: IconButton(
        onPressed: () {
          widget.onDeletePressed?.call(music, controller);
        },
        icon: Icon(Icons.delete),
      ),
    );
  }
}
