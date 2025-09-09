class GalleryImage {
  final String id;
  final String url;
  final String taskName;
  final String langCode;
  final String prompt;
  final int timestamp;

  const GalleryImage({
    required this.id,
    required this.url,
    required this.taskName,
    required this.langCode,
    required this.prompt,
    required this.timestamp,
  });

  /// Витягує індекс зображення з ID
  /// ID має формат: task{taskIndex}_{langCode}_img{imageIndex}_{timestamp}
  int get imageIndex {
    try {
      final parts = id.split('_');
      if (parts.length >= 3) {
        final imgPart = parts[2]; // img{imageIndex}
        if (imgPart.startsWith('img')) {
          return int.parse(imgPart.substring(3));
        }
      }
    } catch (e) {
      print('Error parsing image index from ID $id: $e');
    }
    return 0;
  }

  /// Витягує індекс завдання з ID
  int get taskIndex {
    try {
      final parts = id.split('_');
      if (parts.isNotEmpty) {
        final taskPart = parts[0]; // task{taskIndex}
        if (taskPart.startsWith('task')) {
          return int.parse(taskPart.substring(4));
        }
      }
    } catch (e) {
      print('Error parsing task index from ID $id: $e');
    }
    return 0;
  }
}
