import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';

class AddClothingScreen extends StatefulWidget {
  const AddClothingScreen({super.key});

  @override
  State<AddClothingScreen> createState() => _AddClothingScreenState();
}

class _AddClothingScreenState extends State<AddClothingScreen> {
  File? _imageFile;
  String _selectedCategory = 'Üst Giyim';
  final List<String> _selectedColors = [];
  final List<String> _selectedSeasons = [];
  final _brandController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;

  static const List<String> _categories = [
    'Üst Giyim',
    'Alt Giyim',
    'Dış Giyim',
    'Elbise / Tulum',
    'Aksesuar',
    'Ayakkabı',
    'Çanta',
    'Diğer',
  ];

  static const List<String> _colors = [
    'Siyah',
    'Beyaz',
    'Gri',
    'Lacivert',
    'Mavi',
    'Yeşil',
    'Kırmızı',
    'Pembe',
    'Mor',
    'Sarı',
    'Turuncu',
    'Bej',
    'Kahverengi',
  ];

  static const List<String> _seasons = [
    'İlkbahar',
    'Yaz',
    'Sonbahar',
    'Kış',
  ];

  static const Map<String, Color> _colorMap = {
    'Siyah': Colors.black,
    'Beyaz': Color(0xFFF0F0F0),
    'Gri': Colors.grey,
    'Lacivert': Color(0xFF1B2A6B),
    'Mavi': Colors.blue,
    'Yeşil': Colors.green,
    'Kırmızı': Colors.red,
    'Pembe': Colors.pink,
    'Mor': Colors.purple,
    'Sarı': Colors.amber,
    'Turuncu': Colors.orange,
    'Bej': Color(0xFFD4B896),
    'Kahverengi': Colors.brown,
  };

  @override
  void dispose() {
    _brandController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Fotoğraf Çek'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_imageFile == null) {
      _showSnack('Lütfen bir fotoğraf seçin.');
      return;
    }
    if (_selectedColors.isEmpty) {
      _showSnack('En az bir renk seçin.');
      return;
    }
    if (_selectedSeasons.isEmpty) {
      _showSnack('En az bir mevsim seçin.');
      return;
    }

    setState(() => _saving = true);

    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      setState(() => _saving = false);
      return;
    }

    final ok = await context.read<ClothingProvider>().addItem(
          userId: userId,
          imageFile: _imageFile!,
          category: _selectedCategory,
          colors: List.from(_selectedColors),
          seasons: List.from(_selectedSeasons),
          brand: _brandController.text.trim().isEmpty
              ? null
              : _brandController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      _showSnack(
        context.read<ClothingProvider>().errorMessage ?? 'Kıyafet eklenemedi.',
      );
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kıyafet Ekle'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------------
            // Fotoğraf seçici
            // ---------------------------------------------------------------
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 52,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fotoğraf eklemek için dokun',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit,
                                  size: 16, color: Colors.white),
                              onPressed: _showImageSourceSheet,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // ---------------------------------------------------------------
            // Kategori
            // ---------------------------------------------------------------
            const _SectionLabel('Kategori'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                return ChoiceChip(
                  label: Text(cat),
                  selected: _selectedCategory == cat,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ---------------------------------------------------------------
            // Renk
            // ---------------------------------------------------------------
            const _SectionLabel('Renk'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((colorName) {
                final isSelected = _selectedColors.contains(colorName);
                return FilterChip(
                  avatar: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _colorMap[colorName],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                  ),
                  label: Text(colorName),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val
                          ? _selectedColors.add(colorName)
                          : _selectedColors.remove(colorName);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ---------------------------------------------------------------
            // Mevsim
            // ---------------------------------------------------------------
            const _SectionLabel('Mevsim'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _seasons.map((season) {
                final isSelected = _selectedSeasons.contains(season);
                return FilterChip(
                  label: Text(season),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      val
                          ? _selectedSeasons.add(season)
                          : _selectedSeasons.remove(season);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ---------------------------------------------------------------
            // Marka (isteğe bağlı)
            // ---------------------------------------------------------------
            const _SectionLabel('Marka (İsteğe Bağlı)'),
            const SizedBox(height: 10),
            TextField(
              controller: _brandController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'Örn: Zara, H&M, Mango...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),

            // ---------------------------------------------------------------
            // Notlar (isteğe bağlı)
            // ---------------------------------------------------------------
            const _SectionLabel('Notlar (İsteğe Bağlı)'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Kıyafet hakkında notlar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 36),

            // ---------------------------------------------------------------
            // Kaydet butonu
            // ---------------------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Gardıroba Ekle',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
