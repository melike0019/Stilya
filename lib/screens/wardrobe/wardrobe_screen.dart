import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import 'add_clothing_screen.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<ClothingProvider>().watchItems(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final clothing = context.watch<ClothingProvider>();
    final categories = clothing.categories;
    final items = clothing.filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gardırop'),
        actions: [
          if (clothing.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${clothing.items.length} parça',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Kategori filtre chips — sadece 2+ kategori varsa göster
          if (categories.length > 1)
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = cat == clothing.selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => clothing.selectCategory(cat),
                    ),
                  );
                },
              ),
            ),
          Expanded(child: _buildBody(clothing, items)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddClothingScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Kıyafet Ekle'),
      ),
    );
  }

  Widget _buildBody(ClothingProvider clothing, List<ClothingItem> items) {
    if (clothing.isLoading && clothing.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clothing.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(clothing.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const _EmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ClothingCard(item: items[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Kıyafet kartı
// ---------------------------------------------------------------------------
class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  const _ClothingCard({required this.item});

  static const Map<String, Color> _colorMap = {
    'Siyah': Colors.black,
    'Beyaz': Color(0xFFF0F0F0),
    'Gri': Colors.grey,
    'Lacivert': Color(0xFF1B2A6B),
    'Mavi': Colors.blue,
    'Yeşil': Colors.green,
    'Kırmızı': Colors.red,
    'Pemke': Colors.pink,
    'Pembe': Colors.pink,
    'Mor': Colors.purple,
    'Sarı': Colors.amber,
    'Turuncu': Colors.orange,
    'Bej': Color(0xFFD4B896),
    'Kahverengi': Colors.brown,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fotoğraf
          CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (_, _, _) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Icon(Icons.broken_image_outlined,
                  size: 40, color: Colors.grey),
            ),
          ),
          // Alt gradient + etiket
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.category,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Renk noktaları (max 3)
                  ...item.colors.take(3).map((colorName) {
                    final c = _colorMap[colorName] ?? Colors.grey;
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 0.5),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Boş durum
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withAlpha(100),
            ),
            const SizedBox(height: 20),
            Text(
              'Gardırop henüz boş',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kıyafetlerini ekleyerek dijital gardıropunu oluşturmaya başla!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
