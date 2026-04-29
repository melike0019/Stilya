import 'dart:async';
import 'package:flutter/material.dart';
import '../models/history_model.dart';
import '../services/history_service.dart';

enum HistoryStatus { initial, loading, loaded, error }

class HistoryProvider extends ChangeNotifier {
  final HistoryService _service = HistoryService();
  StreamSubscription? _sub;

  HistoryStatus _status = HistoryStatus.initial;
  List<HistoryModel> _entries = [];
  String? _errorMessage;

  HistoryStatus get status => _status;
  List<HistoryModel> get entries => _entries;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HistoryStatus.loading;

  void watchHistory(String userId) {
    _status = HistoryStatus.loading;
    notifyListeners();
    _sub?.cancel();
    _sub = _service.watchHistory(userId).listen(
      (list) {
        _entries = list;
        _status = HistoryStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _status = HistoryStatus.error;
        notifyListeners();
      },
    );
  }

  Future<bool> addEntry({
    required String userId,
    required String outfitId,
    required DateTime wornDate,
    String? mood,
    String? weather,
    String? occasion,
    String? notes,
  }) async {
    try {
      await _service.addEntry(
        userId: userId,
        outfitId: outfitId,
        wornDate: wornDate,
        mood: mood,
        weather: weather,
        occasion: occasion,
        notes: notes,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    try {
      await _service.deleteEntry(userId: userId, entryId: entryId);
      _entries = _entries.where((e) => e.id != entryId).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Belirli bir ay için giriş listesi
  List<HistoryModel> entriesForMonth(int year, int month) {
    return _entries
        .where((e) => e.wornDate.year == year && e.wornDate.month == month)
        .toList();
  }

  // Belirli bir güne ait girişler
  List<HistoryModel> entriesForDay(DateTime date) {
    return _entries
        .where((e) =>
            e.wornDate.year == date.year &&
            e.wornDate.month == date.month &&
            e.wornDate.day == date.day)
        .toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
