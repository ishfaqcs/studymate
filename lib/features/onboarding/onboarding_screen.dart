import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  static const pages = [
    (
      Icons.calendar_month_rounded,
      'Plan your semester',
      'Keep your classes, assignments, exams and important deadlines organized in one place.'
    ),
    (
      Icons.fact_check_rounded,
      'Stay on top of attendance',
      'Track every class and know exactly where your attendance stands before it becomes a problem.'
    ),
    (
      Icons.insights_rounded,
      'Understand your progress',
      'Monitor your GPA, coursework and semester progress with clear academic insights.'
    ),
  ];
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(actions: [
          TextButton(
              onPressed: () => context.go('/setup'), child: const Text('Skip'))
        ]),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(children: [
                  Expanded(
                      child: PageView.builder(
                          controller: controller,
                          itemCount: pages.length,
                          onPageChanged: (i) => setState(() => page = i),
                          itemBuilder: (context, i) {
                            final p = pages[i];
                            return SingleChildScrollView(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                          width: 104,
                                          height: 104,
                                          decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(32)),
                                          child: Icon(p.$1,
                                              size: 50,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary)),
                                      const SizedBox(height: 24),
                                      Text(p.$2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800),
                                          textAlign: TextAlign.center),
                                      const SizedBox(height: 12),
                                      Text(p.$3,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.5),
                                          textAlign: TextAlign.center),
                                    ]));
                          })),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          pages.length,
                          (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: i == page ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: i == page
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                  borderRadius: BorderRadius.circular(8))))),
                  const SizedBox(height: 20),
                  Row(children: [
                    if (page > 0)
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () => controller.previousPage(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut),
                              child: const Text('Back'))),
                    if (page > 0) const SizedBox(width: 12),
                    Expanded(
                        child: FilledButton(
                            onPressed: () {
                              if (page == pages.length - 1) {
                                context.go('/setup');
                              } else {
                                controller.nextPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut);
                              }
                            },
                            child: Text(page == pages.length - 1
                                ? 'Get started'
                                : 'Next')))
                  ]),
                ]))),
      );
}
