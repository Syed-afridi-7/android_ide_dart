import 'package:flutter/material.dart';

enum GitFileStatus { modified, added, untracked, deleted, clean }

class GitStatusBadge extends StatelessWidget {
  final GitFileStatus status;

  const GitStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == GitFileStatus.clean) return const SizedBox.shrink();

    String label = '';
    Color color = Colors.grey;

    switch (status) {
      case GitFileStatus.modified:
        label = 'M';
        color = Colors.amber;
        break;
      case GitFileStatus.added:
        label = 'A';
        color = Colors.greenAccent;
        break;
      case GitFileStatus.untracked:
        label = 'U';
        color = Colors.blueAccent;
        break;
      case GitFileStatus.deleted:
        label = 'D';
        color = Colors.redAccent;
        break;
      default:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
