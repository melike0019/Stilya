class WeeklyPlanModel {
  final String id;
  final String userId;
  final DateTime weekStartDate;
  final Map<String, String?> days;

  WeeklyPlanModel({
    required this.id,
    required this.userId,
    required this.weekStartDate,
    required this.days,
  });

  factory WeeklyPlanModel.fromFirestore(Map<String, dynamic> data, String id) {
    return WeeklyPlanModel(
      id: id,
      userId: data['userId'] ?? '',
      weekStartDate:
          (data['weekStartDate'] as dynamic)?.toDate() ?? DateTime.now(),
      days: Map<String, String?>.from(data['days'] ?? {
        'monday': null,
        'tuesday': null,
        'wednesday': null,
        'thursday': null,
        'friday': null,
        'saturday': null,
        'sunday': null,
      }),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weekStartDate': weekStartDate,
      'days': days,
    };
  }

  WeeklyPlanModel copyWith({
    Map<String, String?>? days,
  }) {
    return WeeklyPlanModel(
      id: id,
      userId: userId,
      weekStartDate: weekStartDate,
      days: days ?? this.days,
    );
  }

  // Belirli bir güne kombin ata
  WeeklyPlanModel assignOutfit(String day, String? outfitId) {
    final updatedDays = Map<String, String?>.from(days);
    updatedDays[day] = outfitId;
    return copyWith(days: updatedDays);
  }
}