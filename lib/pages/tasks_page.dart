import 'package:flutter/material.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = [
      _TaskCardData('Read chapter 5', 'Psychology', 'Due tomorrow'),
      _TaskCardData('Revise lecture notes', 'Algorithms', 'Due Friday'),
      _TaskCardData('Submit design sketch', 'Design Lab', 'Due next week'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = tasks[index];
          return Card(
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(item.title),
              subtitle: Text('${item.subject}\n${item.meta}'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add_task),
        label: const Text('New task'),
      ),
    );
  }
}

class _TaskCardData {
  const _TaskCardData(this.title, this.subject, this.meta);

  final String title;
  final String subject;
  final String meta;
}
