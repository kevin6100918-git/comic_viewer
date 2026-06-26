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

// Raw fetch — only re-runs when path or server changes, NOT when sort changes.
final _rawFolderProvider =
    FutureProvider.family<List<FileEntry>, List<String>>((ref, pathSegments) {
  final client = ref.watch(apiClientProvider);
  return client.listFolder(pathSegments);
});

// Sorted view — re-computes on sort change without re-fetching.
final folderProvider = Provider.family<AsyncValue<List<FileEntry>>, List<String>>(
  (ref, pathSegments) {
    final rawAsync = ref.watch(_rawFolderProvider(pathSegments));
    final sort = ref.watch(sortProvider);
    return rawAsync.whenData((entries) => _sorted(entries, sort));
  },
);

// Used by ReaderScreen — always name ASC; reuses _rawFolderProvider cache.
final readerFolderProvider =
    Provider.family<AsyncValue<List<FileEntry>>, List<String>>((ref, pathSegments) {
  final rawAsync = ref.watch(_rawFolderProvider(pathSegments));
  return rawAsync.whenData((entries) => _sorted(entries, const SortSettings()));
});
