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
}
