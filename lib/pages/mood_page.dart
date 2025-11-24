import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';

class MoodOption {
  const MoodOption({
    required this.label,
    required this.emoji,
    required this.level,
  });

  final String label;
  final String emoji;
  final MoodLevel level;
}

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});

  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final List<MoodOption> _moodOptions = const [
    MoodOption(label: 'Happy', emoji: '😊', level: MoodLevel.happy),
    MoodOption(label: 'Excited', emoji: '🤩', level: MoodLevel.excited),
    MoodOption(label: 'Grateful', emoji: '🙏', level: MoodLevel.grateful),
    MoodOption(label: 'Relaxed', emoji: '😌', level: MoodLevel.relaxed),
    MoodOption(label: 'Content', emoji: '🙂', level: MoodLevel.content),
    MoodOption(label: 'Tired', emoji: '🥱', level: MoodLevel.tired),
    MoodOption(label: 'Unsure', emoji: '🤔', level: MoodLevel.unsure),
    MoodOption(label: 'Bored', emoji: '😐', level: MoodLevel.bored),
    MoodOption(label: 'Anxious', emoji: '😟', level: MoodLevel.anxious),
    MoodOption(label: 'Angry', emoji: '😠', level: MoodLevel.angry),
    MoodOption(label: 'Stressed', emoji: '😣', level: MoodLevel.stressed),
    MoodOption(label: 'Sad', emoji: '😔', level: MoodLevel.sad),
  ];

  MoodLevel? _selectedMood;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _timeGreeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Night';
  }

  bool get _hasName => _nameController.text.trim().isNotEmpty;

  Future<void> _saveMood() async {
    if (!_hasName) {
      _showMessage('Please share your name first.');
      return;
    }
    if (_selectedMood == null) {
      _showMessage('Please choose how you feel today.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final MoodEntry entry = MoodEntry(
      dateTime: DateTime.now(),
      overallMood: _selectedMood!,
      mainThemeTag: MoodThemeTag.other,
      note: _buildNoteWithName(),
    );

    await DbService.instance.insertMoodEntry(entry);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _selectedMood = null;
    });
    _noteController.clear();
    _showMessage('Thanks, ${_nameController.text.trim()}! Your check-in is saved.');

    await _handleLoginNudge();
  }

  Future<void> _handleLoginNudge() async {
    if (!mounted) return;

    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.moodHistorySave,
    );

    if (!mounted) return;
    if (action == LoginNudgeAction.loginSelected) {
      _showMessage('Login is only required for sharing or cloud sync. You can stay as a guest for now.');
    }
  }

  String _buildNoteWithName() {
    final String name = _nameController.text.trim();
    final String note = _noteController.text.trim();
    if (note.isEmpty) return 'Check-in by $name';
    return '$note — $name';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Check-in')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeGreeting!',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s start with your name before we check in on your mood.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'What should we call you?',
                  hintText: 'Enter your name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Text(
                'How are you feeling today?',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _hasName
                    ? 'Tap the option that matches your mood.'
                    : 'Share your name above to unlock today\'s moods.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IgnorePointer(
                        ignoring: !_hasName,
                        child: Opacity(
                          opacity: _hasName ? 1 : 0.5,
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _moodOptions
                                .map(
                                  (option) => ChoiceChip(
                                    label: Text('${option.emoji} ${option.label}'),
                                    selected: _selectedMood == option.level,
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedMood = option.level;
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Want to add a note?',
                          hintText: 'Any thoughts you want to remember today',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMood,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Saving...' : 'Save check-in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
