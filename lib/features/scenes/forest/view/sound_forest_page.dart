import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          },
        ),
      ) {
    _loadFromPrefs();
  }

  final Map<String, AudioPlayer> _players = {
    'rain': AudioPlayer(),
    'fire': AudioPlayer(),
    'birds': AudioPlayer(),
    'wind': AudioPlayer(),
    'river': AudioPlayer(),
    'crickets': AudioPlayer(),
  };

  final Map<String, String> _soundUrls = {
    'rain': 'assets/sounds/rain.mp3',
    'fire': 'assets/sounds/fire.mp3',
    'birds': 'assets/sounds/birds.mp3',
    'wind': 'assets/sounds/wind.mp3',
    'river': 'assets/sounds/river.mp3',
    'crickets': 'assets/sounds/crickets.mp3',
  };

  void toggleSound(String key) async {
    final isActive = state.activeSounds.contains(key);
    final newActiveSounds = Set<String>.from(state.activeSounds);

    if (isActive) {
      await _players[key]?.stop();
      newActiveSounds.remove(key);
    } else {
      await _players[key]?.setAsset(_soundUrls[key]!);
      await _players[key]?.setLoopMode(LoopMode.all);
      await _players[key]?.setVolume(state.volumes[key] ?? 1.0);
      await _players[key]?.play();
      newActiveSounds.add(key);
    }

    state = state.copyWith(activeSounds: newActiveSounds);
    _saveToPrefs();
  }

  void setVolume(String key, double volume) {
    final newVolumes = Map<String, double>.from(state.volumes);
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
    _clearPrefs();
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
    final newVolumes = Map<String, double>.from(state.volumes);

    for (final key in savedKeys) {
      final volume = prefs.getDouble('volume_$key') ?? 1.0;
      newVolumes[key] = volume;
      await _players[key]?.setAsset(_soundUrls[key]!);
      await _players[key]?.setLoopMode(LoopMode.all);
      await _players[key]?.setVolume(volume);
      await _players[key]?.play();
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
    for (var player in _players.values) {
      player.dispose();
    }
    super.dispose();
  }
}

class SoundForestPage extends ConsumerWidget {
  const SoundForestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);

    final soundItems = [
      {'key': 'rain', 'icon': FontAwesomeIcons.cloudRain, 'label': 'Rain'},
      {'key': 'fire', 'icon': FontAwesomeIcons.fire, 'label': 'Fire'},
      {'key': 'birds', 'icon': FontAwesomeIcons.dove, 'label': 'Birds'},
      {'key': 'wind', 'icon': FontAwesomeIcons.wind, 'label': 'Wind'},
      {'key': 'river', 'icon': FontAwesomeIcons.water, 'label': 'River'},
      {'key': 'crickets', 'icon': FontAwesomeIcons.bug, 'label': 'Crickets'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Forest'),
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle),
            tooltip: 'Stop All',
            onPressed: () => controller.stopAll(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children:
              soundItems.map((item) {
                final String key = item['key'] as String;
                final IconData icon = item['icon'] as IconData;
                final String label = item['label'] as String;
                final isActive = soundState.activeSounds.contains(key);
                final volume = soundState.volumes[key] ?? 1.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow:
                                    isActive
                                        ? [
                                          BoxShadow(
                                            color: Colors.teal.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : [],
                              ),
                              child: CircleAvatar(
                                backgroundColor:
                                    isActive
                                        ? Colors.teal
                                        : Colors.grey.shade300,
                                child: FaIcon(
                                  isActive ? FontAwesomeIcons.volumeHigh : icon,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: isActive,
                              onChanged: (_) => controller.toggleSound(key),
                            ),
                          ],
                        ),
                        if (isActive)
                          Slider(
                            value: volume,
                            onChanged: (val) => controller.setVolume(key, val),
                            min: 0,
                            max: 1,
                            divisions: 10,
                            label: "Volume",
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
