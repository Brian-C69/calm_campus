import 'package:flutter/material.dart';

import '../services/user_profile_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      title: 'Feel seen, not judged',
      body: 'Log your mood, add a quick note, and keep your support contacts handy. CalmCampus responds gently.',
      icon: Icons.favorite,
    ),
    _OnboardSlide(
      title: 'Stay on top of campus life',
      body: 'Track classes, tasks, and announcements. Highlight your next class and get reminders when you want them.',
      icon: Icons.schedule,
    ),
    _OnboardSlide(
      title: 'Talk to DSA or the Buddy',
      body: 'Start a chat with DSA consultants when you need a human, or use the Buddy for quick support.',
      icon: Icons.support_agent,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await UserProfileService.instance.completeFirstRun();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(slide.icon, size: 96, color: theme.colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(
                          slide.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (i) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_index == _slides.length - 1 ? 'Start' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide {
  const _OnboardSlide({required this.title, required this.body, required this.icon});
  final String title;
  final String body;
  final IconData icon;
}
