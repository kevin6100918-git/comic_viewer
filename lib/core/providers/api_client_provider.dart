import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import 'settings_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final address = ref.watch(serverAddressProvider);
  return ApiClient(address);
});
