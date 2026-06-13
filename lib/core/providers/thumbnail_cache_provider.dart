import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/thumbnail_cache_service.dart';

final thumbnailCacheServiceProvider = Provider<ThumbnailCacheService>((ref) {
  return ThumbnailCacheService();
});
