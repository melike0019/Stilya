import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';

// ---------------------------------------------------------------------------
// Kombin önerisi veri modeli
// ---------------------------------------------------------------------------
class OutfitSuggestion {
  final String styleName;
  final List<String> itemIds;
  final String outfitDescription;
  final String makeupTips;
  final String skincareTips;
  final String motivationMessage;

  const OutfitSuggestion({
    required this.styleName,
    required this.itemIds,
    required this.outfitDescription,
    required this.makeupTips,
    required this.skincareTips,
    required this.motivationMessage,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    return OutfitSuggestion(
      styleName: json['styleName'] as String? ?? 'Günlük Şıklık',
      itemIds: List<String>.from(json['itemIds'] as List? ?? []),
      outfitDescription: json['outfitDescription'] as String? ?? '',
      makeupTips: json['makeupTips'] as String? ?? '',
      skincareTips: json['skincareTips'] as String? ?? '',
      motivationMessage: json['motivationMessage'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Chat mesajı
// ---------------------------------------------------------------------------
class ChatMessage {
  final String role; // 'user' veya 'model'
  final String content;

  const ChatMessage({required this.role, required this.content});
}

// ---------------------------------------------------------------------------
// AI Servisi — Gemini 1.5 Flash
// ---------------------------------------------------------------------------
class AIService {
  static final String _endpoint =
      '${ApiConfig.geminiBaseUrl}/${ApiConfig.geminiModel}:generateContent'
      '?key=${ApiConfig.geminiApiKey}';

  // -------------------------------------------------------------------------
  // KOMBİN ÖNERİSİ
  // -------------------------------------------------------------------------
  Future<OutfitSuggestion> getOutfitSuggestion({
    required List<ClothingItem> items,
    required WeatherModel weather,
    required String mood,
    required String occasion,
  }) async {
    _checkApiKey();

    final clothingList = items.isEmpty
        ? 'Gardırop boş.'
        : items
            .map((i) =>
                '• ID:${i.id} | ${i.category} | Renkler: ${i.colors.join(", ")} '
                '| Mevsimler: ${i.seasons.join(", ")}'
                '${i.brand != null ? " | Marka: ${i.brand}" : ""}')
            .join('\n');

    final prompt = '''
Sen STILYA uygulamasının yapay zeka stil asistanısın.
Görevin: Kullanıcının gardırobundaki mevcut kıyafetleri analiz ederek bugüne özel kombin önermek.

== KULLANICI GARDIROBU ==
$clothingList

== BUGÜNÜN KOŞULLARI ==
Hava: ${weather.conditionForPrompt}
Ruh hali: $mood
Etkinlik: $occasion

== KURALLAR ==
1. Sadece gardırop listesindeki kıyafetleri kullan. ID'leri aynen kopyala.
2. Hava koşullarına ve mevsime uygun seçimler yap.
3. Ruh hali ve etkinliğe uygun bir stil oluştur.
4. Yanıtını YALNIZCA aşağıdaki JSON formatında ver. JSON dışında hiçbir metin ekleme.

{
  "styleName": "stilin kısa ve çarpıcı adı (örn: Profesyonel Zarafet)",
  "itemIds": ["gardıroptan seçilen ID'ler"],
  "outfitDescription": "kombini ve tercih nedenlerini açıklayan 2-3 Türkçe cümle",
  "makeupTips": "ruh haline ve etkinliğe uygun somut makyaj önerileri (ürün tonları, teknikler)",
  "skincareTips": "bugünün hava koşullarına göre cilt bakım adımları",
  "motivationMessage": "kullanıcıyı güne hazırlayan kişisel ve ilham verici 1-2 cümle"
}''';

    final raw = await _callGemini([
      {'role': 'user', 'parts': prompt},
    ]);

    final jsonStr = _extractJson(raw);
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return OutfitSuggestion.fromJson(data);
    } catch (_) {
      throw 'AI yanıtı işlenemedi. Lütfen tekrar dene.';
    }
  }

  // -------------------------------------------------------------------------
  // CHAT — Çok turlu doğal dil konuşması
  // -------------------------------------------------------------------------
  Future<String> chat({
    required List<ChatMessage> history,
    List<ClothingItem> clothingItems = const [],
  }) async {
    _checkApiKey();

    final wardrobeSummary = clothingItems.isEmpty
        ? 'Gardırop henüz boş.'
        : clothingItems
            .map((i) => '${i.category} (${i.colors.join(", ")})')
            .join(', ');

    // İlk kullanıcı mesajına sistem bağlamını ekle
    final systemPart =
        'Sen STILYA uygulamasının kişisel stil asistanısın. '
        'Kullanıcıyla samimi, destekleyici ve ilham verici bir üslupla Türkçe konuş. '
        'Moda, stil kombinleri ve güzellik konularında uzmansın. '
        'Kullanıcının mevcut gardırobu: $wardrobeSummary\n\n';

    // Mesaj geçmişini Gemini multi-turn formatına dönüştür
    final contents = <Map<String, dynamic>>[];

    for (var i = 0; i < history.length; i++) {
      final msg = history[i];
      final text = (i == 0 && msg.role == 'user')
          ? '$systemPart${msg.content}'
          : msg.content;

      contents.add({
        'role': msg.role,
        'parts': [{'text': text}],
      });
    }

    return await _callGemini(contents);
  }

  // -------------------------------------------------------------------------
  // Gemini API çağrısı
  // -------------------------------------------------------------------------
  Future<String> _callGemini(List<Map<String, dynamic>> contents) async {
    // Kısa prompt'lar için parts'ı string olarak da destekle
    final formattedContents = contents.map((c) {
      final parts = c['parts'];
      if (parts is String) {
        return {
          'role': c['role'],
          'parts': [{'text': parts}],
        };
      }
      return c;
    }).toList();

    final body = jsonEncode({
      'contents': formattedContents,
      'generationConfig': {
        'temperature': 0.8,
        'maxOutputTokens': 1024,
        'topP': 0.9,
      },
    });

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw 'AI yanıt üretemedi. Tekrar dene.';
        }
        return candidates[0]['content']['parts'][0]['text'] as String;
      case 400:
        throw 'Geçersiz Gemini isteği. API anahtarını kontrol et.';
      case 403:
        throw 'Gemini API erişim reddedildi. Anahtarı kontrol et.';
      case 429:
        throw 'Gemini istek limiti aşıldı. Biraz bekle.';
      default:
        throw 'AI servisi hatası (${response.statusCode}).';
    }
  }

  /// Gemini bazen JSON'u ```json … ``` bloğuna sarar — temizle.
  String _extractJson(String text) {
    final mdBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = mdBlock.firstMatch(text);
    if (match != null) return match.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text.trim();
  }

  void _checkApiKey() {
    if (ApiConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      throw 'Gemini API anahtarı girilmemiş.\n'
          'lib/core/api_config.dart dosyasında geminiApiKey alanını doldur.';
    }
  }
}
