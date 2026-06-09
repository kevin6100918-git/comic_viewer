import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/bookmark_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/models/reading_progress.dart';
import '../../../core/models/bookmark_entry.dart';
import '../../reader/screens/reader_screen.dart';
import '../../settings/screens/settings_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _openReader(
    BuildContext context,
    List<String> pathSegments,
    String title,
    int initialPage,
  ) {
    Navigator.pop(context); // close drawer
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
        pathSegments: pathSegments,
        title: title,
        initialPage: initialPage,
      ),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    final bookmarks = ref.watch(bookmarkProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(colorScheme: colorScheme),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: const [
                        Tab(icon: Icon(Icons.history), text: '瀏覽紀錄'),
                        Tab(icon: Icon(Icons.bookmark_outlined), text: '書籤'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _HistoryTab(
                            history: history,
                            onTap: (p) => _openReader(
                              context,
                              p.pathSegments,
                              p.title,
                              p.page,
                            ),
                          ),
                          _BookmarkTab(
                            bookmarks: bookmarks.values.toList(),
                            onTap: (b) => _openReader(
                              context,
                              b.pathSegments,
                              b.title,
                              b.page,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final ColorScheme colorScheme;
  const _DrawerHeader({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      color: colorScheme.primaryContainer,
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded,
              color: colorScheme.onPrimaryContainer, size: 28),
          const SizedBox(width: 12),
          Text(
            '漫畫書櫃',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<ReadingProgress> history;
  final void Function(ReadingProgress) onTap;

  const _HistoryTab({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('尚無瀏覽紀錄', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, i) {
        final p = history[i];
        return ListTile(
          leading: const Icon(Icons.auto_stories_outlined),
          title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '第 ${p.page + 1} / ${p.total} 頁',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => onTap(p),
        );
      },
    );
  }
}

class _BookmarkTab extends StatelessWidget {
  final List<BookmarkEntry> bookmarks;
  final void Function(BookmarkEntry) onTap;

  const _BookmarkTab({required this.bookmarks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('尚無書籤', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, i) {
        final b = bookmarks[i];
        return ListTile(
          leading: const Icon(Icons.bookmark_outlined),
          title: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '第 ${b.page + 1} / ${b.total} 頁',
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => onTap(b),
        );
      },
    );
  }
}
