import 'package:flutter/material.dart';

import '../models/mood_entry.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';
import '../services/user_profile_service.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations.dart';

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

  String _timeGreeting(AppLocalizations strings) {
    final int hour = DateTime.now().hour;
    if (hour < 12) return strings.t('mood.greeting.morning');
    if (hour < 18) return strings.t('mood.greeting.afternoon');
    return strings.t('mood.greeting.night');
  }

  List<MoodOption> _moodOptions(AppLocalizations strings) {
    return [
      MoodOption(label: strings.t('mood.option.happy'), emoji: '😊', level: MoodLevel.happy),
      MoodOption(label: strings.t('mood.option.excited'), emoji: '🤩', level: MoodLevel.excited),
      MoodOption(label: strings.t('mood.option.grateful'), emoji: '🙏', level: MoodLevel.grateful),
      MoodOption(label: strings.t('mood.option.relaxed'), emoji: '😌', level: MoodLevel.relaxed),
      MoodOption(label: strings.t('mood.option.content'), emoji: '🙂', level: MoodLevel.content),
      MoodOption(label: strings.t('mood.option.tired'), emoji: '🥱', level: MoodLevel.tired),
      MoodOption(label: strings.t('mood.option.unsure'), emoji: '🤔', level: MoodLevel.unsure),
      MoodOption(label: strings.t('mood.option.bored'), emoji: '😐', level: MoodLevel.bored),
      MoodOption(label: strings.t('mood.option.anxious'), emoji: '😟', level: MoodLevel.anxious),
      MoodOption(label: strings.t('mood.option.angry'), emoji: '😠', level: MoodLevel.angry),
      MoodOption(label: strings.t('mood.option.stressed'), emoji: '😣', level: MoodLevel.stressed),
      MoodOption(label: strings.t('mood.option.sad'), emoji: '😔', level: MoodLevel.sad),
    ];
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) {
      _showMessage(AppLocalizations.of(context).t('mood.error.select'));
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
    _showMessage(
      AppLocalizations.of(context).t('mood.saved').replaceFirst('{name}', _userName),
    );
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
    final strings = AppLocalizations.of(context);
    if (note.isEmpty) {
      return strings.t('mood.note.default').replaceFirst('{name}', name);
    }
    return '$note — $name';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final moodOptions = _moodOptions(strings);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('mood.title')),
        actions: [
          IconButton(
            tooltip: strings.t('mood.history'),
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
                '${_timeGreeting(strings)}, $_userName!',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                strings.t('mood.subtitle'),
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                strings.t('mood.prompt'),
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                strings.t('mood.instruction'),
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
                        children: moodOptions
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
                        decoration: InputDecoration(
                          labelText: strings.t('mood.note.label'),
                          hintText: strings.t('mood.note.hint'),
                          border: const OutlineInputBorder(),
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
                  label: Text(_isSaving ? strings.t('mood.saving') : strings.t('mood.save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
