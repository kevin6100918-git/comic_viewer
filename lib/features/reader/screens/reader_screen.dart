import 'dart:async';

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

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _PageMode { normal, tall, wide }

// ── ReaderScreen ──────────────────────────────────────────────────────────────

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

// ── _PageReader ───────────────────────────────────────────────────────────────

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

  // Detected modes and wide-image half states, keyed by real image index.
  final Map<int, _PageMode> _modes = {};
  // true = showing right half, false = showing left half.
  final Map<int, bool> _rightHalf = {};

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

  // ── Next book ──────────────────────────────────────────────────────────────

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

  // ── Wide-image half control ────────────────────────────────────────────────

  void _onModeDetected(int index, _PageMode mode, bool isRtl) {
    if (!mounted) return;
    setState(() {
      _modes[index] = mode;
      // Initialize half-state only once per image.
      if (mode == _PageMode.wide && !_rightHalf.containsKey(index)) {
        // RTL reading starts on the right half; LTR on the left.
        _rightHalf[index] = isRtl;
      }
    });
  }

  void _toggleHalf(int index) {
    if (mounted) setState(() => _rightHalf[index] = !(_rightHalf[index] ?? false));
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

    // Disable user-driven page swiping while on a wide-image page.
    // The GestureDetector inside _AdaptivePage handles swipes for wide images
    // and calls _controller.nextPage/previousPage programmatically.
    // Programmatic animations bypass ScrollPhysics, so they still work.
    final currentMode = _modes[_currentPage] ?? _PageMode.normal;
    final physics = currentMode == _PageMode.wide
        ? const NeverScrollableScrollPhysics()
        : const PageScrollPhysics();

    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          reverse: isRtl,
          physics: physics,
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
            final mode = _modes[index] ?? _PageMode.normal;
            final showRight = _rightHalf[index] ?? isRtl;
            return _AdaptivePage(
              imageUrl: url,
              isRtl: isRtl,
              mode: mode,
              showRightHalf: showRight,
              onModeDetected: (m) => _onModeDetected(index, m, isRtl),
              onToggleHalf: () => _toggleHalf(index),
              onNext: () => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
              onPrevious: () => _controller.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              ),
            );
          },
        ),
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

// ── _AdaptivePage ─────────────────────────────────────────────────────────────
//
// Detects image aspect ratio after load, then renders accordingly:
//   normal  → InteractiveViewer + BoxFit.contain
//   tall    → SingleChildScrollView + fitWidth (vertically scrollable)
//   wide    → half-page view controlled by parent; swipes handled here
//
// For wide images, the outer PageView uses NeverScrollableScrollPhysics.
// This widget's GestureDetector intercepts horizontal swipes and either
// toggles halves or calls onNext/onPrevious to advance the outer controller.

class _AdaptivePage extends StatefulWidget {
  final String imageUrl;
  final bool isRtl;
  final _PageMode mode;
  final bool showRightHalf;
  final void Function(_PageMode) onModeDetected;
  final VoidCallback onToggleHalf;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _AdaptivePage({
    required this.imageUrl,
    required this.isRtl,
    required this.mode,
    required this.showRightHalf,
    required this.onModeDetected,
    required this.onToggleHalf,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<_AdaptivePage> createState() => _AdaptivePageState();
}

class _AdaptivePageState extends State<_AdaptivePage> {
  @override
  void initState() {
    super.initState();
    if (widget.mode == _PageMode.normal) {
      _detectMode();
    }
  }

  @override
  void didUpdateWidget(_AdaptivePage old) {
    super.didUpdateWidget(old);
    // Re-detect if the URL changed (shouldn't happen, but be safe).
    if (old.imageUrl != widget.imageUrl && widget.mode == _PageMode.normal) {
      _detectMode();
    }
  }

  Future<void> _detectMode() async {
    try {
      final provider = CachedNetworkImageProvider(widget.imageUrl);
      final stream = provider.resolve(const ImageConfiguration());
      final completer = Completer<(int, int)>();

      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          if (!completer.isCompleted) {
            completer.complete((info.image.width, info.image.height));
          }
          stream.removeListener(listener);
        },
        onError: (e, st) {
          if (!completer.isCompleted) completer.completeError(e, st);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final (w, h) = await completer.future;
      if (!mounted) return;

      final mode = h > w * 2
          ? _PageMode.tall
          : w > h
              ? _PageMode.wide
              : _PageMode.normal;

      widget.onModeDetected(mode);
    } catch (_) {
      // Keep normal mode on detection failure
    }
  }

  // ── Swipe handling for wide images ─────────────────────────────────────────

  void _handleSwipe(DragEndDetails details) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 200) return;

    // In LTR: negative velocity (swipe left) = forward.
    // In RTL: positive velocity (swipe right) = forward.
    final goForward = widget.isRtl ? v > 0 : v < 0;

    // "Forward boundary" = the half you reach LAST before leaving this image.
    // LTR: right half is last → atForwardEnd when showRightHalf == true.
    // RTL: left half is last → atForwardEnd when showRightHalf == false.
    final atForwardEnd =
        widget.isRtl ? !widget.showRightHalf : widget.showRightHalf;
    final atBackwardEnd =
        widget.isRtl ? widget.showRightHalf : !widget.showRightHalf;

    if (goForward) {
      atForwardEnd ? widget.onNext() : widget.onToggleHalf();
    } else {
      atBackwardEnd ? widget.onPrevious() : widget.onToggleHalf();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return switch (widget.mode) {
      _PageMode.tall => _buildTall(screen),
      _PageMode.wide => _buildWide(screen),
      _PageMode.normal => _buildNormal(),
    };
  }

  Widget _buildNormal() {
    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.contain,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined,
              size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTall(Size screen) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        width: screen.width,
        fit: BoxFit.fitWidth,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined,
              size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  // Wide image: GestureDetector handles swipes; shows left or right half.
  Widget _buildWide(Size screen) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: _handleSwipe,
      child: _halfPage(screen, rightHalf: widget.showRightHalf),
    );
  }

  // Renders one half of a wide image.
  //
  // OverflowBox lets the child exceed parent constraints (screen.width).
  // Setting maxWidth to 2× screen allows the image to render at full double
  // width. Alignment pins the child to the left or right edge, so ClipRect
  // clips the opposite half away.
  Widget _halfPage(Size screen, {required bool rightHalf}) {
    return ClipRect(
      child: OverflowBox(
        maxWidth: screen.width * 2,
        minWidth: 0,
        alignment:
            rightHalf ? Alignment.centerRight : Alignment.centerLeft,
        child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          width: screen.width * 2,
          fit: BoxFit.fitWidth,
          placeholder: (_, _) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined,
                size: 64, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

// ── _NextBookPage ─────────────────────────────────────────────────────────────

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
