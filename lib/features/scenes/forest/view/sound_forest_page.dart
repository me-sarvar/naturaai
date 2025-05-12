import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SoundState {
  final Set<String> activeSounds;
  final Map<String, double> volumes;

  SoundState({required this.activeSounds, required this.volumes});

  SoundState copyWith({
    Set<String>? activeSounds,
    Map<String, double>? volumes,
  }) {
    return SoundState(
      activeSounds: activeSounds ?? this.activeSounds,
      volumes: volumes ?? this.volumes,
    );
  }
}

final soundControllerProvider =
    StateNotifierProvider<SoundController, SoundState>(
      (ref) => SoundController(),
    );

class SoundController extends StateNotifier<SoundState> {
  SoundController()
    : super(
        SoundState(
          activeSounds: {},
          volumes: {
            'rain': 1.0,
            'fire': 1.0,
            'birds': 1.0,
            'wind': 1.0,
            'river': 1.0,
            'crickets': 1.0,
            'frogs': 1.0,
            'leaves': 1.0,
            'water': 1.0,
          },
        ),
      ) {
    _loadFromPrefs();
  }

  final Map<String, AudioPlayer> _players = {
    for (var k in [
      'rain',
      'fire',
      'birds',
      'wind',
      'river',
      'crickets',
      'frogs',
      'leaves',
      'water',
    ])
      k: AudioPlayer(),
  };

  final Map<String, String> _soundUrls = {
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

  void toggleSound(String key) async {
    final isActive = state.activeSounds.contains(key);
    final newActiveSounds = {...state.activeSounds};

    if (isActive) {
      newActiveSounds.remove(key);
      state = state.copyWith(activeSounds: newActiveSounds);
      _saveToPrefs();
      await _players[key]?.setVolume(0.0);
      await _players[key]?.stop();
    } else {
      newActiveSounds.add(key);
      state = state.copyWith(activeSounds: newActiveSounds);
      _saveToPrefs();
      await _players[key]?.setAsset(_soundUrls[key]!);
      await _players[key]?.setLoopMode(LoopMode.all);
      await _players[key]?.setVolume(10); 
      await _players[key]?.play();
      _animateVolume(
        _players[key],
        state.volumes[key] ?? 10,
        const Duration(milliseconds: 300),
      );
    }
  }

  void _animateVolume(
    AudioPlayer? player,
    double targetVolume,
    Duration duration,
  ) async {
    if (player == null || !player.playing) return;

    const int steps = 30; 
    final double currentVolume = player.volume;
    final double volumeChangePerStep = (targetVolume - currentVolume) / steps;
    final int delayPerStep = duration.inMilliseconds ~/ steps;

    for (int i = 0; i < steps; i++) {
      if (!player.playing) break; 
      await Future.delayed(Duration(milliseconds: delayPerStep));
      final newVolume = currentVolume + (volumeChangePerStep * (i + 1));
      player.setVolume(newVolume.clamp(0.0, 1.0));
    }

    if (player.playing) {
      player.setVolume(targetVolume.clamp(0.0, 1.0));
    }
  }

  void setVolume(String key, double volume) {
    final newVolumes = {...state.volumes};
    newVolumes[key] = volume;
    _players[key]?.setVolume(volume);
    state = state.copyWith(volumes: newVolumes);
    _saveToPrefs();
  }

  void stopAll() {
    for (final key in state.activeSounds) {
      _players[key]?.setVolume(0.0);
      _players[key]?.stop();
    }
    state = state.copyWith(activeSounds: {});
    _saveToPrefs();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('activeSounds', state.activeSounds.toList());
    for (final entry in state.volumes.entries) {
      await prefs.setDouble('volume_${entry.key}', entry.value);
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKeys = prefs.getStringList('activeSounds') ?? [];
    final newVolumes = {...state.volumes};

    for (final key in _soundUrls.keys) {
      final savedVolume = prefs.getDouble('volume_$key');
      if (savedVolume != null) {
        newVolumes[key] = savedVolume;
      }
    }

    final soundsToPlay = <Future>[];
    final currentlyActive = <String>{};

    for (final key in savedKeys) {
      if (_soundUrls.containsKey(key)) {
        currentlyActive.add(key);
        final volume = newVolumes[key] ?? 1.0;
        soundsToPlay.add(() async {
          try {
            await _players[key]?.setAsset(_soundUrls[key]!);
            await _players[key]?.setLoopMode(LoopMode.all);
            await _players[key]?.setVolume(volume);
            await _players[key]?.play();
          } catch (e) {
            print('Error loading or playing $key: $e');
            currentlyActive.remove(key);
          }
        }());
      }
    }
    await Future.wait(soundsToPlay);
    state = SoundState(activeSounds: currentlyActive, volumes: newVolumes);
  }

  // Future<void> _clearPrefs() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('activeSounds');
  //   for (final key in state.volumes.keys) {
  //     await prefs.remove('volume_$key');
  //   }
  //   print("Preferences cleared.");
  // }

  @override
  void dispose() {
    for (var p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}

class SoundItem {
  final String key;
  final IconData icon;
  final String label;
  final Color color;

  SoundItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
  });
}

final List<SoundItem> soundItems = [
  SoundItem(
    key: 'rain',
    icon: FontAwesomeIcons.cloudRain,
    label: 'Rain',
    color: Colors.blueAccent[100]!,
  ),
  SoundItem(
    key: 'fire',
    icon: FontAwesomeIcons.fire,
    label: 'Fire',
    color: Colors.orange[300]!,
  ),
  SoundItem(
    key: 'birds',
    icon: FontAwesomeIcons.dove,
    label: 'Birds',
    color: Colors.lightGreen[300]!,
  ),
  SoundItem(
    key: 'wind',
    icon: FontAwesomeIcons.wind,
    label: 'Wind',
    color: Colors.cyan[300]!,
  ),
  SoundItem(
    key: 'river',
    icon: FontAwesomeIcons.water,
    label: 'River',
    color: Colors.blue[300]!,
  ),
  SoundItem(
    key: 'crickets',
    icon: FontAwesomeIcons.bug,
    label: 'Crickets',
    color: Colors.brown[300]!,
  ),
  SoundItem(
    key: 'frogs',
    icon: FontAwesomeIcons.frog,
    label: 'Frogs',
    color: Colors.green[400]!,
  ),
  SoundItem(
    key: 'leaves',
    icon: FontAwesomeIcons.leaf,
    label: 'Leaves',
    color: Colors.green[300]!,
  ),
  SoundItem(
    key: 'water',
    icon: FontAwesomeIcons.droplet,
    label: 'Water',
    color: Colors.lightBlue[300]!,
  ),
];

class SoundForestPage extends ConsumerWidget {
  const SoundForestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);
    final activeCount = soundState.activeSounds.length;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: ShaderMask(
              shaderCallback:
                  (bounds) => LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ).createShader(bounds),
              blendMode: BlendMode.darken,
              child: Image.asset(
                'assets/images/forest.png',
                fit: BoxFit.cover,

                colorBlendMode: BlendMode.overlay,
                color: Colors.teal.withValues(alpha: 0.2),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Forest Sound',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black54,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeCount > 0)
                        Tooltip(
                          message: 'Stop All Sounds',
                          child: IconButton(
                            icon: const Icon(
                              Icons.stop_circle_outlined,
                              color: Colors.white70,
                              size: 30,
                            ),
                            onPressed: controller.stopAll,
                          ),
                        ),
                    ],
                  ),
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1.0,
                        child: child,
                      ),
                    );
                  },
                  child:
                      activeCount > 0
                          ? Padding(
                            key: const ValueKey(
                              'activeCounter',
                            ),
                            padding: const EdgeInsets.only(
                              left: 28,
                              bottom: 16,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 16,
                                  color: Colors.white60,
                                ), // Add a small icon
                                const SizedBox(width: 6),
                                Text(
                                  '$activeCount active mix',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : const SizedBox.shrink(),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.9,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: soundItems.length,
                      itemBuilder: (context, index) {
                        final item = soundItems[index];
                        final isActive = soundState.activeSounds.contains(
                          item.key,
                        );
                        final volume = soundState.volumes[item.key] ?? 1.0;

                        return SoundCell(
                          item: item,
                          isActive: isActive,
                          volume: volume,
                          onToggle: () => controller.toggleSound(item.key),
                          onVolumeChanged:
                              (value) => controller.setVolume(item.key, value),
                        );
                      },
                    ),
                  ),
                ),

                if (activeCount > 0)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: 200,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),

                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      itemCount: soundState.activeSounds.length,
                      itemBuilder: (context, index) {
                        final key = soundState.activeSounds.elementAt(index);
                        final item = soundItems.firstWhere((i) => i.key == key);
                        final volume = soundState.volumes[key] ?? 1.0;

                        return Padding(
                          padding: EdgeInsets.only(
                            right:
                                index == soundState.activeSounds.length - 1
                                    ? 0
                                    : 2,
                          ),
                          child: VolumeControl(
                            item: item,
                            volume: volume,
                            onVolumeChanged:
                                (value) => controller.setVolume(key, value),
                          ),
                        );
                      },
                    ),
                  ),
                if (activeCount == 0) const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SoundCell extends StatelessWidget {
  final SoundItem item;
  final bool isActive;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  const SoundCell({
    super.key,
    required this.item,
    required this.isActive,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color:
                  isActive
                      ? item.color.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isActive
                        ? item.color.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.15),
                width: isActive ? 2.0 : 1.0,
              ),
              boxShadow:
                  isActive
                      ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.3),
                          blurRadius: 8.0,
                          spreadRadius: 1.0,
                        ),
                      ]
                      : [],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: isActive ? 0.1 : 0.02),
                          Colors.black.withValues(alpha: isActive ? 0.1 : 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FaIcon(
                        item.icon,
                        color:
                            isActive
                                ? item.color.brighten(20)
                                : Colors.white.withValues(
                                  alpha: 0.6,
                                ), // Use brighter item color
                        size: 42,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        item.label,
                        style: TextStyle(
                          color:
                              isActive
                                  ? Colors.white
                                  : Colors.white.withValues(
                                    alpha: 0.6,
                                  ), // White text for active
                          fontSize: 14,
                          fontWeight:
                              isActive ? FontWeight.w500 : FontWeight.w300,
                          letterSpacing: 0.8,
                          shadows:
                              isActive
                                  ? [
                                    Shadow(
                                      blurRadius: 2.0,
                                      color: Colors.black38,
                                      offset: Offset(0.5, 0.5),
                                    ),
                                  ]
                                  : [],
                        ),
                      ),
                    ],
                  ),
                ),
                //
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.color,
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.5),
                            blurRadius: 4.0,
                            spreadRadius: 1.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  Color brighten([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    final HSLColor hsl = HSLColor.fromColor(this);
    final double lightness = (hsl.lightness + (percent / 100.0)).clamp(
      0.0,
      1.0,
    );
    return hsl.withLightness(lightness).toColor();
  }
}

class VolumeControl extends StatelessWidget {
  final SoundItem item;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  const VolumeControl({
    super.key,
    required this.item,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sound icon
          FaIcon(item.icon, color: item.color.brighten(20), size: 18),
          const SizedBox(height: 6),

          Expanded(
            child: Container(
              width: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3, 
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    trackShape: const RoundedRectSliderTrackShape(),
                    activeTrackColor: item.color.brighten(10),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    thumbColor: Colors.white,
                    overlayColor: item.color.withValues(alpha: 0.3),
                  ),
                  child: Slider(
                    value: volume,
                    min: 0.0,
                    max: 10,
                    onChanged: onVolumeChanged,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w300,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
