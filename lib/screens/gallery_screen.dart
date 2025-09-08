import 'package:flutter/material.dart';
import '../api/telegram_service.dart';
import '../models/gallery_image.dart';
import '../widgets/gallery_card.dart';

class GalleryScreen extends StatefulWidget {
  final TelegramService? telegramService;

  const GalleryScreen({super.key, this.telegramService});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Тестові дані для візуалізації
  final List<GalleryImage> _mockImages = const [
    GalleryImage(id: 'img_001', url: 'https://picsum.photos/seed/1/300/300'),
    GalleryImage(id: 'img_002', url: 'https://picsum.photos/seed/2/300/300'),
    GalleryImage(id: 'img_003', url: 'https://picsum.photos/seed/3/300/300'),
    GalleryImage(id: 'img_004', url: 'https://picsum.photos/seed/4/300/300'),
    GalleryImage(id: 'img_005', url: 'https://picsum.photos/seed/5/300/300'),
    GalleryImage(id: 'img_006', url: 'https://picsum.photos/seed/6/300/300'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: _mockImages.length,
            itemBuilder: (context, index) {
              final image = _mockImages[index];
              return GalleryCard(
                imageUrl: image.url,
                imageId: image.id,
                onDelete: (id) => print('Delete: $id'),
                onRegenerate: (id) => print('Regenerate: $id'),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.movie_creation_outlined),
            label: const Text('Продовжити монтаж'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              print('Continue montage command sent!');
              // Приклад відправки команди на десктоп
              widget.telegramService?.sendCommand('CMD::CONTINUE_MONTAGE');
            },
          ),
        ),
      ],
    );
  }
}
