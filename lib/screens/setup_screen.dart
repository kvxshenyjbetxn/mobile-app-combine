import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _chatIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bot_token', _tokenController.text.trim());
        await prefs.setString('chat_id', _chatIdController.text.trim());

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка збереження налаштувань: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.smart_toy_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Налаштування Telegram Бота',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'API Token Бота',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Будь ласка, введіть токен';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _chatIdController,
                  decoration: const InputDecoration(
                    labelText: 'Chat ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Будь ласка, введіть Chat ID';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Chat ID має бути числом';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _saveSettings,
                        child: const Text('Зберегти та продовжити'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
