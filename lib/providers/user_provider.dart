import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/badge_service.dart';
import 'dart:async';

enum UserStatus { initial, loading, loaded, error }

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  StreamSubscription? _userSubscription;


  UserStatus _status = UserStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  UserStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == UserStatus.loading;
  int get xpPoints => _user?.xpPoints ?? 0;
  List<String> get badges => _user?.badges ?? [];
  String? get styleProfile => _user?.styleProfile;

  // --- KULLANICI VERİSİNİ YÜKLE ---
  Future<void> loadUser(String userId) async {
    _setLoading();
    try {
      final user = await _userService.getUser(userId);
      if (user != null) {
        _user = user;
        _status = UserStatus.loaded;
      } else {
        _status = UserStatus.error;
        _errorMessage = 'Kullanıcı bulunamadı';
      }
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- KULLANICI VERİSİNİ STREAM İLE DİNLE ---
  void watchUser(String userId) {
    _userSubscription?.cancel();
    
    _userSubscription = _userService.watchUser(userId).listen(
      (user) {
        if (user != null) {
          _user = user;
          _status = UserStatus.loaded;
        } else {
          _user = null;
          _status = UserStatus.error;
          _errorMessage = 'Kullanıcı bulunamadı';
        }
        notifyListeners();
      },
      onError: (e) {
        _setError(e.toString());
      },
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // --- PROFİL GÜNCELLE ---
  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    String? styleProfile,
  }) async {
    _setLoading();
    try {
      await _userService.updateProfile(
        userId: userId,
        displayName: displayName,
        photoURL: photoURL,
        styleProfile: styleProfile,
      );

      // Lokal veriyi de güncelle
      if (_user != null) {
        _user = _user!.copyWith(
          displayName: displayName ?? _user!.displayName,
          photoURL: photoURL ?? _user!.photoURL,
          styleProfile: styleProfile ?? _user!.styleProfile,
        );
      }

      _status = UserStatus.loaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // --- XP EKLE ---
  Future<void> addXP({
    required String userId,
    required int amount,
  }) async {
    try {
      await _userService.addXP(userId: userId, amount: amount);

      // Lokal veriyi de güncelle
      if (_user != null) {
        _user = _user!.copyWith(
          xpPoints: _user!.xpPoints + amount,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- ROZET VER ---
  Future<void> addBadge({
    required String userId,
    required String badge,
  }) async {
    try {
      await _userService.addBadge(userId: userId, badge: badge);

      // Lokal veriyi de güncelle
      if (_user != null && !_user!.badges.contains(badge)) {
        _user = _user!.copyWith(
          badges: [..._user!.badges, badge],
        );
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // --- ROZET KONTROL & ÖDÜLLENDIR ---
  // Mevcut durumu alır, henüz kazanılmamış rozetleri verir ve bildirir.
  // Yeni kazanılan rozet adlarını döner (snackbar için).
  Future<List<String>> checkAndAwardBadges({
    required String userId,
    required int clothingCount,
    required int outfitCount,
    required int aiOutfitCount,
    required int historyCount,
    required int plannedDays,
  }) async {
    if (_user == null) return [];

    final toAward = BadgeService.compute(
      user: _user!,
      clothingCount: clothingCount,
      outfitCount: outfitCount,
      aiOutfitCount: aiOutfitCount,
      historyCount: historyCount,
      plannedDays: plannedDays,
    );

    final newTitles = <String>[];
    for (final badgeId in toAward) {
      await addBadge(userId: userId, badge: badgeId);
      final def = BadgeService.findById(badgeId);
      if (def != null) {
        newTitles.add('${def.emoji} ${def.title}');
        // Her rozet XP kazandırır
        await addXP(userId: userId, amount: def.xpReward);
      }
    }
    return newTitles;
  }

  // --- KULLANICI VERİSİNİ TEMİZLE ---
  void clearUser() {
    _user = null;
    _status = UserStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  // --- YARDIMCI METODLAR ---
  void _setLoading() {
    _status = UserStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = UserStatus.error;
    _errorMessage = message;
    notifyListeners();
  }
}