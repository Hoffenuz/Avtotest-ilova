import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/site_content.dart';

/// Loads the two bundled reference sections. Both are small (a few KB) and
/// read-only, so each is parsed once and kept for the process's lifetime.
class SiteContentService {
  SiteContentService._();

  static List<FactTopic>? _factTopics;
  static List<PenaltyGroup>? _penaltyGroups;
  static Future<List<FactTopic>>? _factTopicsInFlight;
  static Future<List<PenaltyGroup>>? _penaltyGroupsInFlight;

  /// "Yodlash kerak" — nine topics of numbers worth memorising.
  static Future<List<FactTopic>> loadFactTopics() {
    final cached = _factTopics;
    if (cached != null) return SynchronousFuture(cached);
    return _factTopicsInFlight ??=
        _load('assets/data/yodlash.json', FactTopic.fromJson).then((value) {
          _factTopics = value;
          _factTopicsInFlight = null;
          return value;
        });
  }

  /// "Avtodrom" — the practical exam's penalty-point table.
  static Future<List<PenaltyGroup>> loadPenaltyGroups() {
    final cached = _penaltyGroups;
    if (cached != null) return SynchronousFuture(cached);
    return _penaltyGroupsInFlight ??=
        _load('assets/data/avtodrom.json', PenaltyGroup.fromJson).then((value) {
          _penaltyGroups = value;
          _penaltyGroupsInFlight = null;
          return value;
        });
  }

  static Future<List<T>> _load<T>(
    String assetPath,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final list = json.decode(raw) as List<dynamic>;
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
