import '../models/user_model.dart';

/// Tüm rozet tanımları ve ödüllendirme koşulları bu sınıfta.
class BadgeDef {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int xpReward;

  const BadgeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.xpReward,
  });
}

class BadgeService {
  static const List<BadgeDef> all = [
    BadgeDef(
      id: 'first_step',
      title: 'İlk Adım',
      description: 'Gardıroba ilk kıyafetini ekle',
      emoji: '👗',
      xpReward: 10,
    ),
    BadgeDef(
      id: 'wardrobe_10',
      title: 'Gardırop Ustası',
      description: '10 kıyafet ekle',
      emoji: '👚',
      xpReward: 25,
    ),
    BadgeDef(
      id: 'wardrobe_25',
      title: 'Stil Koleksiyoncusu',
      description: '25 kıyafet ekle',
      emoji: '🏆',
      xpReward: 50,
    ),
    BadgeDef(
      id: 'first_outfit',
      title: 'Kombin Kurucusu',
      description: 'İlk kombinini oluştur',
      emoji: '✨',
      xpReward: 15,
    ),
    BadgeDef(
      id: 'outfit_5',
      title: 'Kombin Uzmanı',
      description: '5 kombin kaydet',
      emoji: '💫',
      xpReward: 30,
    ),
    BadgeDef(
      id: 'ai_lover',
      title: 'AI Hayranı',
      description: 'İlk AI önerisini kaydet',
      emoji: '🤖',
      xpReward: 20,
    ),
    BadgeDef(
      id: 'planner_week',
      title: 'Hafta Plancısı',
      description: 'Haftanın 7 gününü planla',
      emoji: '📅',
      xpReward: 40,
    ),
    BadgeDef(
      id: 'history_start',
      title: 'Stil Günlükçüsü',
      description: 'İlk giyim kaydını oluştur',
      emoji: '📝',
      xpReward: 10,
    ),
    BadgeDef(
      id: 'style_queen',
      title: 'Stil Kraliçesi',
      description: 'Stil tercihini belirle',
      emoji: '👑',
      xpReward: 10,
    ),
    BadgeDef(
      id: 'photo_star',
      title: 'Fotoğraf Yıldızı',
      description: 'Profil fotoğrafı ekle',
      emoji: '📸',
      xpReward: 10,
    ),
  ];

  static BadgeDef? findById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Kazanılmış rozetler dışındaki tanımları döner (kilitli rozetler).
  static List<BadgeDef> locked(List<String> earnedIds) =>
      all.where((b) => !earnedIds.contains(b.id)).toList();

  /// Kazanılmış rozet tanımlarını döner.
  static List<BadgeDef> earned(List<String> earnedIds) =>
      all.where((b) => earnedIds.contains(b.id)).toList();

  /// Verilen kullanıcı ve mevcut duruma göre kazanılması gereken
  /// ama henüz verilmemiş rozet ID'lerini döner.
  static List<String> compute({
    required UserModel user,
    required int clothingCount,
    required int outfitCount,
    required int aiOutfitCount,
    required int historyCount,
    required int plannedDays,
  }) {
    final earned = user.badges.toSet();
    final toAward = <String>[];

    void check(String id, bool condition) {
      if (condition && !earned.contains(id)) toAward.add(id);
    }

    check('first_step',   clothingCount >= 1);
    check('wardrobe_10',  clothingCount >= 10);
    check('wardrobe_25',  clothingCount >= 25);
    check('first_outfit', outfitCount >= 1);
    check('outfit_5',     outfitCount >= 5);
    check('ai_lover',     aiOutfitCount >= 1);
    check('planner_week', plannedDays >= 7);
    check('history_start',historyCount >= 1);
    check('style_queen',  user.styleProfile != null && user.styleProfile!.isNotEmpty);
    check('photo_star',   user.photoURL != null && user.photoURL!.isNotEmpty);

    return toAward;
  }
}
