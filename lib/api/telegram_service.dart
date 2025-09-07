import 'dart:async';
import 'package:logging/logging.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

enum MessageType { log, image, status, unknown }

class ParsedMessage {
  final MessageType type;
  final String content;
  final Map<String, String> data;
  ParsedMessage(this.type, this.content, {this.data = const {}});
}

class TelegramService {
  final String _botToken;
  final int _chatId;

  final _log = Logger('TelegramService');
  final _messageController = StreamController<ParsedMessage>.broadcast();
  late final TeleDart _teleDart;
  bool _isInitialized = false;

  Stream<ParsedMessage> get messages => _messageController.stream;

  TelegramService({required String token, required String chatId})
      : _botToken = token,
        _chatId = int.parse(chatId) {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_botToken.isEmpty) {
      _log.warning('Telegram service not initialized: Bot Token is empty.');
      return;
    }

    try {
      final username = (await Telegram(_botToken).getMe()).username;
      _teleDart = TeleDart(_botToken, Event(username!));

      _teleDart.onMessage().listen(_handleTextMessage);
      _teleDart.start();
      _isInitialized = true;
      _log.info('Telegram service started for bot @$username');
    } catch (e) {
      _log.severe('Failed to initialize Telegram service: $e');
      _messageController
          .add(ParsedMessage(MessageType.log, 'ПОМИЛКА: Невірний API токен.'));
    }
  }

  void _handleTextMessage(Message message) {
    if (message.chat.id != _chatId || message.text == null) {
      return;
    }

    final text = message.text!;
    _log.info('Received message: $text');

    if (text.startsWith('LOG::')) {
      _messageController.add(ParsedMessage(MessageType.log, text.substring(5)));
    } else if (text.startsWith('IMAGE::')) {
      try {
        final parts = text.split('::');
        if (parts.length >= 3) {
          _messageController.add(ParsedMessage(MessageType.image, parts[1],
              data: {'url': parts[2]}));
        }
      } catch (e) {
        _log.warning('Could not parse IMAGE message: $text');
      }
    } else {
      _messageController.add(ParsedMessage(MessageType.unknown, text));
    }
  }

  Future<void> sendCommand(String command) async {
    if (!_isInitialized) return;
    try {
      await _teleDart.sendMessage(_chatId, command);
      _log.info('Sent command: $command');
    } catch (e) {
      _log.severe('Error sending command: $e');
    }
  }

  void dispose() {
    if (_isInitialized) {
      _teleDart.stop();
    }
    _messageController.close();
  }
}
