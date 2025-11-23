import 'package:flutter/material.dart';

class HelpNowPage extends StatelessWidget {
  const HelpNowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final helpCards = [
      const _HelpCard(
        title: 'This app is not an emergency service',
        description: 'If you or someone else is in danger, please contact local emergency services.',
        icon: Icons.info_outline,
      ),
      const _HelpCard(
        title: 'Contact DSA counselling',
        description: 'Email: support@dsa.edu | Phone: +65 1234 5678',
        icon: Icons.phone_in_talk,
      ),
      const _HelpCard(
        title: 'Reach out to a trusted mentor',
        description: 'Pick a lecturer or mentor you feel safe with and ask for a quick check-in.',
        icon: Icons.support_agent,
      ),
      const _HelpCard(
        title: 'Crisis hotlines',
        description: 'Samaritans of Singapore: 1767 | IMH Helpline: 6389-2222',
        icon: Icons.healing,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Help Now')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: helpCards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => helpCards[index],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.description, required this.icon});

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
