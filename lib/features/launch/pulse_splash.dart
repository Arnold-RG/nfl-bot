import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../core/services/app_services.dart';
import '../live/brand_mark.dart';

class PulseSplash extends StatefulWidget {
  final VoidCallback onFinished;
  const PulseSplash({super.key, required this.onFinished});

  @override
  State<PulseSplash> createState() => _PulseSplashState();
}

class _PulseSplashState extends State<PulseSplash> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1200)),
      AppServices.permissions.requestEssentialPermissions(),
    ]);
    if (mounted) widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VoiceArtwork(size: 120),
            const SizedBox(height: 24),
            Text(
              'NFL BOT',
              style: theme.textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your body. Your data. Your AI coach.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
