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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          _buildNowPlayingRow(),
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

  Widget _buildNowPlayingRow() {
    final ambientPlaying = _ambientPlayer.playing && _currentAmbientTrack != null;
    final guidedPlaying = _guidedPlayer.playing && _currentGuidedTrack != null;

    if (!ambientPlaying && !guidedPlaying) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ambientPlaying)
              Row(
                children: [
                  const Icon(Icons.graphic_eq),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ambient: ${_currentAmbientTrack!.title}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            if (guidedPlaying) ...[
              if (ambientPlaying) const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.record_voice_over),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Guided: ${_currentGuidedTrack!.title}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
