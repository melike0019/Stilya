import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/clothing_item_model.dart';
import '../providers/auth_provider.dart';
import '../providers/clothing_provider.dart';
import '../providers/outfit_provider.dart';
import '../theme/app_theme.dart';
import 'home/home_screen.dart';
import 'wardrobe/wardrobe_screen.dart';
import 'outfit/outfit_screen.dart';
import 'planner/planner_screen.dart';
import 'profile/profile_screen.dart';

// Sallama eşiği (m/s²) ve bekleme süresi
const double _kShakeThreshold = 18.0;
const Duration _kShakeCooldown = Duration(seconds: 3);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  DateTime _lastShake = DateTime(2000);
  bool _sheetOpen = false;

  static const List<Widget> _screens = [
    HomeScreen(),
    WardrobeScreen(),
    OutfitScreen(),
    PlannerScreen(),
    ProfileScreen(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_outlined,    selectedIcon: Icons.home_rounded,          label: 'Ana Sayfa'),
    _NavItem(icon: Icons.checkroom_outlined, selectedIcon: Icons.checkroom,           label: 'Gardırop'),
    _NavItem(icon: Icons.style_outlined,   selectedIcon: Icons.style,                 label: 'Kombin'),
    _NavItem(icon: Icons.calendar_month_outlined, selectedIcon: Icons.calendar_month, label: 'Ajanda'),
    _NavItem(icon: Icons.person_outline,   selectedIcon: Icons.person_rounded,        label: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startListening();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _accelSub?.resume();
    } else {
      _accelSub?.pause();
    }
  }

  void _startListening() {
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final now = DateTime.now();
      if (magnitude > _kShakeThreshold &&
          now.difference(_lastShake) > _kShakeCooldown &&
          !_sheetOpen) {
        _lastShake = now;
        _onShake();
      }
    });
  }

  void _onShake() {
    final clothing = context.read<ClothingProvider>();
    if (clothing.items.isEmpty) return;

    final outfit = _buildRandomOutfit(clothing.items);
    if (outfit.isEmpty) return;

    _sheetOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShakeOutfitSheet(
        items: outfit,
        allItems: clothing.items,
      ),
    ).whenComplete(() => _sheetOpen = false);
  }

  /// Mevsimine uygun kıyafetleri kategoriye göre rastgele seçer.
  List<ClothingItem> _buildRandomOutfit(List<ClothingItem> all) {
    final season = _currentSeason();
    final rng = Random();

    // Mevsime uyan parçalar, yoksa tümü kullanılır
    final pool = all.where((i) => i.seasons.contains(season)).toList();
    final source = pool.isEmpty ? all : pool;

    // Kategori grupları — öncelik sırasına göre
    final groups = <String, List<ClothingItem>>{};
    for (final item in source) {
      groups.putIfAbsent(item.category, () => []).add(item);
    }

    final result = <ClothingItem>[];
    // Öncelikli kategorilerden birer parça seç
    const priority = [
      'Üst Giyim', 'Alt Giyim', 'Elbise / Tulum',
      'Ayakkabı', 'Dış Giyim', 'Aksesuar', 'Çanta',
    ];
    for (final cat in priority) {
      final list = groups[cat];
      if (list != null && list.isNotEmpty) {
        result.add(list[rng.nextInt(list.length)]);
      }
    }
    // Kalan kategorilerden de ekle
    for (final cat in groups.keys) {
      if (!priority.contains(cat) && groups[cat]!.isNotEmpty) {
        result.add(groups[cat]![rng.nextInt(groups[cat]!.length)]);
      }
    }

    return result.take(5).toList(); // Maksimum 5 parça
  }

  String _currentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withAlpha(25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_navItems.length, (i) {
              return _NavButton(
                item: _navItems[i],
                selected: _currentIndex == i,
                onTap: () => setState(() => _currentIndex = i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── Salla-Giy Bottom Sheet ───────────────────────────────────────────────────
class _ShakeOutfitSheet extends StatefulWidget {
  final List<ClothingItem> items;
  final List<ClothingItem> allItems;

  const _ShakeOutfitSheet({
    required this.items,
    required this.allItems,
  });

  @override
  State<_ShakeOutfitSheet> createState() => _ShakeOutfitSheetState();
}

class _ShakeOutfitSheetState extends State<_ShakeOutfitSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saved || _saving) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    final season = _seasonLabel();
    final ok = await context.read<OutfitProvider>().addOutfit(
          userId: userId,
          name: 'Salla-Giy: $season Kombini',
          itemIds: widget.items.map((i) => i.id).toList(),
          source: 'manual',
        );
    if (mounted) {
      setState(() {
        _saving = false;
        if (ok) _saved = true;
      });
    }
  }

  String _seasonLabel() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'İlkbahar';
    if (month >= 6 && month <= 8) return 'Yaz';
    if (month >= 9 && month <= 11) return 'Sonbahar';
    return 'Kış';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 16, 20,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tutamaç
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text('🎲', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salla-Giy!',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark),
                      ),
                      Text(
                        '${_seasonLabel()} kombinin hazır ✨',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kıyafet fotoğrafları
            ScaleTransition(
              scale: _scaleAnim,
              child: SizedBox(
                height: 150,
                child: Row(
                  children: widget.items
                      .map((item) => Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                right: item != widget.items.last ? 6 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF4F7),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppTheme.dividerColor),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  Expanded(
                                    child: CachedNetworkImage(
                                      imageUrl: item.imageUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      placeholder: (_, _) => const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              color: AppTheme.primaryRose),
                                        ),
                                      ),
                                      errorWidget: (_, _, _) => const Center(
                                        child: Icon(Icons.checkroom_outlined,
                                            color: AppTheme.textLight,
                                            size: 24),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3),
                                    color: Colors.white,
                                    child: Text(
                                      item.category,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: AppTheme.textMedium,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Butonlar
            Row(
              children: [
                // Tekrar Sal
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Kısa gecikme sonra tekrar tetikle
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (context.mounted) {
                          final clothing = context.read<ClothingProvider>();
                          if (clothing.items.isNotEmpty) {
                            final shell = context
                                .findAncestorStateOfType<_MainShellState>();
                            shell?._onShake();
                          }
                        }
                      });
                    },
                    icon: const Text('🎲', style: TextStyle(fontSize: 14)),
                    label: Text('Tekrar Sal',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Kaydet
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saved ? null : (_saving ? null : _save),
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(
                            _saved
                                ? Icons.check_rounded
                                : Icons.bookmark_add_outlined,
                            size: 18,
                          ),
                    label: Text(
                      _saved
                          ? 'Kaydedildi'
                          : _saving
                              ? 'Kaydediliyor…'
                              : 'Kombinimi Kaydet',
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Item & Button ────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: selected ? 44 : 36,
              height: selected ? 32 : 28,
              decoration: selected
                  ? BoxDecoration(
                      color: AppTheme.lightRose,
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: selected ? AppTheme.primaryRose : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppTheme.primaryRose : AppTheme.textLight,
                fontFamily: 'Poppins',
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
