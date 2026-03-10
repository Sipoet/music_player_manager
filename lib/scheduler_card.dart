import 'package:flutter/material.dart';
import 'package:music_player_manager/models/scheduler.dart';
export 'package:music_player_manager/models/scheduler.dart';

class SchedulerCard extends StatelessWidget {
  final Scheduler scheduler;
  final Function(Scheduler scheduler)? onDelete;
  final Function(Scheduler scheduler)? onEdit;
  const SchedulerCard({
    super.key,
    this.onDelete,
    this.onEdit,
    required this.scheduler,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: scheduler.isExpired ? null : () => onEdit?.call(scheduler),
        icon: Icon(Icons.edit),
      ),
      trailing: IconButton(
        onPressed: () => onDelete?.call(scheduler),
        icon: Icon(Icons.delete),
      ),
      title: Text(
        scheduler.playlist == null
            ? scheduler.music?.title ?? ""
            : "Playlist ${scheduler.playlist?.name}",
        style: TextStyle(
          color: scheduler.isExpired ? Colors.grey.shade400 : Colors.black,
        ),
      ),
      subtitle: Text(
        "${scheduler.description}, ${scheduler.changeMode.humanize()}",
        style: TextStyle(
          color: scheduler.isExpired ? Colors.grey.shade400 : Colors.black,
        ),
      ),
    );
  }
}
