import 'package:flutter/material.dart';
import '../models/log_entry.dart';

class LogListItem extends StatelessWidget {
  final LogEntry logEntry;

  const LogListItem({super.key, required this.logEntry});

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.greenAccent;
      case LogLevel.warning:
        return Colors.orangeAccent;
      case LogLevel.error:
        return Colors.redAccent;
    }
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForLevel(logEntry.level);
    final icon = _getIconForLevel(logEntry.level);

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logEntry.message,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    logEntry.timestamp,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
