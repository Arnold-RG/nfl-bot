import 'package:flutter/foundation.dart';

import '../data/world_currencies.dart';
import '../models/subscription.dart';
import 'preferences_service.dart';
import 'telemetry_service.dart';

/// Local membership gate. Card charging needs a payment provider later;
/// this layer already prices in the member's currency and unlocks the product.
class BillingService extends ChangeNotifier {
  final PreferencesService prefs;
  final TelemetryService telemetry;

  BillingService({required this.prefs, required this.telemetry});

  PlanId get planId {
    final raw = prefs.planId;
    return PlanId.values.firstWhere((p) => p.name == raw, orElse: () => PlanId.free);
  }

  SubscriptionPlan get plan => SubscriptionPlan.byId(planId);
  bool get isMember => planId != PlanId.free;

  DateTime? get renewsAt {
    final ms = prefs.planRenewsAtMs;
    return ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  WorldCurrency get currency => WorldCurrencies.byCode(prefs.currencyCode);

  String priceOf(SubscriptionPlan p) => '${currency.format(p.pricePln)} / mo';

  int get voiceTurnsToday => prefs.usageVoiceToday;
  int get scansToday => prefs.usageScansToday;

  int get voiceLimit => isMember ? 100000 : 3;
  int get scanLimit => switch (planId) {
    PlanId.free => 1,
    PlanId.listen => 10,
    PlanId.live || PlanId.pulse => 100000,
  };

  bool get canTalk => voiceTurnsToday < voiceLimit;
  bool get canScan => scansToday < scanLimit;
  bool get canWatchLive => isMember;
  bool get neuralVoice => planId == PlanId.live || planId == PlanId.pulse;

  String? get talkGateReason => canTalk
      ? null
      : 'Free voice turns are used for today. Live membership unlocks unlimited conversation.';

  String? get scanGateReason => canScan
      ? null
      : 'Today’s free plate scan is used. Live membership unlocks unlimited food photos.';

  Future<bool> consumeVoiceTurn() async {
    await prefs.rollUsageDay();
    if (!canTalk) return false;
    await prefs.setUsageVoiceToday(voiceTurnsToday + 1);
    telemetry.record('voice_turn', 'Spoken coaching turn');
    notifyListeners();
    return true;
  }

  Future<bool> consumeScan() async {
    await prefs.rollUsageDay();
    if (!canScan) return false;
    await prefs.setUsageScansToday(scansToday + 1);
    telemetry.record('plate_scan', 'Meal photo analyzed');
    notifyListeners();
    return true;
  }

  Future<void> subscribe(PlanId id) async {
    final chosen = SubscriptionPlan.byId(id);
    final until = DateTime.now().add(const Duration(days: 30));
    await prefs.setPlanId(id.name);
    await prefs.setPlanRenewsAtMs(until.millisecondsSinceEpoch);
    telemetry.record(
      'subscribe',
      '${chosen.name} · ${currency.format(chosen.pricePln)}',
      meta: {'plan': id.name, 'currency': currency.code},
    );
    notifyListeners();
  }

  Future<void> cancel() async {
    await prefs.setPlanId(PlanId.free.name);
    await prefs.setPlanRenewsAtMs(0);
    telemetry.record('cancel', 'Membership returned to Start');
    notifyListeners();
  }
}
