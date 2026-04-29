import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/clothing_item_model.dart';
import '../models/weather_model.dart';

// ---------------------------------------------------------------------------
// Markdown temizleyici — AI bazen ** * # - gibi işaretler ekler
// ---------------------------------------------------------------------------
String _clean(String raw) {
  return raw
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!) // **bold**
      .replaceAllMapped(RegExp(r'\*(.+?)\*'),     (m) => m[1]!) // *italic*
      .replaceAll(RegExp(r'#+\s*'),               '')            // # Başlık
      .replaceAll(RegExp(r'^\s*[-•]\s+', multiLine: true), '')  // - madde
      .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '') // 1. madde
      .replaceAll(RegExp(r'\n{3,}'),              '\n\n')        // fazla boşluk
      .trim();
}

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
    // ID: önekini temizle (AI bazen "ID:xxxx" formatında döner)
    final rawIds = List<String>.from(json['itemIds'] as List? ?? []);
    final cleanIds = rawIds
        .map((id) => id.startsWith('ID:') ? id.substring(3) : id)
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    return OutfitSuggestion(
      styleName:         _clean(json['styleName']         as String? ?? 'Günlük Şıklık'),
      itemIds:           cleanIds,
      outfitDescription: _clean(json['outfitDescription'] as String? ?? ''),
      makeupTips:        _clean(json['makeupTips']        as String? ?? ''),
      skincareTips:      _clean(json['skincareTips']      as String? ?? ''),
      motivationMessage: _clean(json['motivationMessage'] as String? ?? ''),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat mesajı
// ---------------------------------------------------------------------------
class ChatMessage {
  final String role;    // 'user' veya 'model'
  final String content;
  const ChatMessage({required this.role, required this.content});
}

// ---------------------------------------------------------------------------
// AI Servisi — Groq (OpenAI uyumlu, ücretsiz)
// ---------------------------------------------------------------------------
class AIService {
  static const String _chatEndpoint =
      '${ApiConfig.groqBaseUrl}/chat/completions';

  // -------------------------------------------------------------------------
  // KOMBİN ÖNERİSİ — min 3, mümkünse daha fazla seçenek
  // -------------------------------------------------------------------------
  Future<List<OutfitSuggestion>> getOutfitSuggestion({
    required List<ClothingItem> items,
    required WeatherModel weather,
    required String mood,
    required String occasion,
  }) async {
    _checkApiKey();

    // Gardırop listesini hazırla — geçerli ID'leri de ayrıca belirt
    final validIds = items.map((i) => i.id).toSet();

    final clothingList = items.isEmpty
        ? 'Gardırop boş.'
        : items.map((i) =>
            '• ID:${i.id} | ${i.category} | '
            'Renkler: ${i.colors.join(", ")} | '
            'Mevsimler: ${i.seasons.join(", ")}'
            '${i.brand != null ? " | Marka: ${i.brand}" : ""}',
          ).join('\n');

    final validIdList = items.map((i) => i.id).join(', ');

    const systemPrompt =
        'Sen STILYA uygulamasının yapay zeka stil asistanısın. '
        'Görevin kullanıcının gardırobundaki kıyafetleri analiz ederek '
        'hava durumuna, ruh haline ve etkinliğe uygun kombin seçenekleri önermek. '
        'Yanıtını HER ZAMAN geçerli bir JSON nesnesi olarak ver, '
        'başka hiçbir metin veya markdown işareti ekleme.';

    final userPrompt = '''
KULLANICI GARDIROBU (YALNIZCA BUNLARI KULLAN):
$clothingList

GEÇERLİ ID LİSTESİ: $validIdList

BUGÜNÜN KOŞULLARI:
Hava: ${weather.conditionForPrompt}
Ruh hali: $mood
Etkinlik: $occasion

KESİN KURALLAR (İHLAL ETMEDİĞİNDEN EMİN OL):
1. itemIds alanına YALNIZCA yukarıdaki GEÇERLİ ID LİSTESİ'ndeki ID'leri yaz. Başka hiçbir ID kabul edilmez.
2. Gardırop listesinde olmayan kıyafet, ayakkabı, aksesuar veya çanta ÖNERİLEMEZ.
3. Hava koşullarına ve mevsime uygun seçimler yap.
4. Tüm metinleri düz Türkçe yaz — **, *, #, - gibi markdown işaretleri kullanma.
5. Gardıruptaki parçalardan anlamlı şekilde farklılaşan EN AZ 3 kombin öner. Daha fazla anlamlı kombinasyon mümkünse ekleyebilirsin.
6. Her kombinde mümkünse üst giyim, alt giyim, aksesuar ve ayakkabı gibi farklı kategorilerden parçalar seç.
7. Yalnızca aşağıdaki JSON formatında yanıt ver:

{
  "outfits": [
    {
      "styleName": "stilin kısa adı",
      "itemIds": ["sadece geçerli ID'ler"],
      "outfitDescription": "kombini açıklayan 2-3 düz Türkçe cümle",
      "makeupTips": "somut makyaj önerileri, düz metin",
      "skincareTips": "hava koşullarına göre cilt bakım adımları, düz metin",
      "motivationMessage": "1-2 ilham verici cümle, düz metin"
    }
  ]
}''';

    final raw = await _callGroq(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user',   'content': userPrompt},
      ],
      maxTokens: 2048,
    );

    final jsonStr = _extractJson(raw);
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['outfits'] as List? ?? [];
      if (list.isEmpty) throw 'Boş liste';

      // Parse et ve geçersiz ID'leri filtrele
      final outfits = list
          .map((o) => OutfitSuggestion.fromJson(o as Map<String, dynamic>))
          .map((o) => OutfitSuggestion(
                styleName:         o.styleName,
                // Yalnızca gardıropta gerçekten var olan ID'leri tut
                itemIds:           o.itemIds.where(validIds.contains).toList(),
                outfitDescription: o.outfitDescription,
                makeupTips:        o.makeupTips,
                skincareTips:      o.skincareTips,
                motivationMessage: o.motivationMessage,
              ))
          // En az 1 eşleşen parçası olmayan kombinleri at
          .where((o) => o.itemIds.isNotEmpty)
          .toList();

      if (outfits.isEmpty) throw 'Geçerli kombin bulunamadı';
      return outfits;
    } catch (_) {
      throw 'AI yanıtı işlenemedi. Lütfen tekrar dene.';
    }
  }

  // -------------------------------------------------------------------------
  // KÖR NOKTA ANALİZİ — Uzun süredir giyilmemiş parçalarla kombin öner
  // -------------------------------------------------------------------------
  Future<List<OutfitSuggestion>> getBlindSpotSuggestion({
    required List<ClothingItem> forgottenItems,
    required List<ClothingItem> allItems,
  }) async {
    _checkApiKey();

    final validIds = allItems.map((i) => i.id).toSet();

    final forgottenList = forgottenItems.map((i) {
      final days = DateTime.now().difference(i.lastWornAt ?? i.createdAt).inDays;
      return '• ID:${i.id} | ${i.category} | '
          'Renkler: ${i.colors.join(", ")} | '
          'Mevsimler: ${i.seasons.join(", ")} | '
          '$days gündür giyilmedi';
    }).join('\n');

    final allList = allItems.map((i) =>
        '• ID:${i.id} | ${i.category} | Renkler: ${i.colors.join(", ")}')
        .join('\n');

    final validIdList = allItems.map((i) => i.id).join(', ');

    const systemPrompt =
        'Sen STILYA uygulamasının yapay zeka stil asistanısın. '
        'Görevin kullanıcının uzun süredir giymediği kıyafetleri yeniden keşfettirmek. '
        'Yanıtını HER ZAMAN geçerli bir JSON nesnesi olarak ver, '
        'başka hiçbir metin veya markdown işareti ekleme.';

    final userPrompt = '''
UZUN SÜREDİR GİYİLMEYEN KIYAFETLER (Her kombinде en az biri kullanılmalı):
$forgottenList

TÜM GARDİROP (Kombinleri tamamlamak için kullanabilirsin):
$allList

GEÇERLİ ID LİSTESİ: $validIdList

KESİN KURALLAR:
1. itemIds alanına YALNIZCA yukarıdaki GEÇERLİ ID LİSTESİ'ndeki ID'leri yaz.
2. Her kombinде en az bir "uzun süredir giyilmeyen" parça OLMALI.
3. Tüm metinleri düz Türkçe yaz — markdown işareti kullanma.
4. Farklılaşan EN AZ 3 kombin öner.
5. outfitDescription'da o parçanın neden bu kombinle mükemmel uyum sağladığını belirt.
6. Yalnızca aşağıdaki JSON formatında yanıt ver:

{
  "outfits": [
    {
      "styleName": "stilin kısa adı",
      "itemIds": ["sadece geçerli ID'ler"],
      "outfitDescription": "neden bu parçayı yeniden keşfetmen gerektiğini anlatan 2-3 cümle",
      "makeupTips": "bu kombinle uyumlu makyaj önerisi",
      "skincareTips": "cilt bakım hatırlatması",
      "motivationMessage": "gardırobundaki bu gizli hazineyi keşfetmen için ilham verici mesaj"
    }
  ]
}''';

    final raw = await _callGroq(
      messages: [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      maxTokens: 2048,
    );

    final jsonStr = _extractJson(raw);
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['outfits'] as List? ?? [];
      if (list.isEmpty) throw 'Boş liste';

      final outfits = list
          .map((o) => OutfitSuggestion.fromJson(o as Map<String, dynamic>))
          .map((o) => OutfitSuggestion(
                styleName: o.styleName,
                itemIds: o.itemIds.where(validIds.contains).toList(),
                outfitDescription: o.outfitDescription,
                makeupTips: o.makeupTips,
                skincareTips: o.skincareTips,
                motivationMessage: o.motivationMessage,
              ))
          .where((o) => o.itemIds.isNotEmpty)
          .toList();

      if (outfits.isEmpty) throw 'Geçerli kombin bulunamadı';
      return outfits;
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

    final systemPrompt =
        'Sen STILYA uygulamasının kişisel stil asistanısın. '
        'Kullanıcıyla samimi, destekleyici ve ilham verici bir üslupla '
        'Türkçe konuş. Moda, stil kombinleri ve güzellik konularında '
        'uzmansın. Kullanıcının gardırobu: $wardrobeSummary';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      // 'model' rolü Groq'ta geçersiz — 'assistant' olarak gönder
      ...history.map((m) => {
            'role':    m.role == 'model' ? 'assistant' : m.role,
            'content': m.content,
          }),
    ];

    return _callGroq(messages: messages);
  }

  // -------------------------------------------------------------------------
  // Groq API çağrısı (OpenAI uyumlu)
  // -------------------------------------------------------------------------
  Future<String> _callGroq({
    required List<Map<String, String>> messages,
    int retryCount = 0,
    int maxTokens = 1024,
  }) async {
    final response = await http
        .post(
          Uri.parse(_chatEndpoint),
          headers: {
            'Content-Type':  'application/json',
            'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          },
          body: jsonEncode({
            'model':       ApiConfig.groqModel,
            'messages':    messages,
            'temperature': 0.7,
            'max_tokens':  maxTokens,
          }),
        )
        .timeout(const Duration(seconds: 45));

    switch (response.statusCode) {
      case 200:
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      case 400:
        throw 'İstek hatası (400): ${response.body}';
      case 401:
        throw 'Groq API anahtarı geçersiz. api_config.dart dosyasını kontrol et.';
      case 429:
        if (retryCount < 1) {
          await Future.delayed(const Duration(seconds: 5));
          return _callGroq(messages: messages, retryCount: retryCount + 1, maxTokens: maxTokens);
        }
        throw 'İstek limiti aşıldı. Birkaç saniye bekleyip tekrar dene.';
      default:
        throw 'AI servisi hatası (${response.statusCode}): ${response.body}';
    }
  }

  /// Groq bazen JSON'u ```json … ``` bloğuna sarar — temizle.
  String _extractJson(String text) {
    final mdBlock = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = mdBlock.firstMatch(text);
    if (match != null) return match.group(1)!.trim();

    final start = text.indexOf('{');
    final end   = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text.trim();
  }

  void _checkApiKey() {
    if (ApiConfig.groqApiKey == 'YOUR_GROQ_API_KEY') {
      throw 'Groq API anahtarı girilmemiş.\n'
          'lib/core/api_config.dart dosyasında groqApiKey alanını doldur.';
    }
  }
}
