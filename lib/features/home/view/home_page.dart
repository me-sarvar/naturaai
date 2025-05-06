import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:naturaai/core/theme/theme_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:naturaai/shared/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          Tooltip(
            message: 'Logout',
            child: IconButton(
              icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/login');
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              themeMode == ThemeMode.light
                  ? Icons
                      .wb_sunny // Sun icon
                  : Icons.nights_stay, // Moon icon
              size: 50,
              color:
                  themeMode == ThemeMode.light
                      ? Colors.yellow
                      : Colors.blueGrey,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newMode =
                    themeMode == ThemeMode.light
                        ? ThemeMode.dark
                        : ThemeMode.light;
                ref.read(themeNotifierProvider.notifier).setTheme(newMode);
              },
              child: Text(
                themeMode == ThemeMode.light
                    ? 'Switch to Dark Mode'
                    : 'Switch to Light Mode',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
