import 'package:flutter/material.dart';

import '../services/login_nudge_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String _tone = 'Gentle';
  double _temperature = 0.4;

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
    final sampleMessages = [
      const _ChatBubble(text: 'Hi, I am your CalmCampus buddy. How are you?', isUser: false),
      const _ChatBubble(text: 'A bit stressed about exams.', isUser: true),
      const _ChatBubble(
        text: 'Thanks for sharing. Want a short breathing exercise or a study plan reminder?',
        isUser: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Buddy'),
        actions: [
          IconButton(
            tooltip: 'Customise AI companion',
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
              'Logged in is only needed for DSA sharing or cloud sync. You can keep chatting as a guest.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sampleMessages.length,
              itemBuilder: (context, index) => sampleMessages[index],
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
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
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
    final List<String> tones = ['Gentle', 'Direct', 'Practical'];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Customise your AI companion',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the voice and creativity level you like. This stays in guest mode unless you opt in to sync.',
            textAlign: TextAlign.center,
          ),
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
                    const Text('Creativity level'),
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
            label: const Text('Save preferences (guest-friendly)'),
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
