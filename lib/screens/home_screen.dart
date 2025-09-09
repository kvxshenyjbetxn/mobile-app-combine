// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/firebase_service.dart';
import '../services/user_service.dart';
import 'log_screen.dart';
import 'gallery_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  String _currentUserId = '';
  Map<String, int> _userStats = {'logs': 0, 'images': 0};

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userId = await UserService.getUserId();
    final stats = await _firebaseService.getUserStats();

    if (mounted) {
      setState(() {
        _currentUserId = userId;
        _userStats = stats;
      });
    }
  }

  @override
  void dispose() {
    _firebaseService.dispose();
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

    final List<Widget> widgetOptions = <Widget>[
      LogScreen(firebaseService: _firebaseService),
      GalleryScreen(firebaseService: _firebaseService),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Журнал виконання' : 'Галерея Керування',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUserInfo),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showUserSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // User Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.cyanAccent,
                  radius: 20,
                  child: Text(
                    _currentUserId.isNotEmpty
                        ? _currentUserId[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User ID: $_currentUserId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_userStats['logs']} логів • ${_userStats['images']} зображень',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.sync, color: Colors.green, size: 20),
              ],
            ),
          ),

          // Main content
          Expanded(child: widgetOptions.elementAt(_selectedIndex)),
        ],
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

  void _showUserSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSettingsSheet(),
    );
  }

  Widget _buildSettingsSheet() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Налаштування користувача',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.cyanAccent),
            title: const Text(
              'Змінити User ID',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Поточний: $_currentUserId',
              style: TextStyle(color: Colors.grey[400]),
            ),
            onTap: () => _changeUserId(),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Очистити мої дані',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Видалити всі логи та зображення',
              style: TextStyle(color: Colors.grey[400]),
            ),
            onTap: () => _clearUserData(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text(
              'Змінити користувача',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Вийти та увійти з іншим ID',
              style: TextStyle(color: Colors.grey[400]),
            ),
            onTap: () => _switchUser(),
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserId() async {
    Navigator.pop(context); // Закрити bottom sheet

    final newUserId = await _showInputDialog(
      'Змінити User ID',
      'Введіть новий User ID:',
      _currentUserId,
    );

    if (newUserId != null &&
        newUserId.isNotEmpty &&
        newUserId != _currentUserId) {
      await _firebaseService.initializeWithUserId(newUserId);
      await _loadUserInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID змінено на: $newUserId')),
        );
      }
    }
  }

  Future<void> _clearUserData() async {
    Navigator.pop(context); // Закрити bottom sheet

    final confirmed = await _showConfirmDialog(
      'Очистити всі дані',
      'Це permanently видалить всі ваші логи та зображення для User ID: $_currentUserId\n\nВи впевнені?',
    );

    if (confirmed == true) {
      try {
        await _firebaseService.clearUserLogs();
        await _firebaseService.clearUserGallery();
        await _loadUserInfo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Всі дані успішно очищено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Помилка очищення даних: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _switchUser() async {
    Navigator.pop(context); // Закрити bottom sheet
    await UserService.clearUserId(); // Очистити збережений user ID
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<String?> _showInputDialog(
    String title,
    String hint,
    String initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.cyanAccent)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text(
              'Зберегти',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(content, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
  }
}
