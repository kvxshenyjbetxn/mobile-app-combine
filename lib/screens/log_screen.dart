import 'package:flutter/material.dart';
import '../models/log_entry.dart';
import '../../widgets/log_list_item.dart';

class LogScreen extends StatelessWidget {
  const LogScreen({super.key});

  // Тестові дані для візуалізації
  final List<LogEntry> _mockLogs = const [
    LogEntry(
        level: LogLevel.info,
        message: 'Програму запущено. Логування активовано.',
        timestamp: '14:32:01'),
    LogEntry(
        level: LogLevel.info,
        message: 'Завдання "Task 1" додано до черги.',
        timestamp: '14:32:15'),
    LogEntry(
        level: LogLevel.info,
        message: '[Chain] Starting translation to UA...',
        timestamp: '14:33:05'),
    LogEntry(
        level: LogLevel.warning,
        message: 'Pollinations -> Спроба #2 не вдалася. Статус: 502.',
        timestamp: '14:34:10'),
    LogEntry(
        level: LogLevel.info,
        message: 'Pollinations -> УСПІХ: Зображення збережено.',
        timestamp: '14:34:25'),
    LogEntry(
        level: LogLevel.error,
        message: 'Не вдалося створити відео. FFmpeg exited with code 1.',
        timestamp: '14:35:00'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _mockLogs.length,
      itemBuilder: (context, index) {
        return LogListItem(logEntry: _mockLogs[index]);
      },
    );
  }
}
