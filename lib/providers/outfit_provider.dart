import 'package:flutter/material.dart';
import '../models/outfit_model.dart';
import '../services/outfit_service.dart';
import 'dart:async';

enum OutfitStatus { initial, loading, loaded, error }

class OutfitProvider extends ChangeNotifier {
  final OutfitService _outfitService = OutfitService();
  StreamSubscription? _outfitsSubscription;

  OutfitStatus _status = OutfitStatus.initial;
  List<OutfitModel> _outfits = [];
  List<OutfitModel> _favoriteOutfits = [];
  OutfitModel? _selectedOutfit;
  String? _errorMessage;

  OutfitStatus get status => _status;
  List<OutfitModel> get outfits => _outfits;
  List<OutfitModel> get favoriteOutfits => _favoriteOutfits;
  OutfitModel? get selectedOutfit => _selectedOutfit;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == OutfitStatus.loading;
  bool get isEmpty => _outfits.isEmpty;

  // Manuel oluşturulan kombinler
  List<OutfitModel> get manualOutfits =>
      _outfits.where((o) => o.source == 'manual').toList();

  // AI tarafından önerilen kombinler
  List<OutfitModel> get aiOutfits =>
      _outfits.where((o) => o.source == 'ai').toList();

  // --- KOMBİNLERİ YÜKLE ---
  Future<void> loadOutfits(String userId) async {
    _setLoading();
    try {
      final outfits = await _outfitService.getOutfits(userId);
      _outfits = outfits;
      _status = OutfitStatus.loaded;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- KOMBİNLERİ STREAM İLE DİNLE ---
  void watchOutfits(String userId) {
    _outfitsSubscription?.cancel();
    
    _outfitsSubscription = _outfitService
        .watchOutfits(userId)
        .listen((outfits) {
      _outfits = outfits;
      _status = OutfitStatus.loaded;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _outfitsSubscription?.cancel();
    super.dispose();
  }

  // --- FAVORİ KOMBİNLERİ YÜKLE ---
  Future<void> loadFavorites(String userId) async {
    try {
      final favorites = await _outfitService.getFavoriteOutfits(userId);
      _favoriteOutfits = favorites;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- KOMBİN EKLE ---
  Future<bool> addOutfit({
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
    _setLoading();
    try {
      final newOutfit = await _outfitService.addOutfit(
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
      );

      // Lokal listeye başa ekle
      _outfits = [newOutfit, ..._outfits];
      _status = OutfitStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- KOMBİN SİL ---
  Future<bool> deleteOutfit({
    required String userId,
    required String outfitId,
  }) async {
    try {
      await _outfitService.deleteOutfit(
        userId: userId,
        outfitId: outfitId,
      );

      // Lokal listeden çıkar
      _outfits = _outfits
          .where((outfit) => outfit.id != outfitId)
          .toList();

      // Favorilerden de çıkar
      _favoriteOutfits = _favoriteOutfits
          .where((outfit) => outfit.id != outfitId)
          .toList();

      // Seçili kombin silindiyse temizle
      if (_selectedOutfit?.id == outfitId) {
        _selectedOutfit = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- FAVORİYE EKLE / ÇIKAR ---
  Future<void> toggleFavorite({
    required String userId,
    required String outfitId,
    required bool isFavorite,
  }) async {
    try {
      await _outfitService.toggleFavorite(
        userId: userId,
        outfitId: outfitId,
        isFavorite: isFavorite,
      );

      // Lokal _outfits listesinde güncelle
      _outfits = _outfits.map((outfit) {
        if (outfit.id == outfitId) {
          return outfit.copyWith(isFavorite: isFavorite);
        }
        return outfit;
      }).toList();

      // Favoriler listesini güncelle
      if (isFavorite) {
        final outfit = _outfits.firstWhere((o) => o.id == outfitId);
        final alreadyExists =
            _favoriteOutfits.any((o) => o.id == outfitId);
        if (!alreadyExists) {
          _favoriteOutfits = [outfit, ..._favoriteOutfits];
        }
      } else {
        _favoriteOutfits = _favoriteOutfits
            .where((o) => o.id != outfitId)
            .toList();
      }

      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- KOMBİN SEÇ ---
  void selectOutfit(OutfitModel? outfit) {
    _selectedOutfit = outfit;
    notifyListeners();
  }

  // --- LİSTEYİ TEMİZLE ---
  void clearOutfits() {
    _outfits = [];
    _favoriteOutfits = [];
    _selectedOutfit = null;
    _status = OutfitStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // --- YARDIMCI METODLAR ---
  void _setLoading() {
    _status = OutfitStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = OutfitStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}