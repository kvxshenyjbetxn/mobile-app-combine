// lib/screens/gallery_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../api/firebase_service.dart';
import '../models/gallery_image.dart';
import '../widgets/gallery_card.dart';
import 'package:collection/collection.dart';

class GalleryScreen extends StatefulWidget {
  final FirebaseService firebaseService;

  const GalleryScreen({super.key, required this.firebaseService});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<GalleryImage> _images = [];
  StreamSubscription? _imageSubscription;
  bool _showContinueButton = false;

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
          // Показуємо кнопку продовження, якщо є зображення
          _showContinueButton = imageList.isNotEmpty;
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

    // Групуємо зображення за назвою завдання
    final groupedByTask = groupBy(_images, (image) => image.taskName);
    final taskKeys = groupedByTask.keys.toList()..sort();

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: taskKeys.length,
        itemBuilder: (context, taskIndex) {
          final taskName = taskKeys[taskIndex];
          final imagesInTask = groupedByTask[taskName]!;

          // Групуємо зображення всередині завдання за мовою
          final groupedByLang = groupBy(
            imagesInTask,
            (image) => image.langCode,
          );
          final langKeys = groupedByLang.keys.toList()..sort();

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            color: const Color(0xFF1E1E1E),
            child: ExpansionTile(
              title: Text(
                taskName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              initiallyExpanded: true,
              children: langKeys.map((langCode) {
                final imagesInLang = groupedByLang[langCode]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Мова: ${langCode.toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // <-- Змінюємо на 1 колонку
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio:
                                16 / 10, // <-- Робимо картку трохи вищою
                          ),
                      itemCount: imagesInLang.length,
                      itemBuilder: (context, imageIndex) {
                        final image = imagesInLang[imageIndex];
                        return GalleryCard(
                          // Унікальний ключ, що змушує Flutter перебудувати віджет при зміні URL або видаленні
                          key: ValueKey('${image.id}_${image.timestamp}'),
                          imageUrl: image.url,
                          imageId: image.id,
                          currentPrompt: image.prompt,
                          onDelete: (id) {
                            widget.firebaseService.sendDeleteCommand(id);
                          },
                          onRegenerate: (id, {newPrompt}) {
                            widget.firebaseService.sendRegenerateCommand(
                              id,
                              newPrompt: newPrompt,
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: _showContinueButton
          ? FloatingActionButton.extended(
              onPressed: () {
                _showContinueMontageDialog(context);
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text(
                'ПРОДОВЖИТИ МОНТАЖ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showContinueMontageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Продовжити монтаж',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Ви впевнені, що хочете продовжити монтаж? Десктопна програма перейде до фінального етапу створення відео.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Скасувати',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.firebaseService.sendContinueMontageCommand();

                // Приховуємо кнопку після відправки команди
                setState(() {
                  _showContinueButton = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Команда продовження монтажу відправлена!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'ПРОДОВЖИТИ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
