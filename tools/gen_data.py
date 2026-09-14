#!/usr/bin/env python3
"""Regenerate assets/tests-json/ from the avtotestu.uz website's public/ data.

Source of truth: the variant-vision-quiz-main website repo, checked out as a
sibling project. Re-run this whenever the website's question bank changes.

Usage: python tools/gen_data.py [--web-public PATH]
"""
import argparse
import json
import os
import re
import shutil
import sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_WEB_PUBLIC = r'C:\Users\Vosster PC\Desktop\variant-vision-quiz-main\public'
DST = os.path.join(BASE, 'assets', 'tests-json')


def log(msg):
    print(msg, flush=True)


def load_json(path):
    with open(path, encoding='utf-8') as f:
        return json.load(f)


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False)


def copy_topics(web_public):
    src_dir = os.path.join(web_public, 'mavzuli2')
    dst_dir = os.path.join(DST, 'themes')
    if os.path.isdir(dst_dir):
        shutil.rmtree(dst_dir)
    os.makedirs(dst_dir, exist_ok=True)

    files = sorted(f for f in os.listdir(src_dir) if f.endswith('.json'))
    for f in files:
        shutil.copyfile(os.path.join(src_dir, f), os.path.join(dst_dir, f))
    log(f'themes: {len(files)} files copied')
    return files


def copy_variants(web_public):
    src_dir = os.path.join(web_public, 'data', 'variants')
    dst_dir = os.path.join(DST, 'variants')
    if os.path.isdir(dst_dir):
        shutil.rmtree(dst_dir)
    os.makedirs(dst_dir, exist_ok=True)

    files = sorted(
        (f for f in os.listdir(src_dir) if f.endswith('.json')),
        key=lambda f: int(re.search(r'\d+', f).group()),
    )
    total = 0
    for f in files:
        data = load_json(os.path.join(src_dir, f))
        num = int(re.search(r'\d+', f).group())
        # An exam ticket is 20 questions. The LAST one is the exception: it is
        # the ticket the website is still filling in (it grew 10 -> 19 when
        # t_63_q_11..19 were added), so it is allowed to be short but never
        # empty and never over-long. Pinning it to a literal count \u2014 as this
        # guard used to \u2014 made the generator abort every time the website
        # added a question, which is why the app's data went stale.
        if num == max(int(re.search(r'\d+', x).group()) for x in files):
            ok = 1 <= len(data) <= 20
            expected = '1..20 (last, still being filled in)'
        else:
            ok = len(data) == 20
            expected = '20'
        if not ok:
            sys.exit(
                f'ERROR: {f} has {len(data)} questions, expected {expected}. '
                'Website data shape changed \u2014 update this script\u2019s assumptions before continuing.'
            )
        total += len(data)
        shutil.copyfile(os.path.join(src_dir, f), os.path.join(dst_dir, f))
    log(f'variants: {len(files)} files copied ({total} questions total)')
    return files


def build_barcha(web_public):
    """Full question bank, copied from the website's `public/barcha.json`.

    THAT FILE IS THE SOURCE OF TRUTH (docs/MOBILE-CONTENT-PROMPT.md \u00a76.2). It
    is a strict superset of every themes/ and variants/ file: each of those
    repeats questions that live here, and a repeat that disagrees is by
    definition the stale copy.

    This used to be built by merging the topic files instead, which silently
    pinned the app to whatever wording those older files happened to carry:
    487 question/answer texts and 10 answer keys drifted away from the site,
    and the nine newest questions (t_63_q_11..19) \u2014 which no topic file
    contains \u2014 never reached the app at all.
    """
    src = os.path.join(web_public, 'barcha.json')
    bank = load_json(src)

    seen = set()
    for q in bank:
        gid = q.get('task_info', {}).get('global_id')
        if not gid:
            sys.exit(f'ERROR: {src} holds a question with no global_id.')
        if gid in seen:
            sys.exit(f'ERROR: {src} holds {gid} twice.')
        seen.add(gid)

    save_json(os.path.join(DST, 'barcha.json'), bank)
    log(f'barcha.json: {len(bank)} questions (source of truth, copied verbatim)')
    return bank


def build_free_ids(web_public, barcha):
    """Global ids of the free tier's question pool.

    The website serves free users a smaller bank (`free-*.json`, ~1009 of the
    1259 questions) and PRO users the whole thing. The app bundles the whole
    bank either way \u2014 it has to, it works offline \u2014 so the free/PRO split is
    reproduced with an id list the Real Exam draws from for non-PRO users,
    keeping the pool identical to the site's.
    """
    src = os.path.join(web_public, 'free-uz-lat.json')
    if not os.path.isfile(src):
        log(f'WARNING: {src} missing \u2014 free_ids.json not regenerated')
        return

    known = {q['task_info']['global_id'] for q in barcha}
    ids, unknown = [], []
    for q in load_json(src):
        gid = q.get('task_info', {}).get('global_id')
        if gid in known:
            ids.append(gid)
        else:
            unknown.append(gid)

    save_json(os.path.join(DST, 'free_ids.json'), ids)
    log(f'free_ids.json: {len(ids)} ids ({len(barcha) - len(ids)} PRO-only questions held back)')
    if unknown:
        log(f'  WARNING: {len(unknown)} free-tier ids are not in barcha.json: {unknown[:5]}')


def copy_image_sizes(web_root):
    """`[width, height]` of every question image, so the app can reserve the
    exact box before the picture decodes instead of letting the answer buttons
    jump down under the user's finger (docs/MOBILE-CONTENT-PROMPT.md \u00a77.1).
    """
    src = os.path.join(web_root, 'src', 'data', 'question-image-sizes.json')
    if not os.path.isfile(src):
        log(f'WARNING: {src} missing \u2014 image-sizes.json not regenerated')
        return

    data = load_json(src)
    save_json(os.path.join(DST, 'image-sizes.json'), data)
    log(f'image-sizes.json: {len(data.get("numbered", {}))} numbered + '
        f'{len(data.get("other", {}))} named entries')


def copy_road_signs(web_public):
    src = os.path.join(web_public, 'data', 'belgilar.json')
    dst = os.path.join(DST, 'belgilar.json')
    shutil.copyfile(src, dst)
    data = load_json(src)
    item_count = sum(len(g.get('items', [])) for g in data)
    log(f'belgilar.json: {len(data)} groups, {item_count} items')

    src_dir = os.path.join(web_public, 'belgilar')
    dst_dir = os.path.join(DST, 'belgilar_images')
    if os.path.isdir(dst_dir):
        shutil.rmtree(dst_dir)
    os.makedirs(dst_dir, exist_ok=True)

    referenced = {os.path.basename(item.get('src', '')) for g in data for item in g.get('items', [])}
    available = set(os.listdir(src_dir))
    missing = referenced - available

    n = 0
    for fname in sorted(referenced & available):
        shutil.copyfile(os.path.join(src_dir, fname), os.path.join(dst_dir, fname))
        n += 1
    log(f'belgilar_images: {len(referenced)} referenced, {n} copied '
        f'(skipped {len(available) - n} unreferenced of {len(available)} on disk)')
    if missing:
        log(f'  WARNING: {len(missing)} belgilar images referenced in JSON but missing from source: {sorted(missing)[:10]}')


def reconcile_images(web_public, question_sources):
    """Copy only the question images actually referenced by media_url across
    all copied JSON, replacing the app's current (likely stale/orphaned) image
    set with an atomic swap.
    """
    referenced = set()
    for questions in question_sources:
        for q in questions:
            m = (q.get('media_url') or '').strip()
            if m and not m.startswith('http'):
                referenced.add(os.path.basename(m))

    src_dir = os.path.join(web_public, 'images')
    tmp_dir = os.path.join(DST, 'images_new')
    dst_dir = os.path.join(DST, 'images')
    if os.path.isdir(tmp_dir):
        shutil.rmtree(tmp_dir)
    os.makedirs(tmp_dir, exist_ok=True)

    copied = 0
    missing = []
    for fname in sorted(referenced):
        src_path = os.path.join(src_dir, fname)
        if os.path.isfile(src_path):
            shutil.copyfile(src_path, os.path.join(tmp_dir, fname))
            copied += 1
        else:
            missing.append(fname)

    old_count = len(os.listdir(dst_dir)) if os.path.isdir(dst_dir) else 0
    if os.path.isdir(dst_dir):
        shutil.rmtree(dst_dir)
    os.rename(tmp_dir, dst_dir)

    log(f'images: {len(referenced)} referenced, {copied} copied, {len(missing)} missing-from-source')
    if missing:
        log(f'  missing: {missing[:20]}{"..." if len(missing) > 20 else ""}')
    log(f'  pruned: {old_count} -> {copied} files (removed {max(old_count - copied, 0)} orphaned)')


def cleanup_stray_files():
    for fname in ('favicon.ico', 'favicon-compressed.ico', 'logo.ico'):
        p = os.path.join(DST, fname)
        if os.path.isfile(p):
            os.remove(p)
            log(f'removed stray unused file: assets/tests-json/{fname}')


def _canonical(q):
    """Question payload without `task_info.order`, which is just its position
    inside its own file and legitimately differs between copies."""
    c = json.loads(json.dumps(q))
    c.get('task_info', {}).pop('order', None)
    return json.dumps(c, sort_keys=True, ensure_ascii=False)


def dedupe_question_files(barcha):
    """Rewrite themes/ and variants/ as lists of global ids.

    Every question in those files is already in barcha.json, so shipping the
    full payload three times added ~11 MB to the app for nothing. The app
    (QuestionService) resolves an id list against barcha.json and still accepts
    a full question bank, so any file whose content genuinely differs is left
    expanded rather than silently losing its own wording.
    """
    index = {q['task_info']['global_id']: _canonical(q) for q in barcha}
    before = after = 0
    converted = kept = 0

    for folder in ('themes', 'variants'):
        dir_path = os.path.join(DST, folder)
        for name in sorted(os.listdir(dir_path)):
            if not name.endswith('.json'):
                continue
            path = os.path.join(dir_path, name)
            data = load_json(path)
            if data and isinstance(data[0], str):
                continue

            ids = []
            ok = True
            for q in data:
                gid = q.get('task_info', {}).get('global_id')
                if gid not in index or _canonical(q) != index[gid]:
                    ok = False
                    log(f'  kept expanded ({folder}/{name}): {gid} differs from barcha.json')
                    break
                ids.append(gid)

            if not ok:
                kept += 1
                continue

            before += os.path.getsize(path)
            save_json(path, ids)
            after += os.path.getsize(path)
            converted += 1

    log(f'dedupe: {converted} files -> id lists, {kept} kept expanded, '
        f'{(before - after) / 1024 / 1024:.2f} MB saved')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--web-public', default=DEFAULT_WEB_PUBLIC,
                         help='Path to the website\u2019s public/ directory')
    args = parser.parse_args()
    web_public = args.web_public
    web_root = os.path.dirname(os.path.abspath(web_public))

    if not os.path.isdir(web_public):
        sys.exit(f'ERROR: website public dir not found: {web_public}')

    log('=== Regenerating assets/tests-json/ from website data ===')
    log(f'source: {web_public}')

    copy_topics(web_public)
    copy_variants(web_public)
    barcha = build_barcha(web_public)

    # Only barcha.json feeds the image set: themes/ and variants/ become id
    # lists into it below, so a picture referenced by neither is unreachable
    # from the app and would only bloat the download.
    reconcile_images(web_public, [barcha])

    build_free_ids(web_public, barcha)
    copy_image_sizes(web_root)
    copy_road_signs(web_public)
    dedupe_question_files(barcha)
    cleanup_stray_files()

    log('=== Done ===')


if __name__ == '__main__':
    main()
