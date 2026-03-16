class OutfitModel {
  final String id;
  final String userId;
  final String name;
  final List<String> itemIds;
  final String? occasion;
  final String? mood;
  final String? weatherCondition;
  final String? description;
  final String? makeupTips;
  final String? skincareTips;
  final bool isFavorite;
  final String source;
  final DateTime createdAt;

  OutfitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.itemIds,
    this.occasion,
    this.mood,
    this.weatherCondition,
    this.description,
    this.makeupTips,
    this.skincareTips,
    this.isFavorite = false,
    this.source = 'manual',
    required this.createdAt,
  });

  factory OutfitModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OutfitModel(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      itemIds: List<String>.from(data['itemIds'] ?? []),
      occasion: data['occasion'],
      mood: data['mood'],
      weatherCondition: data['weatherCondition'],
      description: data['description'],
      makeupTips: data['makeupTips'],
      skincareTips: data['skincareTips'],
      isFavorite: data['isFavorite'] ?? false,
      source: data['source'] ?? 'manual',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'itemIds': itemIds,
      'occasion': occasion,
      'mood': mood,
      'weatherCondition': weatherCondition,
      'description': description,
      'makeupTips': makeupTips,
      'skincareTips': skincareTips,
      'isFavorite': isFavorite,
      'source': source,
      'createdAt': createdAt,
    };
  }

  OutfitModel copyWith({
    String? name,
    List<String>? itemIds,
    String? occasion,
    String? mood,
    String? weatherCondition,
    String? description,
    String? makeupTips,
    String? skincareTips,
    bool? isFavorite,
    String? source,
  }) {
    return OutfitModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
      occasion: occasion ?? this.occasion,
      mood: mood ?? this.mood,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      description: description ?? this.description,
      makeupTips: makeupTips ?? this.makeupTips,
      skincareTips: skincareTips ?? this.skincareTips,
      isFavorite: isFavorite ?? this.isFavorite,
      source: source ?? this.source,
      createdAt: createdAt,
    );
  }
}