import 'package:flutter/material.dart';
import '../screens/fullscreen_image_screen.dart'; // <-- Імпортуємо новий екран

class GalleryCard extends StatelessWidget {
  final String imageUrl;
  final String imageId;
  final void Function(String) onDelete;
  final void Function(String, {String? newPrompt}) onRegenerate;

  const GalleryCard({
    super.key,
    required this.imageUrl,
    required this.imageId,
    required this.onDelete,
    required this.onRegenerate,
  });

  Future<void> _showEditPromptDialog(BuildContext context) async {
    final controller = TextEditingController();
    final newPrompt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text('Редагувати та перегенерувати'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введіть новий промпт...',
          ),
        ),
        actions: [
          TextButton(
            child: const Text(
              'Скасувати',
              style: TextStyle(color: Colors.grey),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('OK', style: TextStyle(color: Colors.cyanAccent)),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          ),
        ],
      ),
    );

    if (newPrompt != null && newPrompt.isNotEmpty) {
      onRegenerate(imageId, newPrompt: newPrompt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            // Обгортаємо зображення у GestureDetector
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FullscreenImageScreen(imageUrl: imageUrl),
                  ),
                );
              },
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error_outline, color: Colors.redAccent),
                ),
              ),
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Видалити',
                  onPressed: () => onDelete(imageId),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.lightBlueAccent,
                  ),
                  tooltip: 'Редагувати промпт',
                  onPressed: () => _showEditPromptDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                  tooltip: 'Перегенерувати (інший варіант)',
                  onPressed: () => onRegenerate(imageId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
