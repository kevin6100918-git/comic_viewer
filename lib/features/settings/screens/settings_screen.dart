import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(serverAddressProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final address = _controller.text.trim();
    if (address.isEmpty) return;
    await ref.read(serverAddressProvider.notifier).setAddress(address);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已儲存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colorIndex = ref.watch(themeColorIndexProvider);
    final isRtl = ref.watch(readingRtlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Server Address ──────────────────────────────────────────
          _SectionTitle('伺服器位址'),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              prefixText: 'http://',
              hintText: '192.168.0.121:8000',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('儲存'),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '預設值：$kDefaultServerAddress',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),

          const SizedBox(height: 28),

          // ── Theme Mode ──────────────────────────────────────────────
          _SectionTitle('外觀模式'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('系統')),
              ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('淺色')),
              ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('深色')),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setThemeMode(s.first),
          ),

          const SizedBox(height: 28),

          // ── Theme Color ─────────────────────────────────────────────
          _SectionTitle('主題色彩'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(kThemeColors.length, (i) {
              final item = kThemeColors[i];
              final selected = colorIndex == i;
              return GestureDetector(
                onTap: () =>
                    ref.read(themeColorIndexProvider.notifier).setColorIndex(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.outline,
                                width: 3,
                              )
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: item.color.withAlpha(128),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(item.label, style: const TextStyle(fontSize: 11)),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // ── Reading Direction ───────────────────────────────────────
          _SectionTitle('翻頁方向'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: false,
                  icon: Icon(Icons.arrow_forward),
                  label: Text('由左至右')),
              ButtonSegment(
                  value: true,
                  icon: Icon(Icons.arrow_back),
                  label: Text('由右至左')),
            ],
            selected: {isRtl},
            onSelectionChanged: (s) =>
                ref.read(readingRtlProvider.notifier).setRtl(s.first),
          ),
          const SizedBox(height: 8),
          Text(
            isRtl ? '漫畫模式（右→左）' : '一般模式（左→右）',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
