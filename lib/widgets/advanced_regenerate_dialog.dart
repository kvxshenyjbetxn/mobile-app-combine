// lib/widgets/advanced_regenerate_dialog.dart
import 'package:flutter/material.dart';

class AdvancedRegenerateDialog extends StatefulWidget {
  final String currentPrompt;
  final String currentService;
  final String currentModel;

  const AdvancedRegenerateDialog({
    super.key,
    required this.currentPrompt,
    this.currentService = 'pollinations',
    this.currentModel = 'dall-e-3',
  });

  @override
  State<AdvancedRegenerateDialog> createState() =>
      _AdvancedRegenerateDialogState();
}

class _AdvancedRegenerateDialogState extends State<AdvancedRegenerateDialog> {
  late TextEditingController _promptController;
  late String _selectedService;
  late String _selectedModel;
  String? _selectedStyle;

  // Доступні сервіси та моделі
  final Map<String, List<String>> _serviceModels = {
    'pollinations': [
      'dall-e-3',
      'flux',
      'flux-realism',
      'flux-anime',
      'flux-3d',
      'any-dark',
      'flux-pro',
    ],
    'recraft': ['recraftv3', 'recraftv2'],
  };

  final List<String> _recraftStyles = [
    'realistic_image',
    'digital_illustration',
    'vector_illustration',
    'icon',
    'logo_raster',
  ];

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.currentPrompt);
    _selectedService = widget.currentService;
    _selectedModel = widget.currentModel;

    // Встановлюємо стиль за замовчуванням для Recraft
    if (_selectedService == 'recraft') {
      _selectedStyle = 'realistic_image';
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        'Розширена перегенерація',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Промпт
            const Text(
              'Промпт:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Введіть новий промпт...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
              ),
            ),
            const SizedBox(height: 16),

            // Сервіс
            const Text(
              'Сервіс:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedService,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
              ),
              items: _serviceModels.keys.map((service) {
                return DropdownMenuItem(
                  value: service,
                  child: Text(service.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedService = value!;
                  // Оновлюємо модель при зміні сервісу
                  _selectedModel = _serviceModels[_selectedService]!.first;
                  // Встановлюємо стиль для Recraft
                  if (_selectedService == 'recraft') {
                    _selectedStyle = _recraftStyles.first;
                  } else {
                    _selectedStyle = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Модель
            const Text(
              'Модель:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedModel,
              dropdownColor: const Color(0xFF2C2C2C),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF2C2C2C),
              ),
              items: _serviceModels[_selectedService]!.map((model) {
                return DropdownMenuItem(value: model, child: Text(model));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedModel = value!;
                });
              },
            ),

            // Стиль для Recraft
            if (_selectedService == 'recraft') ...[
              const SizedBox(height: 16),
              const Text(
                'Стиль:',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedStyle,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF2C2C2C),
                ),
                items: _recraftStyles.map((style) {
                  return DropdownMenuItem(
                    value: style,
                    child: Text(style.replaceAll('_', ' ').toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStyle = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Скасувати', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            final result = {
              'prompt': _promptController.text.trim(),
              'service': _selectedService,
              'model': _selectedModel,
              if (_selectedStyle != null) 'style': _selectedStyle,
            };
            Navigator.of(context).pop(result);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
          child: const Text(
            'ПЕРЕГЕНЕРУВАТИ',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
