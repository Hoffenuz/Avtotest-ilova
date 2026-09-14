class Option {
  final int id;
  final Map<String, String> texts; // uz_lat, uz_cyr, ru
  final bool isCorrect;

  Option({required this.id, required this.texts, required this.isCorrect});

  String getText(String lang) => texts[lang] ?? texts['uz_lat'] ?? '';

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      id: json['id'] as int,
      texts: {'uz_lat': json['text'] as String? ?? ''},
      isCorrect: json['is_correct'] as bool? ?? false,
    );
  }
}

class Question {
  final String globalId;
  final int ticketNum;
  final int order;
  final String? mediaUrl;
  final Map<String, String> texts; // uz_lat, uz_cyr, ru
  final Map<String, List<Option>> options; // uz_lat, uz_cyr, ru
  final Map<String, String>
  izoh; // uz_lat, uz_cyr, ru — explanation, PRO+online gated

  Question({
    required this.globalId,
    required this.ticketNum,
    required this.order,
    this.mediaUrl,
    required this.texts,
    required this.options,
    this.izoh = const {},
  });

  String getText(String lang) => texts[lang] ?? texts['uz_lat'] ?? '';

  List<Option> getOptions(String lang) =>
      options[lang] ?? options['uz_lat'] ?? [];

  String getIzoh(String lang) => izoh[lang] ?? izoh['uz_lat'] ?? '';

  bool get hasIzoh => izoh.values.any((v) => v.trim().isNotEmpty);

  factory Question.fromJson(Map<String, dynamic> json) {
    final taskInfo = json['task_info'] as Map<String, dynamic>? ?? {};
    final content = json['content'] as Map<String, dynamic>? ?? {};
    final izohJson = json['izoh'] as Map<String, dynamic>? ?? {};

    final texts = <String, String>{};
    final options = <String, List<Option>>{};
    final izoh = <String, String>{};

    for (final langKey in ['uz_lat', 'uz_cyr', 'ru']) {
      final langContent = content[langKey] as Map<String, dynamic>?;
      if (langContent != null) {
        texts[langKey] = langContent['text'] as String? ?? '';
        final opts = langContent['options'] as List<dynamic>? ?? [];
        options[langKey] = opts
            .map((o) => Option.fromJson(o as Map<String, dynamic>))
            .toList();
      }
      final izohText = izohJson[langKey] as String?;
      if (izohText != null && izohText.trim().isNotEmpty) {
        izoh[langKey] = izohText;
      }
    }

    String? mediaUrl = json['media_url'] as String?;
    if (mediaUrl != null && mediaUrl.isEmpty) mediaUrl = null;

    return Question(
      globalId: taskInfo['global_id'] as String? ?? '',
      ticketNum: taskInfo['ticket_num'] as int? ?? 0,
      order: taskInfo['order'] as int? ?? 0,
      mediaUrl: mediaUrl,
      texts: texts,
      options: options,
      izoh: izoh,
    );
  }

  /// Numeric id from JSON `global_id` (e.g. t_3_q_12 → 12).
  int get jsonId {
    final match = RegExp(r'_q_(\d+)$').firstMatch(globalId);
    if (match != null) return int.parse(match.group(1)!);
    return order;
  }

  String get idLabel => '#$jsonId';
}

class Topic {
  final String id;
  final String category;
  final Map<String, String> names; // uz_lat, uz_cyr, ru
  /// Themed source filename under assets/tests-json/themes/, or '' for the
  /// "all questions" pseudo-topic (id "31"), which loads the full bank instead.
  final String filename;

  const Topic({
    required this.id,
    required this.category,
    required this.names,
    required this.filename,
  });

  String getName(String lang) => names[lang] ?? names['uz_lat'] ?? '';

  /// Convenience default-language accessor for call sites without a language
  /// in scope (e.g. resolving a historical cloud result's label).
  String get name => getName('uz_lat');

  bool get isAllQuestions => filename.isEmpty;
}

class TestResult {
  final String? id;
  final String type; // 'topic', 'variant', 'practice'
  final String? testKey;
  final String label;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpentSeconds;
  final DateTime date;
  final bool isCompleted; // true only when all questions were answered

  TestResult({
    this.id,
    required this.type,
    this.testKey,
    required this.label,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpentSeconds,
    required this.date,
    this.isCompleted = false,
  });

  double get percentage =>
      totalQuestions > 0 ? correctAnswers / totalQuestions : 0;
  bool get isPassed => percentage >= 0.9;

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'type': type,
    if (testKey != null) 'testKey': testKey,
    'label': label,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'timeSpentSeconds': timeSpentSeconds,
    'date': date.toIso8601String(),
    'isCompleted': isCompleted,
  };

  factory TestResult.fromJson(Map<String, dynamic> json) => TestResult(
    id: json['id'] as String?,
    type: json['type'] as String,
    testKey: json['testKey'] as String?,
    label: json['label'] as String,
    totalQuestions: json['totalQuestions'] as int,
    correctAnswers: json['correctAnswers'] as int,
    timeSpentSeconds: json['timeSpentSeconds'] as int,
    date: DateTime.parse(json['date'] as String),
    isCompleted: json['isCompleted'] as bool? ?? false,
  );
}
