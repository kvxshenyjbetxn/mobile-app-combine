// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showMontageReadyNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'montage_ready_channel',
          'Готовність до монтажу',
          channelDescription: 'Повідомлення про готовність програми до монтажу',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0,
      '🎨 Програма готова до монтажу',
      'Всі зображення згенеровано. Перейдіть в галерею для продовження монтажу.',
      platformChannelSpecifics,
    );
  }
}
