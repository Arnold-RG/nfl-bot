import 'package:flutter/foundation.dart';

/// Builds and reads pairing links that phone cameras can actually open.
///
/// iOS Camera reports "No usable data found" for custom schemes such as
/// `nfbot://watch/…` because no installed app owns that scheme. A normal
/// `http(s):` URL is recognised and offered as "Open in Safari".
class PairingLink {
  static const _legacyPrefix = 'nfbot://watch/';

  /// Public URL encoded into the on-screen QR.
  static String encode({required String watchId}) {
    final base = _publicOrigin();
    return Uri.parse('$base/pair.html').replace(
      queryParameters: {
        'watch': watchId,
        'ts': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    ).toString();
  }

  /// Read a watch id from a scanned/pasted payload of any supported shape.
  static String? decode(String raw) {
    final code = raw.trim();
    if (code.isEmpty) return null;

    if (code.startsWith(_legacyPrefix)) {
      final id = code.substring(_legacyPrefix.length).split('?').first;
      return id.isEmpty ? null : id;
    }

    final uri = Uri.tryParse(code);
    if (uri != null && uri.hasScheme) {
      final fromQuery = uri.queryParameters['watch'] ?? uri.queryParameters['pair'];
      if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

      if (uri.fragment.contains('?')) {
        final q = Uri.splitQueryString(uri.fragment.split('?').last);
        final fromHash = q['watch'] ?? q['pair'];
        if (fromHash != null && fromHash.isNotEmpty) return fromHash;
      }

      if (uri.pathSegments.isNotEmpty &&
          uri.pathSegments.last != 'pair.html' &&
          uri.pathSegments.last != 'index.html') {
        return uri.pathSegments.last;
      }
    }

    return code.contains('|') ? null : code;
  }

  /// Incoming browser URL after the user scanned the QR on another device.
  static String? fromCurrentLocation() => decode(Uri.base.toString());

  /// True when the QR would encode localhost, which iPhone cannot open.
  static bool get encodesUnreachableHost {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  static String _publicOrigin() {
    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return Uri.base.origin;
    }
    return 'https://nfbot.app';
  }
}
