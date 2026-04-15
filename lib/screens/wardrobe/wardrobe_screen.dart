import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../theme/app_theme.dart';
import 'add_clothing_screen.dart';

// ─── Silme onayı ─────────────────────────────────────────────────────────────
Future<void> _confirmDelete(
    BuildContext context, ClothingItem item) async {
  final userId = context.read<AuthProvider>().user?.id;
  if (userId == null) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFE53935), size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Kıyafeti Sil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5),
          children: [
            const TextSpan(text: '"'),
            TextSpan(
              text: item.category,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(
                text: '" gardırobundan silinecek.\nBu işlem geri alınamaz.'),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Sil'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    await context.read<ClothingProvider>().deleteItem(
          userId: userId,
          itemId: item.id,
          imageUrl: item.imageUrl,
        );
  }
}

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
      if (userId != null) context.read<ClothingProvider>().watchItems(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final clothing = context.watch<ClothingProvider>();
    final categories = clothing.categories;
    final items = clothing.filteredItems;

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Gardırop',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark)),
        actions: [
          if (clothing.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightRose,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${clothing.items.length} parça',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryRose),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (categories.length > 1) _buildCategoryFilter(clothing, categories),
          Expanded(child: _buildBody(clothing, items)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddClothingScreen()),
        ),
        backgroundColor: AppTheme.primaryRose,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Kıyafet Ekle',
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        elevation: 4,
      ),
    );
  }

  Widget _buildCategoryFilter(ClothingProvider clothing, List<String> categories) {
    return Container(
      color: Colors.white,
      child: SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: categories.length,
          itemBuilder: (_, index) {
            final cat = categories[index];
            final isSelected = cat == clothing.selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => clothing.selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryRose : AppTheme.bgEnd,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryRose : AppTheme.dividerColor,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : AppTheme.textMedium,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(ClothingProvider clothing, List<ClothingItem> items) {
    if (clothing.isLoading && clothing.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppTheme.primaryRose),
      );
    }

    if (clothing.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48,
                color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(clothing.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textLight)),
          ],
        ),
      );
    }

    if (items.isEmpty) return const _EmptyState();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => _ClothingCard(item: items[index]),
    );
  }
}

// ─── Clothing Card ───────────────────────────────────────────────────────────
class _ClothingCard extends StatefulWidget {
  final ClothingItem item;
  const _ClothingCard({required this.item});

  @override
  State<_ClothingCard> createState() => _ClothingCardState();
}

class _ClothingCardState extends State<_ClothingCard> {
  bool _pressing = false;

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
    return GestureDetector(
      onLongPress: () => _confirmDelete(context, widget.item),
      onLongPressStart: (_) => setState(() => _pressing = true),
      onLongPressEnd: (_) => setState(() => _pressing = false),
      onLongPressCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: const Color(0xFFF5EEF2),
                  child: CachedNetworkImage(
                    imageUrl: widget.item.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primaryRose),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 40, color: AppTheme.textLight),
                    ),
                  ),
                ),
                // Gradient overlay + kategori etiketi
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
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
                            widget.item.category,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ...widget.item.colors.take(3).map((colorName) {
                          final c = _colorMap[colorName] ?? Colors.grey;
                          return Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white60, width: 0.5),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                // Uzun basma ipucu — sağ üstte küçük silme ikonu
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: _pressing ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.lightRose,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.checkroom_outlined,
                  size: 48, color: AppTheme.primaryRose),
            ),
            const SizedBox(height: 20),
            Text(
              'Gardırop Henüz Boş',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 10),
            Text(
              'Kıyafetlerini ekleyerek dijital gardıropunu oluşturmaya başla!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textMedium, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
