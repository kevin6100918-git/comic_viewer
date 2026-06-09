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
import '../../browser/providers/folder_provider.dart';

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

  // Next-book state: populated async after init
  List<String>? _nextBookPath;
  String? _nextBookTitle;
  bool _nextNavPending = false;

  String get _bookId => widget.pathSegments.join('/');

  List<String> get _parentPath =>
      widget.pathSegments.sublist(0, widget.pathSegments.length - 1);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _controller = PageController(initialPage: _currentPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress();
      _loadNextBookPath();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Next book lookup ───────────────────────────────────────────────────────

  Future<void> _loadNextBookPath() async {
    if (_parentPath.isEmpty) return;
    try {
      final entries = await ref.read(folderProvider(_parentPath).future);
      final folders =
          entries.where((e) => e.type == FileType.folder).toList();
      final idx =
          folders.indexWhere((e) => e.name == widget.pathSegments.last);
      if (idx >= 0 && idx < folders.length - 1) {
        final next = folders[idx + 1];
        if (mounted) {
          setState(() {
            _nextBookPath = [..._parentPath, next.name];
            _nextBookTitle = next.name;
          });
        }
      }
    } catch (_) {}
  }

  // ── Page events ────────────────────────────────────────────────────────────

  void _onPageChanged(int index) {
    // index == images.length is the "next book" transition page
    if (index >= widget.images.length) {
      if (!_nextNavPending) {
        _nextNavPending = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _navigateToNextBook());
      }
      return;
    }
    setState(() => _currentPage = index);
    _saveProgress();
    _preloadAdjacent(index);
  }

  void _preloadAdjacent(int page) {
    final isRtl = ref.read(readingRtlProvider);
    final client = ref.read(apiClientProvider);
    // In RTL mode PageView is reversed: visual "next" = lower index.
    final nextIdx = isRtl ? page - 1 : page + 1;
    final prevIdx = isRtl ? page + 1 : page - 1;
    for (final idx in [nextIdx, prevIdx]) {
      if (idx >= 0 && idx < widget.images.length) {
        precacheImage(
          CachedNetworkImageProvider(
            client.imageUrl(widget.pathSegments, widget.images[idx].name),
          ),
          context,
        );
      }
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void _navigateToNextBook() {
    if (!mounted || _nextBookPath == null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ReaderScreen(
        pathSegments: _nextBookPath!,
        title: _nextBookTitle ?? _nextBookPath!.last,
      ),
    ));
  }

  // ── Progress / bookmark ────────────────────────────────────────────────────

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
            content: Text('書籤已移除'), duration: Duration(seconds: 2)),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final client = ref.read(apiClientProvider);
    final isRtl = ref.watch(readingRtlProvider);
    final autoNext = ref.watch(autoNextBookProvider);
    final bookmarks = ref.watch(bookmarkProvider);
    final hasBookmark = bookmarks.containsKey(_bookId);

    final hasNextPage = autoNext && _nextBookPath != null;
    final pageCount = widget.images.length + (hasNextPage ? 1 : 0);

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          reverse: isRtl,
          itemCount: pageCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            if (index == widget.images.length) {
              return _NextBookPage(title: _nextBookTitle);
            }
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
        // Page counter (only shown for real image pages)
        if (_currentPage < widget.images.length)
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

// ── Transition page shown while navigating to next book ──────────────────────

class _NextBookPage extends StatelessWidget {
  final String? title;
  const _NextBookPage({this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text('前往下一本'),
          if (title != null) ...[
            const SizedBox(height: 8),
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
