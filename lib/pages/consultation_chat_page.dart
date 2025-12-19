import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';

class ConsultationChatArgs {
  const ConsultationChatArgs({
    required this.session,
    required this.counterpartName,
    required this.canClose,
  });

  final ConsultationSession session;
  final String counterpartName;
  final bool canClose;
}

class ConsultationChatPage extends StatefulWidget {
  const ConsultationChatPage({super.key});

  static const String routeName = '/consultation/chat';

  @override
  State<ConsultationChatPage> createState() => _ConsultationChatPageState();
}

class _ConsultationChatPageState extends State<ConsultationChatPage> {
  final ConsultationService _service = ConsultationService.instance;
  final TextEditingController _controller = TextEditingController();
  List<ConsultationMessage> _messages = [];
  bool _loading = true;
  late ConsultationSession _session;
  late String _counterpartName;
  bool _canClose = false;
  UserRole _role = UserRole.student;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await _loadRole();
    await _loadMessages();
  }

  Future<void> _loadRole() async {
    final role = await RoleService.instance.getCachedRole();
    if (!mounted) return;
    setState(() => _role = role);
  }

  Future<void> _loadMessages() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ConsultationChatArgs) {
      _session = args.session;
      _counterpartName = args.counterpartName;
      _canClose = args.canClose;
    } else {
      return;
    }

    final messages = await _service.fetchMessages(_session.id);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final message = await _service.sendMessage(
      sessionId: _session.id,
      content: text,
    );
    if (!mounted) return;
    setState(() {
      _messages = [..._messages, message];
    });
  }

  Future<void> _endSession() async {
    final strings = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('consultation.end.title')),
        content: Text(strings.t('consultation.end.desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.t('consultation.end.confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _service.closeAndPurgeSession(_session.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! ConsultationChatArgs) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.t('consultation.title'))),
        body: Center(child: Text(strings.t('consultation.error'))),
      );
    }

    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.t('consultation.chat.with')} $_counterpartName'),
        actions: [
          if (_canClose)
            IconButton(
              tooltip: strings.t('consultation.end'),
              onPressed: _endSession,
              icon: const Icon(Icons.stop_circle_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadMessages,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isMe = (_role == UserRole.admin && message.senderRole == 'admin') ||
                            (_role == UserRole.student && message.senderRole != 'admin');

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 320),
                            decoration: BoxDecoration(
                              color: isMe ? color.primaryContainer : color.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(message.content),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: strings.t('consultation.input'),
                        border: const OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
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
}
