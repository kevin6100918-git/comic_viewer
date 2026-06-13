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

// Recursively follows the most-recently-updated subfolder at each level
// until reaching a folder that contains images directly, then returns
// the URL of the first image.  maxDepth prevents runaway API calls.
Future<String?> _fetchCoverUrl(
    ApiClient client, List<String> pathSegments,
    {int maxDepth = 6}) async {
  if (maxDepth <= 0) return null;

  final entries = await client.listFolder(pathSegments);

  final folders = entries
      .where((e) => e.type == FileType.folder)
      .toList()
    ..sort((a, b) => b.updated.compareTo(a.updated)); // most recent first

  if (folders.isNotEmpty) {
    final result = await _fetchCoverUrl(
      client,
      [...pathSegments, folders.first.name],
      maxDepth: maxDepth - 1,
    );
    if (result != null) return result;
  }

  // No subfolders (or they all returned null) → look for images here
  final images = entries.where((e) => e.type == FileType.image).toList();
  if (images.isNotEmpty) {
    return client.imageUrl(pathSegments, images.first.name);
  }

  return null;
}
