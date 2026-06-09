import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/settings_provider.dart';

// Used by FolderBrowserScreen — respects user sort settings.
final folderProvider =
    FutureProvider.family<List<FileEntry>, List<String>>((ref, pathSegments) {
  final client = ref.watch(apiClientProvider);
  final sort = ref.watch(sortProvider);
  return client.listFolder(
    pathSegments,
    sortingVote: sort.vote,
    sortingMethod: sort.method,
  );
});

// Used by ReaderScreen — always name ASC so page order is stable.
final readerFolderProvider =
    FutureProvider.family<List<FileEntry>, List<String>>((ref, pathSegments) {
  final client = ref.watch(apiClientProvider);
  return client.listFolder(
    pathSegments,
    sortingVote: 'name',
    sortingMethod: 'ASC',
  );
});
