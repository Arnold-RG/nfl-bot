import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../config/app_theme.dart';
import '../../../../../core/models/smart_watch_model.dart';
import '../../../../../core/providers/app_state.dart';
import '../../../../../core/services/app_services.dart';
import '../../../../../core/services/smart_watch_service.dart';
import '../../../../../core/theme/app_layout.dart';
import '../../../../../core/utils/pairing_link.dart';
import '../components/live_coach_orb.dart';

/// Smart-watch command center: pair over Bluetooth, QR, Wi-Fi, or account,
/// then monitor live vitals.
class WatchHubScreen extends StatefulWidget {
  const WatchHubScreen({super.key});

  @override
  State<WatchHubScreen> createState() => _WatchHubScreenState();
}

class _WatchHubScreenState extends State<WatchHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _qrCtrl = TextEditingController();
  final _wifiHostCtrl = TextEditingController(text: '192.168.1.50');
  final _wifiPinCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _provider = 'Apple Health';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _consumeIncomingPairLink();
    });
  }

  Future<void> _consumeIncomingPairLink() async {
    final incoming = PairingLink.fromCurrentLocation();
    if (incoming == null || AppServices.watch.isConnected) return;

    _tabs.index = 1;
    _qrCtrl.text = incoming;
    await _pair(() => AppServices.watch.pairWithQrCode(incoming));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _qrCtrl.dispose();
    _wifiHostCtrl.dispose();
    _wifiPinCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pair(Future<bool> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);

    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);

    final watch = AppServices.watch;
    final messenger = ScaffoldMessenger.of(context);

    if (ok && watch.isConnected && watch.pairedDevice != null) {
      context.read<AppState>().onWatchConnected(
            watch.pairedDevice!.name,
            watch.vitals,
          );
      AppServices.intelligence.recordVitalsSample(watch.vitals);
      HapticFeedback.mediumImpact();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Connected to ${watch.pairedDevice!.name}'),
          backgroundColor: AppTheme.primaryDark,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(watch.session.statusMessage ?? 'Pairing failed'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _startScan() async {
    final granted = await AppServices.permissions.requestBluetoothPermissions();
    if (!mounted) return;

    // Desktop and web have no Bluetooth stack behind this build, so the scan
    // still runs against the abstraction layer rather than blocking the user.
    if (!granted && Theme.of(context).platform == TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bluetooth permission is needed to scan for watches'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: AppServices.device.openBluetoothSettings,
          ),
        ),
      );
      return;
    }
    await AppServices.watch.startBluetoothScan();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppServices.watch,
      builder: (context, _) {
        final watch = AppServices.watch;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [AppTheme.darkBg, const Color(0xFF0E1814)]
                  : [const Color(0xFFE4F3EC), AppTheme.backgroundColor],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _Header(watch: watch),
                const SizedBox(height: 16),
                if (watch.isConnected)
                  _ConnectedPanel(watch: watch)
                else
                  _PairingPanel(
                    tabs: _tabs,
                    busy: _busy,
                    qrCtrl: _qrCtrl,
                    wifiHostCtrl: _wifiHostCtrl,
                    wifiPinCtrl: _wifiPinCtrl,
                    emailCtrl: _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    provider: _provider,
                    onProviderChanged: (v) => setState(() => _provider = v),
                    onScan: _startScan,
                    onStopScan: watch.stopScan,
                    onPairBluetooth: (device) =>
                        _pair(() => watch.pairBluetooth(device)),
                    onPairQr: () => _pair(() => watch.pairWithQrCode(_qrCtrl.text)),
                    onPairWifi: () => _pair(
                      () => watch.pairWithWifi(
                        host: _wifiHostCtrl.text,
                        pin: _wifiPinCtrl.text,
                      ),
                    ),
                    onPairAccount: () => _pair(
                      () => watch.pairWithAccount(
                        email: _emailCtrl.text,
                        password: _passwordCtrl.text,
                        provider: _provider,
                      ),
                    ),
                    onDemoQr: () => setState(
                      () => _qrCtrl.text =
                          watch.generatePairingQrPayload(refresh: true),
                    ),
                  ),
                const SizedBox(height: 20),
                const _CategoriesStrip(),
                const SizedBox(height: 18),
                _CoachInsight(watch: watch),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final SmartWatchService watch;
  const _Header({required this.watch});

  @override
  Widget build(BuildContext context) {
    final connected = watch.isConnected;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Watch Hub', style: AppLayout.screenTitleStyle(context)),
              const SizedBox(height: 4),
              Text(
                connected
                    ? 'Live sync · ${watch.pairedDevice!.brandLabel}'
                    : 'Bluetooth · QR · Wi-Fi · Account',
                style: AppLayout.subtitleStyle(context),
              ),
            ],
          ),
        ),
        const LiveCoachOrb(size: 58),
      ],
    );
  }
}

class _ConnectedPanel extends StatelessWidget {
  final SmartWatchService watch;
  const _ConnectedPanel({required this.watch});

  @override
  Widget build(BuildContext context) {
    final device = watch.pairedDevice!;
    final vitals = watch.vitals;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF134E3A), Color(0xFF4CC9A8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _WatchFace(brand: device.brand, battery: device.batteryPercent),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${device.model} · FW ${device.firmware}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _Pill(
                              icon: Icons.battery_charging_full_rounded,
                              label: '${device.batteryPercent}%',
                            ),
                            _Pill(
                              icon: Icons.signal_cellular_alt_rounded,
                              label: '${device.signalStrength}%',
                            ),
                            _Pill(
                              icon: Icons.link_rounded,
                              label: watch.session.method.name.toUpperCase(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => watch.syncNow(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        final appState = context.read<AppState>();
                        await watch.disconnect();
                        appState.onWatchDisconnected();
                        AppServices.intelligence.recompute();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _VitalTile(
                title: 'Heart rate',
                value: '${vitals.heartRateBpm}',
                unit: 'bpm',
                subtitle: vitals.zoneLabel,
                color: const Color(0xFFFF6B6B),
                icon: Icons.favorite_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalTile(
                title: 'Blood oxygen',
                value: '${vitals.spo2Percent}',
                unit: '%',
                subtitle: vitals.spo2Percent >= 95 ? 'Normal' : 'Low',
                color: const Color(0xFF5B8DEF),
                icon: Icons.air_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _VitalTile(
                title: 'Stress',
                value: '${vitals.stressScore}',
                unit: '',
                subtitle: vitals.stressLabel,
                color: const Color(0xFFFFB347),
                icon: Icons.psychology_alt_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VitalTile(
                title: 'HRV',
                value: '${vitals.hrvMs}',
                unit: 'ms',
                subtitle: 'Recovery',
                color: const Color(0xFF4CC9A8),
                icon: Icons.monitor_heart_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: AppLayout.cardDecoration(context, radius: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Live heart rhythm',
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Updated ${DateFormat.Hm().format(vitals.lastSynced)}',
                    style: AppLayout.subtitleStyle(context).copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: 40,
                    maxY: 180,
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < vitals.heartRateSeries.length; i++)
                            FlSpot(
                              i.toDouble(),
                              vitals.heartRateSeries[i].toDouble(),
                            ),
                        ],
                        isCurved: true,
                        color: const Color(0xFFFF6B6B),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppLayout.cardDecoration(context, radius: 20),
          child: Row(
            children: [
              _MiniStat(
                label: 'Steps',
                value: NumberFormat.compact().format(vitals.steps),
                icon: Icons.directions_walk_rounded,
              ),
              _MiniStat(
                label: 'Active',
                value: '${vitals.activeMinutes}m',
                icon: Icons.local_fire_department_rounded,
              ),
              _MiniStat(
                label: 'Burn',
                value: '${vitals.caloriesBurned}',
                icon: Icons.bolt_rounded,
              ),
              _MiniStat(
                label: 'Distance',
                value: '${vitals.distanceKm.toStringAsFixed(1)}km',
                icon: Icons.route_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            'Auto live sync',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Stream vitals continuously',
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 12),
          ),
          value: watch.autoSync,
          onChanged: watch.setAutoSync,
          tileColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ],
    );
  }
}

class _PairingPanel extends StatelessWidget {
  final TabController tabs;
  final bool busy;
  final TextEditingController qrCtrl;
  final TextEditingController wifiHostCtrl;
  final TextEditingController wifiPinCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final String provider;
  final ValueChanged<String> onProviderChanged;
  final VoidCallback onScan;
  final VoidCallback onStopScan;
  final ValueChanged<SmartWatchDevice> onPairBluetooth;
  final VoidCallback onPairQr;
  final VoidCallback onPairWifi;
  final VoidCallback onPairAccount;
  final VoidCallback onDemoQr;

  const _PairingPanel({
    required this.tabs,
    required this.busy,
    required this.qrCtrl,
    required this.wifiHostCtrl,
    required this.wifiPinCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.provider,
    required this.onProviderChanged,
    required this.onScan,
    required this.onStopScan,
    required this.onPairBluetooth,
    required this.onPairQr,
    required this.onPairWifi,
    required this.onPairAccount,
    required this.onDemoQr,
  });

  @override
  Widget build(BuildContext context) {
    final session = AppServices.watch.session;
    final inProgress = session.status == WatchConnectionStatus.scanning ||
        session.status == WatchConnectionStatus.pairing ||
        session.status == WatchConnectionStatus.connecting;

    return Container(
      decoration: AppLayout.cardDecoration(context, radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect your watch',
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (session.statusMessage != null)
                  Text(
                    session.statusMessage!,
                    style: AppLayout.subtitleStyle(context).copyWith(
                      fontSize: 13,
                      color: session.status == WatchConnectionStatus.error
                          ? AppTheme.errorColor
                          : null,
                    ),
                  ),
                if (inProgress) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: session.progress.clamp(0.05, 1),
                      minHeight: 6,
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.12),
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TabBar(
            controller: tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppTheme.primaryDark,
            unselectedLabelColor: AppTheme.textLight,
            indicatorColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.dmSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Bluetooth'),
              Tab(text: 'QR Code'),
              Tab(text: 'Wi-Fi'),
              Tab(text: 'Login'),
            ],
          ),
          SizedBox(
            height: 520,
            child: TabBarView(
              controller: tabs,
              children: [
                _BluetoothTab(
                  busy: busy,
                  onScan: onScan,
                  onStopScan: onStopScan,
                  onPair: onPairBluetooth,
                ),
                _QrTab(
                  controller: qrCtrl,
                  busy: busy,
                  onPair: onPairQr,
                  onDemo: onDemoQr,
                ),
                _WifiTab(
                  hostCtrl: wifiHostCtrl,
                  pinCtrl: wifiPinCtrl,
                  busy: busy,
                  onPair: onPairWifi,
                ),
                _AccountTab(
                  emailCtrl: emailCtrl,
                  passwordCtrl: passwordCtrl,
                  provider: provider,
                  onProviderChanged: onProviderChanged,
                  busy: busy,
                  onPair: onPairAccount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BluetoothTab extends StatelessWidget {
  final bool busy;
  final VoidCallback onScan;
  final VoidCallback onStopScan;
  final ValueChanged<SmartWatchDevice> onPair;

  const _BluetoothTab({
    required this.busy,
    required this.onScan,
    required this.onStopScan,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    final watch = AppServices.watch;
    final scanning = watch.session.status == WatchConnectionStatus.scanning;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : (scanning ? onStopScan : onScan),
              icon: Icon(
                scanning ? Icons.stop_rounded : Icons.bluetooth_searching_rounded,
              ),
              label: Text(scanning ? 'Stop scan' : 'Scan nearby'),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: watch.nearbyDevices.isEmpty
                ? Center(
                    child: Text(
                      'Tap scan to find Apple, Samsung, Garmin,\nFitbit, Amazfit, Huawei, and Pixel watches.',
                      textAlign: TextAlign.center,
                      style: AppLayout.subtitleStyle(context),
                    ),
                  )
                : ListView.separated(
                    itemCount: watch.nearbyDevices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final device = watch.nearbyDevices[i];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                          child: Icon(
                            brandIcon(device.brand),
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        title: Text(
                          device.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${device.brandLabel} · signal ${device.signalStrength}%',
                        ),
                        trailing: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : TextButton(
                                onPressed: () => onPair(device),
                                child: const Text('Pair'),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _QrTab extends StatelessWidget {
  final TextEditingController controller;
  final bool busy;
  final VoidCallback onPair;
  final VoidCallback onDemo;

  const _QrTab({
    required this.controller,
    required this.busy,
    required this.onPair,
    required this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    final payload = controller.text.isEmpty
        ? AppServices.watch.generatePairingQrPayload()
        : controller.text;

    final localhostQr = PairingLink.encodesUnreachableHost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(
              data: payload,
              size: 220,
              backgroundColor: Colors.white,
              gapless: true,
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'iPhone Camera opens this as a normal web link. Keep both '
            'devices on the same Wi‑Fi, then tap Open.',
            textAlign: TextAlign.center,
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 12),
          ),
          if (localhostQr) ...[
            const SizedBox(height: 8),
            Text(
              'This page is on localhost, so iPhone cannot reach the link. '
              'Open the app with your computer’s LAN address first '
              '(for example http://192.168.0.107:8080).',
              textAlign: TextAlign.center,
              style: AppLayout.subtitleStyle(context).copyWith(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SelectableText(
            payload,
            textAlign: TextAlign.center,
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 11),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: payload));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pairing link copied')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy link'),
          ),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'QR or pairing link',
              hintText: 'https://…/pair.html?watch=… or BRAND|MODEL|SERIAL',
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(onPressed: onDemo, child: const Text('Demo code')),
              const Spacer(),
              FilledButton(
                onPressed: busy ? null : onPair,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Pair with QR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WifiTab extends StatelessWidget {
  final TextEditingController hostCtrl;
  final TextEditingController pinCtrl;
  final bool busy;
  final VoidCallback onPair;

  const _WifiTab({
    required this.hostCtrl,
    required this.pinCtrl,
    required this.busy,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Connect watches on the same network using their IP address and pairing PIN.',
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: hostCtrl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Watch IP or hostname',
              prefixIcon: Icon(Icons.wifi_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pinCtrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Pairing PIN',
              prefixIcon: Icon(Icons.pin_rounded),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onPair,
              icon: const Icon(Icons.router_rounded),
              label: Text(busy ? 'Connecting…' : 'Connect over Wi-Fi'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTab extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final String provider;
  final ValueChanged<String> onProviderChanged;
  final bool busy;
  final VoidCallback onPair;

  const _AccountTab({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.provider,
    required this.onProviderChanged,
    required this.busy,
    required this.onPair,
  });

  static const _providers = [
    'Apple Health',
    'Samsung Health',
    'Garmin Connect',
    'Fitbit',
    'Google Fit',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: provider,
            decoration: const InputDecoration(labelText: 'Health cloud'),
            items: [
              for (final p in _providers)
                DropdownMenuItem(value: p, child: Text(p)),
            ],
            onChanged: (v) {
              if (v != null) onProviderChanged(v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email or account',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onPair,
              icon: const Icon(Icons.cloud_sync_rounded),
              label: Text(busy ? 'Signing in…' : 'Link account and watch'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesStrip extends StatelessWidget {
  const _CategoriesStrip();

  static const _items = <(IconData, String, Color)>[
    (Icons.favorite_rounded, 'Heart', Color(0xFFFF6B6B)),
    (Icons.nightlight_round, 'Sleep', Color(0xFF7C6CF0)),
    (Icons.directions_run_rounded, 'Activity', Color(0xFF4CC9A8)),
    (Icons.spa_rounded, 'Recovery', Color(0xFF5B8DEF)),
    (Icons.bolt_rounded, 'Energy', Color(0xFFFFB347)),
    (Icons.emergency_rounded, 'Alerts', Color(0xFFE07A8A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health categories',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (icon, label, color) = _items[i];
              return Container(
                width: 88,
                padding: const EdgeInsets.all(12),
                decoration: AppLayout.cardDecoration(context, radius: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoachInsight extends StatelessWidget {
  final SmartWatchService watch;
  const _CoachInsight({required this.watch});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final vitals = watch.vitals;
    final connected = watch.isConnected;

    final insight = switch (true) {
      _ when !connected =>
        'Pair your watch and I will coach you in real time from heart rate, oxygen, stress, and recovery.',
      _ when vitals.stressScore > 65 =>
        'Stress is elevated at ${vitals.stressScore}. Five minutes of slow breathing, then a light walk, will bring it down faster than pushing through.',
      _ when vitals.heartRateBpm > 120 =>
        'You are in the ${vitals.zoneLabel.toLowerCase()} zone at ${vitals.heartRateBpm} bpm. Keep your form tight and stay on top of fluids.',
      _ when vitals.spo2Percent < 95 =>
        'Oxygen saturation is ${vitals.spo2Percent}%. Sit upright, breathe slowly, and check the watch fit before re-measuring.',
      _ =>
        'Vitals look solid — ${vitals.heartRateBpm} bpm, ${vitals.spo2Percent}% oxygen, HRV ${vitals.hrvMs} ms. Good window for focused training.',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppLayout.cardDecoration(context, radius: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LiveCoachOrb(size: 64, openOnTap: false),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.coach.name,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Watch coach',
                  style: AppLayout.subtitleStyle(context).copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  insight,
                  style: GoogleFonts.dmSans(fontSize: 14, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _VitalTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppLayout.cardDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 12),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: GoogleFonts.syne(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: [
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryDark),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          Text(
            label,
            style: AppLayout.subtitleStyle(context).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchFace extends StatelessWidget {
  final WatchBrand brand;
  final int battery;
  const _WatchFace({required this.brand, required this.battery});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1210),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(brandIcon(brand), color: AppTheme.primaryLight, size: 28),
          const SizedBox(height: 6),
          Text(
            '$battery%',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

IconData brandIcon(WatchBrand brand) {
  switch (brand) {
    case WatchBrand.apple:
      return Icons.phone_iphone_rounded;
    case WatchBrand.samsung:
      return Icons.watch_rounded;
    case WatchBrand.garmin:
      return Icons.terrain_rounded;
    case WatchBrand.fitbit:
      return Icons.favorite_border_rounded;
    case WatchBrand.amazfit:
      return Icons.access_time_filled_rounded;
    case WatchBrand.huawei:
      return Icons.watch_later_outlined;
    case WatchBrand.google:
      return Icons.smart_display_rounded;
    case WatchBrand.other:
      return Icons.watch_outlined;
  }
}
