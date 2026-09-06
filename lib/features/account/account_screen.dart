import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/data/world_countries.dart';
import '../../core/data/world_currencies.dart';
import '../../core/data/world_languages.dart';
import '../../core/models/coach_context.dart';
import '../../core/models/subscription.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../shared/app_ui.dart';
import '../watch/watch_connect_screen.dart';
import 'permission_center_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _key;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: AppServices.prefs.userName);
    _email = TextEditingController(text: AppServices.prefs.email);
    _key = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    context.read<AppState>().setUserName(_name.text.trim());
    await AppServices.prefs.setUserName(_name.text.trim());
    await AppServices.prefs.setEmail(_email.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account saved')),
      );
    }
  }

  Future<void> _pickLanguage() async {
    final chosen = await _searchSheet<WorldLanguage>(
      title: 'Language',
      items: WorldLanguages.all,
      label: (l) => l.label,
    );
    if (chosen == null) return;
    await AppServices.locale.setLanguage(chosen.code);
    await AppServices.voice.applyLanguage(chosen.speechLocale);
    if (mounted) setState(() {});
  }

  Future<void> _pickCountry() async {
    final chosen = await _searchSheet<WorldCountry>(
      title: 'Country',
      items: WorldCountries.all,
      label: (c) => '${c.name} · ${c.continent}',
    );
    if (chosen == null) return;
    await AppServices.locale.applyCountry(chosen.iso2);
    await AppServices.voice.applyLanguage(AppServices.locale.speechLocale);
    AppServices.telemetry.countryCode = chosen.iso2;
    if (mounted) setState(() {});
  }

  Future<void> _pickCurrency() async {
    final chosen = await _searchSheet<WorldCurrency>(
      title: 'Currency',
      items: WorldCurrencies.all,
      label: (c) => '${c.code} · ${c.name} · ${c.region}',
    );
    if (chosen == null) return;
    await AppServices.locale.setCurrency(chosen.code);
    if (mounted) setState(() {});
  }

  Future<T?> _searchSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SearchList<T>(title: title, items: items, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppServices.locale;
    final billing = AppServices.billing;
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    return AppPage(
      title: locale.copy.t('you'),
      subtitle: 'Profile, goals, devices, privacy, and plans.',
      children: [
        AppCard(
          child: Column(
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveAccount,
                  child: const Text('Save account'),
                ),
              ),
            ],
          ),
        ),
        SectionLabel('Goals'),
        AppCard(
          child: Column(
            children: [
              SettingTile(
                icon: Icons.flag_outlined,
                title: 'Fitness goal',
                subtitle: state.profile.goal.label,
                onTap: () async {
                  final g = await showModalBottomSheet<FitnessGoal>(
                    context: context,
                    builder: (ctx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final goal in FitnessGoal.values)
                            ListTile(
                              title: Text(goal.label),
                              onTap: () => Navigator.pop(ctx, goal),
                            ),
                        ],
                      ),
                    ),
                  );
                  if (g == null) return;
                  await state.saveProfile(state.profile.copyWith(goal: g));
                },
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.calendar_month_outlined,
                title: 'Training frequency',
                subtitle: '${state.trainingFrequency} days / week',
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.trending_up_rounded,
                title: 'Experience',
                subtitle: state.trainingExperience,
              ),
            ],
          ),
        ),
        SectionLabel('Equipment'),
        AppCard(
          child: Wrap(
            spacing: 8,
            children: [
              for (final opt in ['home', 'gym'])
                ChoiceChip(
                  label: Text(opt == 'home' ? 'Home' : 'Gym'),
                  selected: state.equipmentProfile == opt,
                  onSelected: (_) => state.setEquipmentProfile(opt),
                ),
            ],
          ),
        ),
        SectionLabel('Connected devices'),
        AppCard(
          child: Column(
            children: [
              SettingTile(
                icon: Icons.watch_outlined,
                title: 'Watch',
                subtitle: state.watchConnected
                    ? (state.watchName ?? 'Connected')
                    : 'Not linked · open Watch hub',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Watch')),
                      body: const WatchConnectScreen(),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.health_and_safety_outlined,
                title: kIsWeb ? 'Health platform hub' : 'Apple Health / Health Connect',
                subtitle: kIsWeb
                    ? 'On web this is a hub label only — native HealthKit / Health Connect run on device builds.'
                    : 'HealthKit (iOS) · Health Connect (Android) — permissions via platform hub.',
              ),
            ],
          ),
        ),
        SectionLabel('Privacy'),
        AppCard(
          child: Column(
            children: [
              SettingTile(
                icon: Icons.tune_rounded,
                title: 'Data permissions',
                subtitle: 'Activity, health, GPS, nutrition, AI memory',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PermissionCenterScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.download_outlined,
                title: 'Export my data',
                subtitle: 'Download meals, vitals, and chat (stub)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export queued — coming in a later build'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.delete_outline_rounded,
                title: 'Delete account data',
                subtitle: 'Request deletion (stub)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Deletion request stub — contact support'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SectionLabel('Preferences'),
        AppCard(
          child: Column(
            children: [
              SettingTile(
                icon: Icons.language_rounded,
                title: locale.copy.t('language'),
                subtitle: locale.language.label,
                onTap: _pickLanguage,
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.public_rounded,
                title: locale.copy.t('country'),
                subtitle: locale.country.name,
                onTap: _pickCountry,
              ),
              const Divider(height: 1),
              SettingTile(
                icon: Icons.payments_outlined,
                title: locale.copy.t('currency'),
                subtitle: '${locale.currency.code} · ${locale.currency.name}',
                onTap: _pickCurrency,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.volume_up_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Speak replies aloud',
                  style: theme.textTheme.titleSmall,
                ),
                value: state.voiceEnabled,
                onChanged: state.setVoiceEnabled,
              ),
              const Divider(height: 1),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.dark_mode_outlined,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text('Dark mode', style: theme.textTheme.titleSmall),
                value: state.darkMode,
                onChanged: state.setDarkMode,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionLabel('Subscription · Free / Pro / Ultra'),
        Text(
          billing.isMember
              ? 'Current: ${billing.plan.name} · ${billing.priceOf(billing.plan)}'
              : 'Start on Free. Pro and Ultra unlock voice, plate, and watch depth.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Free', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                SubscriptionPlan.byId(PlanId.free).promise,
                style: theme.textTheme.bodyMedium,
              ),
              if (!billing.isMember)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Current plan',
                    style: theme.textTheme.labelMedium,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (final plan in SubscriptionPlan.allPaid)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlanCard(
              plan: plan,
              price: billing.priceOf(plan),
              current: billing.planId == plan.id,
              recommended: plan.id == PlanId.live,
              onChoose: () async {
                await billing.subscribe(plan.id);
                if (mounted) setState(() {});
              },
            ),
          ),
        if (billing.isMember)
          TextButton(
            onPressed: () async {
              await billing.cancel();
              if (mounted) setState(() {});
            },
            child: const Text('Return to Free'),
          ),
        const SizedBox(height: 8),
        Text(
          'Prices stay in the 15–29 zł band and convert to your local currency. '
          '(Internal plan ids: Listen→Pro, Live→Ultra, Pulse→Ultra+.)',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SectionLabel('AI provider'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add an OpenAI key for ChatGPT-quality replies and a more natural voice.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _key,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API key',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await AppServices.coach.configure(
                          provider: AiProvider.openai,
                          apiKey: _key.text,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('OpenAI connected')),
                        );
                      },
                      child: const Text('OpenAI'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await AppServices.coach.configure(
                          provider: AiProvider.anthropic,
                          apiKey: _key.text,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Claude connected')),
                        );
                      },
                      child: const Text('Claude'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Operators: Creator SOC runs separately.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final String price;
  final bool current;
  final bool recommended;
  final VoidCallback onChoose;

  const _PlanCard({
    required this.plan,
    required this.price,
    required this.current,
    required this.recommended,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.name, style: theme.textTheme.titleMedium),
              if (recommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Popular',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                price,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(plan.promise, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          for (final perk in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(perk, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: current ? null : onChoose,
              child: Text(current ? 'Current plan' : 'Choose ${plan.name}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchList<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) label;

  const _SearchList({
    required this.title,
    required this.items,
    required this.label,
  });

  @override
  State<_SearchList<T>> createState() => _SearchListState<T>();
}

class _SearchListState<T> extends State<_SearchList<T>> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items
        .where((i) => widget.label(i).toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return ListTile(
                  title: Text(widget.label(item)),
                  onTap: () => Navigator.pop(context, item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
