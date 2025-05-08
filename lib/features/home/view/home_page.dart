import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:naturaai/core/theme/theme_notifier.dart';
import 'package:naturaai/shared/providers/auth_provider.dart';
import 'package:naturaai/shared/widgets/language_switcher.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NaturaAI'),
        actions: [
          Row(
            children: [
              // LanguageSwitcher(),

              IconButton(
                tooltip: 'Logout',
                icon: const FaIcon(FontAwesomeIcons.rightFromBracket),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  context.go('/login');
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Image.asset('assets/images/icon.png', height: 150),
              const SizedBox(height: 16),
              const Text(
                'Welcome to NaturaAI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Sound Cards
              _SoundCard(
                title: 'Rain in Forest',
                icon: FontAwesomeIcons.cloudRain,
              ),
              const SizedBox(height: 12),
              _SoundCard(
                title: 'Campfire & Night',
                icon: FontAwesomeIcons.fire,
              ),
              const SizedBox(height: 12),
              _SoundCard(
                title: 'Mix Custom Sounds',
                icon: FontAwesomeIcons.sliders,
              ),

              const Spacer(),

              // Theme Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wb_sunny_outlined),
                  Switch(
                    value: themeMode == ThemeMode.dark,
                    onChanged: (val) {
                      ref
                          .read(themeNotifierProvider.notifier)
                          .setTheme(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  const Icon(Icons.nightlight_round),
                ],
              ),
              const SizedBox(height: 16),

              // Explore More
              ElevatedButton.icon(
                icon: Icon(Icons.forest),
                label: Text('Open Sound Forest'),
                onPressed: () => context.push('/forest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundCard extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SoundCard({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: FaIcon(icon, size: 24),
        title: Text(title),
        trailing: Icon(
          Icons.play_circle_fill,
          color: Theme.of(context).primaryColor,
          size: 28,
        ),
        onTap: () {
          // TODO: implement sound playback
        },
      ),
    );
  }
}
