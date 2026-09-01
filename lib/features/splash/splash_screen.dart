import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/preferences_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _next();
  }

  Future<void> _next() async {
    bool done;
    try {
      done = await PreferencesService.onboardingCompleted();
    } catch (_) {
      done = false;
    }
    if (!mounted) return;
    context.go(done ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/branding/studymate-mark-source.png',
            width: 80, height: 80, semanticLabel: 'StudyMate logo'),
        const SizedBox(height: 18),
        Text(AppConstants.appName,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(AppConstants.tagline,
            style: Theme.of(context).textTheme.bodyLarge),
      ])));
}
