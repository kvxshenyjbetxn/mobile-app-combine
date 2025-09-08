// lib/screens/gallery_screen.dart
import 'dart:async';
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
  List<GalleryImage> _images = [];
  StreamSubscription? _imageSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToImages();
  }

  void _subscribeToImages() {
    _imageSubscription = widget.firebaseService.imageStream.listen((imageList) {
      if (mounted) {
        setState(() {
          _images = imageList;
        });
      }
    });
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Очікування зображень від десктопної програми...'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 16 / 9,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        return GalleryCard(
          imageUrl: image.url,
          imageId: image.id,
          onDelete: (id) {
            // TODO: Implement delete functionality
          },
          onRegenerate: (id) {
            // TODO: Implement regenerate functionality
          },
        );
      },
    );
  }
}
