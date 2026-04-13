import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/clothing_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/ai_service.dart';
import 'ai_chat_screen.dart';

// ---------------------------------------------------------------------------
// Sabit veriler
// ---------------------------------------------------------------------------
const List<Map<String, String>> _moods = [
  {'label': 'Enerjik', 'emoji': '⚡'},
  {'label': 'Özgüvenli', 'emoji': '💪'},
  {'label': 'Sakin', 'emoji': '🌿'},
  {'label': 'Romantik', 'emoji': '🌸'},
  {'label': 'Yaratıcı', 'emoji': '🎨'},
  {'label': 'Stresli', 'emoji': '😤'},
];

const List<Map<String, String>> _occasions = [
  {'label': 'Günlük', 'emoji': '☀️'},
  {'label': 'İş / Toplantı', 'emoji': '💼'},
  {'label': 'Brunch', 'emoji': '🥂'},
  {'label': 'Spor', 'emoji': '🏃'},
  {'label': 'Gece Çıkışı', 'emoji': '🌙'},
  {'label': 'Ev', 'emoji': '🏠'},
];

const Map<String, IconData> _weatherIcons = {
  'Clear': Icons.wb_sunny,
  'Clouds': Icons.cloud,
  'Rain': Icons.umbrella,
  'Drizzle': Icons.grain,
  'Thunderstorm': Icons.thunderstorm,
  'Snow': Icons.ac_unit,
  'Mist': Icons.blur_on,
  'Fog': Icons.blur_on,
  'Haze': Icons.blur_on,
};

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMood = 'Enerjik';
  String _selectedOccasion = 'Günlük';

  OutfitSuggestion? _suggestion;
  bool _isSuggesting = false;
  String? _suggestionError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().fetchWeather();
    });
  }

  Future<void> _getSuggestion() async {
    final clothing = context.read<ClothingProvider>();
    final weatherProv = context.read<WeatherProvider>();

    if (clothing.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce Gardırop sekmesinden kıyafet ekle!'),
        ),
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
      _isSuggesting = true;
      _suggestion = null;
      _suggestionError = null;
    });

    try {
      final result = await AIService().getOutfitSuggestion(
        items: clothing.items,
        weather: weatherProv.weather!,
        mood: _selectedMood,
        occasion: _selectedOccasion,
      );
      if (mounted) setState(() => _suggestion = result);
    } catch (e) {
      if (mounted) setState(() => _suggestionError = e.toString());
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = user?.displayName;
    final name = (displayName != null && displayName.isNotEmpty)
        ? displayName.split(' ').first
        : (user?.email ?? 'Kullanıcı');
    final weather = context.watch<WeatherProvider>();
    final clothing = context.watch<ClothingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stilya'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Stil Asistanı',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AIChatScreen(
                  clothingItems: clothing.items,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // -----------------------------------------------------------------
          // 1. Selamlama
          // -----------------------------------------------------------------
          Text(
            'Merhaba, $name 👋',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Bugün nasıl bir stil yaratmak istersin?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // -----------------------------------------------------------------
          // 2. Hava Durumu Kartı
          // -----------------------------------------------------------------
          _WeatherCard(provider: weather),
          const SizedBox(height: 24),

          // -----------------------------------------------------------------
          // 3. Mod Seçimi
          // -----------------------------------------------------------------
          _SectionTitle('Nasıl hissediyorsun?'),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _moods.length,
              itemBuilder: (_, i) {
                final mood = _moods[i];
                final label = mood['label']!;
                final isSelected = _selectedMood == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${mood['emoji']} $label'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedMood = label),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // -----------------------------------------------------------------
          // 4. Etkinlik Seçimi
          // -----------------------------------------------------------------
          _SectionTitle('Bugün ne var?'),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _occasions.length,
              itemBuilder: (_, i) {
                final occ = _occasions[i];
                final label = occ['label']!;
                final isSelected = _selectedOccasion == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${occ['emoji']} $label'),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedOccasion = label),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // -----------------------------------------------------------------
          // 5. Kombin Öner Butonu
          // -----------------------------------------------------------------
          FilledButton.icon(
            onPressed: _isSuggesting ? null : _getSuggestion,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: _isSuggesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _isSuggesting ? 'Kombin hazırlanıyor…' : 'Kombin Öner',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 16),

          // -----------------------------------------------------------------
          // 6. Hata mesajı
          // -----------------------------------------------------------------
          if (_suggestionError != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _suggestionError!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),

          // -----------------------------------------------------------------
          // 7. AI Kombin Sonuç Kartı
          // -----------------------------------------------------------------
          if (_suggestion != null) ...[
            const SizedBox(height: 8),
            _SuggestionCard(suggestion: _suggestion!),
          ],

          // -----------------------------------------------------------------
          // 8. Stil Asistanı Butonu
          // -----------------------------------------------------------------
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AIChatScreen(clothingItems: clothing.items),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Stil Asistanıyla Konuş',
                style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hava Durumu Kartı
// ---------------------------------------------------------------------------
class _WeatherCard extends StatelessWidget {
  final WeatherProvider provider;
  const _WeatherCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (provider.errorMessage != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.errorMessage!,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final w = provider.weather;
    if (w == null) return const SizedBox.shrink();

    final icon = _weatherIcons[w.condition] ?? Icons.wb_cloudy;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, size: 48, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.cityName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                  Text(
                    w.temperatureStr,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    w.conditionTr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _WeatherStat(
                    icon: Icons.water_drop_outlined,
                    value: '%${w.humidity}'),
                const SizedBox(height: 6),
                _WeatherStat(
                    icon: Icons.air,
                    value: '${w.windSpeed.toStringAsFixed(1)} m/s'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _WeatherStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kombin Öneri Sonuç Kartı
// ---------------------------------------------------------------------------
class _SuggestionCard extends StatelessWidget {
  final OutfitSuggestion suggestion;
  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stil adı
            Row(
              children: [
                Icon(Icons.auto_awesome,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion.styleName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kombin açıklaması
            Text(
              suggestion.outfitDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Bölücü
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(),
            ),

            // Makyaj önerileri
            _TipRow(
              icon: Icons.brush_outlined,
              label: 'Makyaj',
              text: suggestion.makeupTips,
            ),
            const SizedBox(height: 12),

            // Cilt bakımı
            _TipRow(
              icon: Icons.spa_outlined,
              label: 'Cilt Bakımı',
              text: suggestion.skincareTips,
            ),
            const SizedBox(height: 14),

            // Motivasyon mesajı
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion.motivationMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(text,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Yardımcı — Bölüm başlığı
// ---------------------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

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
