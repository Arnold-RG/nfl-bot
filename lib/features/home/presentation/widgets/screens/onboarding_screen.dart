import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../core/models/coach_persona.dart';
import '../../../../../core/models/user_profile.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/theme/app_layout.dart';
import '../components/ai_voice_orb.dart';
import 'profile_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

const _slideCount = 5;

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  CoachVoice _selected = CoachVoice.nova;
  final _nameCtrl = TextEditingController();

  /// The metrics slide owns the final action, since it has to validate first.
  bool get _isMetricsPage => _page == _slideCount - 1;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish(UserProfile profile) async {
    final state = context.read<AppState>();
    final name = _nameCtrl.text.trim();
    state.setUserName(name.isEmpty ? 'Athlete' : name);
    await AppServices.prefs.setCoachVoice(_selected);
    await state.saveProfile(profile);
    widget.onComplete();
  }

  /// Tapping a voice speaks a sample line, so the choice is made by ear
  /// rather than by reading a label.
  Future<void> _auditionVoice(CoachVoice voice) async {
    setState(() => _selected = voice);
    final persona = CoachPersona.forVoice(voice);
    await AppServices.voice.speak(
      '${persona.name} here. I will talk you through your training, '
      'your food, and your recovery.',
      voice: voice,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [AppTheme.darkBg, AppTheme.darkSurface]
                : [const Color(0xFFE8F5F0), AppTheme.backgroundColor],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    Text(
                      'NFLBot',
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                    const Spacer(),
                    ...List.generate(_slideCount, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(left: 6),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? scheme.primary
                              : scheme.onSurface.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    const _Slide(
                      title: 'A coach that\ntalks back',
                      desc:
                          'NFLBot is a live AI voice trainer. Ask it anything out loud and '
                          'it answers out loud, using your own numbers.',
                      child: AiVoiceOrb(
                        size: 168,
                        state: VoiceOrbState.speaking,
                      ),
                    ),
                    _Slide(
                      title: 'Pick your\ncoach voice',
                      desc:
                          'Tap to hear each one. You can switch any time in Settings.',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final persona in CoachPersona.all) ...[
                            _VoicePick(
                              persona: persona,
                              selected: _selected == persona.voice,
                              onTap: () => _auditionVoice(persona.voice),
                            ),
                            if (persona != CoachPersona.all.last)
                              const SizedBox(width: 16),
                          ],
                        ],
                      ),
                    ),
                    const _Slide(
                      title: 'Sync your\nsmart watch',
                      desc:
                          'Pair over Bluetooth, QR code, Wi-Fi, or your health account. '
                          'Live heart rate, oxygen, HRV, and sleep feed straight into your readiness score.',
                      child: _WatchSyncGraphic(),
                    ),
                    _Slide(
                      title: 'What should\nwe call you?',
                      desc: 'Personalize your dashboard and coach messages.',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: TextField(
                          controller: _nameCtrl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.syne(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(hintText: 'Your name'),
                        ),
                      ),
                    ),
                    // Targets are meaningless without these, so onboarding
                    // ends here rather than starting everyone on defaults.
                    ProfileForm(
                      initial: UserProfile.empty,
                      submitLabel: 'Start training',
                      onSubmit: _finish,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: () => _pageCtrl.previousPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        ),
                        child: Text(
                          'Back',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                            color: AppLayout.subtitleColor(context),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (!_isMetricsPage)
                      FilledButton(
                        onPressed: () => _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        ),
                        child: const Text('Continue'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchSyncGraphic extends StatelessWidget {
  const _WatchSyncGraphic();

  static const _methods = <(IconData, String)>[
    (Icons.bluetooth_rounded, 'Bluetooth'),
    (Icons.qr_code_2_rounded, 'QR code'),
    (Icons.wifi_rounded, 'Wi-Fi'),
    (Icons.cloud_sync_rounded, 'Account'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 116,
          decoration: BoxDecoration(
            color: const Color(0xFF0B1210),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.primary, width: 3),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.3),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_rounded,
                  color: scheme.primary.withValues(alpha: 0.9), size: 30),
              const SizedBox(height: 6),
              Text(
                '72 bpm',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '98% SpO₂',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (icon, label) in _methods)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  final String title, desc;
  final Widget child;
  const _Slide({required this.title, required this.desc, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppLayout.subtitleStyle(context).copyWith(height: 1.55, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _VoicePick extends StatelessWidget {
  final CoachPersona persona;
  final bool selected;
  final VoidCallback onTap;

  const _VoicePick({
    required this.persona,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final borderIdle =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : Theme.of(context).cardColor.withValues(alpha: 0.6),
          border: Border.all(
            color: selected ? primary : borderIdle,
            width: selected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            AiVoiceOrb(
              size: 90,
              state: selected ? VoiceOrbState.speaking : VoiceOrbState.idle,
            ),
            const SizedBox(height: 10),
            Text(
              persona.name,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              persona.tagline,
              style: AppLayout.subtitleStyle(context).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

