import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/bookmark_entry.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/models/reading_progress.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../browser/providers/folder_provider.dart' show readerFolderProvider;

class ReaderScreen extends ConsumerWidget {
  final List<String> pathSegments;
  final String title;
  final int initialPage;

  const ReaderScreen({
    super.key,
    required this.pathSegments,
    required this.title,
    this.initialPage = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folderAsync = ref.watch(readerFolderProvider(pathSegments));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: folderAsync.when(
        data: (entries) {
          final images =
              entries.where((e) => e.type == FileType.image).toList();
          if (images.isEmpty) {
            return const Center(child: Text('沒有找到圖片'));
          }
          return _PageReader(
            pathSegments: pathSegments,
            title: title,
            images: images,
            initialPage: initialPage.clamp(0, images.length - 1).toInt(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
      ),
    );
  }
}

class _PageReader extends ConsumerStatefulWidget {
  final List<String> pathSegments;
  final String title;
  final List<FileEntry> images;
  final int initialPage;

  const _PageReader({
    required this.pathSegments,
    required this.title,
    required this.images,
    required this.initialPage,
  });

  @override
  ConsumerState<_PageReader> createState() => _PageReaderState();
}

class _PageReaderState extends ConsumerState<_PageReader> {
  late final PageController _controller;
  late int _currentPage;

  String get _bookId => widget.pathSegments.join('/');

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(initialPage: _currentPage);
    // Save initial page to history on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _saveProgress());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _saveProgress();
  }

  void _saveProgress() {
    ref.read(historyProvider.notifier).updateProgress(
          ReadingProgress(
            bookId: _bookId,
            title: widget.title,
            pathSegments: widget.pathSegments,
            page: _currentPage,
            total: widget.images.length,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  void _toggleBookmark() {
    final notifier = ref.read(bookmarkProvider.notifier);
    final existing = notifier.getBookmark(_bookId);
    if (existing != null) {
      notifier.removeBookmark(_bookId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('書籤已移除'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      notifier.setBookmark(BookmarkEntry(
        bookId: _bookId,
        title: widget.title,
        pathSegments: widget.pathSegments,
        page: _currentPage,
        total: widget.images.length,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('書籤已加入（第 ${_currentPage + 1} 頁）'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.read(apiClientProvider);
    final isRtl = ref.watch(readingRtlProvider);
    final bookmarks = ref.watch(bookmarkProvider);
    final hasBookmark = bookmarks.containsKey(_bookId);

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          reverse: isRtl,
          itemCount: widget.images.length,
          onPageChanged: _onPageChanged,
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
        // Page counter
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
        // Bookmark button
        Positioned(
          bottom: 12,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'bookmark_fab',
            tooltip: hasBookmark ? '移除書籤' : '加入書籤',
            backgroundColor:
                hasBookmark ? Theme.of(context).colorScheme.primary : null,
            foregroundColor:
                hasBookmark ? Theme.of(context).colorScheme.onPrimary : null,
            onPressed: _toggleBookmark,
            child: Icon(
              hasBookmark ? Icons.bookmark : Icons.bookmark_border,
            ),
          ),
        ),
      ],
    );
  }
}
