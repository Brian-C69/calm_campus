import 'dart:async';

import 'package:flutter/material.dart';

import '../models/breathing_exercise.dart';

enum _BreathingPhase { inhale, hold, exhale, finished }

class BreathingSessionPage extends StatefulWidget {
  const BreathingSessionPage({
    super.key,
    required this.exercise,
  });

  final BreathingExercise exercise;

  @override
  State<BreathingSessionPage> createState() => _BreathingSessionPageState();
}

class _BreathingSessionPageState extends State<BreathingSessionPage> {
  Timer? _timer;
  _BreathingPhase _phase = _BreathingPhase.inhale;
  int _secondsRemaining = 0;
  int _currentCycle = 1;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _timer?.cancel();
    setState(() {
      _currentCycle = 1;
    });
    _startPhase(_BreathingPhase.inhale);
  }

  void _startPhase(_BreathingPhase phase) {
    _timer?.cancel();

    final seconds = _phaseDuration(phase);

    setState(() {
      _phase = phase;
      _secondsRemaining = seconds;
    });

    if (phase == _BreathingPhase.finished) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining -= 1);
      } else {
        _nextPhase();
      }
    });
  }

  int _phaseDuration(_BreathingPhase phase) {
    switch (phase) {
      case _BreathingPhase.inhale:
        return widget.exercise.inhaleSeconds;
      case _BreathingPhase.hold:
        return widget.exercise.holdSeconds;
      case _BreathingPhase.exhale:
        return widget.exercise.exhaleSeconds;
      case _BreathingPhase.finished:
        return 0;
    }
  }

  void _nextPhase() {
    switch (_phase) {
      case _BreathingPhase.inhale:
        if (widget.exercise.holdSeconds > 0) {
          _startPhase(_BreathingPhase.hold);
        } else {
          _startPhase(_BreathingPhase.exhale);
        }
        break;
      case _BreathingPhase.hold:
        _startPhase(_BreathingPhase.exhale);
        break;
      case _BreathingPhase.exhale:
        if (_currentCycle < widget.exercise.cycles) {
          setState(() => _currentCycle += 1);
          _startPhase(_BreathingPhase.inhale);
        } else {
          _startPhase(_BreathingPhase.finished);
          _timer?.cancel();
        }
        break;
      case _BreathingPhase.finished:
        break;
    }
  }

  String get _phaseLabel {
    switch (_phase) {
      case _BreathingPhase.inhale:
        return 'Breathe in';
      case _BreathingPhase.hold:
        return 'Hold';
      case _BreathingPhase.exhale:
        return 'Breathe out';
      case _BreathingPhase.finished:
        return 'Session complete';
    }
  }

  double get _phaseProgress {
    final duration = _phaseDuration(_phase);
    if (duration == 0) return 1;
    return (_secondsRemaining.clamp(0, duration)) / duration;
  }

  Color _phaseColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (_phase) {
      case _BreathingPhase.inhale:
        return scheme.primaryContainer;
      case _BreathingPhase.hold:
        return scheme.tertiaryContainer;
      case _BreathingPhase.exhale:
        return scheme.secondaryContainer;
      case _BreathingPhase.finished:
        return scheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxSize = constraints.maxWidth * 0.6;
          final circleSize = maxSize.clamp(180.0, 320.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.exercise.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text('Cycle $_currentCycle of ${widget.exercise.cycles}'),
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  height: circleSize * _sizeMultiplier,
                  width: circleSize * _sizeMultiplier,
                  decoration: BoxDecoration(
                    color: _phaseColor(context),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _phaseLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _phase == _BreathingPhase.finished
                            ? 'Nice work. Notice if your shoulders feel softer now.'
                            : '$_secondsRemaining s',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_phase != _BreathingPhase.finished)
                  Column(
                    children: [
                      LinearProgressIndicator(value: 1 - _phaseProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Follow the prompts to complete ${widget.exercise.cycles} cycles.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                if (_phase == _BreathingPhase.finished) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Want to go again?',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _startSession,
                        child: const Text('Repeat exercise'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back to list'),
                      ),
                    ],
                  ),
                ],
                if (_phase != _BreathingPhase.finished) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.stop),
                    onPressed: () {
                      _timer?.cancel();
                      _startPhase(_BreathingPhase.finished);
                    },
                    label: const Text('End session'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  double get _sizeMultiplier {
    switch (_phase) {
      case _BreathingPhase.inhale:
        return 1.0;
      case _BreathingPhase.hold:
        return 0.9;
      case _BreathingPhase.exhale:
        return 0.8;
      case _BreathingPhase.finished:
        return 0.85;
    }
  }
}
