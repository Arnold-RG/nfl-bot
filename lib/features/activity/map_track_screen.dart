import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../core/providers/app_state.dart';

/// GPS map + live step tracking surface.
class MapTrackScreen extends StatefulWidget {
  const MapTrackScreen({super.key});

  @override
  State<MapTrackScreen> createState() => _MapTrackScreenState();
}

class _MapTrackScreenState extends State<MapTrackScreen> {
  final _map = MapController();
  LatLng _center = const LatLng(40.7128, -74.0060);
  final List<LatLng> _trail = [];
  StreamSubscription<Position>? _sub;
  String _status = 'Locating…';
  bool _tracking = false;
  double _meters = 0;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (kIsWeb) {
      setState(() => _status = 'Map ready — enable location in browser if prompted');
    }
    final ok = await _ensurePermission();
    if (!ok) {
      setState(() => _status = 'Location permission needed for GPS track');
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _center = here;
        _trail
          ..clear()
          ..add(here);
        _status = 'GPS locked';
      });
      _map.move(here, 16);
    } catch (_) {
      setState(() => _status = 'Could not get position — using default map');
    }
  }

  Future<bool> _ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return false;
    }
    final service = await Geolocator.isLocationServiceEnabled();
    return service;
  }

  Future<void> _toggleTrack() async {
    if (_tracking) {
      await _sub?.cancel();
      _sub = null;
      setState(() {
        _tracking = false;
        _status = 'Track paused · ${_meters.toStringAsFixed(0)} m';
      });
      return;
    }
    final ok = await _ensurePermission();
    if (!ok) {
      setState(() => _status = 'Allow location to start tracking');
      return;
    }
    setState(() {
      _tracking = true;
      _status = 'Tracking route…';
    });
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      final next = LatLng(pos.latitude, pos.longitude);
      if (_trail.isNotEmpty) {
        _meters += Geolocator.distanceBetween(
          _trail.last.latitude,
          _trail.last.longitude,
          next.latitude,
          next.longitude,
        );
      }
      setState(() {
        _center = next;
        _trail.add(next);
      });
      _map.move(next, _map.camera.zoom);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = context.watch<AppState>().steps;
    final goal = context.watch<AppState>().stepGoal;

    return Scaffold(
      backgroundColor: AppTheme.labBg,
      appBar: AppBar(title: const Text('Map & steps')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: 'STEPS',
                    value: '$steps',
                    hint: 'goal $goal',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'ROUTE',
                    value: '${(_meters / 1000).toStringAsFixed(2)} km',
                    hint: _status,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nfbot.app',
                  ),
                  if (_trail.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _trail,
                          color: AppTheme.bronze,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _center,
                        width: 36,
                        height: 36,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bronze,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.labInk,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _toggleTrack,
                  icon: Icon(
                    _tracking ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(_tracking ? 'Stop GPS track' : 'Start GPS track'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String hint;

  const _Stat({
    required this.label,
    required this.value,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.labCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.labBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
