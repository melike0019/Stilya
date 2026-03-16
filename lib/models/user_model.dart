class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final int xpPoints;
  final List<String> badges;
  final DateTime createdAt;
  final String? styleProfile;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.xpPoints = 0,
    this.badges = const [],
    required this.createdAt,
    this.styleProfile,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoURL: data['photoURL'],
      xpPoints: data['xpPoints'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      styleProfile: data['styleProfile'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'xpPoints': xpPoints,
      'badges': badges,
      'createdAt': createdAt,
      'styleProfile': styleProfile,
    };
  }

  // Mevcut kullanıcıyı güncellemek için
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    int? xpPoints,
    List<String>? badges,
    String? styleProfile,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      xpPoints: xpPoints ?? this.xpPoints,
      badges: badges ?? this.badges,
      createdAt: createdAt,
      styleProfile: styleProfile ?? this.styleProfile,
    );
  }
}