#!/usr/bin/env node
// ============================================================================
// gen_sections.mjs — regenerate assets/data/ from the website's TypeScript
// ----------------------------------------------------------------------------
// Two of the website's sections keep their content in TypeScript rather than
// JSON: "Yodlash kerak" (src/lib/yodlashRaqamlari.ts) and "Avtodrom"
// (src/lib/avtodromPenalties.ts). The app cannot read those, and hand-copying
// them means the app goes stale the moment the site is edited
// (docs/MOBILE-CONTENT-PROMPT.md §1.6 and §10.2), so they are transpiled and
// evaluated here instead.
//
// LANGUAGE KEYS — THE TRAP (docs/MOBILE-CONTENT-PROMPT.md §2):
//   The website uses TWO different conventions and `uz` means opposite things
//   in them. Question JSON uses `uz_lat` / `uz_cyr` / `ru`; the `Localized`
//   type these two files use is `oz` (latin) / `uz` (cyrillic) / `ru`.
//   Everything the app reads uses the question-JSON convention, so the
//   translation happens HERE, once, on the way in — never in the app.
//
// Usage: node tools/gen_sections.mjs [--web-root PATH]
// ============================================================================

import { createRequire } from 'node:module';
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const BASE = dirname(dirname(fileURLToPath(import.meta.url)));
const DEFAULT_WEB_ROOT = 'C:\\Users\\Vosster PC\\Desktop\\variant-vision-quiz-main';

const argIndex = process.argv.indexOf('--web-root');
const WEB_ROOT = argIndex === -1 ? DEFAULT_WEB_ROOT : process.argv[argIndex + 1];
const OUT_DIR = join(BASE, 'assets', 'data');

/** esbuild is the website's dev dependency; this tool borrows it. */
const require = createRequire(join(WEB_ROOT, 'package.json'));
let esbuild;
try {
  esbuild = require('esbuild');
} catch {
  console.error(
    `ERROR: esbuild not found under ${WEB_ROOT}/node_modules.\n` +
      'Run `npm install` in the website repo, or pass --web-root.',
  );
  process.exit(1);
}

/**
 * The two source files import icon components from `lucide-react` purely to
 * render them on the web. The app draws its own icons, so the import is
 * answered with a stub rather than pulling React into this script.
 */
const stubLucide = {
  name: 'stub-lucide',
  setup(build) {
    build.onResolve({ filter: /^lucide-react$/ }, () => ({
      path: 'lucide-react',
      namespace: 'stub',
    }));
    // Deliberately CommonJS: with an ESM stub esbuild checks every named
    // import against the stub's export list and fails on the first icon.
    // A CJS module has no statically known exports, so any name resolves.
    build.onLoad({ filter: /.*/, namespace: 'stub' }, () => ({
      contents: 'module.exports = new Proxy({}, { get: () => null });',
      loader: 'js',
    }));
  },
};

async function loadSiteModule(relPath, exportNames) {
  const entry = join(WEB_ROOT, relPath);
  const result = await esbuild.build({
    stdin: {
      contents: exportNames
        .map((n) => `export { ${n} } from ${JSON.stringify(entry.replace(/\\/g, '/'))};`)
        .join('\n'),
      resolveDir: dirname(entry),
      loader: 'ts',
    },
    bundle: true,
    format: 'esm',
    platform: 'node',
    write: false,
    plugins: [stubLucide],
    logLevel: 'silent',
  });

  const code = result.outputFiles[0].text;
  const url = 'data:text/javascript;base64,' + Buffer.from(code, 'utf8').toString('base64');
  return import(url);
}

// ────────────────────────────────────────────────────────── language mapping

/** `{oz, uz, ru}` (website UI convention) → `{uz_lat, uz_cyr, ru}` (app). */
function localized(value, where) {
  if (!value || typeof value !== 'object') {
    throw new Error(`${where}: expected a Localized object, got ${JSON.stringify(value)}`);
  }
  const out = { uz_lat: value.oz, uz_cyr: value.uz, ru: value.ru };
  for (const [key, text] of Object.entries(out)) {
    if (typeof text !== 'string' || text.trim() === '') {
      throw new Error(`${where}: ${key} is empty — every string must exist in all three languages`);
    }
  }
  return out;
}

// ──────────────────────────────────────────────────────────────── converters

function convertFactTopics(topics) {
  return topics.map((topic, i) => {
    const at = `yodlash[${i}] (${topic.id})`;
    if (!topic.id) throw new Error(`${at}: missing id`);
    return {
      id: topic.id,
      title: localized(topic.title, `${at}.title`),
      subtitle: localized(topic.subtitle, `${at}.subtitle`),
      groups: topic.groups.map((group, g) => ({
        heading: localized(group.heading, `${at}.groups[${g}].heading`),
        rows: group.rows.map((row, r) => {
          const rowAt = `${at}.groups[${g}].rows[${r}]`;
          if (typeof row.value !== 'string' || row.value.trim() === '') {
            throw new Error(`${rowAt}: missing value`);
          }
          return {
            label: localized(row.label, `${rowAt}.label`),
            value: row.value,
            unit: localized(row.unit, `${rowAt}.unit`),
          };
        }),
      })),
    };
  });
}

const PENALTY_LEVELS = new Set(['kichik', 'orta', 'qopol']);

function convertPenaltyGroups(groups) {
  return groups.map((group, i) => {
    const at = `avtodrom[${i}] (${group.level})`;
    if (!PENALTY_LEVELS.has(group.level)) {
      throw new Error(`${at}: unknown level — expected one of ${[...PENALTY_LEVELS].join(', ')}`);
    }
    return {
      level: group.level,
      title: localized(group.title, `${at}.title`),
      items: group.items.map((item, n) => {
        const itemAt = `${at}.items[${n}]`;
        if (!Number.isInteger(item.no) || !Number.isInteger(item.points)) {
          throw new Error(`${itemAt}: \`no\` and \`points\` must be whole numbers`);
        }
        return {
          no: item.no,
          points: item.points,
          text: localized(item.text, `${itemAt}.text`),
          // Optional in the source: only some penalties carry a condition
          // ("per 5 seconds", "per mistake").
          note: item.note ? localized(item.note, `${itemAt}.note`) : null,
        };
      }),
    };
  });
}

// ─────────────────────────────────────────────────────────────────────── run

function write(name, data) {
  mkdirSync(OUT_DIR, { recursive: true });
  writeFileSync(join(OUT_DIR, name), JSON.stringify(data), 'utf8');
  return join('assets', 'data', name);
}

const yodlashMod = await loadSiteModule('src/lib/yodlashRaqamlari.ts', ['FACT_TOPICS']);
const avtodromMod = await loadSiteModule('src/lib/avtodromPenalties.ts', ['PENALTY_GROUPS']);

const yodlash = convertFactTopics(yodlashMod.FACT_TOPICS);
const avtodrom = convertPenaltyGroups(avtodromMod.PENALTY_GROUPS);

const rowCount = yodlash.reduce(
  (sum, t) => sum + t.groups.reduce((s, g) => s + g.rows.length, 0),
  0,
);
const itemCount = avtodrom.reduce((sum, g) => sum + g.items.length, 0);

console.log(`=== Regenerating assets/data/ from ${WEB_ROOT} ===`);
console.log(`${write('yodlash.json', yodlash)}: ${yodlash.length} topics, ${rowCount} rows`);
console.log(`${write('avtodrom.json', avtodrom)}: ${avtodrom.length} groups, ${itemCount} penalties`);

// The official table is numbered 1..32 with no gaps; a missing number means a
// penalty was lost in transit rather than deliberately removed.
const numbers = avtodrom.flatMap((g) => g.items.map((i) => i.no)).sort((a, b) => a - b);
const gaps = numbers.filter((n, i) => i > 0 && n !== numbers[i - 1] + 1);
if (numbers[0] !== 1 || gaps.length > 0) {
  console.log(`  WARNING: penalty numbering is not 1..${numbers.at(-1)} without gaps`);
}
console.log('=== Done ===');
