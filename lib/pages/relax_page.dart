import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/relax_track.dart';

class RelaxPage extends StatefulWidget {
  const RelaxPage({super.key});

  @override
  State<RelaxPage> createState() => _RelaxPageState();
}

class _RelaxPageState extends State<RelaxPage> {

  final AudioPlayer _player = AudioPlayer();

  final List<RelaxTrack> _ambientTracks = const [
    RelaxTrack(
      title: 'Calm River',
      assetPath: 'lib/audio/ambient/Calm_River.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Denali',
      assetPath: 'lib/audio/ambient/Denali.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Fireplace',
      assetPath: 'lib/audio/ambient/Fireplace.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Falling Sundrops',
      assetPath: 'lib/audio/ambient/Falling_Sundrops.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Flowing Stream',
      assetPath: 'lib/audio/ambient/Flowing_Streme.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Flying Above Clouds',
      assetPath: 'lib/audio/ambient/Flying_above_clouds.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Into the Horizon',
      assetPath: 'lib/audio/ambient/Into_the_horizon.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Jasper Lake',
      assetPath: 'lib/audio/ambient/Jasper_Lake.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Moving Cloudbreak',
      assetPath: 'lib/audio/ambient/Moving_cloudbreak.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Olympic',
      assetPath: 'lib/audio/ambient/Olympic.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Open Ocean',
      assetPath: 'lib/audio/ambient/Open_Ocean.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Passing Clouds',
      assetPath: 'lib/audio/ambient/passing_clouds.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Pouring Rain',
      assetPath: 'lib/audio/ambient/Pouring_Rain.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Silent Earth',
      assetPath: 'lib/audio/ambient/Silent_Earth.mp3',
      category: 'Ambient',
    ),
    RelaxTrack(
      title: 'Suspended Droplets',
      assetPath: 'lib/audio/ambient/Suspended_Droplets.mp3',
      category: 'Ambient',
    ),
  ];

  final List<RelaxTrack> _guidedTracks = const [
    RelaxTrack(
      title: 'Focus Day 1',
      assetPath: 'lib/audio/guided/focus_day1.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 2',
      assetPath: 'lib/audio/guided/focus_day2.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 3',
      assetPath: 'lib/audio/guided/focus_day3.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 4',
      assetPath: 'lib/audio/guided/focus_day4.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 5',
      assetPath: 'lib/audio/guided/focus_day5.mp3',
      category: 'Guided',
    ),
    RelaxTrack(
      title: 'Focus Day 6',
      assetPath: 'lib/audio/guided/focus_day6.mp3',
      category: 'Guided',
    ),
  ];

  RelaxTrack? _currentTrack;
  bool _isLoadingTrack = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleTrack(RelaxTrack track) async {
    final bool isCurrent = _currentTrack?.assetPath == track.assetPath;
    setState(() => _isLoadingTrack = true);

    try {
      if (!isCurrent) {
        await _player.stop();
        await _player.setAudioSource(AudioSource.asset(track.assetPath));
        await _player.play();
        setState(() => _currentTrack = track);
      } else {
        if (_player.playing) {
          await _player.pause();
        } else {
          await _player.play();
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start audio: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTrack = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: const Text('Relax & Meditations')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Bring down the noise with a calming ambient bed or follow a short guided focus session.',
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Ambient soundscapes',
                description: 'Soft textures to play while you study or rest.',
                tracks: _ambientTracks,
                playerState: playerState,
              ),
              const SizedBox(height: 12),
              _buildSection(
                title: 'Guided focus series',
                description: 'Short sessions to centre yourself before a busy day.',
                tracks: _guidedTracks,
                playerState: playerState,
              ),
              const SizedBox(height: 16),
              if (_currentTrack != null)
                _buildNowPlaying(playerState: playerState, track: _currentTrack!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<RelaxTrack> tracks,
    required PlayerState? playerState,
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
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                child: Icon(
                  track.category == 'Ambient' ? Icons.spa_outlined : Icons.self_improvement,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              title: Text(track.title),
              subtitle: Text(track.category),
              trailing: _buildTrailingControl(track, playerState),
              onTap: () => _toggleTrack(track),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingControl(RelaxTrack track, PlayerState? playerState) {
    final bool isCurrent = _currentTrack?.assetPath == track.assetPath;
    final bool isPlayingCurrent = isCurrent && (playerState?.playing ?? false);
    final bool isBuffering = isCurrent &&
        ((playerState?.processingState == ProcessingState.loading) ||
            (playerState?.processingState == ProcessingState.buffering));

    if ((_isLoadingTrack && isCurrent) || isBuffering) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: Icon(isPlayingCurrent ? Icons.pause : Icons.play_arrow),
      onPressed: () => _toggleTrack(track),
    );
  }

  Widget _buildNowPlaying({required PlayerState? playerState, required RelaxTrack track}) {
    final bool isPlaying = playerState?.playing ?? false;
    final bool isCompleted = playerState?.processingState == ProcessingState.completed;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.graphic_eq,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    track.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted ? 'Session completed' : 'Now playing',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              onPressed: () => _toggleTrack(track),
            ),
          ],
        ),
      ),
    );
  }
}
