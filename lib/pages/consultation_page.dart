import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';
import '../services/user_profile_service.dart';
import 'consultation_chat_page.dart';

class ConsultationPage extends StatefulWidget {
  const ConsultationPage({super.key});

  @override
  State<ConsultationPage> createState() => _ConsultationPageState();
}

class _ConsultationPageState extends State<ConsultationPage> {
  final ConsultationService _service = ConsultationService.instance;
  List<Consultant> _consultants = [];
  List<ConsultationSession> _sessions = [];
  bool _isLoading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loggedIn = await UserProfileService.instance.isLoggedIn();
    final consultants = await _service.fetchConsultants();
    final sessions = loggedIn ? await _service.fetchSessionsForCurrentUser() : <ConsultationSession>[];

    if (!mounted) return;
    setState(() {
      _loggedIn = loggedIn;
      _consultants = consultants;
      _sessions = sessions;
      _isLoading = false;
    });
  }

  Future<void> _startSession(Consultant consultant) async {
    if (!_loggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).t('consultation.login'))),
      );
      return;
    }

    try {
      final session = await _service.startSession(consultant.id);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        ConsultationChatPage.routeName,
        arguments: ConsultationChatArgs(
          session: session,
          counterpartName: consultant.displayName,
          canClose: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).t('consultation.error')}\n$e')),
      );
    }
  }

  Future<void> _openSession(ConsultationSession session) async {
    final consultant = _consultants.firstWhere(
      (c) => c.id == session.consultantId,
      orElse: () => Consultant(
        id: session.consultantId,
        displayName: AppLocalizations.of(context).t('consultation.consultant'),
      ),
    );
    if (!mounted) return;
    Navigator.pushNamed(
      context,
      ConsultationChatPage.routeName,
      arguments: ConsultationChatArgs(
        session: session,
        counterpartName: consultant.displayName,
        canClose: true,
      ),
    );
  }

  Widget _buildAvatar(String? url, {bool isOnline = false}) {
    return Stack(
      children: [
        CircleAvatar(
          backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
          child: (url == null || url.isEmpty) ? const Icon(Icons.person) : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('consultation.title')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    color: color.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.t('consultation.hero.title'),
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(strings.t('consultation.hero.copy')),
                          if (!_loggedIn) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => Navigator.pushNamed(context, '/auth'),
                              icon: const Icon(Icons.login),
                              label: Text(strings.t('consultation.login')),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_sessions.isNotEmpty) ...[
                    Text(strings.t('consultation.active'), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._sessions.map(
                      (session) => Card(
                        child: ListTile(
                          leading: _buildAvatar(
                            _consultants
                                .firstWhere(
                                  (c) => c.id == session.consultantId,
                                  orElse: () => Consultant(
                                    id: session.consultantId,
                                    displayName: strings.t('consultation.consultant'),
                                  ),
                                )
                                .avatarUrl,
                          ),
                          title: Text(strings.t('consultation.session')),
                          subtitle: Text(
                            strings.t('consultation.session.status').replaceFirst('{status}', session.status),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openSession(session),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(strings.t('consultation.consultants'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_consultants.isEmpty)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.hourglass_empty),
                        title: Text(strings.t('consultation.none')),
                        subtitle: Text(strings.t('consultation.none.desc')),
                      ),
                    ),
                  ..._consultants.map(
                    (consultant) => Card(
                      elevation: 0,
                      child: ListTile(
                        leading: _buildAvatar(consultant.avatarUrl, isOnline: consultant.isOnline),
                        title: Text(consultant.displayName),
                        subtitle: Text(
                          consultant.tags.isNotEmpty
                              ? consultant.tags.join(' • ')
                              : strings.t('consultation.consultant.desc'),
                        ),
                        trailing: FilledButton(
                          onPressed: consultant.isOnline ? () => _startSession(consultant) : null,
                          child: Text(strings.t('consultation.start')),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
