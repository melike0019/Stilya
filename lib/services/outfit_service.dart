import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/outfit_model.dart';

class OutfitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının kombin koleksiyonuna kısayol
  CollectionReference _outfitsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('outfits');
  }

  // --- KOMBİN EKLE ---
  Future<OutfitModel> addOutfit({
    required String userId,
    required String name,
    required List<String> itemIds,
    String? occasion,
    String? mood,
    String? weatherCondition,
    String? description,
    String? makeupTips,
    String? skincareTips,
    String source = 'manual',
  }) async {
    try {
      final outfit = OutfitModel(
        id: '',
        userId: userId,
        name: name,
        itemIds: itemIds,
        occasion: occasion,
        mood: mood,
        weatherCondition: weatherCondition,
        description: description,
        makeupTips: makeupTips,
        skincareTips: skincareTips,
        source: source,
        createdAt: DateTime.now(),
      );

      final docRef = await _outfitsRef(userId).add(outfit.toFirestore());

      return OutfitModel(
  id: docRef.id,
  userId: outfit.userId,
  name: outfit.name,
  itemIds: outfit.itemIds,
  occasion: outfit.occasion,
  mood: outfit.mood,
  weatherCondition: outfit.weatherCondition,
  description: outfit.description,
  makeupTips: outfit.makeupTips,
  skincareTips: outfit.skincareTips,
  isFavorite: outfit.isFavorite,
  source: outfit.source,
  createdAt: outfit.createdAt,
);

    } catch (e) {
      throw 'Kombin eklenemedi: $e';
    }
  }

  // --- TÜM KOMBİNLERİ GETİR ---
  Future<List<OutfitModel>> getOutfits(String userId) async {
    try {
      final snapshot = await _outfitsRef(userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return OutfitModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw 'Kombinler alınamadı: $e';
    }
  }

  // --- KOMBİNLERİ STREAM OLARAK DİNLE ---
  Stream<List<OutfitModel>> watchOutfits(String userId) {
    return _outfitsRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return OutfitModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // --- FAVORİ KOMBİNLERİ GETİR ---
  Future<List<OutfitModel>> getFavoriteOutfits(String userId) async {
    try {
      final snapshot = await _outfitsRef(userId)
          .where('isFavorite', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return OutfitModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw 'Favori kombinler alınamadı: $e';
    }
  }

  // --- FAVORİYE EKLE / ÇIKAR ---
  Future<void> toggleFavorite({
    required String userId,
    required String outfitId,
    required bool isFavorite,
  }) async {
    try {
      await _outfitsRef(userId).doc(outfitId).update({
        'isFavorite': isFavorite,
      });
    } catch (e) {
      throw 'Favori güncellenemedi: $e';
    }
  }

  // --- KOMBİN GÜNCELLE ---
  Future<void> updateOutfit({
    required String userId,
    required String outfitId,
    String? name,
    List<String>? itemIds,
    String? occasion,
    String? mood,
    String? weatherCondition,
    String? description,
    String? makeupTips,
    String? skincareTips,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (name != null) updates['name'] = name;
      if (itemIds != null) updates['itemIds'] = itemIds;
      if (occasion != null) updates['occasion'] = occasion;
      if (mood != null) updates['mood'] = mood;
      if (weatherCondition != null) updates['weatherCondition'] = weatherCondition;
      if (description != null) updates['description'] = description;
      if (makeupTips != null) updates['makeupTips'] = makeupTips;
      if (skincareTips != null) updates['skincareTips'] = skincareTips;

      if (updates.isEmpty) return;

      await _outfitsRef(userId).doc(outfitId).update(updates);
    } catch (e) {
      throw 'Kombin güncellenemedi: $e';
    }
  }

  // --- KOMBİN SİL ---
  Future<void> deleteOutfit({
    required String userId,
    required String outfitId,
  }) async {
    try {
      await _outfitsRef(userId).doc(outfitId).delete();
    } catch (e) {
      throw 'Kombin silinemedi: $e';
    }
  }

  // --- HAVA DURUMUNA GÖRE FİLTRELE ---
  Future<List<OutfitModel>> getOutfitsByWeather({
    required String userId,
    required String weatherCondition,
  }) async {
    try {
      final snapshot = await _outfitsRef(userId)
          .where('weatherCondition', isEqualTo: weatherCondition)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return OutfitModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw 'Kombinler filtrelenemedi: $e';
    }
  }
}