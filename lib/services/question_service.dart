import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/question.dart';

/// Decodes a question-bank JSON string. Top-level so it can run in a
/// background isolate via [compute] — `barcha.json` alone is ~3.8 MB, and
/// parsing it on the UI isolate froze the app for a noticeable beat every
/// time a test, the mistakes list, or the saved list was opened.
List<Question> parseQuestionsJson(String jsonString) {
  final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
  return jsonList
      .map((item) => Question.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
}

class QuestionService {
  static Random _random = Random();

  /// Makes the practice/exam draw reproducible. Tests that compare two runs of
  /// the same screen need the same questions both times — otherwise they are
  /// comparing two different exams and fail at random.
  @visibleForTesting
  static void seedRandomForTest(int seed) {
    _random = Random(seed);
  }

  /// Parsed banks, most-recently-used last. Bounded so the full bank plus a
  /// few topic/variant files stay hot without growing without limit.
  static const int _maxCachedBanks = 5;
  static final LinkedHashMap<String, List<Question>> _cache =
      LinkedHashMap<String, List<Question>>();

  /// De-duplicates concurrent loads of the same asset (e.g. the difficult-
  /// questions pool requesting several topics at once).
  static final Map<String, Future<List<Question>>> _inFlight = {};

  /// Drops every parsed bank. Call on memory pressure.
  static void clearCache() {
    _cache.clear();
  }

  static Future<List<Question>> loadFromAsset(String assetPath) {
    final cached = _cache.remove(assetPath);
    if (cached != null) {
      _cache[assetPath] = cached; // refresh LRU position
      return SynchronousFuture(cached);
    }

    final pending = _inFlight[assetPath];
    if (pending != null) return pending;

    final future = _parseAsset(assetPath);
    _inFlight[assetPath] = future;
    return future.whenComplete(() => _inFlight.remove(assetPath));
  }

  static Future<List<Question>> _parseAsset(String assetPath) async {
    // cache: false — the raw JSON string is not kept around; only the parsed
    // objects are, which are what we actually reuse.
    final jsonString = await rootBundle.loadString(assetPath, cache: false);

    // Topic and variant files are stored as plain lists of global ids
    // (`["t_1_q_1", …]`) instead of repeating the questions themselves: every
    // one of them already lives in barcha.json, and duplicating the payload
    // cost ~11 MB of the shipped app. Full question banks are still accepted
    // so a non-migrated file keeps working.
    final questions = _looksLikeIdIndex(jsonString)
        ? await loadQuestionsByGlobalIds(
            (json.decode(jsonString) as List<dynamic>).cast<String>(),
          )
        : await compute(parseQuestionsJson, jsonString);

    _cache[assetPath] = questions;
    while (_cache.length > _maxCachedBanks) {
      _cache.remove(_cache.keys.first);
    }
    return questions;
  }

  /// A list of ids starts with `["`; a list of questions starts with `[{`.
  static bool _looksLikeIdIndex(String jsonString) {
    for (var i = 0; i < jsonString.length; i++) {
      final c = jsonString[i];
      if (c == ' ' || c == '\n' || c == '\r' || c == '\t' || c == '[') continue;
      return c == '"';
    }
    return false;
  }

  /// Parses the question bank ahead of the first screen that needs it.
  ///
  /// Measured cold: ~44 ms to read the 3.9 MB asset, ~50 ms to decode it,
  /// ~12 ms to build the objects — on a desktop. On the cheap Android phones
  /// most of this app's users have, that is comfortably a third of a second,
  /// and it was being paid at the exact moment a test was tapped, on top of a
  /// route transition. Doing it while the user is still looking at the home
  /// screen makes the first test open instantly instead.
  ///
  /// Safe to call more than once: it goes through the same cache and
  /// in-flight de-duplication as every other load.
  static Future<void> warmUp() async {
    try {
      await loadAllQuestions();
    } catch (e) {
      // A failed warm-up costs nothing: the real load will try again and
      // surface the error where it can be shown.
      debugPrint('QuestionService.warmUp: $e');
    }
  }

  static Future<List<Question>> loadTopicQuestions(String filename) async {
    return loadFromAsset('assets/tests-json/themes/$filename');
  }

  static Future<List<Question>> loadVariantQuestions(String filename) async {
    return loadFromAsset('assets/tests-json/variants/$filename');
  }

  static Future<List<Question>> loadAllQuestions() async {
    return loadFromAsset('assets/tests-json/barcha.json');
  }

  static Future<List<Question>> loadPracticeQuestions({int count = 20}) async {
    // Copy before shuffling — [loadAllQuestions] hands back the cached list.
    final all = List<Question>.of(await loadAllQuestions())..shuffle(_random);
    return all.take(count).toList();
  }

  /// Global ids of the free tier's question pool, as served by the website's
  /// `free-*.json` (1009 of the 1259 questions).
  ///
  /// The app bundles the whole bank — it has to, tests run offline — so the
  /// free/PRO split cannot be a matter of which file is downloaded the way it
  /// is on the site. This id list reproduces it instead, keeping the pool a
  /// free user draws an exam from identical to the website's.
  static List<String>? _freeIds;
  static Future<List<String>>? _freeIdsInFlight;

  static Future<List<String>> loadFreeQuestionIds() {
    final cached = _freeIds;
    if (cached != null) return SynchronousFuture(cached);
    return _freeIdsInFlight ??= _parseFreeIds().whenComplete(
      () => _freeIdsInFlight = null,
    );
  }

  static Future<List<String>> _parseFreeIds() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/tests-json/free_ids.json',
      );
      final ids = (json.decode(raw) as List<dynamic>).cast<String>();
      _freeIds = ids;
      return ids;
    } catch (e) {
      // A missing manifest must not lock a free user out of the exam. Falling
      // back to the whole bank is the generous direction to fail in: it hands
      // out a slightly wider pool, never a narrower one, and it never grants
      // access to anything actually gated (explanations stay PRO-only, and
      // they are not shown in the exam at all).
      debugPrint('QuestionService.loadFreeQuestionIds: $e');
      _freeIds = const [];
      return const [];
    }
  }

  /// A Real Exam draw: [count] questions picked at random, from the free pool
  /// for a free user and from the whole bank for a PRO one — the same split
  /// the website makes between `free-*.json` and `barcha-*.json`.
  static Future<List<Question>> loadExamQuestions({
    required bool isPro,
    int count = 20,
  }) async {
    final all = await loadAllQuestions();

    List<Question> pool;
    if (isPro) {
      pool = all;
    } else {
      final freeIds = (await loadFreeQuestionIds()).toSet();
      pool = freeIds.isEmpty
          ? all
          : all.where((q) => freeIds.contains(q.globalId)).toList();
      if (pool.isEmpty) pool = all;
    }

    final shuffled = List<Question>.of(pool)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  static Future<List<Question>> loadQuestionsByGlobalIds(
    List<String> globalIds,
  ) async {
    if (globalIds.isEmpty) return [];
    final all = await loadAllQuestions();
    final byId = {for (final q in all) q.globalId: q};
    return globalIds.map((id) => byId[id]).whereType<Question>().toList();
  }

  static Future<Question?> findQuestionByGlobalId(String globalId) async {
    final list = await loadQuestionsByGlobalIds([globalId]);
    return list.isEmpty ? null : list.first;
  }

  /// Matches the website's `topicCategories` (src/pages/MavzuliTestlar.tsx)
  /// exactly — same ids, category grouping, and per-language labels. Topic
  /// "31" (Barcha savollar) has no themed file; it's a pseudo-topic that
  /// routes to [loadAllQuestions] (see [Topic.isAllQuestions]).
  static List<Topic> getTopics() {
    return const [
      // ── Asosiy ──
      Topic(
        id: '31',
        category: 'asosiy',
        filename: '',
        names: {
          'uz_lat': 'Barcha savollar',
          'uz_cyr': 'Барча саволлар',
          'ru': 'Все вопросы',
        },
      ),
      Topic(
        id: '35a',
        category: 'asosiy',
        filename: '35a.json',
        names: {
          'uz_lat': 'Yangi savollar',
          'uz_cyr': 'Янги саволлар',
          'ru': 'Новые вопросы',
        },
      ),
      Topic(
        id: '1',
        category: 'asosiy',
        filename: '1.json',
        names: {
          'uz_lat': 'Umumiy qoidalar',
          'uz_cyr': 'Умумий қоидалар',
          'ru': 'Общие правила',
        },
      ),
      Topic(
        id: '2',
        category: 'asosiy',
        filename: '2.json',
        names: {
          'uz_lat': 'Haydovchining umumiy vazifalari',
          'uz_cyr': 'Ҳайдовчининг умумий вазифалари ва пиёдалар',
          'ru': 'Общие обязанности водителя и пешеходы',
        },
      ),
      // ── Yo'l belgilari ──
      Topic(
        id: '3',
        category: 'belgilar',
        filename: '3.json',
        names: {
          'uz_lat': 'Ogohlantiruvchi belgilar',
          'uz_cyr': 'Огоҳлантирувчи белгилар',
          'ru': 'Предупреждающие знаки',
        },
      ),
      Topic(
        id: '4',
        category: 'belgilar',
        filename: '4.json',
        names: {
          'uz_lat': 'Imtiyoz belgilar',
          'uz_cyr': 'Имтиёз белгилар',
          'ru': 'Знаки приоритета',
        },
      ),
      Topic(
        id: '5',
        category: 'belgilar',
        filename: '5.json',
        names: {
          'uz_lat': 'Taqiqlovchi belgilar',
          'uz_cyr': 'Тақиқловчи белгилар',
          'ru': 'Запрещающие знаки',
        },
      ),
      Topic(
        id: '6',
        category: 'belgilar',
        filename: '6.json',
        names: {
          'uz_lat': 'Buyuruvchi belgilar',
          'uz_cyr': 'Буюрувчи белгилар',
          'ru': 'Предписывающие знаки',
        },
      ),
      Topic(
        id: '7',
        category: 'belgilar',
        filename: '7.json',
        names: {
          'uz_lat': 'Axborot ishora belgilari',
          'uz_cyr': 'Ахборот ишора белгилари',
          'ru': 'Информационные знаки',
        },
      ),
      Topic(
        id: '8',
        category: 'belgilar',
        filename: '8.json',
        names: {
          'uz_lat': "Qo'shimcha axborot belgilari",
          'uz_cyr': 'Қўшимча ахборот белгилари',
          'ru': 'Дополнительные информационные знаки',
        },
      ),
      // ── Chorrahalar ──
      Topic(
        id: '20',
        category: 'chorrahalar',
        filename: '20.json',
        names: {
          'uz_lat': 'Chorrahalarda harakatlanish',
          'uz_cyr': 'Чорраҳаларда ҳаракатланиш',
          'ru': 'Движение на перекрестках',
        },
      ),
      Topic(
        id: '34',
        category: 'chorrahalar',
        filename: '34tengaxamiyatli.json',
        names: {
          'uz_lat': 'Teng ahamiyatli chorrahalar',
          'uz_cyr': 'Тенг аҳамиятли чорраҳалар',
          'ru': 'Равнозначные перекрестки',
        },
      ),
      Topic(
        id: '33',
        category: 'chorrahalar',
        filename: '33.json',
        names: {
          'uz_lat': "Tartibga solinmagan chorrahada asosiy yo'l",
          'uz_cyr': 'Тартибга солинмаган чорраҳада асосий йўл',
          'ru': 'Главная дорога на нерегулируемом перекрестке',
        },
      ),
      // ── Yo'l chiziqlari ──
      Topic(
        id: '9',
        category: 'chiziqlar',
        filename: '9.json',
        names: {
          'uz_lat': 'Yotiq chiziqlar 1',
          'uz_cyr': 'Ётиқ чизиқлар 1',
          'ru': 'Горизонтальная разметка 1',
        },
      ),
      Topic(
        id: '10',
        category: 'chiziqlar',
        filename: '10.json',
        names: {
          'uz_lat': 'Yotiq va tik chiziqlar 2',
          'uz_cyr': 'Ётиқ ва тик чизиқлар 2',
          'ru': 'Горизонтальная и вертикальная разметка 2',
        },
      ),
      // ── Svetafor va ishoralar ──
      Topic(
        id: '11',
        category: 'ishoralar',
        filename: '11.json',
        names: {
          'uz_lat': 'Svetafor ishoralari',
          'uz_cyr': 'Светафор ишоралари',
          'ru': 'Сигналы светофора',
        },
      ),
      Topic(
        id: '12',
        category: 'ishoralar',
        filename: '12.json',
        names: {
          'uz_lat': 'Tartibga soluvchining ishoralari',
          'uz_cyr': 'Тартибга солувчининг ишоралари',
          'ru': 'Сигналы регулировщика',
        },
      ),
      Topic(
        id: '13',
        category: 'ishoralar',
        filename: '13.json',
        names: {
          'uz_lat': 'Ogohlantiruvchi va avariya ishoralari',
          'uz_cyr': 'Огоҳлантирувчи ва авария ишоралари',
          'ru': 'Предупредительные и аварийные сигналы',
        },
      ),
      // ── Harakatlanish qoidalari ──
      Topic(
        id: '14',
        category: 'harakat',
        filename: '14.json',
        names: {
          'uz_lat': "Yo'llarda harakatlanish",
          'uz_cyr': 'Йўлларда ҳаракатланиш',
          'ru': 'Начало движения (Маневр)',
        },
      ),
      Topic(
        id: '15',
        category: 'harakat',
        filename: '15.json',
        names: {
          'uz_lat': 'Transport vositalarining joylashuvi',
          'uz_cyr': 'Tранспорт воситаларининг жойлашуви',
          'ru': 'Расположение транспортных средств на проезжей части',
        },
      ),
      Topic(
        id: '16',
        category: 'harakat',
        filename: '16.json',
        names: {
          'uz_lat': 'Harakatlanish tezligi',
          'uz_cyr': 'Ҳаракатланиш тезлиги',
          'ru': 'Скорость движения',
        },
      ),
      Topic(
        id: '17',
        category: 'harakat',
        filename: '17.json',
        names: {
          'uz_lat': "Quvib o'tish",
          'uz_cyr': 'Қувиб ўтиш',
          'ru': 'Обгон',
        },
      ),
      Topic(
        id: '18',
        category: 'harakat',
        filename: '18.json',
        names: {
          'uz_lat': "To'xtash va to'xtab turish qoidalari 1",
          'uz_cyr': 'Тўхташ ва тўхтаб туриш қоидалари 1',
          'ru': 'Правила остановки и стоянки 1',
        },
      ),
      Topic(
        id: '19',
        category: 'harakat',
        filename: '19.json',
        names: {
          'uz_lat': "To'xtash va to'xtab turish qoidalari 2",
          'uz_cyr': 'Тўхташ ва тўхтаб туриш қоидалари 2',
          'ru': 'Правила остановки и стоянки 2',
        },
      ),
      // ── Maxsus holatlar ──
      Topic(
        id: '21',
        category: 'maxsus',
        filename: '21.json',
        names: {
          'uz_lat': "Piyodalar o'tish joylari va turar joylar",
          'uz_cyr': 'Пиёдалар ўтиш жойлари ва турар жой',
          'ru': 'Пешеходные переходы и движение в жилых зонах',
        },
      ),
      Topic(
        id: '22',
        category: 'maxsus',
        filename: '22.json',
        names: {
          'uz_lat': "Temir yo'l kesishmalari va Avtomagistrallar",
          'uz_cyr': 'Темир йўл кесишмалари ва Автомагистраллар',
          'ru': 'Железнодорожные переезды и движение по автомагистралям',
        },
      ),
      Topic(
        id: '23',
        category: 'maxsus',
        filename: '23.json',
        names: {
          'uz_lat': "Yo'nalishli transport vositalarining imtiyozlari",
          'uz_cyr': 'Йўналишли транспорт воситаларининг имтиёзлари',
          'ru': 'Преимущества маршрутных транспортных средств',
        },
      ),
      Topic(
        id: '24',
        category: 'maxsus',
        filename: '24.json',
        names: {
          'uz_lat': 'Shatakka olish',
          'uz_cyr': 'Транспорт воситаларини шатакка олиш',
          'ru': 'Буксировка транспортных средств',
        },
      ),
      Topic(
        id: '25',
        category: 'maxsus',
        filename: '25.json',
        names: {
          'uz_lat': "Yo'l harakati xavfsizligini ta'minlash",
          'uz_cyr': 'Йўл ҳаракати хавфсизлигини таъминлаш',
          'ru': 'Обучение вождению',
        },
      ),
      Topic(
        id: '26',
        category: 'maxsus',
        filename: '26.json',
        names: {
          'uz_lat': 'Odam va yuk tashish',
          'uz_cyr': 'Одам ва юк ташиш',
          'ru': 'Перевозка людей и грузов',
        },
      ),
      Topic(
        id: '27',
        category: 'maxsus',
        filename: '27.json',
        names: {
          'uz_lat': 'Harakatlanish taqiqlanadigan vaziyatlar',
          'uz_cyr': 'ҳаракатланиш тақиқланадиган вазиятлар',
          'ru': 'Ситуации, когда запрещено движение транспортных средств',
        },
      ),
      // ── Xavfsizlik va yordam ──
      Topic(
        id: '28',
        category: 'xavfsizlik',
        filename: '28.json',
        names: {
          'uz_lat': "Harakat xavfsizligini ta'minlash 1",
          'uz_cyr': 'Ҳаракат хавфсизлигини таъминлаш 1',
          'ru': 'Обеспечение безопасности движения 1',
        },
      ),
      Topic(
        id: '29',
        category: 'xavfsizlik',
        filename: '29.json',
        names: {
          'uz_lat': "Harakat xavfsizligini ta'minlash 2",
          'uz_cyr': 'Ҳаракат хавфсизлигини таъминлаш 2',
          'ru': 'Обеспечение безопасности движения 2',
        },
      ),
      Topic(
        id: '30',
        category: 'xavfsizlik',
        filename: '30.json',
        names: {
          'uz_lat': 'Birinchi tibbiy yordam',
          'uz_cyr': 'Биринчи тиббий ёрдам',
          'ru': 'Первая медицинская помощь',
        },
      ),
    ];
  }

  /// Category order + labels matching the website's `topicCategories`.
  static const List<MapEntry<String, Map<String, String>>> topicCategoryOrder =
      [
        MapEntry('asosiy', {
          'uz_lat': 'Asosiy',
          'uz_cyr': 'Асосий',
          'ru': 'Основное',
        }),
        MapEntry('belgilar', {
          'uz_lat': "Yo'l belgilari",
          'uz_cyr': 'Йўл белгилари',
          'ru': 'Дорожные знаки',
        }),
        MapEntry('chorrahalar', {
          'uz_lat': 'Chorrahalar',
          'uz_cyr': 'Чорраҳалар',
          'ru': 'Перекрестки',
        }),
        MapEntry('chiziqlar', {
          'uz_lat': "Yo'l chiziqlari",
          'uz_cyr': 'Йўл чизиқлари',
          'ru': 'Дорожная разметка',
        }),
        MapEntry('ishoralar', {
          'uz_lat': 'Svetafor va ishoralar',
          'uz_cyr': 'Светафор ва ишоралар',
          'ru': 'Светофор и сигналы',
        }),
        MapEntry('harakat', {
          'uz_lat': 'Harakatlanish qoidalari',
          'uz_cyr': 'Ҳаракатланиш қоидалари',
          'ru': 'Правила движения',
        }),
        MapEntry('maxsus', {
          'uz_lat': 'Maxsus holatlar',
          'uz_cyr': 'Махсус ҳолатлар',
          'ru': 'Особые условия',
        }),
        MapEntry('xavfsizlik', {
          'uz_lat': 'Xavfsizlik va yordam',
          'uz_cyr': 'Хавфсизлик ва ёрдам',
          'ru': 'Безопасность и помощь',
        }),
      ];

  /// Must equal the number of files under assets/tests-json/variants/ —
  /// test/question_assets_test.dart fails when a sync adds one and this
  /// is left behind (the ticket would be bundled but never listed).
  static const int variantCount = 64;

  static List<String> getVariantFiles() {
    return List.generate(variantCount, (i) => 'v${i + 1}.json');
  }
}
