import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';

// Returns the first image URL from the most recently modified child folder.
// Falls back to the first image found directly in the folder if no child folders exist.
final coverUrlProvider =
    FutureProvider.family<String?, List<String>>((ref, pathSegments) {
  final client = ref.watch(apiClientProvider);
  return _coverUrl(client, pathSegments);
});

Future<String?> _coverUrl(
    ApiClient client, List<String> pathSegments) async {
  final entries = await client.listFolder(pathSegments);

  final folders = entries
      .where((e) => e.type == FileType.folder)
      .toList()
    ..sort((a, b) => b.updated.compareTo(a.updated)); // most recent first

  if (folders.isNotEmpty) {
    final bookPath = [...pathSegments, folders.first.name];
    final bookEntries = await client.listFolder(bookPath);
    final images = bookEntries
        .where((e) => e.type == FileType.image)
        .toList();
    if (images.isNotEmpty) {
      return client.imageUrl(bookPath, images.first.name);
    }
  }

  // Fallback: images sitting directly in this folder
  final directImages = entries.where((e) => e.type == FileType.image).toList();
  if (directImages.isNotEmpty) {
    return client.imageUrl(pathSegments, directImages.first.name);
  }

  return null;
}
