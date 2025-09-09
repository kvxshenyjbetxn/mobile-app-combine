import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/log_entry.dart';
import '../models/gallery_image.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';

class FirebaseService {
  String? _userId;
  String get basePath => 'users/${_userId ?? "default"}';

  late DatabaseReference _logsRef;
  late DatabaseReference _imagesRef;
  late DatabaseReference _commandsRef;
  late DatabaseReference _statusRef;

  final StreamController<List<LogEntry>> _logStreamController =
      StreamController<List<LogEntry>>.broadcast();
  final StreamController<List<GalleryImage>> _imageStreamController =
      StreamController<List<GalleryImage>>.broadcast();
  final StreamController<bool> _montageReadyController =
      StreamController<bool>.broadcast();

  bool _previousMontageReadyState = false; // Відслідковуємо попередній стан

  late StreamSubscription _logSubscription;
  late StreamSubscription _imageSubscription;
  late StreamSubscription _statusSubscription;

  Stream<List<LogEntry>> get logStream => _logStreamController.stream;
  Stream<List<GalleryImage>> get imageStream => _imageStreamController.stream;
  Stream<bool> get montageReadyStream => _montageReadyController.stream;

  FirebaseService() {
    _initializeWithStoredUserId();
  }

  Future<void> _initializeWithStoredUserId() async {
    final userId = await UserService.getUserId();
    if (userId.isNotEmpty) {
      await initializeWithUserId(userId);
    } else {
      _initializeReferences();
    }

    NotificationService.initialize();
    _listenToLogs();
    _listenToImages();
    _listenToMontageStatus();
  }

  Future<void> initializeWithUserId(String userId) async {
    // Спочатку зупиняємо поточні слухачі (якщо вони ініціалізовані)
    try {
      _logSubscription.cancel();
    } catch (e) {
      // Ignore if not initialized
    }
    try {
      _imageSubscription.cancel();
    } catch (e) {
      // Ignore if not initialized
    }
    try {
      _statusSubscription.cancel();
    } catch (e) {
      // Ignore if not initialized
    }

    _userId = userId;
    await UserService.setUserId(userId);
    print("DEBUG: About to initialize references with userId: $userId");
    _initializeReferences();

    // Перезапускаємо слухачі з новими шляхами
    print("DEBUG: About to restart listeners");
    _listenToLogs();
    _listenToImages();
    _listenToMontageStatus();
    print("Firebase initialized with User ID: $_userId");
  }

  void _initializeReferences() {
    print("DEBUG: _initializeReferences called with basePath: $basePath");
    print("DEBUG: _userId = $_userId");
    _logsRef = FirebaseDatabase.instance.ref('$basePath/logs');
    _imagesRef = FirebaseDatabase.instance.ref('$basePath/images');
    _commandsRef = FirebaseDatabase.instance.ref('$basePath/commands');
    _statusRef = FirebaseDatabase.instance.ref('$basePath/status');
    print("DEBUG: _logsRef path: ${_logsRef.path}");
  }

  void _listenToLogs() {
    print("DEBUG: _listenToLogs starting, listening to path: ${_logsRef.path}");
    _logSubscription = _logsRef.onValue.listen((event) {
      print("DEBUG: Firebase event received");
      print("DEBUG: snapshot exists: ${event.snapshot.exists}");
      print("DEBUG: snapshot value: ${event.snapshot.value}");

      final List<LogEntry> logs = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          print("DEBUG: Processing ${data.length} log entries");
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
          print("DEBUG: Processed ${logs.length} logs, sending to stream");
        } catch (e) {
          print("Error parsing log data snapshot: $e");
        }
      } else {
        print("DEBUG: No log data found (snapshot doesn't exist or is null)");
      }
      print("DEBUG: Adding ${logs.length} logs to stream");
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

          // Показуємо повідомлення тільки при зміні з false на true
          if (isReady && !_previousMontageReadyState) {
            NotificationService.showMontageReadyNotification();
          }

          _previousMontageReadyState = isReady;
          _montageReadyController.add(isReady);
        } catch (e) {
          print("Error parsing status data: $e");
          _previousMontageReadyState = false;
          _montageReadyController.add(false);
        }
      } else {
        _previousMontageReadyState = false;
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

  /// Очищення логів тільки для поточного користувача
  Future<void> clearUserLogs() async {
    try {
      await _logsRef.remove();
      print('Logs cleared for user $_userId');
    } catch (e) {
      print('Error clearing logs: $e');
      rethrow;
    }
  }

  /// Очищення галереї тільки для поточного користувача
  Future<void> clearUserGallery() async {
    try {
      // Очищення Database
      await _imagesRef.remove();

      // Очищення Storage файлів
      try {
        final storageRef = FirebaseStorage.instance.ref(
          '$_userId/gallery_images',
        );
        final listResult = await storageRef.listAll();

        for (var item in listResult.items) {
          await item.delete();
        }
      } catch (storageError) {
        print('Storage clearing error (may be empty): $storageError');
      }

      print('Gallery cleared for user $_userId');
    } catch (e) {
      print('Error clearing gallery: $e');
      rethrow;
    }
  }

  /// Отримання статистики тільки для поточного користувача
  Future<Map<String, int>> getUserStats() async {
    try {
      final logsSnapshot = await _logsRef.get();
      final imagesSnapshot = await _imagesRef.get();

      int logsCount = 0;
      int imagesCount = 0;

      if (logsSnapshot.exists && logsSnapshot.value != null) {
        final logsData = logsSnapshot.value as Map;
        logsCount = logsData.length;
      }

      if (imagesSnapshot.exists && imagesSnapshot.value != null) {
        final imagesData = imagesSnapshot.value as Map;
        imagesCount = imagesData.length;
      }

      return {'logs': logsCount, 'images': imagesCount};
    } catch (e) {
      print('Error getting user stats: $e');
      return {'logs': 0, 'images': 0};
    }
  }

  /// Отримання поточного User ID
  String? get currentUserId => _userId;

  /// Отримання списку всіх існуючих User ID з Firebase
  Future<List<String>> getExistingUserIds() async {
    try {
      final usersRef = FirebaseDatabase.instance.ref('users');
      final snapshot = await usersRef.get();

      if (snapshot.exists && snapshot.value != null) {
        final usersData = snapshot.value as Map;
        final userIds = usersData.keys.map((key) => key.toString()).toList();

        // Сортуємо числові ID
        userIds.sort((a, b) {
          final aNum = int.tryParse(a) ?? 99999;
          final bNum = int.tryParse(b) ?? 99999;
          return aNum.compareTo(bNum);
        });

        return userIds;
      }

      return [];
    } catch (e) {
      print('Error getting existing user IDs: $e');
      return [];
    }
  }
}
