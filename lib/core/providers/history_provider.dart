import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reading_progress.dart';
import 'settings_provider.dart';

const _kHistoryKey = 'reading_history';
const _kMaxHistory = 100;

class HistoryNotifier extends StateNotifier<List<ReadingProgress>> {
  final SharedPreferences _prefs;

  HistoryNotifier(this._prefs) : super(_load(_prefs));

  static List<ReadingProgress> _load(SharedPreferences prefs) {
    final json = prefs.getString(_kHistoryKey);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list
          .map((e) => ReadingProgress.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> updateProgress(ReadingProgress progress) async {
    final updated = state.where((e) => e.bookId != progress.bookId).toList();
    updated.insert(0, progress);
    if (updated.length > _kMaxHistory) {
      updated.removeRange(_kMaxHistory, updated.length);
    }
    state = updated;
    await _persist();
  }

  ReadingProgress? getProgress(String bookId) {
    for (final e in state) {
      if (e.bookId == bookId) return e;
    }
    return null;
  }

  Future<void> _persist() async {
    final json = jsonEncode(state.map((e) => e.toJson()).toList());
    await _prefs.setString(_kHistoryKey, json);
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<ReadingProgress>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return HistoryNotifier(prefs);
});
