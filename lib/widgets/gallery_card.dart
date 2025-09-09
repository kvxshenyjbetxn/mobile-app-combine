import 'package:flutter/material.dart';
import '../screens/fullscreen_image_screen.dart';
import '../api/firebase_service.dart';
import 'advanced_regenerate_dialog.dart';

class GalleryCard extends StatefulWidget {
  final String imageUrl;
  final String imageId;
  final String currentPrompt;
  final void Function(String) onDelete;
  final void Function(String, {String? newPrompt}) onRegenerate;

  const GalleryCard({
    super.key,
    required this.imageUrl,
    required this.imageId,
    required this.currentPrompt,
    required this.onDelete,
    required this.onRegenerate,
  });

  @override
  State<GalleryCard> createState() => _GalleryCardState();
}

class _GalleryCardState extends State<GalleryCard> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _showEditPromptDialog(BuildContext context) async {
    final controller = TextEditingController(text: widget.currentPrompt);
    final newPrompt = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          'Редагувати та перегенерувати',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Введіть новий промпт...',
            hintStyle: TextStyle(color: Colors.grey),
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
      widget.onRegenerate(widget.imageId, newPrompt: newPrompt);
    }
  }

  Future<void> _showAdvancedRegenerateDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AdvancedRegenerateDialog(
        currentPrompt: widget.currentPrompt,
        currentService: 'pollinations', // За замовчуванням
        currentModel: 'dall-e-3', // За замовчуванням
      ),
    );

    if (result != null) {
      // Використовуємо Firebase service для відправки розширеної команди
      await _firebaseService.sendRegenerateCommand(
        widget.imageId,
        newPrompt: result['prompt'],
        serviceOverride: result['service'],
        modelOverride: result['model'],
        styleOverride: result['style'],
      );
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
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        FullscreenImageScreen(imageUrl: widget.imageUrl),
                  ),
                );
              },
              child: Image.network(
                widget.imageUrl,
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
            color: Colors.black.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Видалити',
                  onPressed: () => widget.onDelete(widget.imageId),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Colors.lightBlueAccent,
                  ),
                  tooltip: 'Редагувати промпт',
                  onPressed: () => _showEditPromptDialog(context),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.refresh, color: Colors.greenAccent),
                  tooltip: 'Перегенерувати',
                  color: const Color(0xFF2C2C2C),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'simple',
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.greenAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Швидка перегенерація',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'advanced',
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            color: Colors.cyanAccent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Розширені налаштування',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'simple') {
                      widget.onRegenerate(widget.imageId);
                    } else if (value == 'advanced') {
                      _showAdvancedRegenerateDialog(context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
