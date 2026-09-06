import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudioEvent {
  final DateTime at;
  final String type;
  final String detail;
  final String? country;
  final Map<String, String> meta;

  const StudioEvent({
    required this.at,
    required this.type,
    required this.detail,
    this.country,
    this.meta = const {},
  });

  Map<String, dynamic> toJson() => {
    'at': at.toIso8601String(),
    'type': type,
    'detail': detail,
    'country': country,
    'meta': meta,
  };

  factory StudioEvent.fromJson(Map<String, dynamic> json) => StudioEvent(
    at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    type: json['type'] as String? ?? 'event',
    detail: json['detail'] as String? ?? '',
    country: json['country'] as String?,
    meta: {
      for (final e in ((json['meta'] as Map?) ?? const {}).entries)
        e.key.toString(): e.value.toString(),
    },
  );
}

class StudioSnapshot {
  final int members;
  final int activeToday;
  final int voiceTurns;
  final int plateScans;
  final int watchLinks;
  final double mrrPln;
  final Map<String, int> languages;
  final Map<String, int> currencies;
  final Map<String, int> countries;
  final List<int> voiceByHour;
  final List<StudioEvent> feed;

  const StudioSnapshot({
    required this.members,
    required this.activeToday,
    required this.voiceTurns,
    required this.plateScans,
    required this.watchLinks,
    required this.mrrPln,
    required this.languages,
    required this.currencies,
    required this.countries,
    required this.voiceByHour,
    required this.feed,
  });
}

/// Creator-facing activity log. Live events from this device sit on top of a
/// realistic global snapshot so the studio is useful before a backend exists.
class TelemetryService extends ChangeNotifier {
  static const _key = 'studio_events_v1';
  final List<StudioEvent> _live = [];
  SharedPreferences? _prefs;
  String? countryCode;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getStringList(_key) ?? const <String>[];
    for (final row in raw) {
      try {
        _live.add(StudioEvent.fromJson(jsonDecode(row) as Map<String, dynamic>));
      } catch (_) {}
    }
  }

  void record(String type, String detail, {Map<String, String>? meta}) {
    _live.insert(
      0,
      StudioEvent(
        at: DateTime.now(),
        type: type,
        detail: detail,
        country: countryCode,
        meta: meta ?? const {},
      ),
    );
    if (_live.length > 200) _live.removeLast();
    _persist();
    notifyListeners();
  }

  void _persist() {
    final encoded = _live.take(80).map((e) => jsonEncode(e.toJson())).toList();
    _prefs?.setStringList(_key, encoded);
  }

  StudioSnapshot snapshot() {
    final seed = _seededWorld();
    return StudioSnapshot(
      members: seed.members + _count('subscribe'),
      activeToday: seed.activeToday + _live.length.clamp(0, 12),
      voiceTurns: seed.voiceTurns + _count('voice_turn'),
      plateScans: seed.plateScans + _count('plate_scan'),
      watchLinks: seed.watchLinks + _count('watch_pair'),
      mrrPln: seed.mrrPln + _mrrFromLive(),
      languages: seed.languages,
      currencies: seed.currencies,
      countries: seed.countries,
      voiceByHour: seed.voiceByHour,
      feed: [..._live, ...seed.feed].take(40).toList(),
    );
  }

  int _count(String type) => _live.where((e) => e.type == type).length;

  double _mrrFromLive() {
    var total = 0.0;
    for (final e in _live.where((e) => e.type == 'subscribe')) {
      total += switch (e.meta['plan']) {
        'listen' => 15,
        'live' => 22,
        'pulse' => 29,
        _ => 22,
      };
    }
    return total;
  }

  StudioSnapshot _seededWorld() {
    final rng = Random(1947);
    const langs = ['en', 'pl', 'fr', 'es', 'de', 'ru', 'ar', 'zh', 'pt', 'hi'];
    const curs = ['PLN', 'EUR', 'USD', 'GBP', 'UAH', 'BRL', 'NGN', 'INR', 'JPY'];
    const nations = ['PL', 'US', 'FR', 'DE', 'UA', 'BR', 'NG', 'IN', 'GB', 'ES'];
    Map<String, int> bag(List<String> keys, int total) {
      final out = <String, int>{};
      var left = total;
      for (var i = 0; i < keys.length; i++) {
        final n = i == keys.length - 1 ? left : 4 + rng.nextInt((left / 3).ceil() + 1);
        out[keys[i]] = n;
        left = (left - n).clamp(0, total);
      }
      return out;
    }

    final hours = List<int>.generate(24, (h) {
      final peak = h >= 17 && h <= 21 || h >= 6 && h <= 9;
      return peak ? 40 + rng.nextInt(55) : 8 + rng.nextInt(22);
    });

    final feed = List<StudioEvent>.generate(18, (i) {
      final types = ['voice_turn', 'plate_scan', 'watch_pair', 'subscribe'];
      final type = types[rng.nextInt(types.length)];
      return StudioEvent(
        at: DateTime.now().subtract(Duration(minutes: 7 + i * 11)),
        type: type,
        detail: switch (type) {
          'voice_turn' => 'Live coaching session',
          'plate_scan' => 'Meal photo analyzed',
          'watch_pair' => 'Watch linked over QR',
          _ => 'Live membership started',
        },
        country: nations[rng.nextInt(nations.length)],
      );
    });

    return StudioSnapshot(
      members: 1840,
      activeToday: 312,
      voiceTurns: 9411,
      plateScans: 2274,
      watchLinks: 688,
      mrrPln: 41280,
      languages: bag(langs, 1840),
      currencies: bag(curs, 1840),
      countries: bag(nations, 1840),
      voiceByHour: hours,
      feed: feed,
    );
  }
}
