import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../config/supabase_config.dart';

/// Real reachability check, not just interface state — a device can report
/// "connected" to Wi-Fi with no actual internet access, which interface-only
/// checks (connectivity_plus alone) can't detect. Probes the app's own
/// backend host, since that's what actually matters for PRO/explanation
/// gating: if it can't be reached, the feature can't work regardless of
/// whether some other host would respond.
class ConnectivityService {
  ConnectivityService._();

  static String get _probeHost => Uri.parse(SupabaseConfig.url).host;

  /// How long a probe result may be reused.
  ///
  /// Reachability does not change from one tap to the next, but the probe was
  /// being paid for on every one: opening a PRO topic ran it, then the
  /// explanation panel ran it again, each costing a DNS round trip of up to
  /// four seconds on a weak connection. That was most of the delay between
  /// tapping a topic and seeing it.
  static const Duration _cacheTtl = Duration(seconds: 8);

  /// Long enough for a slow mobile network, short enough not to feel frozen.
  static const Duration _lookupTimeout = Duration(seconds: 3);

  static bool? _cached;
  static DateTime? _cachedAt;
  static Future<bool>? _inFlight;

  /// Drops the cached answer — call when a retry must really re-probe.
  static void invalidateCache() {
    _cached = null;
    _cachedAt = null;
  }

  static Future<bool> isOnline() {
    final cached = _cached;
    final at = _cachedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < _cacheTtl) {
      return Future.value(cached);
    }

    // Concurrent callers share one probe instead of each opening their own.
    return _inFlight ??= _probe().whenComplete(() => _inFlight = null);
  }

  static Future<bool> _probe() async {
    var online = false;
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.every((r) => r == ConnectivityResult.none)) {
        _remember(false);
        return false;
      }
    } catch (_) {
      // Plugin failure shouldn't block the reachability probe below.
    }

    try {
      final result = await InternetAddress.lookup(
        _probeHost,
      ).timeout(_lookupTimeout);
      online = result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }

    _remember(online);
    return online;
  }

  static void _remember(bool value) {
    _cached = value;
    _cachedAt = DateTime.now();
  }

  /// Emits a fresh reachability check whenever the OS reports a connectivity
  /// change (e.g. Wi-Fi ↔ mobile data ↔ none).
  static Stream<bool> get onStatusChange =>
      Connectivity().onConnectivityChanged.asyncMap((_) {
        // The interface just changed, so any cached answer is stale by
        // definition.
        invalidateCache();
        return isOnline();
      });
}
