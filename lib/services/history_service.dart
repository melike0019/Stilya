import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/history_model.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _historyRef(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('history');

  Future<HistoryModel> addEntry({
    required String userId,
    required String outfitId,
    required DateTime wornDate,
    String? mood,
    String? weather,
    String? occasion,
    String? notes,
  }) async {
    final entry = HistoryModel(
      id: '',
      userId: userId,
      outfitId: outfitId,
      wornDate: wornDate,
      mood: mood,
      weather: weather,
      occasion: occasion,
      notes: notes,
    );
    final ref = await _historyRef(userId).add(entry.toFirestore());
    return HistoryModel(
      id: ref.id,
      userId: userId,
      outfitId: outfitId,
      wornDate: wornDate,
      mood: mood,
      weather: weather,
      occasion: occasion,
      notes: notes,
    );
  }

  Future<List<HistoryModel>> getHistory(String userId,
      {int limit = 60}) async {
    final snap = await _historyRef(userId)
        .orderBy('wornDate', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((d) =>
            HistoryModel.fromFirestore(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }

  Stream<List<HistoryModel>> watchHistory(String userId, {int limit = 90}) {
    return _historyRef(userId)
        .orderBy('wornDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HistoryModel.fromFirestore(
                d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    await _historyRef(userId).doc(entryId).delete();
  }
}
