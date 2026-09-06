import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';
import '../../core/services/app_services.dart';
import '../../core/utils/pairing_link.dart';
import '../shared/app_ui.dart';

class WatchConnectScreen extends StatefulWidget {
  const WatchConnectScreen({super.key});

  @override
  State<WatchConnectScreen> createState() => _WatchConnectScreenState();
}

class _WatchConnectScreenState extends State<WatchConnectScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _incoming());
  }

  Future<void> _incoming() async {
    final id = PairingLink.fromCurrentLocation();
    if (id == null || AppServices.watch.isConnected) return;
    await _pair(() => AppServices.watch.pairWithQrCode(id));
  }

  Future<void> _pair(Future<bool> Function() action) async {
    if (!AppServices.billing.canWatchLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watch sync is included in Ultra plans.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    final watch = AppServices.watch;
    if (ok && watch.isConnected && watch.pairedDevice != null) {
      context.read<AppState>().onWatchConnected(
            watch.pairedDevice!.name,
            watch.vitals,
          );
      AppServices.telemetry.record('watch_pair', watch.pairedDevice!.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: AppServices.watch,
      builder: (context, _) {
        final watch = AppServices.watch;
        final payload = watch.generatePairingQrPayload();
        final connected = watch.isConnected && watch.pairedDevice != null;

        return AppPage(
          title: 'Watch',
          subtitle:
              'Scan the QR with your phone camera, or pair nearby over Bluetooth.',
          children: [
            if (connected) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.watch_rounded,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                watch.pairedDevice!.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'Connected',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _Vital(
                          label: 'Heart',
                          value: '${watch.vitals.heartRateBpm}',
                          unit: 'bpm',
                        ),
                        _Vital(
                          label: 'Steps',
                          value: '${watch.vitals.steps}',
                          unit: '',
                        ),
                        _Vital(
                          label: 'SpO₂',
                          value: '${watch.vitals.spo2Percent}',
                          unit: '%',
                        ),
                        _Vital(
                          label: 'Burn',
                          value: '${watch.vitals.caloriesBurned}',
                          unit: 'kcal',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () {
                        watch.disconnect();
                        context.read<AppState>().onWatchDisconnected();
                      },
                      child: const Text('Disconnect'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              AppCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: QrImageView(
                        data: payload,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Use iPhone Camera — it opens a normal web link.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (PairingLink.encodesUnreachableHost) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Open the app with your computer’s LAN address first '
                        '(not localhost).',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SelectableText(
                      payload,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: payload)),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy link'),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy
                            ? null
                            : () => _pair(() => watch.pairWithQrCode(payload)),
                        child: Text(_busy ? 'Linking…' : 'Pair from this QR'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                                await AppServices.permissions
                                    .requestBluetoothPermissions();
                                await watch.startBluetoothScan();
                                final nearby = watch.nearbyDevices;
                                if (nearby.isEmpty) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No nearby watches yet — try the QR.',
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                await _pair(
                                  () => watch.pairBluetooth(nearby.first),
                                );
                              },
                        icon: const Icon(Icons.bluetooth_searching_rounded),
                        label: const Text('Scan Bluetooth'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Vital extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _Vital({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                ),
          ),
          Text(
            unit.isEmpty ? label : '$label $unit',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
