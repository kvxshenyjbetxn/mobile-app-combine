import 'dart:async';
import 'package:flutter/material.dart';
import '../api/firebase_service.dart';
import '../models/log_entry.dart';
import '../widgets/log_list_item.dart';

class LogScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const LogScreen({super.key, required this.firebaseService});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  // Тепер _logs буде напряму отримувати список з FirebaseService
  List<LogEntry> _logs = [];
  StreamSubscription? _logSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _subscribeToLogs();
  }

  void _subscribeToLogs() {
    // Слухаємо потік, який тепер надсилає повний список List<LogEntry>
    _logSubscription = widget.firebaseService.logStream.listen((logList) {
      if (mounted) {
        setState(() {
          // Просто оновлюємо наш локальний список
          _logs = logList;
        });
      }
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Очікування логів від десктопної програми...'),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        return LogListItem(logEntry: _logs[index]);
      },
    );
  }
}
