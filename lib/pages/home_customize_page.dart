import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/home_layout_service.dart';

class HomeCustomizePage extends StatefulWidget {
  const HomeCustomizePage({super.key});

  @override
  State<HomeCustomizePage> createState() => _HomeCustomizePageState();
}

class _HomeCustomizePageState extends State<HomeCustomizePage> {
  late List<HomeTileConfig> _visible;
  late List<HomeTileConfig> _hidden;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final defaults = HomeLayoutService.instance.defaults;
    final layout = await HomeLayoutService.instance.loadLayout();
    final map = {for (var d in defaults) d.id: d};
    final visible = layout.order.where((id) => !layout.hidden.contains(id)).map((id) => map[id]).whereType<HomeTileConfig>().toList();
    final hidden = defaults.where((d) => layout.hidden.contains(d.id)).toList();
    setState(() {
      _visible = visible;
      _hidden = hidden;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final order = [..._visible.map((e) => e.id), ..._hidden.map((e) => e.id)];
    final hiddenIds = _hidden.map((e) => e.id).toSet();
    await HomeLayoutService.instance.saveLayout(HomeLayoutState(order: order, hidden: hiddenIds));
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _toggleVisibility(HomeTileConfig tile) {
    setState(() {
      if (_hidden.contains(tile)) {
        _hidden.remove(tile);
        _visible.add(tile);
      } else {
        _visible.remove(tile);
        _hidden.add(tile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.t('home.customize'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('home.customize')),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: strings.t('common.save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('home.customize.visible'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _visible.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _visible.removeAt(oldIndex);
                    _visible.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final tile = _visible[index];
                  return ListTile(
                    key: ValueKey(tile.id),
                    leading: Icon(tile.icon),
                    title: Text(strings.t(tile.labelKey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility_off),
                      tooltip: strings.t('home.customize.hide'),
                      onPressed: () => _toggleVisibility(tile),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(strings.t('home.customize.hidden'), style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hidden
                  .map(
                    (tile) => FilterChip(
                      label: Text(strings.t(tile.labelKey)),
                      selected: false,
                      onSelected: (_) => _toggleVisibility(tile),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Text(strings.t('home.customize.helper'), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
