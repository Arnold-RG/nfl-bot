import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../../config/app_theme.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../screens/live_voice_screen.dart';
import 'live_coach_orb.dart';

/// Home-screen entry into the live Bot coach.
class CoachCard extends StatelessWidget {
  const CoachCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final msg = state.coachMessage.isNotEmpty
            ? state.coachMessage
            : '${state.coach.name} is ready. Say “hey bot” or tap to talk.';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LiveVoiceScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1512), Color(0xFF2A221C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.labBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electric.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const LiveCoachOrb(size: 86, openOnTap: false),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              state.coach.name,
                              style: GoogleFonts.syne(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.labInk,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const _LiveDot(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          msg,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppTheme.labMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.smart_toy_rounded,
                              size: 14,
                              color: AppTheme.electric,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Say “hey bot” · tap to talk',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.electric,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    final live = AppServices.coach.isModelBacked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: (live ? AppTheme.electric : AppTheme.labMuted)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        live ? 'LIVE AI' : 'ON-DEVICE',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: live ? AppTheme.electric : AppTheme.labMuted,
        ),
      ),
    );
  }
}
