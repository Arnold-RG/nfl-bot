import '../ai/ai_orchestrator.dart';
import '../platform/health_data_platform.dart';
import '../providers/app_state.dart';
import 'ai_coach_service.dart';
import 'billing_service.dart';
import 'device_bridge_service.dart';
import 'food_vision_service.dart';
import 'intelligence_service.dart';
import 'locale_service.dart';
import 'local_storage_service.dart';
import 'permissions_service.dart';
import 'preferences_service.dart';
import 'security_service.dart';
import 'smart_watch_service.dart';
import 'steps_service.dart';
import 'telemetry_service.dart';
import 'voice_coach_service.dart';

/// Global service locator initialized at app startup.
class AppServices {
  static late PreferencesService prefs;
  static late VoiceCoachService voice;
  static late SecurityService security;
  static late LocalStorageService storage;
  static late PermissionsService permissions;
  static late StepsService steps;
  static late SmartWatchService watch;
  static late DeviceBridgeService device;
  static late AiCoachService coach;
  static late FoodVisionService foodVision;
  static late IntelligenceService intelligence;
  static late TelemetryService telemetry;
  static late LocaleService locale;
  static late BillingService billing;
  static late AppState appState;
  static late HealthDataPlatform health;
  static late AiOrchestrator orchestrator;
}
