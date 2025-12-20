import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuideOverlay extends StatefulWidget {
  const GuideOverlay({
    super.key,
    required this.pageId,
    required this.steps,
    required this.child,
  });

  final String pageId;
  final List<GuideStep> steps;
  final Widget child;

  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay> {
  bool _show = false;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('guide_seen_${widget.pageId}') ?? false;
    if (!mounted) return;
    setState(() {
      _show = !seen && widget.steps.isNotEmpty;
    });
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guide_seen_${widget.pageId}', true);
    if (!mounted) return;
    setState(() {
      _show = false;
    });
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _finish();
    } else {
      setState(() {
        _index += 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_show) _GuideCard(step: widget.steps[_index], onNext: _next, onFinish: _finish, isLast: _index == widget.steps.length - 1),
      ],
    );
  }
}

class GuideStep {
  const GuideStep({required this.title, required this.body});
  final String title;
  final String body;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.step,
    required this.onNext,
    required this.onFinish,
    required this.isLast,
  });

  final GuideStep step;
  final VoidCallback onNext;
  final VoidCallback onFinish;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(step.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(step.body, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onFinish,
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isLast ? onFinish : onNext,
                    child: Text(isLast ? 'Finish' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
