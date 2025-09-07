enum LogLevel { info, warning, error }

class LogEntry {
  final LogLevel level;
  final String message;
  final String timestamp;

  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
  });
}