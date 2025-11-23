import 'package:flutter/material.dart';

class RelaxPage extends StatelessWidget {
  const RelaxPage({super.key});

  @override
  Widget build(BuildContext context) {
    final relaxItems = [
      _RelaxItem('Focus waves', 'Soft beats to help you study'),
      _RelaxItem('Gentle sleep', 'Wind down with calm tones'),
      _RelaxItem('Breathe with me', '3-minute grounding meditation'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Relax & Meditations')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: relaxItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = relaxItems[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.spa_outlined),
              title: Text(item.title),
              subtitle: Text(item.description),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {},
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RelaxItem {
  const _RelaxItem(this.title, this.description);

  final String title;
  final String description;
}
