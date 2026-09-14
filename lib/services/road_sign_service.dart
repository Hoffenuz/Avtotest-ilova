import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/road_sign.dart';

class RoadSignService {
  RoadSignService._();

  static List<RoadSignGroup>? _cache;

  static Future<List<RoadSignGroup>> loadGroups() async {
    final cached = _cache;
    if (cached != null) return cached;

    final jsonString = await rootBundle.loadString(
      'assets/tests-json/belgilar.json',
    );
    final list = json.decode(jsonString) as List<dynamic>;
    final groups = list
        .map((g) => RoadSignGroup.fromJson(g as Map<String, dynamic>))
        .toList();
    _cache = groups;
    return groups;
  }
}
