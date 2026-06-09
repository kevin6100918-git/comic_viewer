import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../browser/providers/folder_provider.dart';

class ReaderScreen extends ConsumerWidget {
  final List<String> pathSegments;
  final String title;

  const ReaderScreen({
    super.key,
    required this.pathSegments,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderAsync = ref.watch(folderProvider(pathSegments));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: folderAsync.when(
        data: (entries) {
          final images =
              entries.where((e) => e.type == FileType.image).toList();
          if (images.isEmpty) {
            return const Center(child: Text('沒有找到圖片'));
          }
          return _PageReader(pathSegments: pathSegments, images: images);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
      ),
    );
  }
}

class _PageReader extends ConsumerStatefulWidget {
  final List<String> pathSegments;
  final List<FileEntry> images;

  const _PageReader({required this.pathSegments, required this.images});

  @override
  ConsumerState<_PageReader> createState() => _PageReaderState();
}

class _PageReaderState extends ConsumerState<_PageReader> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.read(apiClientProvider);

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (context, index) {
            final url = client.imageUrl(
              widget.pathSegments,
              widget.images[index].name,
            );
            return InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, _) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 64, color: Colors.grey),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_currentPage + 1} / ${widget.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
