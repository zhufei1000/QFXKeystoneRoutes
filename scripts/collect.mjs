/**
 * QFXKeystoneRoutes —— keystone.guru 大秘境路线采集器
 *
 * 数据源（全部匿名公开，不需要账号）:
 *   1) GET /routes/retail/{slug}              列表页(SSR) -> 该副本榜单顺序 + 收藏量
 *   2) GET /route/{slug}/{pk}/{titleSlug}     详情页(内联 JSON) -> 层数/热度/作者/词缀
 *   3) GET /ajax/{pk}/mdtExport?...            MDT 原生路线串
 *
 * 输出:
 *   data/meta.json          每副本 top-N 的元数据(不含路线串,体积小)
 *   data/routes/{slug}.json  每副本的 mdt_string 列表(体积大,单独分片)
 *   data/manifest.json       数据版本
 *   data/Data.lua            打包后的压缩数据(供插件直接加载)
 *
 * 用法:
 *   node scripts/collect.mjs                 全量采集
 *   node scripts/collect.mjs --limit 18      每副本条数(默认 18,不翻页)
 *   node scripts/collect.mjs --incremental   增量(只重抓变化条目)
 */

import { writeFileSync, readFileSync, existsSync, mkdirSync } from 'node:fs';
import { buildPack } from './pack-data.mjs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');
const DATA_DIR = join(ROOT, 'data');
const OUT_DIR = join(ROOT, 'data');

const BASE = 'https://keystone.guru';
const UA = process.env.KG_USER_AGENT
  || 'QFXKeystoneRoutes-collector/1.0 (addon data pipeline; contact: local user)';

const ARGS = process.argv.slice(2);
const opt = (name, dflt) => {
  const i = ARGS.indexOf('--' + name);
  return i >= 0 && ARGS[i + 1] && !ARGS[i + 1].startsWith('--') ? ARGS[i + 1] : dflt;
};
const has = name => ARGS.includes('--' + name);

const LIMIT = parseInt(opt('limit', '18'), 10);
const INCREMENTAL = has('incremental');
const SLEEP_MS = parseInt(opt('sleep', '160'), 10);
// 最短采集间隔(小时): 每天 cron 触发, 由本脚本判断是否真的满 48h
const MIN_INTERVAL_H = parseInt(opt('min-interval-hours', '0'), 10);
const FORCE = has('force') || process.env.FORCE === 'true' || process.env.FORCE === '1';

const H_HTML = { 'User-Agent': UA, Accept: 'text/html,application/xhtml+xml' };
const H_JSON = { 'User-Agent': UA, 'X-Requested-With': 'XMLHttpRequest', Accept: 'application/json, text/plain, */*' };
const REQUEST_TIMEOUT_MS = parseInt(opt('request-timeout-ms', '30000'), 10);
// 整轮采集的硬截止时间。超时直接失败，不写入任何半成品数据。
const DEADLINE_MIN = parseInt(opt('deadline-minutes', '20'), 10);
const STARTED_AT = Date.now();

const sleep = ms => new Promise(r => setTimeout(r, ms));
const jitter = (base, spread) => base + Math.floor(Math.random() * spread);

function checkDeadline() {
  if (Date.now() - STARTED_AT > DEADLINE_MIN * 60000) {
    throw new Error(`collection deadline (${DEADLINE_MIN} min) exceeded; refusing to write partial data`);
  }
}

/** fetch + HTTP status validation. A 403/404/500 page must never be parsed as data. */
async function request(url, headers, label) {
  const res = await fetch(url, { headers, signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS) });
  if (!res.ok) {
    const retryAfter = res.headers.get('retry-after');
    const error = new Error(`${label}: HTTP ${res.status}${retryAfter ? ` (retry-after ${retryAfter}s)` : ''}`);
    error.status = res.status;
    error.retryAfter = retryAfter;
    throw error;
  }
  return res;
}

async function fetchText(url, headers, label) {
  return (await request(url, headers, label)).text();
}

async function fetchJson(url, headers, label) {
  const text = await (await request(url, headers, label)).text();
  try {
    return JSON.parse(text);
  } catch {
    throw new Error(`${label}: response is not valid JSON`);
  }
}

function extractBalanced(s, i) {
  let d = 0, q = false, e = false;
  for (let k = i; k < s.length; k++) {
    const c = s[k];
    if (q) { if (e) { e = false; continue } if (c === '\\') { e = true; continue } if (c === '"') q = false; continue; }
    if (c === '"') { q = true; continue; }
    if (c === '{') d++; else if (c === '}') { d--; if (!d) return s.slice(i, k + 1); }
  }
  return null;
}

/** 详情页里内联的完整路线对象 */
async function fetchRouteDetail(slug, pk, titleSlug) {
  const url = `${BASE}/route/${slug}/${pk}/${titleSlug}`;
  const html = await fetchText(url, H_HTML, `detail ${pk}`);

  let i = -1, from = 0;
  while (true) {
    const k = html.indexOf('_inlineManager.init(', from);
    if (k < 0) break;
    if (html.slice(k, k + 300).includes('common/maps/map')) { i = k; break; }
    from = k + 1;
  }
  if (i < 0) throw new Error('no map blob in ' + url);
  const dr = JSON.parse(extractBalanced(html, html.indexOf('{', i))).dungeonroute;

  const m = html.match(/"mdtExportUrl":"([^"]+)"/);
  if (!m) throw new Error('no mdtExportUrl in ' + url);
  const mdtUrl = m[1].replace(/\\\//g, '/');

  const exp = await fetchJson(BASE + mdtUrl, { ...H_JSON, Referer: url }, `mdtExport ${pk}`);
  if (!exp.mdt_string) throw new Error('no mdt_string for ' + pk);

  return {
    meta: {
      pk: dr.public_key,
      t: dr.title,
      lm: dr.level_min, lx: dr.level_max,
      v: dr.views, ve: dr.views_embed,
      p: dr.popularity,
      rt: dr.rating, rc: dr.rating_count,
      a: dr.author && dr.author.name,
      ap: dr.author && dr.author.public_key,
      sx: dr.season_id,
      mv: dr.mapping_version_id,
      mcp: !!(dr.mapping_version && dr.mapping_version.mdt_changes_pending),
      pub: dr.published,
      kg: dr.dungeon && dr.dungeon.id,
      af: (dr.affixes && dr.affixes[0] && dr.affixes[0].affixes || [])
        .map(a => ({ i: a.affix_id, k: a.key })),
    },
    mdt: exp.mdt_string,
    warnings: exp.warnings || [],
  };
}

/** 列表页 -> [{pk, titleSlug, title, favorites, rank}] */
function parseListPage(html) {
  const out = [];
  const seen = new Set();
  const chunks = html.split('card_dungeonroute').slice(1);
  for (const c of chunks) {
    const m = c.match(/\/route\/([a-z0-9-]+)\/([A-Za-z0-9]{7})\/([a-z0-9-]+)/);
    if (!m) continue;
    const [, slug, pk, titleSlug] = m;
    if (seen.has(pk)) continue;
    seen.add(pk);
    const fav = (c.match(/title="(\d+) favorites"/) || [])[1];
    const title = (c.match(/hero_title">\s*<a[^>]*>\s*([\s\S]{0,120}?)\s*</) || [])[1];
    out.push({
      slug, pk, titleSlug,
      title: title ? title.replace(/\s+/g, ' ').trim() : null,
      favorites: fav ? parseInt(fav, 10) : null,
    });
    if (out.length >= LIMIT) break;
  }
  return out;
}

async function withRetry(label, fn, tries = 3) {
  let last;
  for (let t = 0; t < tries; t++) {
    try { return await fn(); } catch (e) {
      last = e;
      console.warn(`  ! ${label} failed (${t + 1}/${tries}): ${e.message}`);
      if (t === tries - 1) break;
      const retryAfter = Number(e.retryAfter);
      const waitMs = Number.isFinite(retryAfter) && retryAfter > 0
        ? Math.min(retryAfter * 1000, 15000)
        : 800 * (t + 1);
      await sleep(waitMs);
    }
  }
  throw last;
}

async function main() {
  mkdirSync(join(DATA_DIR, 'routes'), { recursive: true });
  mkdirSync(OUT_DIR, { recursive: true });

  // 旧数据用于增量比对
  const prevMetaPath = join(DATA_DIR, 'meta.json');
  const prevMeta = existsSync(prevMetaPath) ? JSON.parse(readFileSync(prevMetaPath, 'utf8')) : null;

  console.log(`QFXKeystoneRoutes collector | limit=${LIMIT} incremental=${INCREMENTAL}`);

  // 0) 最短间隔闸门: 避免每天的 cron 真的每天都抓一遍
  const manifestPath = join(DATA_DIR, 'manifest.json');
  if (MIN_INTERVAL_H > 0 && !FORCE && existsSync(manifestPath)) {
    try {
      const prev = JSON.parse(readFileSync(manifestPath, 'utf8'));
      const ageH = (Date.now() - Date.parse(prev.generatedAt)) / 3600000;
      if (Number.isFinite(ageH) && ageH < MIN_INTERVAL_H) {
        console.log(`距上次采集仅 ${ageH.toFixed(1)}h (< ${MIN_INTERVAL_H}h)，跳过。`);
        console.log('如需强制采集: --force 或设置 FORCE=1');
        return;
      }
      console.log(`距上次采集 ${ageH.toFixed(1)}h，可以采集。`);
    } catch { /* manifest 损坏则忽略闸门 */ }
  }

  // 1) 当前零售赛季副本列表
  const indexHtml = await withRetry('index', () =>
    fetchText(`${BASE}/routes/retail`, H_HTML, 'dungeon index'));
  const slugs = [...new Set([...indexHtml.matchAll(/href="https:\/\/keystone\.guru\/routes\/retail\/([a-z0-9-]+)"/g)]
    .map(m => m[1]))];
  if (!slugs.length) throw new Error('dungeon index returned no slugs; refusing to overwrite existing data');
  console.log(`dungeons (${slugs.length}): ${slugs.join(', ')}`);

  const meta = { dungeons: {} };
  const routeFiles = {};
  let reqCount = 0, routeCount = 0;

  for (const slug of slugs) {
    checkDeadline();
    console.log(`\n[${slug}]`);
    const listHtml = await withRetry(`${slug} list`, () =>
      fetchText(`${BASE}/routes/retail/${slug}`, H_HTML, `${slug} list`));
    reqCount++;
    await sleep(jitter(SLEEP_MS, 120));

    const entries = parseListPage(listHtml);
    if (!entries.length) throw new Error(`${slug}: list page returned no routes; refusing to overwrite existing data`);
    console.log(`  list entries: ${entries.length}`);

    const recs = [];
    const strings = [];

    for (let i = 0; i < entries.length; i++) {
      checkDeadline();
      const e = entries[i];

      let detail;
      try {
        detail = await withRetry(`${slug}#${i} ${e.pk}`, () =>
          fetchRouteDetail(e.slug, e.pk, e.titleSlug));
      } catch (err) {
        console.warn(`  - skip ${e.pk}: ${err.message}`);
        continue;
      }
      reqCount += 2; // detail + mdtExport
      await sleep(jitter(SLEEP_MS, 120));

      const m = detail.meta;
      m.r = i + 1;                          // 榜单名次
      m.f = e.favorites ?? 0;               // 收藏量(仅列表页可见; 0 收藏时 keystone 不渲染该元素)
      m.d = slug;                           // 副本 slug
      if (m.pub !== 'world') { console.warn(`  - skip ${e.pk}: published=${m.pub}`); continue; }
      if (m.mcp) { console.warn(`  - skip ${e.pk}: mdt_changes_pending`); continue; }

      recs.push(m);
      strings.push(detail.mdt);
      routeCount++;
    }

    if (!recs.length) throw new Error(`${slug}: no usable routes collected; refusing to overwrite existing data`);
    if (recs.length < Math.ceil(entries.length / 2)) {
      throw new Error(`${slug}: collected only ${recs.length}/${entries.length} routes; refusing to overwrite existing data`);
    }

    meta.dungeons[slug] = {
      kg: recs[0]?.kg ?? null,
      n: recs.length,
      routes: recs,
    };
    routeFiles[slug] = strings;
    console.log(`  collected: ${recs.length}/${entries.length}  (skipped ${entries.length - recs.length})`);
  }

  // 防止页面改版/风控导致数据被大幅清空。
  const prevRouteCount = prevMeta
    ? Object.values(prevMeta.dungeons || {}).reduce((sum, d) => sum + (d.n ?? d.routes?.length ?? 0), 0)
    : 0;
  if (prevRouteCount > 0 && routeCount < Math.ceil(prevRouteCount / 2)) {
    throw new Error(`collected ${routeCount} routes, far below previous ${prevRouteCount}; refusing to overwrite existing data`);
  }

  checkDeadline();
  const now = new Date();
  const version = now.toISOString().replace(/[-:]/g, '').replace(/\.\d+Z$/, 'Z');
  meta.version = version;
  meta.generatedAt = now.toISOString();
  meta.source = 'keystone.guru';
  meta.limit = LIMIT;

  // 2) 落盘中间产物
  writeFileSync(prevMetaPath, JSON.stringify(meta, null, 1), 'utf8');
  for (const [slug, strings] of Object.entries(routeFiles)) {
    writeFileSync(join(DATA_DIR, 'routes', `${slug}.json`), JSON.stringify(strings), 'utf8');
  }
  const manifest = {
    version,
    generatedAt: meta.generatedAt,
    dungeons: Object.fromEntries(Object.entries(meta.dungeons).map(([k, v]) => [k, v.n])),
    routeCount,
    requestCount: reqCount,
  };
  writeFileSync(join(DATA_DIR, 'manifest.json'), JSON.stringify(manifest, null, 2), 'utf8');

  // 3) 无损合并 CBOR 后按副本压缩，与离线重打包共用同一格式。
  const lua = buildPack(meta, routeFiles);
  writeFileSync(join(OUT_DIR, 'Data.lua'), lua, 'utf8');
  console.log(`routes       : ${routeCount}`);
  console.log(`requests     : ${reqCount}`);
  console.log(`dungeons     : ${Object.keys(meta.dungeons).length}`);
  console.log(`Data.lua     : ${(Buffer.byteLength(lua, 'utf8') / 1024).toFixed(1)} KB`);
  console.log(`version      : ${version}`);
}

main().catch(e => { console.error('FATAL', e); process.exit(1); });
