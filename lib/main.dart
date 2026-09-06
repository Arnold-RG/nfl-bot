import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'core/ai/ai_orchestrator.dart';
import 'core/platform/health_data_platform.dart';
import 'core/providers/app_state.dart';
import 'core/services/ai_coach_service.dart';
import 'core/services/app_services.dart';
import 'core/services/billing_service.dart';
import 'core/services/device_bridge_service.dart';
import 'core/services/food_vision_service.dart';
import 'core/services/intelligence_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/locale_service.dart';
import 'core/services/permissions_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/security_service.dart';
import 'core/services/smart_watch_service.dart';
import 'core/services/steps_service.dart';
import 'core/services/telemetry_service.dart';
import 'core/services/voice_coach_service.dart';
import 'features/launch/pulse_splash.dart';
import 'features/onboarding/welcome_flow.dart';
import 'features/shell/nflbot_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrap();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: AppServices.appState,
      child: const NFLBotApp(),
    ),
  );
}

Future<void> _safe(String name, Future<void> Function() fn) async {
  try {
    await fn();
  } catch (e) {
    debugPrint('Bootstrap: $name failed ($e)');
  }
}

Future<void> _bootstrap() async {
  AppServices.prefs = PreferencesService();
  await AppServices.prefs.init();
  await AppServices.prefs.rollUsageDay();

  AppServices.storage = LocalStorageService();
  await AppServices.storage.init();

  AppServices.telemetry = TelemetryService();
  await _safe('telemetry', AppServices.telemetry.init);
  AppServices.telemetry.countryCode = AppServices.prefs.countryCode;

  AppServices.locale = LocaleService(AppServices.prefs);
  AppServices.locale.suggestFromDevice();

  AppServices.billing = BillingService(
    prefs: AppServices.prefs,
    telemetry: AppServices.telemetry,
  );

  AppServices.voice = VoiceCoachService();
  await _safe('voice', AppServices.voice.init);
  await _safe(
    'voice-locale',
    () => AppServices.voice.applyLanguage(AppServices.locale.speechLocale),
  );

  AppServices.security = SecurityService();
  AppServices.permissions = PermissionsService();

  AppServices.watch = SmartWatchService();
  await _safe('watch', AppServices.watch.init);

  AppServices.device = DeviceBridgeService();
  await _safe('device', () async {
    await AppServices.device.capabilities();
  });

  AppServices.coach = AiCoachService();
  await _safe('coach', AppServices.coach.init);

  AppServices.foodVision = FoodVisionService(coach: AppServices.coach);

  AppServices.intelligence = IntelligenceService(
    storage: AppServices.storage,
    watch: AppServices.watch,
  );
  AppServices.intelligence.recompute();

  final appState = AppState();
  appState.initFromPrefs(
    userName: AppServices.prefs.userName,
    voice: AppServices.prefs.coachVoice,
    darkMode: AppServices.prefs.darkMode,
    voiceEnabled: AppServices.prefs.voiceEnabled,
    biometricEnabled: AppServices.prefs.biometricEnabled,
  );
  appState.loadFromStorage();
  AppServices.appState = appState;
  AppServices.health = HealthDataPlatform(appState);
  AppServices.orchestrator = AiOrchestrator(AppServices.health);

  final watch = AppServices.watch;
  if (watch.isConnected && watch.pairedDevice != null) {
    appState.onWatchConnected(watch.pairedDevice!.name, watch.vitals);
  }

  var lastIntelligencePass = DateTime.fromMillisecondsSinceEpoch(0);
  watch.addListener(() {
    if (!watch.isConnected) return;
    appState.syncWatchVitals(watch.vitals);
    final now = DateTime.now();
    if (now.difference(lastIntelligencePass) > const Duration(minutes: 1)) {
      lastIntelligencePass = now;
      AppServices.intelligence.recordVitalsSample(watch.vitals);
    }
  });

  AppServices.steps = StepsService(
    onStepsUpdated: appState.updateSteps,
    onStatusUpdated: appState.updateStepStatus,
  );
  await _safe('steps', AppServices.steps.start);
}

class NFLBotApp extends StatefulWidget {
  const NFLBotApp({super.key});

  @override
  State<NFLBotApp> createState() => _NFLBotAppState();
}

enum _LaunchPhase { splash, onboarding, main }

class _NFLBotAppState extends State<NFLBotApp> {
  _LaunchPhase _phase = _LaunchPhase.splash;

  void _onSplashDone() {
    setState(() {
      _phase = AppServices.prefs.onboardingDone
          ? _LaunchPhase.main
          : _LaunchPhase.onboarding;
    });
  }

  Future<void> _onOnboardingDone() async {
    await AppServices.prefs.setOnboardingDone(true);
    await AppServices.prefs.setUserName(context.read<AppState>().userName);
    if (mounted) setState(() => _phase = _LaunchPhase.main);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          title: AppConfig.appDescription,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: switch (_phase) {
            _LaunchPhase.splash => PulseSplash(onFinished: _onSplashDone),
            _LaunchPhase.onboarding => WelcomeFlow(onComplete: _onOnboardingDone),
            _LaunchPhase.main => const NflBotShell(),
          },
          onGenerateRoute: AppRouter.generateRoute,
        );
      },
    );
  }
}
