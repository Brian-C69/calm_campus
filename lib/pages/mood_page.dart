import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';
import '../services/user_profile_service.dart';

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
  String _userName = 'Friend';
  bool _isSaving = false;
  bool _hasPromptedForLogin = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final bool isLoggedIn = await UserProfileService.instance.isLoggedIn();
    final String? storedName =
        isLoggedIn ? await UserProfileService.instance.getNickname() : null;
    if (!mounted) return;
    setState(() {
      final bool hasName = storedName?.trim().isNotEmpty ?? false;
      _userName = (isLoggedIn && hasName) ? storedName!.trim() : 'Friend';
    });
  }

  String get _timeGreeting {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Night';
  }

  Future<void> _saveMood() async {
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
    _showMessage('Thanks, $_userName! Your check-in is saved.');
  }

  Future<void> _handleLoginNudge() async {
    if (!mounted || _hasPromptedForLogin) return;

    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.moodHistorySave,
    );

    if (!mounted) return;
    setState(() {
      _hasPromptedForLogin = true;
    });

    if (action == LoginNudgeAction.loginSelected) {
      await Navigator.pushNamed(context, '/auth');
      if (!mounted) return;
    }
  }

  String _buildNoteWithName() {
    final String name = _userName.trim();
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
      appBar: AppBar(
        title: const Text('Mood Check-in'),
        actions: [
          IconButton(
            tooltip: 'View mood history',
            onPressed: () => Navigator.pushNamed(context, '/history'),
            icon: const Icon(Icons.timeline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_timeGreeting, $_userName!',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'We\'ll personalise this check-in using your saved name.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'How are you feeling today?',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the option that matches your mood.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _moodOptions
                            .map(
                              (option) => ChoiceChip(
                                label: Text('${option.emoji} ${option.label}'),
                                selected: _selectedMood == option.level,
                                onSelected: (_) async {
                                  await _handleLoginNudge();
                                  if (!mounted) return;
                                  setState(() {
                                    _selectedMood = option.level;
                                  });
                                },
                              ),
                            )
                            .toList(),
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
