import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/telegram_service.dart';
import '../models/log_entry.dart';
import '../widgets/log_list_item.dart';

class LogScreen extends StatefulWidget {
  final TelegramService? telegramService;

  const LogScreen({super.key, this.telegramService});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final List<LogEntry> _logs = [];
  StreamSubscription? _messageSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
  }

  @override
  void didUpdateWidget(covariant LogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.telegramService != oldWidget.telegramService) {
      _unsubscribe();
      _subscribeToMessages();
    }
  }

  void _subscribeToMessages() {
    if (widget.telegramService == null) return;

    _messageSubscription = widget.telegramService!.messages.listen((message) {
      if (message.type == MessageType.log) {
        if (mounted) {
          setState(() {
            final newLog = LogEntry(
              level: _getLogLevelFromString(message.content),
              message: message.content,
              timestamp: DateFormat('HH:mm:ss').format(DateTime.now()),
            );
            _logs.insert(0, newLog); // Додаємо новий лог на початок списку
          });
        }
      }
    });
  }

  LogLevel _getLogLevelFromString(String message) {
    final lowerCaseMessage = message.toLowerCase();
    if (lowerCaseMessage.contains('error') ||
        lowerCaseMessage.contains('помилка') ||
        lowerCaseMessage.contains('failed')) {
      return LogLevel.error;
    }
    if (lowerCaseMessage.contains('warning') ||
        lowerCaseMessage.contains('попередження')) {
      return LogLevel.warning;
    }
    return LogLevel.info;
  }

  void _unsubscribe() {
    _messageSubscription?.cancel();
  }

  @override
  void dispose() {
    _unsubscribe();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.telegramService == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Ініціалізація Telegram сервісу...'),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'Очікування логів від десктопної програми...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse:
          false, // Список тепер не перевернутий, бо ми додаємо елементи на початок
      padding: const EdgeInsets.all(8.0),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return LogListItem(logEntry: _logs[index]);
      },
    );
  }
}
