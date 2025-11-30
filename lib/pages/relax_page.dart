import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/relax_track.dart';
import 'breathing_page.dart';

class RelaxPage extends StatefulWidget {
  const RelaxPage({super.key});

  @override
  State<RelaxPage> createState() => _RelaxPageState();
}

class _RelaxPageState extends State<RelaxPage> {
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _guidedPlayer = AudioPlayer();

  RelaxTrack? _currentAmbientTrack;
  RelaxTrack? _currentGuidedTrack;

  bool _isLoadingAmbient = false;
  bool _isLoadingGuided = false;
  bool _isPlayerExpanded = false;
  double _ambientVolume = 0.8;
  double _guidedVolume = 0.8;

  final List<RelaxTrack> _ambientTracks = const [
    RelaxTrack(
      title: 'Calm River',
      assetPath: 'assets/audio/ambient/Calm_River.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Denali',
      assetPath: 'assets/audio/ambient/Denali.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Fireplace',
      assetPath: 'assets/audio/ambient/Fireplace.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Falling Sundrops',
      assetPath: 'assets/audio/ambient/Falling_Sundrops.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Flowing Stream',
      assetPath: 'assets/audio/ambient/Flowing_Stream.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Flying Above Clouds',
      assetPath: 'assets/audio/ambient/Flying_above_clouds.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Into the Horizon',
      assetPath: 'assets/audio/ambient/Into_the_horizon.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Jasper Lake',
      assetPath: 'assets/audio/ambient/Jasper_Lake.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Moving Cloudbreak',
      assetPath: 'assets/audio/ambient/Moving_cloudbreak.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Olympic',
      assetPath: 'assets/audio/ambient/Olympic.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Open Ocean',
      assetPath: 'assets/audio/ambient/Open_Ocean.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Pouring Rain',
      assetPath: 'assets/audio/ambient/Pouring_Rain.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Silent Earth',
      assetPath: 'assets/audio/ambient/Silent_Earth.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Suspended Droplets',
      assetPath: 'assets/audio/ambient/Suspended_Droplets.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Passing Clouds',
      assetPath: 'assets/audio/ambient/passing_clouds.mp3',
      category: 'Ambient',
    ),
  ];

  final List<RelaxTrack> _guidedTracks = const [
    RelaxTrack(
      title: 'Focus Day 1',
      assetPath: 'assets/audio/guided/focus_day1.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Focus Day 2',
      assetPath: 'assets/audio/guided/focus_day2.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Focus Day 3',
      assetPath: 'assets/audio/guided/focus_day3.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Focus Day 4',
      assetPath: 'assets/audio/guided/focus_day4.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Focus Day 5',
      assetPath: 'assets/audio/guided/focus_day5.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Focus Day 6',
      assetPath: 'assets/audio/guided/focus_day6.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Focus Day 7',
      assetPath: 'assets/audio/guided/focus_day7.mp3',
      category: 'Focus',
    ),
    RelaxTrack(
      title: 'Managing Stress Day 1',
      assetPath: 'assets/audio/guided/stress_day1.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Managing Stress Day 2',
      assetPath: 'assets/audio/guided/stress_day2.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Managing Stress Day 3',
      assetPath: 'assets/audio/guided/stress_day3.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Managing Stress Day 4',
      assetPath: 'assets/audio/guided/stress_day4.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Managing Stress Day 5',
      assetPath: 'assets/audio/guided/stress_day5.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Managing Stress Day 6',
      assetPath: 'assets/audio/guided/stress_day6.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Managing Stress  Day 7',
      assetPath: 'assets/audio/guided/stress_day7.mp3',
      category: 'Stress Relief',
    ),
    RelaxTrack(
      title: 'Relax at Night',
      assetPath: 'assets/audio/guided/Relax_at_Night.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 1',
      assetPath: 'assets/audio/guided/sleep_day1.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 2',
      assetPath: 'assets/audio/guided/sleep_day2.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 3',
      assetPath: 'assets/audio/guided/sleep_day3.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 4',
      assetPath: 'assets/audio/guided/sleep_day4.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 5',
      assetPath: 'assets/audio/guided/sleep_day5.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 6',
      assetPath: 'assets/audio/guided/sleep_day6.mp3',
      category: 'Sleep',
    ),
    RelaxTrack(
      title: 'Sleep Day 7',
      assetPath: 'assets/audio/guided/sleep_day7.mp3',
      category: 'Sleep',
    ),
  ];

  @override
  void dispose() {
    _ambientPlayer.dispose();
    _guidedPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ambientPlayer.setVolume(_ambientVolume);
    _guidedPlayer.setVolume(_guidedVolume);
  }

  Future<void> _toggleAmbient(RelaxTrack track) async {
    final isCurrent = _currentAmbientTrack?.assetPath == track.assetPath;
    if (!isCurrent) {
      setState(() {
        _isLoadingAmbient = true;
        _currentAmbientTrack = track;
      });

      try {
        await _ambientPlayer.stop();
        await _ambientPlayer
            .setAudioSource(AudioSource.asset(track.assetPath));
        await _ambientPlayer.setLoopMode(LoopMode.all);
        // Start playback but don't await the full track duration.
        _ambientPlayer.play();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start ambient audio: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingAmbient = false);
        }
      }
    } else {
      final state = _ambientPlayer.playerState;
      final isCompleted = state.processingState == ProcessingState.completed;

      try {
        if (isCompleted) {
          await _ambientPlayer.seek(Duration.zero);
          _ambientPlayer.play();
        } else if (_ambientPlayer.playing) {
          await _ambientPlayer.pause();
        } else {
          _ambientPlayer.play();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update ambient audio: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleGuided(RelaxTrack track) async {
    final isCurrent = _currentGuidedTrack?.assetPath == track.assetPath;
    if (!isCurrent) {
      setState(() {
        _isLoadingGuided = true;
        _currentGuidedTrack = track;
      });

      try {
        await _guidedPlayer.stop();
        await _guidedPlayer
            .setAudioSource(AudioSource.asset(track.assetPath));
        await _guidedPlayer.setLoopMode(LoopMode.off);
        // Start playback but don't await the full track duration.
        _guidedPlayer.play();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start guided audio: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingGuided = false);
        }
      }
    } else {
      final state = _guidedPlayer.playerState;
      final isCompleted = state.processingState == ProcessingState.completed;

      try {
        if (isCompleted) {
          await _guidedPlayer.seek(Duration.zero);
          _guidedPlayer.play();
        } else if (_guidedPlayer.playing) {
          await _guidedPlayer.pause();
        } else {
          _guidedPlayer.play();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not update guided audio: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final playerPadding = _isPlayerExpanded ? 260.0 : 140.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Relax & Meditations')),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, playerPadding + safeBottom),
            children: [
              _buildBreathingCard(context),
              const SizedBox(height: 12),
              const Text(
                'Layer a calming ambient bed with a short guided focus session. '
                'You can play ambient and guided audio together.',
              ),
              const SizedBox(height: 16),
              StreamBuilder<PlayerState>(
                stream: _ambientPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final ambientState = snapshot.data;
                  return _buildSection(
                    title: 'Ambient soundscapes',
                    description: 'Soft textures to play while you study or rest.',
                    tracks: _ambientTracks,
                    playerState: ambientState,
                    isAmbient: true,
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<PlayerState>(
                stream: _guidedPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final guidedState = snapshot.data;
                  return _buildSection(
                    title: 'Guided series',
                    description:
                        'Pick a Focus, Stress Relief, or Sleep session to match how you want to feel.',
                    tracks: _guidedTracks,
                    playerState: guidedState,
                    isAmbient: false,
                    groupByCategory: true,
                  );
                },
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: _buildFloatingPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guided breathing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Short guided breathing to help your body settle when stress spikes. Start to follow clear prompts and a countdown.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.self_improvement_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BreathingPage(),
                      ),
                    );
                  },
                  label: const Text('Start breathing exercise'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BreathingPage(),
                      ),
                    );
                  },
                  child: const Text('View exercises'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<RelaxTrack> tracks,
    required PlayerState? playerState,
    required bool isAmbient,
    bool groupByCategory = false,
  }) {
    final groupedTracks = groupByCategory
        ? _groupTracksByCategory(tracks)
        : {
            '': tracks,
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ...groupedTracks.entries.map((entry) {
          final categoryLabel = entry.key;
          final categoryTracks = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (groupByCategory)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ...categoryTracks.map(
                (track) => Card(
                  elevation: 0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        isAmbient ? Icons.spa_outlined : Icons.self_improvement,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                    title: Text(track.title),
                    subtitle: Text(track.category),
                    trailing: _buildTrailingControl(
                      track: track,
                      playerState: playerState,
                      isAmbient: isAmbient,
                    ),
                    onTap: () => isAmbient
                        ? _toggleAmbient(track)
                        : _toggleGuided(track),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Map<String, List<RelaxTrack>> _groupTracksByCategory(
    List<RelaxTrack> tracks,
  ) {
    final grouped = <String, List<RelaxTrack>>{};

    for (final track in tracks) {
      grouped.putIfAbsent(track.category, () => []).add(track);
    }

    return grouped;
  }

  Widget _buildTrailingControl({
    required RelaxTrack track,
    required PlayerState? playerState,
    required bool isAmbient,
  }) {
    final currentTrack = isAmbient ? _currentAmbientTrack : _currentGuidedTrack;
    final isCurrent = currentTrack?.assetPath == track.assetPath;
    final isPlayingCurrent = isCurrent && (playerState?.playing ?? false);
    final isBuffering = isCurrent &&
        !(playerState?.playing ?? false) &&
        ((playerState?.processingState == ProcessingState.loading) ||
            (playerState?.processingState == ProcessingState.buffering));

    final isLoading = isAmbient ? _isLoadingAmbient : _isLoadingGuided;

    if ((isLoading && isCurrent) || isBuffering) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: Icon(isPlayingCurrent ? Icons.pause : Icons.play_arrow),
      onPressed: () =>
          isAmbient ? _toggleAmbient(track) : _toggleGuided(track),
    );
  }


  Future<void> _seekGuided(double offsetSeconds) async {
    final newPosition = _clampPosition(
      _guidedPlayer.position,
      _guidedPlayer.duration,
      offsetSeconds,
    );
    await _guidedPlayer.seek(newPosition);
  }

  Duration _clampPosition(
    Duration current,
    Duration? duration,
    double offsetSeconds,
  ) {
    final targetMilliseconds =
        (current.inMilliseconds + (offsetSeconds * 1000)).round();
    final lowerBounded = math.max(0, targetMilliseconds);
    final upperBound = duration?.inMilliseconds;

    if (upperBound != null) {
      final clamped = math.min(lowerBounded, upperBound);
      return Duration(milliseconds: clamped);
    }

    return Duration(milliseconds: lowerBounded);
  }

  Widget _buildFloatingPlayer() {
    final showAmbient = _currentAmbientTrack != null;
    final showGuided = _currentGuidedTrack != null;

    if (!showAmbient && !showGuided) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<PlayerState>(
      stream: _ambientPlayer.playerStateStream,
      builder: (context, ambientSnapshot) {
        return StreamBuilder<PlayerState>(
          stream: _guidedPlayer.playerStateStream,
          builder: (context, guidedSnapshot) {
            final ambientState = ambientSnapshot.data;
            final guidedState = guidedSnapshot.data;

            final collapsedTitle = [
              if (showAmbient) 'Ambient: ${_currentAmbientTrack!.title}',
              if (showGuided) 'Guided: ${_currentGuidedTrack!.title}',
            ].join('  •  ');

            return SafeArea(
              child: Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isPlayerExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Now playing',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            tooltip: _isPlayerExpanded ? 'Minimize' : 'Expand',
                            onPressed: () {
                              setState(() {
                                _isPlayerExpanded = !_isPlayerExpanded;
                              });
                            },
                            icon: Icon(
                              _isPlayerExpanded
                                  ? Icons.close_fullscreen
                                  : Icons.open_in_full,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 200),
                        firstCurve: Curves.easeInOut,
                        secondCurve: Curves.easeInOut,
                        crossFadeState: _isPlayerExpanded
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (showAmbient)
                              AmbientPlayerControls(
                                title: _currentAmbientTrack!.title,
                                isPlaying: ambientState?.playing ?? false,
                                onPlayPause: () =>
                                    _toggleAmbient(_currentAmbientTrack!),
                                volume: _ambientVolume,
                                onVolumeChanged: (value) {
                                  setState(() => _ambientVolume = value);
                                  _ambientPlayer.setVolume(value);
                                },
                              ),
                            if (showGuided) ...[
                              if (showAmbient) const SizedBox(height: 12),
                              GuidedPlayerControls(
                                title: _currentGuidedTrack!.title,
                                isPlaying: guidedState?.playing ?? false,
                                onPlayPause: () =>
                                    _toggleGuided(_currentGuidedTrack!),
                                onForward: () => _seekGuided(0.5),
                                onBackward: () => _seekGuided(-0.5),
                                volume: _guidedVolume,
                                onVolumeChanged: (value) {
                                  setState(() => _guidedVolume = value);
                                  _guidedPlayer.setVolume(value);
                                },
                              ),
                            ],
                          ],
                        ),
                        secondChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collapsedTitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              alignment: WrapAlignment.end,
                              children: [
                                if (showAmbient)
                                  IconButton.filledTonal(
                                    tooltip: ambientState?.playing == true
                                        ? 'Pause ambient'
                                        : 'Play ambient',
                                    icon: Icon(ambientState?.playing == true
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    onPressed: () =>
                                        _toggleAmbient(_currentAmbientTrack!),
                                  ),
                                if (showGuided)
                                  IconButton.filledTonal(
                                    tooltip: guidedState?.playing == true
                                        ? 'Pause guided'
                                        : 'Play guided',
                                    icon: Icon(guidedState?.playing == true
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                    onPressed: () =>
                                        _toggleGuided(_currentGuidedTrack!),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AmbientPlayerControls extends StatelessWidget {
  const AmbientPlayerControls({
    super.key,
    required this.title,
    required this.isPlaying,
    required this.onPlayPause,
    required this.volume,
    required this.onVolumeChanged,
  });

  final String title;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.graphic_eq, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text('Ambient',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: onPlayPause,
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.volume_up, size: 18),
            Expanded(
              child: Slider(
                value: volume,
                min: 0,
                max: 1,
                divisions: 10,
                label: volume.toStringAsFixed(1),
                onChanged: onVolumeChanged,
              ),
            ),
            Text('${(volume * 100).round()}%'),
          ],
        ),
      ],
    );
  }
}

class GuidedPlayerControls extends StatelessWidget {
  const GuidedPlayerControls({
    super.key,
    required this.title,
    required this.isPlaying,
    required this.onPlayPause,
    required this.onForward,
    required this.onBackward,
    required this.volume,
    required this.onVolumeChanged,
  });

  final String title;
  final bool isPlaying;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;
  final VoidCallback onBackward;
  final double volume;
  final ValueChanged<double> onVolumeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.record_voice_over, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text('Guided',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Back 0.5s',
              onPressed: onBackward,
              icon: const Icon(Icons.replay_5),
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: onPlayPause,
            ),
            IconButton(
              tooltip: 'Forward 0.5s',
              onPressed: onForward,
              icon: const Icon(Icons.forward_5),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.volume_up, size: 18),
            Expanded(
              child: Slider(
                value: volume,
                min: 0,
                max: 1,
                divisions: 10,
                label: volume.toStringAsFixed(1),
                onChanged: onVolumeChanged,
              ),
            ),
            Text('${(volume * 100).round()}%'),
          ],
        ),
      ],
    );
  }
}
