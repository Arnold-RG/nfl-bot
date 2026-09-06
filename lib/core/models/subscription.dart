/// Internal ids keep listen/live/pulse for billing compatibility;
/// UI presents Free / Pro / Ultra.
enum PlanId { free, listen, live, pulse }

/// Monthly plans authored in PLN (15–29 zł) and converted to the member's currency.
class SubscriptionPlan {
  final PlanId id;
  final String name;
  final double pricePln;
  final String promise;
  final List<String> perks;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.pricePln,
    required this.promise,
    required this.perks,
  });

  static const listen = SubscriptionPlan(
    id: PlanId.listen,
    name: 'Pro',
    pricePln: 15,
    promise: 'Unlimited live voice coaching in your language.',
    perks: [
      'Unlimited ChatGPT-style voice turns',
      'Coach replies in any language you pick',
      '10 plate photos each month',
      'Personalized calorie and protein targets',
    ],
  );

  static const live = SubscriptionPlan(
    id: PlanId.live,
    name: 'Ultra',
    pricePln: 22,
    promise: 'Voice plus instant food photos and a live watch link.',
    perks: [
      'Everything in Pro',
      'Unlimited food photo analysis',
      'Smartwatch pairing and live vitals',
      'Hands-free conversation that keeps going',
      'Human neural voice when an AI key is connected',
    ],
  );

  static const pulse = SubscriptionPlan(
    id: PlanId.pulse,
    name: 'Ultra+',
    pricePln: 29,
    promise: 'The full trainer: voice, plate, watch, and weekly body reports.',
    perks: [
      'Everything in Ultra',
      'Weekly spoken body report',
      'Priority neural voice',
      'Export of meals, vitals, and chat',
      'Priority coaching quality checks',
    ],
  );

  static const allPaid = [listen, live, pulse];

  static SubscriptionPlan byId(PlanId id) => switch (id) {
    PlanId.listen => listen,
    PlanId.live => live,
    PlanId.pulse => pulse,
    PlanId.free => const SubscriptionPlan(
      id: PlanId.free,
      name: 'Free',
      pricePln: 0,
      promise: 'Try the AI health coach before you pay.',
      perks: ['3 voice turns a day', '1 plate photo a day'],
    ),
  };
}
