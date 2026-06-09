import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';

// Recursively drills into the first sub-folder until an image is found.
// Returns null if no image exists anywhere under the given path.
final coverUrlProvider =
    FutureProvider.family<String?, List<String>>((ref, pathSegments) {
  final client = ref.watch(apiClientProvider);
  return _findFirstImageUrl(client, pathSegments);
});

Future<String?> _findFirstImageUrl(
    ApiClient client, List<String> pathSegments) async {
  final entries = await client.listFolder(pathSegments);

  final images = entries.where((e) => e.type == FileType.image).toList();
  if (images.isNotEmpty) {
    return client.imageUrl(pathSegments, images.first.name);
  }

  final folders = entries.where((e) => e.type == FileType.folder).toList();
  if (folders.isNotEmpty) {
    return _findFirstImageUrl(client, [...pathSegments, folders.first.name]);
  }

  return null;
}
