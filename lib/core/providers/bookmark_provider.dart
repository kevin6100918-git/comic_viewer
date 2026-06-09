import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bookmark_entry.dart';
import 'settings_provider.dart';

const _kBookmarkKey = 'bookmarks';

class BookmarkNotifier extends StateNotifier<Map<String, BookmarkEntry>> {
  final SharedPreferences _prefs;

  BookmarkNotifier(this._prefs) : super(_load(_prefs));

  static Map<String, BookmarkEntry> _load(SharedPreferences prefs) {
    final json = prefs.getString(_kBookmarkKey);
    if (json == null) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map(
        (k, v) => MapEntry(k, BookmarkEntry.fromJson(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> setBookmark(BookmarkEntry entry) async {
    state = {...state, entry.bookId: entry};
    await _persist();
  }

  Future<void> removeBookmark(String bookId) async {
    final updated = Map<String, BookmarkEntry>.from(state);
    updated.remove(bookId);
    state = updated;
    await _persist();
  }

  BookmarkEntry? getBookmark(String bookId) => state[bookId];

  Future<void> _persist() async {
    final json = jsonEncode(
      state.map((k, v) => MapEntry(k, v.toJson())),
    );
    await _prefs.setString(_kBookmarkKey, json);
  }
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, Map<String, BookmarkEntry>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BookmarkNotifier(prefs);
});
