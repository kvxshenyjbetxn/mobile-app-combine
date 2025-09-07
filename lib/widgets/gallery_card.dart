import 'package:flutter/material.dart';

class GalleryCard extends StatelessWidget {
  final String imageUrl;
  final String imageId;
  final Function(String) onDelete;
  final Function(String) onRegenerate;

  const GalleryCard({
    super.key,
    required this.imageUrl,
    required this.imageId,
    required this.onDelete,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[850],
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              // Елегантний плейсхолдер на час завантаження
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
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => onDelete(imageId),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
                  onPressed: () {/* TODO: Implement edit dialog */},
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.greenAccent),
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
