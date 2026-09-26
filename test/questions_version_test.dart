import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The bundled question bank must be the website's current one.
///
/// tools/gen_data.py copies the website's questions-version.json (date,
/// counts, barcha.json hash) next to the bank. The first test catches a
/// half-finished or hand-edited sync; the second compares with the website
/// checkout on this machine and fails the run — and so tools/build_release.ps1
/// — when the site's questions changed after the last sync.
void main() {
  const dir = 'assets/tests-json';
  final local = File('$dir/questions-version.json');

  Map<String, dynamic> readMap(File f) =>
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  List<dynamic> readList(String path) =>
      jsonDecode(File(path).readAsStringSync()) as List<dynamic>;

  test('the bundled bank agrees with its own version file', () {
    expect(
      local.existsSync(),
      isTrue,
      reason: '$dir/questions-version.json yo‘q — python tools/gen_data.py ni ishga tushiring',
    );
    final v = readMap(local);
    const fix = 'sinxron yarim qolgan yoki qo‘lda tahrirlangan — python tools/gen_data.py';
    expect(readList('$dir/barcha.json').length, v['questions'], reason: 'barcha.json: $fix');
    expect(readList('$dir/free_ids.json').length, v['free'], reason: 'free_ids.json: $fix');
    final variants = Directory('$dir/variants')
        .listSync()
        .where((e) => RegExp(r'[\\/]v\d+\.json$').hasMatch(e.path))
        .length;
    expect(variants, v['variants'], reason: 'variants/: $fix');
  });

  final sitePublic = Platform.environment['AVTOSMART_SITE_PUBLIC'] ??
      '../../../variant-vision-quiz-main/public';
  final siteFile = File('$sitePublic/data/questions-version.json');

  test(
    'the bundled bank is the website’s current one',
    () {
      final site = readMap(siteFile);
      final mine = readMap(local);
      expect(
        mine['barchaSha256'],
        site['barchaSha256'],
        reason: 'Savollar eskirgan: ilovada ${mine['updated']} (${mine['questions']} savol), '
            'saytda ${site['updated']} (${site['questions']} savol) — '
            'python tools/gen_data.py ni ishga tushiring',
      );
    },
    skip: siteFile.existsSync()
        ? false
        : 'sayt nusxasi topilmadi ($sitePublic) — solishtirish o‘tkazib yuborildi',
  );
}
