import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/log_entry.dart';

class FirebaseService {
  final DatabaseReference _logsRef = FirebaseDatabase.instance.ref('logs');
  final StreamController<List<LogEntry>> _logStreamController =
      StreamController<List<LogEntry>>.broadcast();
  late StreamSubscription _logSubscription;

  // Тепер стрім буде віддавати одразу весь список логів
  Stream<List<LogEntry>> get logStream => _logStreamController.stream;

  FirebaseService() {
    _listenToLogs();
  }

  void _listenToLogs() {
    // ЗАМІНА: onChildAdded -> onValue.
    // Цей слухач реагує на БУДЬ-ЯКІ зміни даних у вузлі 'logs'.
    _logSubscription = _logsRef.onValue.listen((event) {
      final List<LogEntry> logs = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          // Отримуємо всі логи як великий об'єкт
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          // Конвертуємо кожен запис у LogEntry
          data.forEach((key, value) {
            final logData = Map<String, dynamic>.from(value as Map);
            final message = logData['message'] as String;
            final timestampStr = logData['timestamp'] as String;
            final timeOnly = timestampStr.split(' ')[1].substring(0, 8);

            logs.add(
              LogEntry(
                level: _getLogLevelFromString(message),
                message: message,
                timestamp: timeOnly,
              ),
            );
          });

          // Сортуємо логи, щоб найновіші були зверху
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        } catch (e) {
          print("Error parsing log data snapshot: $e");
        }
      }
      // Відправляємо повний, відсортований список у додаток
      _logStreamController.add(logs);
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

  void dispose() {
    _logSubscription.cancel();
    _logStreamController.close();
  }
}
