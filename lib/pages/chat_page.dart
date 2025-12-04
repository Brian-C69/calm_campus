import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/class_entry.dart';
import '../models/period_cycle.dart';
import '../models/support_contact.dart';
import '../services/chat_service.dart';
import '../services/db_service.dart';
import '../services/login_nudge_service.dart';
import '../services/user_profile_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _tone = 'Gentle';
  double _temperature = 0.4;
  static const String _storageKey = 'chat_history';
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _history = [];
  final List<_ChatTurn> _turns = [];
  bool _isSending = false;
  List<String> _suggestedActions = [];
  bool _showSuggestions = true;
  bool _shareAllData = false;
  bool _loadingContext = false;
  ConsentFlags _consent = const ConsentFlags();
  ChatContext _context = const ChatContext();
  bool _showGuestNote = true;
  String? _error;

  Future<void> _openCustomization() async {
    final LoginNudgeAction action = await LoginNudgeService.instance.maybePrompt(
      context,
      LoginNudgeTrigger.aiCustomization,
    );

    if (!mounted) return;
    if (action == LoginNudgeAction.loginSelected) {
      await Navigator.pushNamed(context, '/auth');
      if (!mounted) return;
    }

    // Allow customization even as guest.
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _CustomizationSheet(
        tone: _tone,
        temperature: _temperature,
        onToneChanged: (value) => setState(() => _tone = value),
        onTemperatureChanged: (value) => setState(() => _temperature = value),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadChatPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('chat.title')),
        actions: [
          IconButton(
            tooltip: strings.t('chat.customize'),
            onPressed: _openCustomization,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showGuestNote)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      strings.t('chat.note'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.t('chat.note.dismiss'),
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      setState(() => _showGuestNote = false);
                      await UserProfileService.instance.setChatNoteSeen();
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              controller: _scrollController,
              itemCount: _turns.length,
              itemBuilder: (context, index) => _ChatBubble(
                text: _turns[index].content,
                isUser: _turns[index].isUser,
              ),
            ),
          ),
          if (_suggestedActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.t('chat.suggested'),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _showSuggestions = !_showSuggestions),
                        child: Text(_showSuggestions ? strings.t('chat.suggested.hide') : strings.t('chat.suggested.show')),
                      ),
                    ],
                  ),
                  if (_showSuggestions) ...[
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _suggestedActions
                            .map(
                              (action) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(action),
                                  onPressed: _isSending ? null : () => _handleAction(action, strings),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: strings.t('chat.hint'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: strings.t('chat.send'),
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved == null) return;
    try {
      final List<dynamic> parsed = jsonDecode(saved) as List<dynamic>;
      final loadedMessages = parsed
          .map((e) => ChatMessage(role: e['role']?.toString() ?? 'assistant', content: e['content']?.toString() ?? ''))
          .toList();
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(loadedMessages);
        _turns
          ..clear()
          ..addAll(loadedMessages.map((m) => _ChatTurn(content: m.content, isUser: m.role == 'user')));
      });
      _scrollToEnd();
    } catch (_) {
      // Ignore corrupt history and continue.
    }
  }

  Future<void> _loadChatPrefs() async {
    final shareAll = await UserProfileService.instance.getChatShareAll();
    final noteSeen = await UserProfileService.instance.isChatNoteSeen();
    if (!mounted) return;
    setState(() {
      _shareAllData = shareAll;
      _showGuestNote = !noteSeen;
      _loadingContext = shareAll;
    });
    if (_shareAllData) {
      await _buildContextAndConsent(AppLocalizations.of(context));
      if (mounted) {
        setState(() => _loadingContext = false);
      }
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_history.map((m) => m.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _sendMessage([String? quickAction]) async {
    final strings = AppLocalizations.of(context);
    final text = (quickAction ?? _controller.text).trim();
    if (text.isEmpty || _isSending) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _turns.add(_ChatTurn(content: text, isUser: true));
      _history.add(ChatMessage(role: 'user', content: text));
      _isSending = true;
      _error = null;
      _controller.clear();
    });
    await _saveHistory();
    _scrollToEnd();

    try {
      if (_shareAllData && !_loadingContext && _consent.isEmpty && _turns.length == 1) {
        await _buildContextAndConsent(strings);
      }

      final reply = await _chatService.sendMessage(
        message: text,
        history: _history,
        consent: _consent,
        context: _context,
        timeout: const Duration(seconds: 25),
      );
      if (!mounted) return;
      final assistantMessage = _combineAssistantMessage(reply);
      setState(() {
        _turns.add(_ChatTurn(content: assistantMessage, isUser: false));
        _history.add(ChatMessage(role: 'assistant', content: assistantMessage));
        _suggestedActions = reply.suggestedActions;
      });
      await _saveHistory();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _turns.add(_ChatTurn(content: strings.t('chat.unavailable'), isUser: false));
      });
      await _saveHistory();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToEnd();
      }
    }
  }

  Future<void> _handleAction(String action, AppLocalizations strings) async {
    final lower = action.toLowerCase();
    if (lower.contains('challenge')) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/challenges');
      return;
    }
    await _sendMessage(action);
  }

  String _combineAssistantMessage(ChatReply reply) {
    if (reply.followUpQuestion.isEmpty) return reply.messageForUser;
    return '${reply.messageForUser}\n\n${reply.followUpQuestion}';
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _buildContextAndConsent(AppLocalizations strings) async {
    try {
      final profile = await _buildProfile();
      final mood = await _buildMoodSummary();
      final timetable = await _buildTimetableSummary();
      final tasks = await _buildTasksSummary();
      final sleep = await _buildSleepSummary();
      final period = await _buildPeriodSummary();
      final movement = await _buildMovementSummary();
      final contacts = await _buildContactsSummary();

      setState(() {
        _consent = const ConsentFlags(
          profile: true,
          mood: true,
          timetable: true,
          tasks: true,
          sleep: true,
          period: true,
          movement: true,
          contacts: true,
        );
        _context = ChatContext(
          profile: profile,
          mood: mood,
          timetable: timetable,
          tasks: tasks,
          sleep: sleep,
          period: period,
          movement: movement,
          contacts: contacts,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = strings.t('chat.unavailable');
        _shareAllData = false;
        _consent = const ConsentFlags();
        _context = const ChatContext();
      });
    }
  }

  Future<Map<String, dynamic>?> _buildProfile() async {
    final nickname = await UserProfileService.instance.getNickname();
    final course = await UserProfileService.instance.getCourse();
    final year = await UserProfileService.instance.getYearOfStudy();
    if ((nickname ?? '').isEmpty && (course ?? '').isEmpty && year == null) return null;
    return {
      if (nickname != null && nickname.isNotEmpty) 'nickname': nickname,
      if (course != null && course.isNotEmpty) 'course': course,
      if (year != null) 'year': year.toString(),
    };
  }

  Future<Map<String, dynamic>?> _buildMoodSummary() async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 7));
    final entries = await DbService.instance.getMoodEntries(from: from, to: now);
    if (entries.isEmpty) return null;
    final Map<String, int> counts = {};
    final List<String> notes = [];
    for (final entry in entries) {
      counts.update(entry.overallMood.name, (v) => v + 1, ifAbsent: () => 1);
      final note = entry.note ?? '';
      if (note.isNotEmpty) notes.add(note);
    }
    final topMoods = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final summary = 'Last 7 days: ${entries.length} entries; top moods: ${topMoods.map((e) => '${e.key} (${e.value})').take(3).join(', ')}';
    return {
      'summary': summary,
      if (notes.isNotEmpty) 'recentNotes': notes.take(3).toList(),
    };
  }

  Future<Map<String, dynamic>?> _buildTimetableSummary() async {
    final now = DateTime.now();
    final today = await DbService.instance.getClassesForDay(now.weekday);
    final all = await DbService.instance.getAllClasses();
    ClassEntry? nextClass;
    DateTime? nextTime;
    for (final c in all) {
      final dt = _nextOccurrenceForClass(c, now);
      if (dt == null) continue;
      if (nextTime == null || dt.isBefore(nextTime)) {
        nextTime = dt;
        nextClass = c;
      }
    }
    final Map<String, dynamic> payload = {};
    if (today.isNotEmpty) payload['today'] = today.map((c) => _formatClass(c)).toList();
    if (nextClass != null) payload['next'] = [_formatClass(nextClass)];
    return payload.isEmpty ? null : payload;
  }

  Map<String, dynamic> _formatClass(ClassEntry c) {
    return {
      'title': c.subject,
      'time': c.startTime,
      'startTime': c.startTime,
      'endTime': c.endTime,
      'location': c.location,
      'lecturer': c.lecturer,
      'classType': c.classType,
      'dayOfWeek': c.dayOfWeek,
    };
  }

  DateTime? _nextOccurrenceForClass(ClassEntry c, DateTime now) {
    final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(c.startTime);
    if (timeMatch == null) return null;
    final hour = int.tryParse(timeMatch.group(1)!);
    final minute = int.tryParse(timeMatch.group(2)!);
    if (hour == null || minute == null) return null;
    final target = DateTime(now.year, now.month, now.day, hour, minute);
    final desiredDow =
        (c.dayOfWeek < DateTime.monday || c.dayOfWeek > DateTime.sunday) ? target.weekday : c.dayOfWeek;
    final currentDow = target.weekday;
    int delta = desiredDow - currentDow;
    if (delta < 0 || (delta == 0 && target.isBefore(now))) {
      delta += 7;
    }
    return target.add(Duration(days: delta));
  }

  Future<Map<String, dynamic>?> _buildTasksSummary() async {
    final tasks = await DbService.instance.getPendingTasks();
    if (tasks.isEmpty) return null;
    final pending = tasks.take(5).map((t) {
      final dueLabel = _dueLabel(t.dueDate);
      return {
        'title': t.title,
        'due': dueLabel,
        'priority': t.priority.name,
      };
    }).toList();
    return {'pending': pending};
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    if (diff < 0) return 'overdue ${diff.abs()}d';
    return 'in ${diff}d';
  }

  Future<Map<String, dynamic>?> _buildSleepSummary() async {
    final entries = await DbService.instance.getSleepEntries(limit: 5);
    if (entries.isEmpty) return null;
    final avg = entries.map((e) => e.durationHours).reduce((a, b) => a + b) / entries.length;
    final last = entries.first;
    return {
      'recentAverage': '${avg.toStringAsFixed(1)}h',
      'lastNight': '${last.durationHours.toStringAsFixed(1)}h (restfulness ${last.restfulness}/5)',
    };
  }

  Future<Map<String, dynamic>?> _buildPeriodSummary() async {
    final cycles = await DbService.instance.getRecentCycles(limit: 3);
    if (cycles.isEmpty) return null;
    final lengths = cycles.where((c) => c.calculatedCycleLength != null).map((c) => c.calculatedCycleLength!).toList();
    final avgLen = lengths.isNotEmpty ? (lengths.reduce((a, b) => a + b) / lengths.length).round() : null;
    final last = cycles.first;
    final predicted = _predictNextPeriodStartFromCycles(cycles);
    final DateTimeRange? window = predicted == null ? null : _estimateOvulationWindowFromPrediction(predicted);
    return {
      if (avgLen != null) 'summary': 'Avg cycle ~${avgLen}d',
      'nextPeriodHint': 'Last period ended ${_formatShortDate(last.cycleEndDate.toLocal())}',
      if (predicted != null) 'predictedNext': _formatShortDate(predicted),
      if (window != null) 'ovulationWindow': '${_formatShortDate(window.start)} to ${_formatShortDate(window.end)}',
    };
  }

  Future<Map<String, dynamic>?> _buildMovementSummary() async {
    final from = DateTime.now().subtract(const Duration(days: 7));
    final moves = await DbService.instance.getMovementEntries(from: from, to: DateTime.now());
    if (moves.isEmpty) return null;
    final days = moves.map((m) => DateTime(m.date.year, m.date.month, m.date.day)).toSet().length;
    final avgMins = moves.map((m) => m.minutes).reduce((a, b) => a + b) / moves.length;
    return {
      'recentSummary': 'Active on $days day(s) last 7d, ~${avgMins.toStringAsFixed(0)} mins avg',
      'energyNotes': 'Common types: ${moves.map((m) => m.type.name).toSet().take(3).join(', ')}',
    };
  }

  Future<Map<String, dynamic>?> _buildContactsSummary() async {
    final contacts = await DbService.instance.getTopPriorityContacts(3);
    if (contacts.isEmpty) return null;
    return {
      'top': contacts.map((c) => _formatContact(c)).toList(),
    };
  }

  Map<String, dynamic> _formatContact(SupportContact c) {
    return {
      'name': c.name,
      'relationship': c.relationship,
      'contactType': c.contactType.name,
    };
  }

  String _formatShortDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime? _predictNextPeriodStartFromCycles(List<PeriodCycle> cycles) {
    if (cycles.length < 2) return null;
    final List<PeriodCycle> sorted = List.of(cycles)..sort((a, b) => b.cycleStartDate.compareTo(a.cycleStartDate));
    final List<int> cycleLengths = [];
    for (int i = 0; i < sorted.length - 1; i++) {
      final DateTime currentStart = sorted[i].cycleStartDate;
      final DateTime previousStart = sorted[i + 1].cycleStartDate;
      final int diff = currentStart.difference(DateTime(previousStart.year, previousStart.month, previousStart.day)).inDays;
      cycleLengths.add(diff);
    }
    if (cycleLengths.isEmpty) return null;
    final double average = cycleLengths.reduce((a, b) => a + b) / cycleLengths.length;
    return sorted.first.cycleStartDate.add(Duration(days: average.round()));
  }

  DateTimeRange? _estimateOvulationWindowFromPrediction(DateTime predictedNextStart) {
    final DateTime windowStart = predictedNextStart.subtract(const Duration(days: 16));
    final DateTime windowEnd = predictedNextStart.subtract(const Duration(days: 12));
    return DateTimeRange(start: windowStart, end: windowEnd);
  }
}
class _CustomizationSheet extends StatelessWidget {
  const _CustomizationSheet({
    required this.tone,
    required this.temperature,
    required this.onToneChanged,
    required this.onTemperatureChanged,
  });

  final String tone;
  final double temperature;
  final ValueChanged<String> onToneChanged;
  final ValueChanged<double> onTemperatureChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final List<String> tones = [
      strings.t('chat.tone.gentle'),
      strings.t('chat.tone.direct'),
      strings.t('chat.tone.practical'),
    ];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            strings.t('chat.customize.title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(strings.t('chat.customize.desc'), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: tones
                .map(
                  (value) => ChoiceChip(
                    label: Text(value),
                    selected: tone == value,
                    onSelected: (_) => onToneChanged(value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.t('chat.customize.creativity')),
                    Slider(
                      min: 0.1,
                      max: 1,
                      divisions: 9,
                      value: temperature,
                      label: temperature.toStringAsFixed(1),
                      onChanged: onTemperatureChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.check),
            label: Text(strings.t('chat.customize.save')),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final background = isUser
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text),
        ),
      ],
    );
  }
}

class _ChatTurn {
  const _ChatTurn({required this.content, required this.isUser});

  final String content;
  final bool isUser;
}
