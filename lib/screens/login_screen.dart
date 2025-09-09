import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../api/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const LoginScreen({super.key, required this.firebaseService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userIdController = TextEditingController();
  bool _isLoading = false;
  List<String> _existingUserIds = [];

  @override
  void initState() {
    super.initState();
    _checkExistingUserId();
    _loadExistingUserIds();
  }

  Future<void> _loadExistingUserIds() async {
    try {
      final userIds = await widget.firebaseService.getExistingUserIds();
      if (mounted) {
        setState(() {
          _existingUserIds = userIds;
        });
      }
    } catch (e) {
      print('Error loading existing user IDs: $e');
    }
  }

  Future<void> _checkExistingUserId() async {
    final userId = await UserService.getUserId();
    if (userId.isNotEmpty) {
      // Пробуємо увійти анонімно та використати збережений UID
      await _signInAnonymouslyAndConnect(userId);
    }
  }

  Future<void> _login() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      _showError('Будь ласка, введіть User ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _signInAnonymouslyAndConnect(userId);
    } catch (e) {
      _showError('Помилка підключення: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAnonymouslyAndConnect(String targetUserId) async {
    try {
      // Замість спроби підключитися до існуючого користувача,
      // ми створюємо власний анонімний обліковий запис для читання
      await FirebaseAuth.instance.signInAnonymously();

      // Але використовуємо targetUserId для читання даних
      await UserService.setUserId(targetUserId);

      // Ініціалізуємо Firebase Service з target userId (не з нашого auth)
      await widget.firebaseService.initializeWithUserId(targetUserId);

      _navigateToHome();
    } catch (e) {
      throw Exception('Не вдалося підключитися: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.cyanAccent, width: 2),
                ),
                child: const Icon(
                  Icons.account_circle,
                  size: 80,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 40),

              // Title
              const Text(
                'ProjectCombain',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Введіть ваш User ID',
                style: TextStyle(fontSize: 18, color: Colors.grey[300]),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Цей ID синхронізує ваші дані з desktop додатком',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Input field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: TextField(
                  controller: _userIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'User ID',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: 'наприклад: 123, 456, abc123',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: Icon(Icons.person, color: Colors.grey[400]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  enabled: !_isLoading,
                ),
              ),
              const SizedBox(height: 24),

              // Existing User IDs section
              if (_existingUserIds.isNotEmpty) ...[
                Text(
                  'Існуючі User ID для синхронізації:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingUserIds.length,
                    itemBuilder: (context, index) {
                      final userId = _existingUserIds[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(userId),
                          onPressed: () {
                            _userIdController.text = userId;
                          },
                          backgroundColor: const Color(0xFF1E1E1E),
                          labelStyle: const TextStyle(color: Colors.white),
                          side: BorderSide(color: Colors.grey[600]!),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Login button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : const Text(
                          'Підключитися',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Help button
              TextButton(
                onPressed: () => _showHelpDialog(),
                child: Text(
                  'Що таке User ID?',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Про User ID',
          style: TextStyle(color: Colors.cyanAccent),
        ),
        content: Text(
          'User ID - це унікальний ідентифікатор, який розділяє ваші дані від інших користувачів.\n\n'
          'Desktop додаток автоматично створює новий ID при першому запуску (1, 2, 3...).\n\n'
          'Для синхронізації з desktop:\n'
          '1. Запустіть desktop додаток\n'
          '2. Подивіться ваш User ID в налаштуваннях Firebase\n'
          '3. Введіть той самий ID тут\n\n'
          'Або оберіть існуючий ID зі списку вище.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Зрозуміло',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }
}
