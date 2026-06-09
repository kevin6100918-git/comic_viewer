import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../providers/cover_provider.dart';

class FolderCard extends ConsumerWidget {
  final FileEntry entry;
  final List<String> pathSegments;
  final VoidCallback onTap;

  const FolderCard({
    super.key,
    required this.entry,
    required this.pathSegments,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverAsync = ref.watch(coverUrlProvider(pathSegments));

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: coverAsync.when(
                data: (url) => url != null
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _Placeholder(),
                        errorWidget: (_, _, _) =>
                            const _Placeholder(isError: true),
                      )
                    : const _Placeholder(),
                loading: () => const _Placeholder(),
                error: (_, _) => const _Placeholder(isError: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                entry.name,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool isError;

  const _Placeholder({this.isError = false});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          isError ? Icons.broken_image_outlined : Icons.auto_stories_outlined,
          color: Colors.grey.shade400,
          size: 48,
        ),
      ),
    );
  }
}
