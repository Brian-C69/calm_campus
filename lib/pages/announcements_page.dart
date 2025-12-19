import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';
import '../l10n/app_localizations.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';
import '../services/user_profile_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final List<Announcement> _announcements = [];
  bool _isLoading = true;
  bool _canManage = false;
  bool _canHide = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadAnnouncements();
  }

  Future<void> _loadRole() async {
    final bool isLoggedIn = await UserProfileService.instance.isLoggedIn();
    final UserRole role = isLoggedIn ? await RoleService.instance.getCachedRole() : UserRole.student;
    if (!mounted) return;
    setState(() {
      _canManage = role == UserRole.admin;
      _canHide = isLoggedIn && role != UserRole.admin;
    });
  }

  Future<void> _loadAnnouncements() async {
    final List<Announcement> items = await AnnouncementService.instance.loadAnnouncements();
    if (!mounted) return;

    setState(() {
      _announcements
        ..clear()
        ..addAll(items);
      _isLoading = false;
    });
  }

  Future<void> _openComposer() async {
    if (!_canManage) return;
    final strings = AppLocalizations.of(context);
    final _AnnouncementDraft? draft = await showModalBottomSheet<_AnnouncementDraft>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final double insets = MediaQuery.of(context).viewInsets.bottom;
        final double safeBottom = MediaQuery.of(context).padding.bottom;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: insets + safeBottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _AnnouncementComposer(
                onSubmit: (draft) => Navigator.of(context).pop(draft),
              ),
            ),
          ),
        );
      },
    );

    if (draft == null) return;

    setState(() => _isLoading = true);
    Announcement saved;
    try {
      saved = await AnnouncementService.instance.publishAnnouncement(
        draft.announcement,
        sendNotification: draft.sendNotification,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.t('announcements.error')}\n$e',
          ),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;

    setState(() {
      _announcements.insert(0, saved);
      _isLoading = false;
    });
  }

  Future<void> _hideAnnouncement(Announcement announcement) async {
    final strings = AppLocalizations.of(context);
    if (announcement.id != null) {
      await AnnouncementService.instance.hideAnnouncement(announcement.id!);
    }
    if (!mounted) return;
    setState(() {
      _announcements.removeWhere((a) => a.id == announcement.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.t('announcements.hidden'))),
    );
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    if (!_canManage) return;
    final strings = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('announcements.delete.title')),
        content: Text(strings.t('announcements.delete.desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.t('common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.t('announcements.remove')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (announcement.id != null) {
      try {
        await AnnouncementService.instance.deleteAnnouncement(announcement.id!);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${strings.t('announcements.error')}\n$e')),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _announcements.removeWhere((a) => a.id == announcement.id);
    });
  }

  void _openDetails(Announcement announcement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final double safeBottom = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: safeBottom + 12,
              left: 16,
              right: 16,
              top: 12,
            ),
            child: _AnnouncementDetailSheet(announcement: announcement),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('announcements.title')),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
                ? _EmptyState(onCompose: _canManage ? _openComposer : null, canManage: _canManage)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final Announcement announcement = _announcements[index];
                      return Card(
                        color: colorScheme.surfaceContainerHigh,
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((announcement.category ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    announcement.category!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: colorScheme.primary),
                                  ),
                                ),
                              Text(
                                announcement.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                announcement.summary,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  _MetaChip(
                                    icon: Icons.person_outline,
                                    label: announcement.author,
                                  ),
                                  _MetaChip(
                                    icon: Icons.schedule,
                                    label: DateFormat('MMM d, h:mm a')
                                        .format(announcement.publishedAt),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openDetails(announcement),
                                    icon: const Icon(Icons.article_outlined),
                                    label: const Text('Read'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_canHide && announcement.id != null)
                                    TextButton.icon(
                                      onPressed: () => _hideAnnouncement(announcement),
                                      icon: const Icon(Icons.hide_source_outlined),
                                      label: Text(strings.t('announcements.hide')),
                                    ),
                                  const SizedBox(width: 8),
                                  if (announcement.id != null && _canManage)
                                    TextButton.icon(
                                      onPressed: () => _deleteAnnouncement(announcement),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Remove'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: _openComposer,
              icon: const Icon(Icons.add),
              label: Text(strings.t('announcements.newPost')),
            )
          : null,
    );
  }
}

class _AnnouncementDraft {
  const _AnnouncementDraft({
    required this.announcement,
    required this.sendNotification,
  });

  final Announcement announcement;
  final bool sendNotification;
}

class _AnnouncementComposer extends StatefulWidget {
  const _AnnouncementComposer({required this.onSubmit});

  final ValueChanged<_AnnouncementDraft> onSubmit;

  @override
  State<_AnnouncementComposer> createState() => _AnnouncementComposerState();
}

class _AnnouncementComposerState extends State<_AnnouncementComposer> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _authorController =
      TextEditingController(text: 'DSA Wellness Desk');
  final TextEditingController _categoryController =
      TextEditingController(text: 'Wellbeing update');

  bool _sendNotification = true;

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _bodyController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).t('announcements.compose.title'),
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).t('announcements.compose.titleLabel')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _summaryController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('announcements.compose.summaryLabel'),
            helperText: AppLocalizations.of(context).t('announcements.compose.summary.helper'),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bodyController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).t('announcements.compose.bodyLabel'),
            alignLabelWithHint: true,
            helperText: AppLocalizations.of(context).t('announcements.compose.body.helper'),
          ),
          minLines: 6,
          maxLines: null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _authorController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).t('announcements.compose.from')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _categoryController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context).t('announcements.compose.category')),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _sendNotification,
          onChanged: (value) => setState(() => _sendNotification = value),
          title: Text(AppLocalizations.of(context).t('announcements.compose.notify')),
          subtitle: Text(AppLocalizations.of(context).t('announcements.compose.notify.desc')),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).t('common.cancel')),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _isValid ? _submit : null,
              icon: const Icon(Icons.send),
              label: Text(AppLocalizations.of(context).t('announcements.compose.publish')),
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final Announcement announcement = Announcement(
      title: _titleController.text.trim(),
      summary: _summaryText,
      body: _bodyController.text.trim(),
      author: _authorController.text.trim().isEmpty ? 'DSA Wellness Desk' : _authorController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
    );

    widget.onSubmit(
      _AnnouncementDraft(
        announcement: announcement,
        sendNotification: _sendNotification,
      ),
    );
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty && _bodyController.text.trim().length > 20;

  String get _summaryText {
    final String summary = _summaryController.text.trim();
    if (summary.isNotEmpty) return summary;
    final String body = _bodyController.text.trim();
    if (body.length <= 120) return body;
    return '${body.substring(0, 120)}...';
  }
}

class _AnnouncementDetailSheet extends StatelessWidget {
  const _AnnouncementDetailSheet({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<String> paragraphs =
        announcement.body.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((announcement.category ?? '').isNotEmpty)
                      Text(
                        announcement.category!,
                        style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
                      ),
                    const SizedBox(height: 4),
                    Text(announcement.title, style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                          icon: Icons.person_outline,
                          label: announcement.author,
                        ),
                        _MetaChip(
                          icon: Icons.schedule,
                          label: DateFormat('MMM d, h:mm a').format(announcement.publishedAt),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...paragraphs.map(
            (paragraph) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                paragraph,
                style: textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onCompose, this.canManage = false});

  final VoidCallback? onCompose;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.t('announcements.empty.title'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(strings.t('announcements.empty.desc')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (canManage && onCompose != null)
          ElevatedButton.icon(
            onPressed: onCompose,
            icon: const Icon(Icons.add),
            label: Text(strings.t('announcements.createFirst')),
          ),
      ],
    );
  }
}
