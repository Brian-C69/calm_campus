import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../services/chat_service.dart';
import '../services/login_nudge_service.dart';

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              strings.t('chat.note'),
              style: Theme.of(context).textTheme.bodySmall,
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedActions
                        .map(
                          (action) => ActionChip(
                            label: Text(action),
                            onPressed: _isSending ? null : () => _sendMessage(action),
                          ),
                        )
                        .toList(),
                  ),
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

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
      final reply = await _chatService.sendMessage(
        message: text,
        history: _history,
        consent: const ConsentFlags(), // Wire real user consents here.
        context: const ChatContext(),
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
      if (!mounted) return;
      setState(() => _isSending = false);
      _scrollToEnd();
    }
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
