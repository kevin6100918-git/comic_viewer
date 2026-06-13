import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/thumbnail_cache_provider.dart';

// Returns cover image URL for a folder, checking local SQLite cache first.
// Cache key is the joined path segments; TTL is 7 days.
final coverUrlProvider =
    FutureProvider.family<String?, List<String>>((ref, pathSegments) async {
  final client = ref.watch(apiClientProvider);
  final cache = ref.watch(thumbnailCacheServiceProvider);
  final cacheKey = pathSegments.join('/');

  final cached = await cache.getCachedUrl(cacheKey);
  if (cached != null) return cached;

  final url = await _fetchCoverUrl(client, pathSegments);
  if (url != null) {
    await cache.setCachedUrl(cacheKey, url);
  }
  return url;
});

Future<String?> _fetchCoverUrl(
    ApiClient client, List<String> pathSegments) async {
  final entries = await client.listFolder(pathSegments);

  final folders = entries
      .where((e) => e.type == FileType.folder)
      .toList()
    ..sort((a, b) => b.updated.compareTo(a.updated)); // most recent first

  if (folders.isNotEmpty) {
    final bookPath = [...pathSegments, folders.first.name];
    final bookEntries = await client.listFolder(bookPath);
    final images = bookEntries.where((e) => e.type == FileType.image).toList();
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
