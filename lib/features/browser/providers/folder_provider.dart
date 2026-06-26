import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/settings_provider.dart';

List<FileEntry> _sorted(List<FileEntry> entries, SortSettings sort) {
  final result = [...entries];
  result.sort((a, b) {
    final cmp = sort.vote == 'name'
        ? a.name.compareTo(b.name)
        : (a.ctime ?? 0).compareTo(b.ctime ?? 0);
    return sort.method == 'ASC' ? cmp : -cmp;
  });
  return result;
}

// Used by FolderBrowserScreen — respects user sort settings.
final folderProvider =
    FutureProvider.family<List<FileEntry>, List<String>>((ref, pathSegments) async {
  final client = ref.watch(apiClientProvider);
  final sort = ref.watch(sortProvider);
  final entries = await client.listFolder(pathSegments);
  return _sorted(entries, sort);
});

// Used by ReaderScreen — always name ASC so page order is stable.
final readerFolderProvider =
    FutureProvider.family<List<FileEntry>, List<String>>((ref, pathSegments) async {
  final client = ref.watch(apiClientProvider);
  final entries = await client.listFolder(pathSegments);
  return _sorted(entries, const SortSettings());
});
