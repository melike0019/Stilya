import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/clothing_item_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/outfit_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import 'ai_chat_screen.dart';

// ─── Sabit veriler ─────────────────────────────────────────────────────────
const List<Map<String, String>> _moods = [
  {'label': 'Enerjik',   'emoji': '⚡'},
  {'label': 'Özgüvenli', 'emoji': '✨'},
  {'label': 'Sakin',     'emoji': '🌿'},
  {'label': 'Romantik',  'emoji': '🌸'},
  {'label': 'Yaratıcı',  'emoji': '🎨'},
  {'label': 'Stresli',   'emoji': '😤'},
];

const List<Map<String, String>> _occasions = [
  {'label': 'Günlük',        'emoji': '☀️'},
  {'label': 'İş / Toplantı', 'emoji': '💼'},
  {'label': 'Brunch',        'emoji': '🥂'},
  {'label': 'Spor',          'emoji': '🏃'},
  {'label': 'Gece Çıkışı',   'emoji': '🌙'},
  {'label': 'Ev',            'emoji': '🏠'},
];

const Map<String, IconData> _weatherIcons = {
  'Clear': Icons.wb_sunny_rounded,
  'Clouds': Icons.cloud_rounded,
  'Rain': Icons.umbrella_rounded,
  'Drizzle': Icons.grain,
  'Thunderstorm': Icons.thunderstorm_rounded,
  'Snow': Icons.ac_unit_rounded,
  'Mist': Icons.blur_on_rounded,
  'Fog': Icons.blur_on_rounded,
  'Haze': Icons.blur_on_rounded,
};

// ─── HomeScreen ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood     = 'Enerjik';
  String _selectedOccasion = 'Günlük';

  List<OutfitSuggestion>? _suggestions;
  bool _isSuggesting    = false;
  String? _suggestionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  Future<void> _getSuggestion() async {
    final clothing    = context.read<ClothingProvider>();
    final weatherProv = context.read<WeatherProvider>();

    if (clothing.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce Gardırop sekmesinden kıyafet ekle!')),
      );
      return;
    }
    if (!weatherProv.hasWeather) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hava durumu henüz yüklenmedi.')),
      );
      return;
    }

    setState(() {
      _isSuggesting    = true;
      _suggestions     = null;
      _suggestionError = null;
    });

    try {
      final results = await context.read<AIService>().getOutfitSuggestion(
        items: clothing.items,
        weather: weatherProv.weather!,
        mood: _selectedMood,
        occasion: _selectedOccasion,
      );
      if (mounted) setState(() => _suggestions = results);
    } catch (e) {
      if (mounted) setState(() => _suggestionError = e.toString());
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final user     = auth.user;
    final dn       = user?.displayName;
    final name     = (dn != null && dn.isNotEmpty)
        ? dn.split(' ').first
        : (user?.email ?? 'Kullanıcı');
    final weather  = context.watch<WeatherProvider>();
    final clothing = context.watch<ClothingProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bgStart,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkRose, AppTheme.primaryRose],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Merhaba, $name ✨',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bugün nasıl bir stil yaratmak istersin?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ),
              titlePadding: EdgeInsets.zero,
              title: null,
            ),
            title: Text(
              'STILYA',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                tooltip: 'Stil Asistanı',
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.lightRose,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: AppTheme.primaryRose),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AIChatScreen(clothingItems: clothing.items),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ── Body ────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hava Durumu
                _WeatherCard(provider: weather),
                const SizedBox(height: 20),

                // Mood
                _SectionHeader(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Nasıl hissediyorsun?',
                ),
                const SizedBox(height: 10),
                _HorizontalChips(
                  items: _moods,
                  selected: _selectedMood,
                  onSelect: (v) => setState(() => _selectedMood = v),
                ),
                const SizedBox(height: 20),

                // Occasion
                _SectionHeader(
                  icon: Icons.event_note_outlined,
                  title: 'Bugün ne var?',
                ),
                const SizedBox(height: 10),
                _HorizontalChips(
                  items: _occasions,
                  selected: _selectedOccasion,
                  onSelect: (v) => setState(() => _selectedOccasion = v),
                ),
                const SizedBox(height: 24),

                // AI Button
                _SuggestButton(
                  isSuggesting: _isSuggesting,
                  onPressed: _getSuggestion,
                ),
                const SizedBox(height: 12),

                // Stil Asistanı
                _ChatButton(clothingItems: clothing.items),

                // Error
                if (_suggestionError != null) ...[
                  const SizedBox(height: 12),
                  _ErrorCard(message: _suggestionError!),
                ],

                // Kombin seçenekleri
                if (_suggestions != null && _suggestions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.style_outlined,
                          size: 16, color: AppTheme.primaryRose),
                      const SizedBox(width: 6),
                      Text(
                        '${_suggestions!.length} Kombin Seçeneği',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_suggestions!.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _SuggestionCard(
                      suggestion: _suggestions![i],
                      allItems: clothing.items,
                      outfitNumber: i + 1,
                    ),
                  )),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hava Durumu Kartı ──────────────────────────────────────────────────────
class _WeatherCard extends StatelessWidget {
  final WeatherProvider provider;
  const _WeatherCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppTheme.lightRose,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppTheme.primaryRose),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE8F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.textLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(provider.errorMessage!,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppTheme.textLight)),
            ),
          ],
        ),
      );
    }

    final w = provider.weather;
    if (w == null) return const SizedBox.shrink();

    final icon = _weatherIcons[w.condition] ?? Icons.wb_cloudy_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkRose, AppTheme.primaryRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.cityName,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.white.withAlpha(180)),
                ),
                Text(
                  w.temperatureStr,
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                Text(
                  w.conditionTr,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white.withAlpha(200)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WeatherBadge(icon: Icons.water_drop_outlined,
                  value: '%${w.humidity}'),
              const SizedBox(height: 6),
              _WeatherBadge(icon: Icons.air_rounded,
                  value: '${w.windSpeed.toStringAsFixed(1)} m/s'),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeatherBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  const _WeatherBadge({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryRose),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: AppTheme.textDark),
        ),
      ],
    );
  }
}

// ─── Horizontal Chip List ────────────────────────────────────────────────────
class _HorizontalChips extends StatelessWidget {
  final List<Map<String, String>> items;
  final String selected;
  final ValueChanged<String> onSelect;
  const _HorizontalChips({
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item  = items[i];
          final label = item['label']!;
          final isSelected = selected == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryRose : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryRose
                        : AppTheme.dividerColor,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryRose.withAlpha(50),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  '${item['emoji']} $label',
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
    );
  }
}

// ─── Suggest Button ─────────────────────────────────────────────────────────
class _SuggestButton extends StatelessWidget {
  final bool isSuggesting;
  final VoidCallback onPressed;
  const _SuggestButton({required this.isSuggesting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSuggesting ? null : onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: isSuggesting
              ? null
              : const LinearGradient(
                  colors: [AppTheme.darkRose, AppTheme.primaryRose],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          color: isSuggesting ? AppTheme.lightRose : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSuggesting
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryRose.withAlpha(70),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSuggesting)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.primaryRose))
            else
              const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              isSuggesting ? 'Kombin Hazırlanıyor…' : 'Kombin Öner',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSuggesting ? AppTheme.primaryRose : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Chat Button ─────────────────────────────────────────────────────────────
class _ChatButton extends StatelessWidget {
  final List<ClothingItem> clothingItems;
  const _ChatButton({required this.clothingItems});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AIChatScreen(clothingItems: clothingItems)),
      ),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: AppTheme.primaryRose, size: 18),
            const SizedBox(width: 10),
            Text(
              'Stil Asistanıyla Konuş',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryRose),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error Card ──────────────────────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Suggestion Card ─────────────────────────────────────────────────────────
class _SuggestionCard extends StatefulWidget {
  final OutfitSuggestion suggestion;
  final List<ClothingItem> allItems;
  final int outfitNumber;

  const _SuggestionCard({
    required this.suggestion,
    required this.allItems,
    required this.outfitNumber,
  });

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _saved = false;
  bool _saving = false;

  /// AI bazen "ID:xxxx" formatında döner, bazen sadece "xxxx" — ikisini de yakala.
  List<ClothingItem> get _matchedItems {
    final cleanIds = widget.suggestion.itemIds
        .map((id) => id.startsWith('ID:') ? id.substring(3) : id)
        .toSet();
    return widget.allItems.where((item) => cleanIds.contains(item.id)).toList();
  }

  Future<void> _saveOutfit() async {
    if (_saved || _saving) return;
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _saving = true);
    final ok = await context.read<OutfitProvider>().addOutfit(
          userId: userId,
          name: widget.suggestion.styleName,
          itemIds: widget.suggestion.itemIds,
          description: widget.suggestion.outfitDescription,
          makeupTips: widget.suggestion.makeupTips,
          skincareTips: widget.suggestion.skincareTips,
          source: 'ai',
        );
    if (mounted) setState(() { _saving = false; if (ok) _saved = true; });
  }

  @override
  Widget build(BuildContext context) {
    final matched = _matchedItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRose.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Kombin Numarası + Stil Adı başlık bandı ──────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${widget.outfitNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.suggestion.styleName,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else if (_saved)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20)
                else
                  GestureDetector(
                    onTap: _saveOutfit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Kaydet',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Kıyafet Fotoğrafları (Mosaic Grid) ───────────────────
          if (matched.isNotEmpty)
            _OutfitPhotosMosaic(items: matched)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFFFFF0F5),
              child: Column(
                children: [
                  const Icon(Icons.checkroom_outlined,
                      color: AppTheme.primaryRose, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'Gardıroba kıyafet ekledikçe\nburada fotoğraflar görünecek',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textMedium),
                  ),
                ],
              ),
            ),

          // ── Metin İçerik ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Açıklama
                Text(
                  widget.suggestion.outfitDescription,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppTheme.textMedium, height: 1.6),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppTheme.dividerColor),
                ),

                // Makyaj & cilt bakımı
                _TipRow(icon: Icons.brush_outlined, label: 'Makyaj',
                    text: widget.suggestion.makeupTips),
                const SizedBox(height: 10),
                _TipRow(icon: Icons.spa_outlined, label: 'Cilt Bakımı',
                    text: widget.suggestion.skincareTips),
                const SizedBox(height: 12),

                // Motivasyon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0F5), Color(0xFFFCE8F3)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded,
                          color: AppTheme.primaryRose, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.suggestion.motivationMessage,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kıyafet Fotoğraf Şeridi ─────────────────────────────────────────────────
// ≤4 parça → eşit genişlikte sütunlar, ekranı doldurur
//  5+ parça → yatay kaydırmalı sabit genişlik kartlar
// BoxFit.contain → fotoğraf hiç kırpılmadan tam görünür
class _OutfitPhotosMosaic extends StatelessWidget {
  final List<ClothingItem> items;
  const _OutfitPhotosMosaic({required this.items});

  // Fotoğraf alanı yüksekliği
  static const double _photoH = 160;
  // Kategori etiket alanı yüksekliği
  static const double _labelH = 24;
  // 5+ parça için sabit hücre genişliği
  static const double _scrollCellW = 100;

  @override
  Widget build(BuildContext context) {
    final totalH = _photoH + _labelH;

    if (items.length <= 4) {
      // Tüm parçalar yan yana, ekranı eşit böler
      return SizedBox(
        height: totalH,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(items.length, (i) {
            final last = i == items.length - 1;
            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: last
                      ? null
                      : const Border(
                          right: BorderSide(
                              color: Color(0xFFEDD5E2), width: 1)),
                ),
                child: _cell(items[i]),
              ),
            );
          }),
        ),
      );
    }

    // 5+ parça: kaydırılabilir
    return SizedBox(
      height: totalH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => SizedBox(
          width: _scrollCellW,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDD5E2)),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: _cell(items[i]),
          ),
        ),
      ),
    );
  }

  Widget _cell(ClothingItem item) {
    return Column(
      children: [
        // Fotoğraf alanı — açık pembe zemin, contain fit
        SizedBox(
          height: _photoH,
          child: ColoredBox(
            color: const Color(0xFFFAF4F7),
            child: CachedNetworkImage(
              imageUrl: item.imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: _photoH,
              placeholder: (_, _) => const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: AppTheme.primaryRose),
                ),
              ),
              errorWidget: (_, _, _) => const Center(
                child: Icon(Icons.checkroom_outlined,
                    color: AppTheme.textLight, size: 24),
              ),
            ),
          ),
        ),
        // Kategori etiketi — beyaz zemin, fotoğrafın altında
        Container(
          height: _labelH,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFEDD5E2), width: 0.5),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.category,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 9,
              color: AppTheme.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _TipRow({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.lightRose,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppTheme.primaryRose),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppTheme.textDark)),
              const SizedBox(height: 2),
              Text(text,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppTheme.textMedium, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
