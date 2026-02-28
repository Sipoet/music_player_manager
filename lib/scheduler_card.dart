import 'package:flutter/material.dart';
import 'package:music_player_manager/models/scheduler.dart';
export 'package:music_player_manager/models/scheduler.dart';

class SchedulerCard extends StatelessWidget {
  final Scheduler scheduler;
  const SchedulerCard({super.key, required this.scheduler});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(scheduler.music.title),
      subtitle: Text(scheduler.description),
    );
  }
}
