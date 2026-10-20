// Compare CBOR bytes against a saved original pack, rather than comparing rewritten strings.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { buildPack, readPack, unpack, runtimeMeta } from '../scripts/pack-data.mjs';

const original = readPack(readFileSync(process.argv[2], 'utf8'));
const lua = readFileSync('data/Data.lua', 'utf8');
const current = readPack(lua);
assert.equal(current.format, 2);
assert.equal(current.meta.version, original.meta.version);
assert.equal(current.meta.generatedAt, original.meta.generatedAt);
assert.deepEqual(current.meta, runtimeMeta(original.meta));
let count = 0;
for (const [slug, texts] of Object.entries(original.routeFiles)) {
  const bytes = unpack(current.blobs[slug]);
  const ends = current.ends[slug];
  assert.equal(ends.length, texts.length);
  let start = 0;
  texts.forEach((text, index) => {
    const expected = unpack(text.slice(7));
    assert.deepEqual(bytes.subarray(start, ends[index]), expected, `${slug} #${index + 1}`);
    start = ends[index];
    count++;
  });
  assert.equal(start, bytes.length);
}
assert.equal(count, 144);
assert.equal(buildPack(original.meta, original.routeFiles), lua, 'collector and offline packer agree');
const broken = structuredClone(original.routeFiles);
broken['kings-rest'][0] = 'invalid MDT string';
assert.throws(() => buildPack(original.meta, broken), /Unsupported MDT/);
console.log(`PASS: ${count} routes byte-for-byte identical; metadata, timestamps, boundaries, and collector packing verified`);
console.log('Metadata JSON bytes:', Buffer.byteLength(JSON.stringify(original.meta)), '->',
  Buffer.byteLength(JSON.stringify(current.meta)));
console.log('Route blob bytes:', Object.values(original.blobs).reduce((n, s) => n + s.length, 0), '->',
  Object.values(current.blobs).reduce((n, s) => n + s.length, 0));
