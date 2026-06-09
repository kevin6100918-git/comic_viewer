import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kDefaultServerAddress = '192.168.0.121:8000';
const _kServerAddressKey = 'server_address';

final sharedPreferencesProvider = Provider<SharedPreferences>((_) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in ProviderScope');
});

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
