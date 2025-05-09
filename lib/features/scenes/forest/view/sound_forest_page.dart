import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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

// 🎮 THEME PROVIDER

final themeProvider = StateProvider<String>((ref) => 'forest');

// 🎛️ CONTROLLER

class SoundController extends StateNotifier<SoundState> {
  SoundController()
      : super(SoundState(
          activeSounds: {},
          volumes: {
            'rain': 0.7,
            'fire': 0.8,
            'birds': 0.6,
            'wind': 0.5,
            'river': 0.7,
            'crickets': 0.6,
            'frogs': 0.5,
            'leaves': 0.4,
            'water': 0.6,
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
    HapticFeedback.lightImpact();
    
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
    HapticFeedback.mediumImpact();
    
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
  final String description;

  SoundItem({
    required this.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.description,
  });
}

// Theme Data
class ThemeData {
  final String name;
  final String bgImage;
  final Color primaryColor;
  final Color accentColor;
  final LinearGradient gradient;

  ThemeData({
    required this.name,
    required this.bgImage,
    required this.primaryColor,
    required this.accentColor,
    required this.gradient,
  });
}

final Map<String, ThemeData> appThemes = {
  'forest': ThemeData(
    name: 'Forest',
    bgImage: 'assets/images/forest.png',
    primaryColor: Colors.teal,
    accentColor: Colors.tealAccent,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.teal.withOpacity(0.7), Colors.green.withOpacity(0.7)],
    ),
  ),
  'night': ThemeData(
    name: 'Night',
    bgImage: 'assets/images/night.png', // You'll need to add this image
    primaryColor: Colors.indigo,
    accentColor: Colors.purpleAccent,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.indigo.withOpacity(0.7), Colors.purple.withOpacity(0.7)],
    ),
  ),
  'beach': ThemeData(
    name: 'Beach',
    bgImage: 'assets/images/beach.png', // You'll need to add this image
    primaryColor: Colors.blue,
    accentColor: Colors.cyanAccent,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.blue.withOpacity(0.7), Colors.cyan.withOpacity(0.7)],
    ),
  ),
};

final List<SoundItem> soundItems = [
  SoundItem(
    key: 'rain', 
    icon: FontAwesomeIcons.cloudRain, 
    label: 'Rain', 
    color: Colors.blueAccent,
    description: 'Gentle rainfall to soothe your mind',
  ),
  SoundItem(
    key: 'fire', 
    icon: FontAwesomeIcons.fire, 
    label: 'Fire', 
    color: Colors.orangeAccent,
    description: 'Crackling campfire for cozy ambiance',
  ),
  SoundItem(
    key: 'birds', 
    icon: FontAwesomeIcons.dove, 
    label: 'Birds', 
    color: Colors.lightBlueAccent,
    description: 'Cheerful birdsong to brighten your day',
  ),
  SoundItem(
    key: 'wind', 
    icon: FontAwesomeIcons.wind, 
    label: 'Wind', 
    color: Colors.teal,
    description: 'Gentle breeze rustling through trees',
  ),
  SoundItem(
    key: 'river', 
    icon: FontAwesomeIcons.water, 
    label: 'River', 
    color: Colors.blue,
    description: 'Flowing water creating natural harmony',
  ),
  SoundItem(
    key: 'crickets', 
    icon: FontAwesomeIcons.bug, 
    label: 'Crickets', 
    color: Colors.greenAccent,
    description: 'Evening cricket chorus for peaceful nights',
  ),
  SoundItem(
    key: 'frogs', 
    icon: FontAwesomeIcons.frog, 
    label: 'Frogs', 
    color: Colors.green,
    description: 'Rhythmic frog calls from a night pond',
  ),
  SoundItem(
    key: 'leaves', 
    icon: FontAwesomeIcons.leaf, 
    label: 'Leaves', 
    color: Colors.lightGreen,
    description: 'Rustling leaves in a gentle forest',
  ),
  SoundItem(
    key: 'water', 
    icon: FontAwesomeIcons.droplet, 
    label: 'Water', 
    color: Colors.cyan,
    description: 'Calming water droplets for meditation',
  ),
];

// 📱 UI COMPONENTS

class SoundForestPage extends ConsumerWidget {
  const SoundForestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final soundState = ref.watch(soundControllerProvider);
    final controller = ref.read(soundControllerProvider.notifier);
    final themeKey = ref.watch(themeProvider);
    final theme = appThemes[themeKey]!;
    final activeCount = soundState.activeSounds.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        children: [
          // Background Image with Parallax Effect
          ParallaxBackground(imagePath: theme.bgImage),
          
          // Blur Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                gradient: theme.gradient,
              ),
            ),
          ),
          
          // Main UI
          Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.black.withOpacity(0.2),
              elevation: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.waves,
                    color: theme.accentColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sound Forest',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                if (activeCount > 0)
                  IconButton(
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.white, size: 28),
                    onPressed: () => _showStopConfirmation(context, controller, theme),
                    tooltip: 'Stop All Sounds',
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.palette, color: Colors.white),
                  onSelected: (value) {
                    ref.read(themeProvider.notifier).state = value;
                  },
                  itemBuilder: (context) => appThemes.entries
                      .map((entry) => PopupMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value.name),
                          ))
                      .toList(),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Active Sound Display
                  if (activeCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.accentColor.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.speaker_group,
                              color: theme.accentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Sounds: $activeCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Sound Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.9,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: soundItems.length,
                        itemBuilder: (context, index) {
                          final item = soundItems[index];
                          final isActive = soundState.activeSounds.contains(item.key);
                          final volume = soundState.volumes[item.key] ?? 1.0;
                          
                          return AnimatedSoundCard(
                            item: item,
                            isActive: isActive,
                            volume: volume,
                            theme: theme,
                            onToggle: () => controller.toggleSound(item.key),
                            onVolumeChanged: (value) => controller.setVolume(item.key, value),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Bottom Info
                  if (activeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      width: double.infinity,
                      color: Colors.black38,
                      child: Text(
                        'Mix multiple sounds to create your perfect ambient environment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStopConfirmation(BuildContext context, SoundController controller, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.accentColor.withOpacity(0.5), width: 1),
        ),
        title: Text(
          'Stop All Sounds?',
          style: TextStyle(color: theme.accentColor),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'This will stop all currently playing sounds.',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              controller.stopAll();
              Navigator.pop(context);
            },
            child: const Text('Stop All'),
          ),
        ],
      ),
    );
  }
}

class AnimatedSoundCard extends StatefulWidget {
  final SoundItem item;
  final bool isActive;
  final double volume;
  final ThemeData theme;
  final VoidCallback onToggle;
  final ValueChanged<double> onVolumeChanged;

  const AnimatedSoundCard({
    super.key,
    required this.item,
    required this.isActive,
    required this.volume,
    required this.theme,
    required this.onToggle,
    required this.onVolumeChanged,
  });

  @override
  State<AnimatedSoundCard> createState() => _AnimatedSoundCardState();
}

class _AnimatedSoundCardState extends State<AnimatedSoundCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSoundCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      onLongPress: () {
        setState(() {
          _showInfo = true;
        });
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showInfo = false;
            });
          }
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isActive
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.isActive
                      ? widget.item.color
                      : Colors.white30,
                  width: widget.isActive ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isActive
                        ? widget.item.color.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                    spreadRadius: widget.isActive ? 1 : 0,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19), // Account for border
                child: Stack(
                  children: [
                    // Glow Effect when active
                    if (widget.isActive)
                      Positioned(
                        top: -20,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.item.color.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Info Overlay (shown on long press)
                    if (_showInfo)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              color: Colors.black.withOpacity(0.7),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.item.label,
                                    style: TextStyle(
                                      color: widget.item.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.item.description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Main Content
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Sound Icon and Label
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: widget.isActive
                                ? widget.item.color.withOpacity(0.3)
                                : Colors.white.withOpacity(0.1),
                            child: FaIcon(
                              widget.item.icon,
                              color: widget.isActive
                                  ? widget.item.color
                                  : Colors.white70,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.item.label,
                            style: TextStyle(
                              color: widget.isActive
                                  ? widget.item.color
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          
                          // Toggle Switch
                          const SizedBox(height: 12),
                          FlutterSwitch(
                            width: 56,
                            height: 28,
                            toggleSize: 22,
                            padding: 2,
                            value: widget.isActive,
                            onToggle: (_) => widget.onToggle(),
                            activeColor: widget.item.color.withOpacity(0.8),
                            inactiveColor: Colors.white24,
                            activeToggleColor: Colors.white,
                            inactiveToggleColor: Colors.white70,
                          ),
                          
                          // Volume Slider (only visible when active)
                          if (widget.isActive)
                            Opacity(
                              opacity: _opacityAnimation.value,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.volume_down,
                                      color: widget.item.color.withOpacity(0.7),
                                      size: 14,
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          thumbShape: const RoundSliderThumbShape(
                                              enabledThumbRadius: 6),
                                          overlayShape: const RoundSliderOverlayShape(
                                              overlayRadius: 12),
                                          trackHeight: 3,
                                          activeTrackColor: widget.item.color,
                                          inactiveTrackColor: Colors.white30,
                                          thumbColor: Colors.white,
                                          overlayColor: widget.item.color.withOpacity(0.3),
                                        ),
                                        child: Slider(
                                          value: widget.volume,
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: widget.onVolumeChanged,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.volume_up,
                                      color: widget.item.color.withOpacity(0.7),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Active Indicator
                    if (widget.isActive)
                      Positioned(
                        top: 8,
                        right: 8, 
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.item.color,
                            boxShadow: [
                              BoxShadow(
                                color: widget.item.color.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ParallaxBackground extends StatefulWidget {
  final String imagePath;

  const ParallaxBackground({super.key, required this.imagePath});

  @override
  _ParallaxBackgroundState createState() => _ParallaxBackgroundState();
}

class _ParallaxBackgroundState extends State<ParallaxBackground> {
  double offsetX = 0;
  double offsetY = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: Stream.periodic(const Duration(milliseconds: 50), (i) => i),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final time = DateTime.now().millisecondsSinceEpoch / 5000;
          offsetX = sin(time) * 10;
          offsetY = cos(time) * 10;
        }

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
          width: MediaQuery.of(context).size.width + 20,
          height: MediaQuery.of(context).size.height + 20,
          left: -10 + offsetX,
          top: -10 + offsetY,
          child: Image.asset(
            widget.imagePath,
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}