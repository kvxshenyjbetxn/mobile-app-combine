import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart'; // Автоматично згенерований файл
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  // Переконуємось, що Flutter ініціалізовано
  WidgetsFlutterBinding.ensureInitialized();

  // Ініціалізуємо Firebase з опціями для вашого проєкту
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ініціалізуємо сервіс повідомлень
  await NotificationService.initialize();

  // Запитуємо дозвіл для повідомлень
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combain App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyanAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.tealAccent,
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.ubuntuTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey,
        ),
      ),
      // Завжди запускаємо головний екран
      home: const HomeScreen(),
    );
  }
}
