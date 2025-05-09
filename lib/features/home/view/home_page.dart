import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:naturaai/core/theme/theme_notifier.dart';

final soundControllerProvider =
    StateNotifierProvider<SoundController, Set<String>>(
      (ref) => SoundController(),
    );

class SoundController extends StateNotifier<Set<String>> {
  SoundController() : super({});

  final Map<String, AudioPlayer> _players = {};

  final Map<String, String> _soundFiles = {
    'rain': 'assets/sounds/rain.mp3',
    'fire': 'assets/sounds/fire.mp3',
    'birds': 'assets/sounds/birds.mp3',
    'wind': 'assets/sounds/wind.mp3',
    'river': 'assets/sounds/river.mp3',
    'crickets': 'assets/sounds/crickets.mp3',
    'frogs': 'assets/sounds/frogs.mp3',
    'leaves': 'assets/sounds/leaves.mp3',
    'water': 'assets/sounds/water.mp3',
  };

  Future<void> toggleSound(String key) async {
    final isPlaying = state.contains(key);
    final newState = {...state};

    if (isPlaying) {
      newState.remove(key);
      state = newState;
      await _players[key]?.stop();
    } else {
      newState.add(key);
      state = newState;
      _players[key] ??= AudioPlayer();
      await _players[key]!.setAsset(_soundFiles[key]!);
      await _players[key]!.setLoopMode(LoopMode.all);
      await _players[key]!.play();
    }
  }

  @override
  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSounds = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);

    final List<_SoundItem> soundItems = [
      _SoundItem(
        'Rain in Forest',
        'rain',
        FontAwesomeIcons.cloudRain,
        Colors.teal,
      ),
      _SoundItem(
        'Campfire & Night',
        'fire',
        FontAwesomeIcons.fire,
        Colors.deepOrange,
      ),
      _SoundItem(
        'Birds in Morning',
        'birds',
        FontAwesomeIcons.dove,
        Colors.lightBlue,
      ),
      _SoundItem('Wind Breeze', 'wind', FontAwesomeIcons.wind, Colors.blueGrey),
      _SoundItem('River Flow', 'river', FontAwesomeIcons.water, Colors.cyan),
      _SoundItem(
        'Crickets at Night',
        'crickets',
        FontAwesomeIcons.bug,
        Colors.purple,
      ),
      _SoundItem(
        'Frogs in Swamp',
        'frogs',
        FontAwesomeIcons.frog,
        Colors.green,
      ),
      _SoundItem(
        'Falling Leaves',
        'leaves',
        FontAwesomeIcons.tree,
        Colors.brown,
      ),
      _SoundItem(
        'Water Dripping',
        'water',
        FontAwesomeIcons.tint,
        Colors.blueAccent,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Natura AI'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: ElevatedButton.icon(
              icon: const FaIcon(
                FontAwesomeIcons.rightFromBracket,
                size: 16,
                color: Colors.teal,
              ),
              label: const Text('Logout', style: TextStyle(color: Colors.teal)),
              onPressed: () {
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.withAlpha(10),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(color: Colors.teal.withAlpha(60)),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    ...soundItems.map((item) {
                      final isActive = activeSounds.contains(item.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => controller.toggleSound(item.key),
                          child: Container(
                            decoration: BoxDecoration(
                              color: item.color.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.color.withAlpha(80),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: item.color.withAlpha(40),
                                  child: FaIcon(
                                    item.icon,
                                    color: item.color,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isActive
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  size: 26,
                                  color: item.color,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.05),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wb_sunny_outlined,
                          color: Colors.orangeAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        FlutterSwitch(
                          width: 56.0,
                          height: 28.0,
                          toggleSize: 24.0,
                          value:
                              ref.watch(themeNotifierProvider) ==
                              ThemeMode.dark,
                          borderRadius: 30.0,
                          padding: 4.0,
                          activeColor: Colors.teal,
                          inactiveColor: Colors.grey.withValues(alpha: 0.3),
                          activeIcon: const Icon(
                            Icons.dark_mode,
                            color: Colors.white,
                            size: 18,
                          ),
                          inactiveIcon: const Icon(
                            Icons.light_mode,
                            color: Colors.white,
                            size: 18,
                          ),
                          onToggle: (val) {
                            ref
                                .read(themeNotifierProvider.notifier)
                                .setTheme(
                                  val ? ThemeMode.dark : ThemeMode.light,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.nightlight_round,
                          color: Colors.deepPurple,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.forest, color: Colors.teal),
                    label: const Text(
                      'Forest',
                      style: TextStyle(color: Colors.teal),
                    ),
                    onPressed: () => context.push('/forest'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.withAlpha(10),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.teal.withAlpha(60)),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: Icon(
                      activeSounds.isNotEmpty
                          ? Icons.stop_circle_rounded
                          : Icons.volume_off_rounded,
                      color: Colors.teal,
                    ),
                    label: const Text(
                      'Stop All',
                      style: TextStyle(color: Colors.teal),
                    ),
                    onPressed:
                        activeSounds.isNotEmpty
                            ? () {
                              activeSounds.toList().forEach(
                                controller.toggleSound,
                              );
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.withAlpha(10),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(color: Colors.teal.withAlpha(60)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundItem {
  final String title;
  final String key;
  final IconData icon;
  final Color color;

  _SoundItem(this.title, this.key, this.icon, this.color);
}
