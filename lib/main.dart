import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final botToken = prefs.getString('bot_token');
  final bool settingsExist = botToken != null && botToken.isNotEmpty;

  runApp(MyApp(settingsExist: settingsExist));
}

class MyApp extends StatelessWidget {
  final bool settingsExist;

  const MyApp({super.key, required this.settingsExist});

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
          surface: Color(0xFF1E1E1E), // Виправлено застарілий параметр
        ),
        textTheme: GoogleFonts.ubuntuTextTheme(
          ThemeData.dark().textTheme,
        ),
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
      initialRoute: settingsExist ? '/home' : '/setup',
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
