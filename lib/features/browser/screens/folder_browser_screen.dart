import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../reader/screens/reader_screen.dart';
import '../../sidebar/widgets/app_drawer.dart';
import '../providers/folder_provider.dart';
import '../widgets/folder_card.dart';

class FolderBrowserScreen extends ConsumerStatefulWidget {
  final List<String> pathSegments;
  final String title;

  const FolderBrowserScreen({
    super.key,
    required this.pathSegments,
    required this.title,
  });

  @override
  ConsumerState<FolderBrowserScreen> createState() =>
      _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends ConsumerState<FolderBrowserScreen> {
  bool _navigating = false;

  Future<void> _onFolderTap(FileEntry entry) async {
    if (_navigating) return;
    setState(() => _navigating = true);

    final childPath = [...widget.pathSegments, entry.name];
    try {
      final client = ref.read(apiClientProvider);
      final sort = ref.read(sortProvider);
      final entries = await client.listFolder(
        childPath,
        sortingVote: sort.vote,
        sortingMethod: sort.method,
      );

      if (!mounted) return;

      final hasImages = entries.any((e) => e.type == FileType.image);

      if (hasImages) {
        final bookId = childPath.join('/');
        final savedPage =
            ref.read(historyProvider.notifier).getProgress(bookId)?.page ?? 0;
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReaderScreen(
            pathSegments: childPath,
            title: entry.name,
            initialPage: savedPage,
          ),
        ));
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FolderBrowserScreen(
            pathSegments: childPath,
            title: entry.name,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法開啟資料夾：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  void _showSortSheet() {
    final sort = ref.read(sortProvider);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _SortSheet(current: sort),
    );
  }

  @override
  Widget build(BuildContext context) {
    final folderAsync = ref.watch(folderProvider(widget.pathSegments));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onPressed: _showSortSheet,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          folderAsync.when(
            data: (entries) {
              final folders =
                  entries.where((e) => e.type == FileType.folder).toList();
              if (folders.isEmpty) {
                return const Center(child: Text('沒有找到任何資料夾'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final entry = folders[index];
                  return FolderCard(
                    entry: entry,
                    pathSegments: [...widget.pathSegments, entry.name],
                    onTap: () => _onFolderTap(entry),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('連線失敗\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.invalidate(folderProvider(widget.pathSegments)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('重試'),
                  ),
                ],
              ),
            ),
          ),
          if (_navigating)
            const ColoredBox(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

class _SortSheet extends ConsumerWidget {
  final SortSettings current;
  const _SortSheet({required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(sortProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('排序方式',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            _SortTile(
              label: '名稱',
              icon: Icons.sort_by_alpha,
              vote: 'name',
              current: sort,
              onTap: (v, m) =>
                  ref.read(sortProvider.notifier).setSort(vote: v, method: m),
            ),
            _SortTile(
              label: '修改時間',
              icon: Icons.access_time,
              vote: 'updated',
              current: sort,
              onTap: (v, m) =>
                  ref.read(sortProvider.notifier).setSort(vote: v, method: m),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final String vote;
  final SortSettings current;
  final void Function(String vote, String method) onTap;

  const _SortTile({
    required this.label,
    required this.icon,
    required this.vote,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = current.vote == vote;
    final isAsc = current.method == 'ASC';

    return ListTile(
      leading: Icon(icon,
          color: isActive ? Theme.of(context).colorScheme.primary : null),
      title: Text(label,
          style: isActive
              ? TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600)
              : null),
      trailing: isActive
          ? Icon(
              isAsc ? Icons.arrow_upward : Icons.arrow_downward,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        // If same vote, toggle direction; otherwise set new vote with ASC
        final newMethod =
            isActive ? (isAsc ? 'DESC' : 'ASC') : 'ASC';
        onTap(vote, newMethod);
      },
    );
  }
}
