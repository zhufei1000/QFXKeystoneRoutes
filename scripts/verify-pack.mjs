/** Offline validation of data/Data.lua, data/meta.json and data/manifest.json. No network. */
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { buildPack, readPack, runtimeMeta, unpack } from './pack-data.mjs';

const readJson = path => JSON.parse(readFileSync(path, 'utf8'));
// Windows checkouts may use CRLF; line endings are not part of the pack contract.
const lf = text => text.replace(/\r\n/g, '\n');

const meta = readJson('data/meta.json');
const manifest = readJson('data/manifest.json');
const lua = readFileSync('data/Data.lua', 'utf8');
const pack = readPack(lua);

assert.equal(pack.format, 2, 'data pack must use format 2');
assert.equal(pack.meta.version, meta.version, 'Data.lua and meta.json versions differ');
assert.equal(pack.meta.generatedAt, meta.generatedAt, 'Data.lua and meta.json timestamps differ');
assert.equal(manifest.version, meta.version, 'manifest.json and meta.json versions differ');
assert.equal(manifest.generatedAt, meta.generatedAt, 'manifest.json and meta.json timestamps differ');
assert.deepEqual(pack.meta, runtimeMeta(meta), 'Data.lua metadata differs from filtered meta.json');
assert.deepEqual(
  Object.keys(manifest.dungeons).sort(),
  Object.keys(meta.dungeons).sort(),
  'manifest.json and meta.json dungeon lists differ',
);

let total = 0;
let rawBytes = 0;
for (const [slug, dungeon] of Object.entries(meta.dungeons)) {
  const routes = dungeon.routes || [];
  const ends = pack.ends[slug];
  assert.ok(pack.routeFiles[slug], `missing route shard: ${slug}`);
  assert.equal(pack.routeFiles[slug].length, routes.length, `${slug}: shard/meta route count differs`);
  assert.equal(pack.meta.dungeons[slug]?.n, routes.length, `${slug}: packed route count differs`);
  assert.equal(manifest.dungeons[slug], routes.length, `${slug}: manifest route count differs`);
  assert.equal(ends?.length, routes.length, `${slug}: byte-range count differs`);

  const raw = unpack(pack.blobs[slug]);
  let start = 0;
  for (let i = 0; i < ends.length; i++) {
    assert.ok(ends[i] > start, `${slug} #${i + 1}: byte range is empty or out of order`);
    assert.ok(ends[i] <= raw.length, `${slug} #${i + 1}: byte range exceeds the shard`);
    start = ends[i];
    total++;
  }
  assert.equal(start, raw.length, `${slug}: byte ranges do not cover the shard`);
  rawBytes += raw.length;
}

assert.equal(total, manifest.routeCount, 'manifest.json routeCount differs from the pack');
assert.equal(total, Object.values(meta.dungeons).reduce((sum, d) => sum + (d.routes?.length || 0), 0),
  'meta.json route count differs from the pack');
assert.equal(lf(buildPack(meta, pack.routeFiles)), lf(lua), 'Data.lua cannot be reproduced from meta.json and its route payloads');

console.log(`PASS: ${Object.keys(meta.dungeons).length} dungeons, ${total} routes, ${(rawBytes / 1024).toFixed(1)} KB CBOR, version ${meta.version}`);
