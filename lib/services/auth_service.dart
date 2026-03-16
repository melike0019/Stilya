import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı stream olarak dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mevcut Firebase kullanıcısı
  User? get currentUser => _auth.currentUser;

  // --- KAYIT OL ---
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      // Firebase Auth display name güncelle
      await user.updateDisplayName(displayName);

      // Firestore'a kullanıcı dokümanı oluştur
      final userModel = UserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        xpPoints: 0,
        badges: [],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- GİRİŞ YAP ---
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      // Firestore'dan kullanıcı verisini al
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- ÇIKIŞ YAP ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // --- ŞİFRE SIFIRLA ---
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // --- HESAP SİL ---
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Firestore dokümanını sil
    await _firestore.collection('users').doc(user.uid).delete();

    // Firebase Auth hesabını sil
    await user.delete();
  }

  // --- HATA YÖNETİMİ ---
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlış.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}