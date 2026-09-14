/// Content sections the website keeps in TypeScript rather than JSON:
/// "Yodlash kerak" (`src/lib/yodlashRaqamlari.ts`) and "Avtodrom"
/// (`src/lib/avtodromPenalties.ts`).
///
/// `tools/gen_sections.mjs` transpiles those files and writes
/// `assets/data/yodlash.json` / `assets/data/avtodrom.json`. It also converts
/// the website's UI language keys (`oz`/`uz`/`ru`) to the question-JSON keys
/// this app uses everywhere (`uz_lat`/`uz_cyr`/`ru`) — see the note in that
/// script about `uz` meaning different things in the two conventions.
library;

/// A `{uz_lat, uz_cyr, ru}` map with the app's usual fallback behaviour.
class Localized {
  final Map<String, String> _values;

  const Localized(this._values);

  factory Localized.fromJson(Map<String, dynamic> json) => Localized({
    for (final key in const ['uz_lat', 'uz_cyr', 'ru'])
      if (json[key] is String) key: json[key] as String,
  });

  String get(String lang) => _values[lang] ?? _values['uz_lat'] ?? '';

  bool get isEmpty => _values.values.every((v) => v.trim().isEmpty);
}

/// One "what → how much" line, e.g. *Yengil avtomobillar — 100 km/soat*.
class FactRow {
  final Localized label;
  final String value;
  final Localized unit;

  const FactRow({required this.label, required this.value, required this.unit});

  factory FactRow.fromJson(Map<String, dynamic> json) => FactRow(
    label: Localized.fromJson(json['label'] as Map<String, dynamic>),
    value: json['value'] as String? ?? '',
    unit: Localized.fromJson(json['unit'] as Map<String, dynamic>),
  );
}

class FactGroup {
  final Localized heading;
  final List<FactRow> rows;

  const FactGroup({required this.heading, required this.rows});

  factory FactGroup.fromJson(Map<String, dynamic> json) => FactGroup(
    heading: Localized.fromJson(json['heading'] as Map<String, dynamic>),
    rows: (json['rows'] as List<dynamic>)
        .map((r) => FactRow.fromJson(r as Map<String, dynamic>))
        .toList(growable: false),
  );
}

/// One of the nine "numbers worth memorising" topics.
class FactTopic {
  final String id;
  final Localized title;
  final Localized subtitle;
  final List<FactGroup> groups;

  const FactTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.groups,
  });

  factory FactTopic.fromJson(Map<String, dynamic> json) => FactTopic(
    id: json['id'] as String? ?? '',
    title: Localized.fromJson(json['title'] as Map<String, dynamic>),
    subtitle: Localized.fromJson(json['subtitle'] as Map<String, dynamic>),
    groups: (json['groups'] as List<dynamic>)
        .map((g) => FactGroup.fromJson(g as Map<String, dynamic>))
        .toList(growable: false),
  );

  int get rowCount => groups.fold(0, (sum, g) => sum + g.rows.length);
}

/// Severity of a driving-ground (avtodrom) penalty, as the official table
/// grades them. The strings match the website's `PenaltyLevel` union.
enum PenaltyLevel {
  kichik,
  orta,
  qopol;

  static PenaltyLevel? parse(String? raw) => switch (raw) {
    'kichik' => PenaltyLevel.kichik,
    'orta' => PenaltyLevel.orta,
    'qopol' => PenaltyLevel.qopol,
    _ => null,
  };
}

class PenaltyItem {
  /// Row number in the official table (1..32).
  final int no;
  final int points;
  final Localized text;

  /// Extra condition ("per 5 seconds", "per mistake"); absent for most rows.
  final Localized? note;

  const PenaltyItem({
    required this.no,
    required this.points,
    required this.text,
    this.note,
  });

  factory PenaltyItem.fromJson(Map<String, dynamic> json) {
    final note = json['note'];
    return PenaltyItem(
      no: (json['no'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      text: Localized.fromJson(json['text'] as Map<String, dynamic>),
      note: note is Map<String, dynamic> ? Localized.fromJson(note) : null,
    );
  }
}

class PenaltyGroup {
  final PenaltyLevel level;
  final Localized title;
  final List<PenaltyItem> items;

  const PenaltyGroup({
    required this.level,
    required this.title,
    required this.items,
  });

  factory PenaltyGroup.fromJson(Map<String, dynamic> json) => PenaltyGroup(
    level: PenaltyLevel.parse(json['level'] as String?) ?? PenaltyLevel.kichik,
    title: Localized.fromJson(json['title'] as Map<String, dynamic>),
    items: (json['items'] as List<dynamic>)
        .map((i) => PenaltyItem.fromJson(i as Map<String, dynamic>))
        .toList(growable: false),
  );
}
