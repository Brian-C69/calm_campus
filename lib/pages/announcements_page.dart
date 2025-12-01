import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/announcement.dart';
import '../services/announcement_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final List<Announcement> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
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
    final Announcement saved = await AnnouncementService.instance.publishAnnouncement(
      draft.announcement,
      sendNotification: draft.sendNotification,
    );

    if (!mounted) return;

    setState(() {
      _announcements.insert(0, saved);
      _isLoading = false;
    });
  }

  Future<void> _deleteAnnouncement(Announcement announcement) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this post?'),
        content: const Text('This will remove the post from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (announcement.id != null) {
      await AnnouncementService.instance.deleteAnnouncement(announcement.id!);
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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest news'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
                ? _EmptyState(onCompose: _openComposer)
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
                                  if (announcement.id != null)
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        icon: const Icon(Icons.add),
        label: const Text('New post'),
      ),
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
        Text('New wellness update', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: 'Title'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _summaryController,
          decoration: const InputDecoration(
            labelText: 'Short summary',
            helperText: 'One or two sentences students see first.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _bodyController,
          decoration: const InputDecoration(
            labelText: 'Full message',
            alignLabelWithHint: true,
            helperText: 'Keep it gentle and clear. Add helplines if relevant.',
          ),
          minLines: 6,
          maxLines: null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _authorController,
          decoration: const InputDecoration(labelText: 'From'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _categoryController,
          decoration: const InputDecoration(labelText: 'Category'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _sendNotification,
          onChanged: (value) => setState(() => _sendNotification = value),
          title: const Text('Send a notification now'),
          subtitle: const Text('Students will see this as a push alert on this device.'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _isValid ? _submit : null,
              icon: const Icon(Icons.send),
              label: const Text('Publish'),
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
  const _EmptyState({required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
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
                Text('No news yet', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Tap "New post" to share a gentle update from DSA or counselling.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: onCompose,
          icon: const Icon(Icons.add),
          label: const Text('Create first post'),
        ),
      ],
    );
  }
}
