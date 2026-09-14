class RoadSign {
  final String src;
  final String code;
  final Map<String, String> titles; // uz_lat, uz_cyr, ru

  const RoadSign({required this.src, required this.code, required this.titles});

  String getTitle(String lang) => titles[lang] ?? titles['uz_lat'] ?? '';

  /// Bundled asset filename — belgilar_images/ is a flat folder, so only the
  /// basename of the source website's `/belgilar/<file>` path is kept.
  String get assetFileName {
    final parts = src.split('/');
    return parts.isEmpty ? src : parts.last;
  }

  factory RoadSign.fromJson(Map<String, dynamic> json) {
    final titleJson = json['title'] as Map<String, dynamic>? ?? {};
    return RoadSign(
      src: json['src'] as String? ?? '',
      code: json['code'] as String? ?? '',
      titles: {
        for (final lang in ['uz_lat', 'uz_cyr', 'ru'])
          if (titleJson[lang] != null) lang: titleJson[lang] as String,
      },
    );
  }
}

class RoadSignGroup {
  final Map<String, String> titles; // uz_lat, uz_cyr, ru
  final List<RoadSign> items;

  const RoadSignGroup({required this.titles, required this.items});

  String getTitle(String lang) => titles[lang] ?? titles['uz_lat'] ?? '';

  factory RoadSignGroup.fromJson(Map<String, dynamic> json) {
    final titleJson = json['title'] as Map<String, dynamic>? ?? {};
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return RoadSignGroup(
      titles: {
        for (final lang in ['uz_lat', 'uz_cyr', 'ru'])
          if (titleJson[lang] != null) lang: titleJson[lang] as String,
      },
      items: itemsJson
          .map((i) => RoadSign.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}
