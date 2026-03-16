class HistoryModel {
  final String id;
  final String userId;
  final String outfitId;
  final DateTime wornDate;
  final String? mood;
  final String? weather;
  final String? occasion;
  final String? notes;

  HistoryModel({
    required this.id,
    required this.userId,
    required this.outfitId,
    required this.wornDate,
    this.mood,
    this.weather,
    this.occasion,
    this.notes,
  });

  factory HistoryModel.fromFirestore(Map<String, dynamic> data, String id) {
    return HistoryModel(
      id: id,
      userId: data['userId'] ?? '',
      outfitId: data['outfitId'] ?? '',
      wornDate: (data['wornDate'] as dynamic)?.toDate() ?? DateTime.now(),
      mood: data['mood'],
      weather: data['weather'],
      occasion: data['occasion'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'outfitId': outfitId,
      'wornDate': wornDate,
      'mood': mood,
      'weather': weather,
      'occasion': occasion,
      'notes': notes,
    };
  }
}
