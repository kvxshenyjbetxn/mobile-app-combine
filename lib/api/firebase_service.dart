import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/log_entry.dart';
import '../models/gallery_image.dart';
import '../services/notification_service.dart';

class FirebaseService {
  final DatabaseReference _logsRef = FirebaseDatabase.instance.ref('logs');
  final DatabaseReference _imagesRef = FirebaseDatabase.instance.ref('images');
  final DatabaseReference _statusRef = FirebaseDatabase.instance.ref('status');

  final StreamController<List<LogEntry>> _logStreamController =
      StreamController<List<LogEntry>>.broadcast();
  final StreamController<List<GalleryImage>> _imageStreamController =
      StreamController<List<GalleryImage>>.broadcast();
  final StreamController<bool> _montageReadyController =
      StreamController<bool>.broadcast();

  late StreamSubscription _logSubscription;
  late StreamSubscription _imageSubscription;
  late StreamSubscription _statusSubscription;

  Stream<List<LogEntry>> get logStream => _logStreamController.stream;
  Stream<List<GalleryImage>> get imageStream => _imageStreamController.stream;
  Stream<bool> get montageReadyStream => _montageReadyController.stream;

  FirebaseService() {
    NotificationService.initialize();
    _listenToLogs();
    _listenToImages();
    _listenToMontageStatus();
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
                prompt: imageData['prompt'] as String? ?? '',
                timestamp: imageData['timestamp'] as int? ?? 0,
              ),
            );
          });
          // Сортуємо зображення спочатку за завданням, потім за індексом зображення
          images.sort((a, b) {
            final taskComparison = a.taskIndex.compareTo(b.taskIndex);
            if (taskComparison != 0) {
              return taskComparison;
            }
            return a.imageIndex.compareTo(b.imageIndex);
          });
        } catch (e) {
          print("Error parsing image data snapshot: $e");
        }
      }
      _imageStreamController.add(images);
    });
  }

  void _listenToMontageStatus() {
    _statusSubscription = _statusRef.onValue.listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          final isReady = data['montage_ready'] as bool? ?? false;

          if (isReady) {
            NotificationService.showMontageReadyNotification();
          }

          _montageReadyController.add(isReady);
        } catch (e) {
          print("Error parsing status data: $e");
          _montageReadyController.add(false);
        }
      } else {
        _montageReadyController.add(false);
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

  void dispose() {
    _logSubscription.cancel();
    _imageSubscription.cancel();
    _statusSubscription.cancel();
    _logStreamController.close();
    _imageStreamController.close();
    _montageReadyController.close();
  }

  // --- Нові методи для відправки команд ---
  final DatabaseReference _commandsRef = FirebaseDatabase.instance.ref(
    'commands',
  );

  Future<void> sendDeleteCommand(String imageId) async {
    try {
      await _commandsRef.push().set({
        'command': 'delete',
        'imageId': imageId,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print("Error sending delete command: $e");
    }
  }

  Future<void> sendRegenerateCommand(
    String imageId, {
    String? newPrompt,
    String? serviceOverride,
    String? modelOverride,
    String? styleOverride,
  }) async {
    try {
      final payload = {
        'command': 'regenerate',
        'imageId': imageId,
        'timestamp': ServerValue.timestamp,
      };
      if (newPrompt != null) {
        payload['newPrompt'] = newPrompt;
      }
      if (serviceOverride != null) {
        payload['serviceOverride'] = serviceOverride;
      }
      if (modelOverride != null) {
        payload['modelOverride'] = modelOverride;
      }
      if (styleOverride != null) {
        payload['styleOverride'] = styleOverride;
      }
      await _commandsRef.push().set(payload);
    } catch (e) {
      print("Error sending regenerate command: $e");
    }
  }

  Future<void> sendContinueMontageCommand() async {
    try {
      await _commandsRef.push().set({
        'command': 'continue_montage',
        'timestamp': ServerValue.timestamp,
      });
      print("Continue montage command sent successfully");
    } catch (e) {
      print("Error sending continue montage command: $e");
    }
  }
}
