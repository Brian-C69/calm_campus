import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import 'consultation_chat_page.dart';

class ConsultationInboxPage extends StatefulWidget {
  const ConsultationInboxPage({super.key});

  @override
  State<ConsultationInboxPage> createState() => _ConsultationInboxPageState();
}

class _ConsultationInboxPageState extends State<ConsultationInboxPage> {
  final ConsultationService _service = ConsultationService.instance;
  List<ConsultationSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await _service.fetchSessionsForCurrentUser();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _openSession(ConsultationSession session) async {
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      ConsultationChatPage.routeName,
      arguments: ConsultationChatArgs(
        session: session,
        counterpartName: AppLocalizations.of(context).t('consultation.student'),
        canClose: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('consultation.inbox.title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.support_agent),
                      title: Text(strings.t('consultation.session')),
                      subtitle: Text(
                        strings.t('consultation.session.status').replaceFirst('{status}', session.status),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openSession(session),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
