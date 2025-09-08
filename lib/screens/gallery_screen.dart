// lib/screens/gallery_screen.dart
import 'package:flutter/material.dart';
import '../api/firebase_service.dart';
import '../models/gallery_image.dart';
import '../widgets/gallery_card.dart';

class GalleryScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const GalleryScreen({super.key, required this.firebaseService});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<GalleryImage> _mockImages = const [
    GalleryImage(id: 'img_001', url: 'https://picsum.photos/seed/1/300/300'),
    GalleryImage(id: 'img_002', url: 'https://picsum.photos/seed/2/300/300'),
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
                onDelete: (id) {},
                onRegenerate: (id) {},
              );
            },
          ),
        ),
      ],
    );
  }
}
