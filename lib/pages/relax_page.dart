import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/relax_track.dart';

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
    // ...rest of your ambient tracks, update paths similarly
  ];

  final List<RelaxTrack> _guidedTracks = const [
    RelaxTrack(
      title: 'Focus Day 1',
      assetPath: 'assets/audio/guided/focus_day1.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 2',
      assetPath: 'assets/audio/guided/focus_day2.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 3',
      assetPath: 'assets/audio/guided/focus_day3.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 4',
      assetPath: 'assets/audio/guided/focus_day4.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 5',
      assetPath: 'assets/audio/guided/focus_day5.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 6',
      assetPath: 'assets/audio/guided/focus_day6.mp3',
      category: 'Guided',
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
    setState(() => _isLoadingAmbient = true);

    try {
      if (!isCurrent) {
        await _ambientPlayer.stop();
        await _ambientPlayer.setAudioSource(AudioSource.asset(track.assetPath));
        await _ambientPlayer.setLoopMode(LoopMode.all);
        await _ambientPlayer.play();
        setState(() => _currentAmbientTrack = track);
      } else {
        final state = _ambientPlayer.playerState;
        final isCompleted = state.processingState == ProcessingState.completed;

        if (isCompleted) {
          await _ambientPlayer.seek(Duration.zero);
          await _ambientPlayer.play();
        } else if (_ambientPlayer.playing) {
          await _ambientPlayer.pause();
        } else {
          await _ambientPlayer.play();
        }
      }
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
  }

  Future<void> _toggleGuided(RelaxTrack track) async {
    final isCurrent = _currentGuidedTrack?.assetPath == track.assetPath;
    setState(() => _isLoadingGuided = true);

    try {
      if (!isCurrent) {
        await _guidedPlayer.stop();
        await _guidedPlayer.setAudioSource(AudioSource.asset(track.assetPath));
        await _guidedPlayer.setLoopMode(LoopMode.off);
        await _guidedPlayer.play();
        setState(() => _currentGuidedTrack = track);
      } else {
        final state = _guidedPlayer.playerState;
        final isCompleted = state.processingState == ProcessingState.completed;

        if (isCompleted) {
          await _guidedPlayer.seek(Duration.zero);
          await _guidedPlayer.play();
        } else if (_guidedPlayer.playing) {
          await _guidedPlayer.pause();
        } else {
          await _guidedPlayer.play();
        }
      }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relax & Meditations')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
            children: [
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
                    title: 'Guided focus series',
                    description: 'Short sessions to centre yourself before a busy day.',
                    tracks: _guidedTracks,
                    playerState: guidedState,
                    isAmbient: false,
                  );
                },
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildFloatingPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<RelaxTrack> tracks,
    required PlayerState? playerState,
    required bool isAmbient,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        ...tracks.map(
          (track) => Card(
            elevation: 0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  isAmbient ? Icons.spa_outlined : Icons.self_improvement,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(track.title),
              subtitle: Text(isAmbient ? 'Ambient' : 'Guided'),
              trailing: _buildTrailingControl(
                track: track,
                playerState: playerState,
                isAmbient: isAmbient,
              ),
              onTap: () =>
                  isAmbient ? _toggleAmbient(track) : _toggleGuided(track),
            ),
          ),
        ),
      ],
    );
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

    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Floating player',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (showAmbient)
              StreamBuilder<PlayerState>(
                stream: _ambientPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final isPlaying = state?.playing ?? false;
                  return _buildAmbientPlayerControls(
                    title: _currentAmbientTrack!.title,
                    isPlaying: isPlaying,
                    onPlayPause: () => _toggleAmbient(_currentAmbientTrack!),
                    volume: _ambientVolume,
                    onVolumeChanged: (value) {
                      setState(() => _ambientVolume = value);
                      _ambientPlayer.setVolume(value);
                    },
                  );
                },
              ),
            if (showGuided) ...[
              if (showAmbient) const SizedBox(height: 12),
              StreamBuilder<PlayerState>(
                stream: _guidedPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  final isPlaying = state?.playing ?? false;
                  return _buildGuidedPlayerControls(
                    title: _currentGuidedTrack!.title,
                    isPlaying: isPlaying,
                    onPlayPause: () => _toggleGuided(_currentGuidedTrack!),
                    onForward: () => _seekGuided(0.5),
                    onBackward: () => _seekGuided(-0.5),
                    volume: _guidedVolume,
                    onVolumeChanged: (value) {
                      setState(() => _guidedVolume = value);
                      _guidedPlayer.setVolume(value);
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientPlayerControls({
    required String title,
    required bool isPlaying,
    required VoidCallback onPlayPause,
    required double volume,
    required ValueChanged<double> onVolumeChanged,
  }) {
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
          ],
        ),
      ],
    );
  }

  Widget _buildGuidedPlayerControls({
    required String title,
    required bool isPlaying,
    required VoidCallback onPlayPause,
    required VoidCallback onForward,
    required VoidCallback onBackward,
    required double volume,
    required ValueChanged<double> onVolumeChanged,
  }) {
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
                  Text('Guided', style: Theme.of(context).textTheme.bodySmall),
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
          ],
        ),
      ],
    );
  }
}
