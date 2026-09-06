import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../live/live_stage_screen.dart';

/// AI Coach tab — conversational layer that connects body data.
class CoachHubScreen extends StatelessWidget {
  const CoachHubScreen({super.key});

  static const _prompts = [
    'What should I do now?',
    'How recovered am I?',
    'What should I train today?',
    'Am I hitting protein?',
    'Summarize my week',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Coach · connects activity, food, training, recovery',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.electricDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _prompts.length,
                      separatorBuilder: (_, i) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final p = _prompts[i];
                        return ActionChip(
                          label: Text(p),
                          onPressed: state.coachThinking
                              ? null
                              : () => state.sendChatMessage(p),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(child: LiveStageScreen()),
      ],
    );
  }
}
