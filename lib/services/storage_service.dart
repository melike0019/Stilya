import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // --- KIYAFEt FOTOĞRAFI YÜKLE ---
  Future<String> uploadClothingImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Fotoğrafı sıkıştır
      final compressedFile = await _compressImage(imageFile);

      // Eşsiz dosya adı oluştur
      final fileName = '${_uuid.v4()}.jpg';

      // Storage'daki yolu belirle
      final ref = _storage
          .ref()
          .child('clothing')
          .child(userId)
          .child(fileName);

      // Yükle
      await ref.putFile(compressedFile ?? imageFile);

      // URL'yi al ve döndür
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw 'Fotoğraf yüklenemedi: $e';
    }
  }

  // --- PROFİL FOTOĞRAFI YÜKLE ---
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final compressedFile = await _compressImage(imageFile);

      // Profil fotoğrafı hep aynı isimde → eski fotoğrafın üstüne yazar
      final ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile.jpg');

      await ref.putFile(compressedFile ?? imageFile);

      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw 'Profil fotoğrafı yüklenemedi: $e';
    }
  }

  // --- FOTOĞRAF SİL ---
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw 'Fotoğraf silinemedi: $e';
    }
  }

  // --- FOTOĞRAFI SIKIŞTIR (private) ---
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1080,
      );

      if (result == null) return null;
      return File(result.path);
    } catch (e) {
      return null; // Sıkıştırma başarısız olursa orijinali kullan
    }
  }
}