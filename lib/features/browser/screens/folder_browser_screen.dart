import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/file_entry.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../reader/screens/reader_screen.dart';
import '../../settings/screens/settings_screen.dart';
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

  // Fetches the child folder's contents and navigates to the appropriate screen.
  // Opens ReaderScreen if the folder contains images; otherwise opens another FolderBrowserScreen.
  Future<void> _onFolderTap(FileEntry entry) async {
    if (_navigating) return;
    setState(() => _navigating = true);

    final childPath = [...widget.pathSegments, entry.name];
    try {
      final client = ref.read(apiClientProvider);
      final entries = await client.listFolder(childPath);

      if (!mounted) return;

      final hasImages = entries.any((e) => e.type == FileType.image);

      if (hasImages) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReaderScreen(
            pathSegments: childPath,
            title: entry.name,
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

  @override
  Widget build(BuildContext context) {
    final folderAsync = ref.watch(folderProvider(widget.pathSegments));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
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
