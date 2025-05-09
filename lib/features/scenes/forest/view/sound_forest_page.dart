import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🧠 STATE

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

// 🎛️ CONTROLLER

class SoundController extends StateNotifier<SoundState> {
  SoundController()
      : super(SoundState(
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
        )) {
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
      'water'
    ])
      k: AudioPlayer()
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
      await _players[key]?.stop();
    } else {
      newActiveSounds.add(key);
      state = state.copyWith(activeSounds: newActiveSounds);
      _saveToPrefs();
      await _players[key]?.setAsset(_soundUrls[key]!);
      await _players[key]?.setLoopMode(LoopMode.all);
      await _players[key]?.setVolume(state.volumes[key] ?? 1.0);
      await _players[key]?.play();
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

    for (final key in savedKeys) {
      if (_soundUrls.containsKey(key)) {
        final volume = newVolumes[key] ?? 1.0;
        await _players[key]?.setAsset(_soundUrls[key]!);
        await _players[key]?.setLoopMode(LoopMode.all);
        await _players[key]?.setVolume(volume);
        await _players[key]?.play();
      }
    }

    state = SoundState(activeSounds: savedKeys.toSet(), volumes: newVolumes);
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activeSounds');
    for (final key in state.volumes.keys) {
      await prefs.remove('volume_$key');
    }
  }

  @override
  void dispose() {
    for (var p in _players.values) {
      p.dispose();
    }
    super.dispose();
  }
}

// 🎵 SOUND DATA

class SoundItem {
  final String key;
  final IconData icon;
  final String label;

  SoundItem({
    required this.key,
    required this.icon,
    required this.label,
  });
}

final List<SoundItem> soundItems = [
  SoundItem(key: 'rain', icon: FontAwesomeIcons.cloudRain, label: 'Rain'),
  SoundItem(key: 'fire', icon: FontAwesomeIcons.fire, label: 'Fire'),
  SoundItem(key: 'birds', icon: FontAwesomeIcons.dove, label: 'Birds'),
  SoundItem(key: 'wind', icon: FontAwesomeIcons.wind, label: 'Wind'),
  SoundItem(key: 'river', icon: FontAwesomeIcons.water, label: 'River'),
  SoundItem(key: 'crickets', icon: FontAwesomeIcons.bug, label: 'Crickets'),
  SoundItem(key: 'frogs', icon: FontAwesomeIcons.frog, label: 'Frogs'),
  SoundItem(key: 'leaves', icon: FontAwesomeIcons.leaf, label: 'Leaves'),
  SoundItem(key: 'water', icon: FontAwesomeIcons.droplet, label: 'Water'),
];

// 📱 UI COMPONENTS

class SoundForestPage extends ConsumerWidget {
  const SoundForestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);
    final activeCount = soundState.activeSounds.length;

    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient overlay
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
                stops: [0.6, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.darken,
              child: Image.asset(
                'assets/images/forest.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Sound Forest',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (activeCount > 0)
                        IconButton(
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                            color: Colors.white70,
                            size: 28,
                          ),
                          onPressed: controller.stopAll,
                          tooltip: 'Stop All Sounds',
                        ),
                    ],
                  ),
                ),
                
                // Active Sound Counter
                if (activeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 26, bottom: 16),
                    child: Text(
                      '$activeCount active',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                
                // Sound Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.95,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: soundItems.length,
                      itemBuilder: (context, index) {
                        final item = soundItems[index];
                        final isActive = soundState.activeSounds.contains(item.key);
                        final volume = soundState.volumes[item.key] ?? 1.0;
                        
                        return SoundCell(
                          item: item,
                          isActive: isActive,
                          volume: volume,
                          onToggle: () => controller.toggleSound(item.key),
                          onVolumeChanged: (value) => controller.setVolume(item.key, value),
                        );
                      },
                    ),
                  ),
                ),
                
                // Bottom Volume Controls
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: soundState.activeSounds.length,
                    itemBuilder: (context, index) {
                      final key = soundState.activeSounds.elementAt(index);
                      final item = soundItems.firstWhere((i) => i.key == key);
                      final volume = soundState.volumes[key] ?? 1.0;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: VolumeControl(
                          item: item,
                          volume: volume,
                          onVolumeChanged: (value) => controller.setVolume(key, value),
                        ),
                      );
                    },
                  ),
                ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.2) 
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.7) 
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            FaIcon(
              item.icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
              size: 26,
            ),
            const SizedBox(height: 12),
            
            // Label
            Text(
              item.label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w400 : FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
            
            // Active indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(top: 8),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive 
                    ? Colors.white 
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sound name
        Text(
          item.label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        
        // Vertical slider
        Container(
          height: 60,
          width: 28,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(14),
          ),
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                trackShape: const RoundedRectSliderTrackShape(),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
              ),
              child: Slider(
                value: volume,
                min: 0.0,
                max: 1.0,
                onChanged: onVolumeChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}