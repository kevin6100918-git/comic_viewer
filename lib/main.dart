import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/settings_provider.dart';
import 'features/browser/screens/folder_browser_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ComicViewerApp(),
    ),
  );
}

class ComicViewerApp extends StatelessWidget {
  const ComicViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '漫畫書櫃',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const FolderBrowserScreen(
        pathSegments: ['漫畫'],
        title: '漫畫書櫃',
      ),
    );
  }
}
