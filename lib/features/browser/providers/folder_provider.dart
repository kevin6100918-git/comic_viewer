import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';

final folderProvider =
    FutureProvider.family<List<FileEntry>, List<String>>((ref, pathSegments) {
  final client = ref.watch(apiClientProvider);
  return client.listFolder(pathSegments);
});
