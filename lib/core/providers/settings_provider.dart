import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDefaultServerAddress = '192.168.0.121:8000';
const _kServerAddressKey = 'server_address';
const _kThemeModeKey = 'theme_mode';
const _kThemeColorKey = 'theme_color';
const _kReadingRtlKey = 'reading_rtl';
const _kSortVoteKey = 'sort_vote';
const _kSortMethodKey = 'sort_method';

// Theme color options: (label, seed color)
const kThemeColors = [
  (label: '靛藍', color: Color(0xFF3F51B5)),
  (label: '青藍', color: Color(0xFF009688)),
  (label: '深紫', color: Color(0xFF673AB7)),
  (label: '翠綠', color: Color(0xFF4CAF50)),
  (label: '玫瑰', color: Color(0xFFE91E63)),
  (label: '深橘', color: Color(0xFFFF5722)),
];

final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in ProviderScope');
});

// ── Server Address ────────────────────────────────────────────────────────────

class ServerAddressNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  ServerAddressNotifier(this._prefs)
      : super(_prefs.getString(_kServerAddressKey) ?? kDefaultServerAddress);

  Future<void> setAddress(String address) async {
    state = address;
    await _prefs.setString(_kServerAddressKey, address);
  }
}

final serverAddressProvider =
    StateNotifierProvider<ServerAddressNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ServerAddressNotifier(prefs);
});

// ── Theme Mode ────────────────────────────────────────────────────────────────

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  static ThemeMode _load(SharedPreferences prefs) {
    switch (prefs.getString(_kThemeModeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_kThemeModeKey, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

// ── Theme Color ───────────────────────────────────────────────────────────────

class ThemeColorIndexNotifier extends StateNotifier<int> {
  final SharedPreferences _prefs;

  ThemeColorIndexNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_clamp(prefs.getInt(_kThemeColorKey) ?? 0));

  static int _clamp(int v) =>
      v.clamp(0, kThemeColors.length - 1).toInt();

  Future<void> setColorIndex(int index) async {
    state = _clamp(index);
    await _prefs.setInt(_kThemeColorKey, state);
  }
}

final themeColorIndexProvider =
    StateNotifierProvider<ThemeColorIndexNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeColorIndexNotifier(prefs);
});

// ── Reading Direction ─────────────────────────────────────────────────────────

class ReadingRtlNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  ReadingRtlNotifier(this._prefs)
      : super(_prefs.getBool(_kReadingRtlKey) ?? false);

  Future<void> setRtl(bool value) async {
    state = value;
    await _prefs.setBool(_kReadingRtlKey, value);
  }
}

final readingRtlProvider =
    StateNotifierProvider<ReadingRtlNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReadingRtlNotifier(prefs);
});

// ── Auto Next Book ────────────────────────────────────────────────────────────

const _kAutoNextBookKey = 'auto_next_book';

class AutoNextBookNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  AutoNextBookNotifier(this._prefs)
      : super(_prefs.getBool(_kAutoNextBookKey) ?? true);

  Future<void> set(bool value) async {
    state = value;
    await _prefs.setBool(_kAutoNextBookKey, value);
  }
}

final autoNextBookProvider =
    StateNotifierProvider<AutoNextBookNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AutoNextBookNotifier(prefs);
});

// ── Sort Settings ─────────────────────────────────────────────────────────────

class SortSettings {
  final String vote; // 'name' | 'updated'
  final String method; // 'ASC' | 'DESC'

  const SortSettings({this.vote = 'name', this.method = 'ASC'});

  SortSettings copyWith({String? vote, String? method}) => SortSettings(
        vote: vote ?? this.vote,
        method: method ?? this.method,
      );
}

class SortNotifier extends StateNotifier<SortSettings> {
  final SharedPreferences _prefs;

  SortNotifier(this._prefs)
      : super(SortSettings(
          vote: _prefs.getString(_kSortVoteKey) ?? 'name',
          method: _prefs.getString(_kSortMethodKey) ?? 'ASC',
        ));

  Future<void> setSort({String? vote, String? method}) async {
    state = state.copyWith(vote: vote, method: method);
    await _prefs.setString(_kSortVoteKey, state.vote);
    await _prefs.setString(_kSortMethodKey, state.method);
  }
}

final sortProvider = StateNotifierProvider<SortNotifier, SortSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SortNotifier(prefs);
});
