/** Offline lossless route packing. No network requests. */
import { readFileSync, writeFileSync } from 'node:fs';
import { deflateRawSync, inflateRawSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const PREFIX = '!~MDT2~';
const pack = buffer => deflateRawSync(buffer, { level: 9 }).toString('base64');
export const unpack = blob => inflateRawSync(Buffer.from(blob, 'base64'));
const routeFields = ['r', 't', 'a', 'lm', 'lx', 'v', 'f', 'p', 'mv', 'af'];

export function runtimeMeta(meta) {
  return {
    version: meta.version, generatedAt: meta.generatedAt, source: meta.source,
    dungeons: Object.fromEntries(Object.entries(meta.dungeons).map(([slug, dungeon]) => [slug, {
      n: dungeon.routes.length,
      routes: dungeon.routes.map(route => Object.fromEntries(routeFields
        .filter(key => route[key] !== undefined).map(key => [key, key === 'af'
          ? route.af.map(affix => ({ k: affix.k })) : route[key]]))),
    }])),
  };
}

export function buildPack(meta, routeFiles) {
  const blobs = {}, ends = {};
  let routeCount = 0;
  for (const [slug, strings] of Object.entries(routeFiles)) {
    if (strings.length !== meta.dungeons[slug]?.routes.length) throw Error(`Route count mismatch: ${slug}`);
    let offset = 0;
    ends[slug] = [];
    const records = strings.map(text => {
      if (!text.startsWith(PREFIX)) throw Error(`Unsupported MDT route format: ${slug}`);
      const cbor = unpack(text.slice(PREFIX.length));
      if (!cbor.length) throw Error(`Empty MDT route: ${slug}`);
      offset += cbor.length;
      ends[slug].push(offset);
      routeCount++;
      return cbor;
    });
    // Preserve every CBOR byte. A shared Deflate window removes duplication across routes.
    blobs[slug] = pack(Buffer.concat(records));
  }
  return `-- QFXKeystoneRoutes data pack (generated; do not edit).
-- CBOR records share one Deflate stream per dungeon; routeEnds indexes byte ranges.
-- Only the selected record is deserialized. No expanded shard cache.
-- Routes: ${routeCount}
local B = {}
B.format = 2
B.version = ${JSON.stringify(meta.version)}
B.generatedAt = ${JSON.stringify(meta.generatedAt)}
B.meta = [[${pack(Buffer.from(JSON.stringify(runtimeMeta(meta)), 'utf8'))}]]
B.routes = {}
B.routeEnds = {}
${Object.entries(blobs).map(([slug, blob]) => `B.routes[${JSON.stringify(slug)}] = [[${blob}]]
B.routeEnds[${JSON.stringify(slug)}] = {${ends[slug].join(',')}}`).join('\n')}
_G.MyKGRoutesData = B
`;
}

export function readPack(lua) {
  const metaBlob = lua.match(/B\.meta = \[\[([\s\S]*?)\]\]/)[1];
  const meta = JSON.parse(unpack(metaBlob));
  const blobs = Object.fromEntries([...lua.matchAll(/B\.routes\["([^"]+)"\] = \[\[([\s\S]*?)\]\]/g)]
    .map(match => [match[1], match[2]]));
  const format = /B\.format = 2/.test(lua) ? 2 : 1;
  const ends = Object.fromEntries([...lua.matchAll(/B\.routeEnds\["([^"]+)"\] = \{([^}]+)\}/g)]
    .map(match => [match[1], match[2].split(',').map(Number)]));
  const routeFiles = Object.fromEntries(Object.entries(blobs).map(([slug, blob]) => {
    const raw = unpack(blob);
    if (format === 1) return [slug, JSON.parse(raw)];
    let start = 0;
    return [slug, ends[slug].map(end => {
      const text = PREFIX + pack(raw.subarray(start, end));
      start = end;
      return text;
    })];
  }));
  return { meta, metaBlob, blobs, ends, routeFiles, format };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const path = fileURLToPath(new URL('../data/Data.lua', import.meta.url));
  const original = readFileSync(path, 'utf8');
  const { meta, routeFiles } = readPack(original);
  const output = buildPack(meta, routeFiles);
  writeFileSync(path, output, 'utf8');
  console.log(`Offline repack: ${Buffer.byteLength(original)} -> ${Buffer.byteLength(output)} bytes; ${meta.version} unchanged`);
}
