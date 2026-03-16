import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının koleksiyon referansı - kısayol
  CollectionReference get _users => _firestore.collection('users');

  // --- KULLANICI VERİSİNİ GETİR ---
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw 'Kullanıcı bilgisi alınamadı: $e';
    }
  }

  // --- KULLANICIYI STREAM OLARAK DİNLE ---
  Stream<UserModel?> watchUser(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  // --- PROFİL GÜNCELLE ---
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? photoURL,
    String? styleProfile,
  }) async {
    try {
      // Sadece null olmayan alanları güncelle
      final Map<String, dynamic> updates = {};

      if (displayName != null) updates['displayName'] = displayName;
      if (photoURL != null) updates['photoURL'] = photoURL;
      if (styleProfile != null) updates['styleProfile'] = styleProfile;

      if (updates.isEmpty) return;

      await _users.doc(userId).update(updates);
    } catch (e) {
      throw 'Profil güncellenemedi: $e';
    }
  }

  // --- XP EKLE ---
  Future<void> addXP({
    required String userId,
    required int amount,
  }) async {
    try {
      await _users.doc(userId).update({
        'xpPoints': FieldValue.increment(amount),
      });
    } catch (e) {
      throw 'XP eklenemedi: $e';
    }
  }

  // --- ROZET VER ---
  Future<void> addBadge({
    required String userId,
    required String badge,
  }) async {
    try {
      await _users.doc(userId).update({
        'badges': FieldValue.arrayUnion([badge]),
      });
    } catch (e) {
      throw 'Rozet eklenemedi: $e';
    }
  }
}