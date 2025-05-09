import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_switch/flutter_switch.dart';
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
  final Color color;

  SoundItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
  });
}

final List<SoundItem> soundItems = [
  SoundItem(key: 'rain', icon: FontAwesomeIcons.cloudRain, label: 'Rain', color: Colors.blueAccent),
  SoundItem(key: 'fire', icon: FontAwesomeIcons.fire, label: 'Fire', color: Colors.orangeAccent),
  SoundItem(key: 'birds', icon: FontAwesomeIcons.dove, label: 'Birds', color: Colors.lightBlueAccent),
  SoundItem(key: 'wind', icon: FontAwesomeIcons.wind, label: 'Wind', color: Colors.teal),
  SoundItem(key: 'river', icon: FontAwesomeIcons.water, label: 'River', color: Colors.blue),
  SoundItem(key: 'crickets', icon: FontAwesomeIcons.bug, label: 'Crickets', color: Colors.greenAccent),
  SoundItem(key: 'frogs', icon: FontAwesomeIcons.frog, label: 'Frogs', color: Colors.green),
  SoundItem(key: 'leaves', icon: FontAwesomeIcons.leaf, label: 'Leaves', color: Colors.lightGreen),
  SoundItem(key: 'water', icon: FontAwesomeIcons.droplet, label: 'Water', color: Colors.cyan),
];

// 📱 UI COMPONENTS

class SoundForestPage extends ConsumerWidget {
  const SoundForestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);
    final activeCount = soundState.activeSounds.length;

    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/forest.png',
            fit: BoxFit.cover,
          ),
        ),
        
        // Main UI
        Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Sound Forest', 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 24,
              )
            ),
            centerTitle: true,
            actions: [
              if (activeCount > 0)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 28),
                  onPressed: () => _showStopConfirmation(context, controller),
                  tooltip: 'Stop All Sounds',
                ),
            ],
          ),
          body: Column(
            children: [
              // Active Sound Count
              if (activeCount > 0)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active Sounds: $activeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              
              // Sound List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: soundItems.length,
                    itemBuilder: (context, index) {
                      final item = soundItems[index];
                      final isActive = soundState.activeSounds.contains(item.key);
                      final volume = soundState.volumes[item.key] ?? 1.0;
                      
                      return SoundCard(
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
            ],
          ),
        ),
      ],
    );
  }

  void _showStopConfirmation(BuildContext context, SoundController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        title: const Text('Stop All Sounds?'),
        content: const Text('This will stop all currently playing sounds.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.stopAll();
              Navigator.pop(context);
            },
            child: const Text('Stop All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class SoundCard extends StatelessWidget {
  final SoundItem item;
  final bool isActive;
  final double volume;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  const SoundCard({
    super.key,
    required this.item,
    required this.isActive,
    required this.volume,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? item.color : Colors.white30,
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 3),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sound Icon and Label
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isActive 
                      ? item.color.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                    child: FaIcon(
                      item.icon,
                      color: isActive ? item.color : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Toggle Switch
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlutterSwitch(
                  width: 42,
                  height: 22,
                  toggleSize: 18,
                  value: isActive,
                  onToggle: (_) => onToggle(),
                  activeColor: item.color,
                  inactiveColor: Colors.white30,
                ),
              ],
            ),
          ),
          
          // Volume Slider (only visible when active)
          if (isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.volume_down, color: Colors.white, size: 14),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: volume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: item.color,
                        inactiveColor: Colors.white30,
                        onChanged: onVolumeChanged,
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up, color: Colors.white, size: 14),
                ],
              ),
            ),
        ],
      ),
    );
  }
}