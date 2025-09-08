import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/telegram_service.dart';
import 'log_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  TelegramService? _telegramService;
  // late final List<Widget> _widgetOptions; // Цей рядок більше не потрібен тут

  @override
  void initState() {
    super.initState();
    _initializeTelegramService();
    // Ініціалізація віджетів перенесена в метод build
  }

  Future<void> _initializeTelegramService() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('bot_token');
    final chatId = prefs.getString('chat_id');

    if (token != null && chatId != null) {
      setState(() {
        _telegramService = TelegramService(token: token, chatId: chatId);
      });
    }
  }

  @override
  void dispose() {
    _telegramService?.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: const Color(0xFF1E1E1E),
      ),
    );

    // Створюємо список віджетів тут, щоб він оновлювався при зміні стану
    final List<Widget> widgetOptions = <Widget>[
      LogScreen(telegramService: _telegramService),
      GalleryScreen(telegramService: _telegramService),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Журнал виконання' : 'Галерея Керування',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions, // Використовуємо локальну змінну
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.terminal), label: 'Журнал'),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library_outlined),
            activeIcon: Icon(Icons.photo_library),
            label: 'Галерея',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
