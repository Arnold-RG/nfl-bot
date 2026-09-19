import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

/// Body / progress — empty until the user adds real check-ins.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(
        backgroundColor: AppTheme.labBg,
        title: const Text('Body'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Watch yourself transform.',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.labInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Private check-ins stay empty until you add them. No sample photos or stats.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.labCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.labBorder),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 40, color: AppTheme.labMuted),
                  SizedBox(height: 12),
                  Text(
                    'No comparison yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.labInk,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Front · Back · Left · Right — when you are ready',
                    style: TextStyle(color: AppTheme.labMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final label in ['—', '—', '—', '—'])
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.labCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.labBorder),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.labMuted,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
