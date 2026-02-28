import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:music_player_manager/models/music.dart';
import 'package:music_player_manager/models/playlist.dart';
export 'package:music_player_manager/models/playlist.dart';
import 'dart:async';
import 'package:music_player_manager/music_controller.dart';

class MusicPlayer extends StatefulWidget {
  final MusicController controller;
  final Playlist playlist;
  const MusicPlayer({
    super.key,
    required this.controller,
    required this.playlist,
  });

  @override
  State<MusicPlayer> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  MusicController get controller => widget.controller;
  AudioPlayer get player => widget.controller.player;
  Music? get music => widget.controller.currentMusic;
  Playlist get playlist => widget.playlist;
  Duration? _duration;
  Duration? _position;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';
  @override
  void initState() {
    controller.addListener(() {
      setState(() {});
    });
    player.getDuration().then(
      (value) => setState(() {
        _duration = value;
      }),
    );
    player.getCurrentPosition().then(
      (value) => setState(() {
        _position = value;
      }),
    );
    _initStreams();
    super.initState();
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // Subscriptions only can be closed asynchronously,
    // therefore events can occur after widget has been disposed.
    if (mounted) {
      super.setState(fn);
    }
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _position = Duration.zero;
        if (playlist.hasNext) {
          playlist.next(controller);
        }
      });
    });

    _playerStateChangeSubscription = player.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      children: [
        Row(
          mainAxisAlignment: .spaceAround,
          spacing: 15,
          children: [
            IconButton(
              onPressed: playlist.hasPrevious
                  ? () => playlist.previous(controller)
                  : null,
              icon: Icon(Icons.skip_previous),
            ),
            IconButton(
              onPressed: () {
                controller.playOrPause().whenComplete(() {
                  setState(() {});
                });
              },
              icon: Icon(controller.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              onPressed: () => setState(() {
                controller.stop();
              }),
              icon: Icon(Icons.stop),
            ),
            IconButton(
              onPressed: playlist.hasNext
                  ? () => playlist.next(controller)
                  : null,
              icon: Icon(Icons.skip_next),
            ),
          ],
        ),
        Slider(
          onChanged: (value) async {
            final duration = await controller.player.getDuration();
            if (duration == null) {
              return;
            }
            final position = value * duration.inMilliseconds;
            controller.seek(Duration(milliseconds: position.round()));
          },
          value:
              (_position != null &&
                  _duration != null &&
                  _position!.inMilliseconds > 0 &&
                  _position!.inMilliseconds < _duration!.inMilliseconds)
              ? _position!.inMilliseconds / _duration!.inMilliseconds
              : 0.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                _position != null
                    ? '$_positionText / $_durationText'
                    : _duration != null
                    ? _durationText
                    : '',
                style: const TextStyle(fontSize: 16.0),
              ),
              Text(controller.currentMusic?.title ?? ''),
            ],
          ),
        ),
      ],
    );
  }
}
