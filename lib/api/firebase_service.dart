import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/log_entry.dart';
import '../models/gallery_image.dart';

class FirebaseService {
  final DatabaseReference _logsRef = FirebaseDatabase.instance.ref('logs');
  final DatabaseReference _imagesRef = FirebaseDatabase.instance.ref('images');

  final StreamController<List<LogEntry>> _logStreamController =
      StreamController<List<LogEntry>>.broadcast();
  final StreamController<List<GalleryImage>> _imageStreamController =
      StreamController<List<GalleryImage>>.broadcast();

  late StreamSubscription _logSubscription;
  late StreamSubscription _imageSubscription;

  Stream<List<LogEntry>> get logStream => _logStreamController.stream;
  Stream<List<GalleryImage>> get imageStream => _imageStreamController.stream;

  FirebaseService() {
    _listenToLogs();
    _listenToImages();
  }

  void _listenToLogs() {
    _logSubscription = _logsRef.onValue.listen((event) {
      final List<LogEntry> logs = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
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
          logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        } catch (e) {
          print("Error parsing log data snapshot: $e");
        }
      }
      _logStreamController.add(logs);
    });
  }

  void _listenToImages() {
    _imageSubscription = _imagesRef.onValue.listen((event) {
      final List<GalleryImage> images = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          data.forEach((key, value) {
            final imageData = Map<String, dynamic>.from(value as Map);
            images.add(
              GalleryImage(
                id: imageData['id'] as String,
                url: imageData['url'] as String,
                taskName: imageData['taskName'] as String? ?? 'Unnamed Task',
                langCode: imageData['langCode'] as String? ?? 'N/A',
              ),
            );
          });
          // Сортуємо зображення за їх ID
          images.sort((a, b) => a.id.compareTo(b.id));
        } catch (e) {
          print("Error parsing image data snapshot: $e");
        }
      }
      _imageStreamController.add(images);
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
    _imageSubscription.cancel();
    _logStreamController.close();
    _imageStreamController.close();
  }
}
