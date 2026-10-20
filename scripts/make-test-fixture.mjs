/** 生成 Lua 测试夹具: test/mockdata.lua */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { unpack, readPack } from './pack-data.mjs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, '..');

const lua = readFileSync(join(ROOT, 'data/Data.lua'), 'utf8');
const { meta, metaBlob: metaRaw, blobs, ends, routeFiles: shards, format } = readPack(lua);

/** JSON -> Lua table 字面量 (使用转义短字符串, 避免长字符串歧义) */
function luaStr(s) {
  let out = '"';
  for (const ch of s) {
    if (ch === '"') out += '\\"';
    else if (ch === '\\') out += '\\\\';
    else if (ch === '\n') out += '\\n';
    else if (ch === '\r') out += '\\r';
    else if (ch === '\t') out += '\\t';
    else if (ch.charCodeAt(0) < 32) out += '\\' + String(ch.charCodeAt(0)).padStart(3, '0');
    else out += ch;
  }
  return out + '"';
}
function toLua(v) {
  if (v === null || v === undefined) return 'nil';
  if (typeof v === 'boolean') return v ? 'true' : 'false';
  if (typeof v === 'number') return Number.isInteger(v) ? String(v) : v.toFixed(6);
  if (typeof v === 'string') return luaStr(v);
  if (Buffer.isBuffer(v)) return '"' + [...v].map(byte => '\\' + String(byte).padStart(3, '0')).join('') + '"';
  if (Array.isArray(v)) return '{' + v.map(toLua).join(',') + '}';
  const parts = [];
  for (const [k, val] of Object.entries(v)) parts.push(`[${luaStr(k)}]=${toLua(val)}`);
  return '{' + parts.join(',') + '}';
}

const out = [];
out.push('-- 自动生成: 测试夹具 (模拟 C_EncodingUtil 解码结果)');
out.push('local M = {}');
out.push('M.blobMap = {');
out.push(`  [${luaStr(metaRaw)}] = ${toLua(meta)},`);
for (const [slug, arr] of Object.entries(shards)) {
  if (format === 1) out.push(`  [${luaStr(blobs[slug])}] = ${toLua(arr)},`);
}
out.push('}');
out.push(`M.routeStrings = ${toLua(shards)}`);
out.push(`M.rawByBlob = ${toLua(Object.fromEntries(Object.entries(blobs).map(([slug, blob]) => [blob, unpack(blob)])))}`);
out.push(`M.cborByText = ${toLua(Object.fromEntries(Object.values(shards).flat().map(text => [text, unpack(text.slice(7))])))}`);
out.push('M.pack = {');
out.push(`  format = ${format},`);
out.push(`  version = ${luaStr(meta.version)},`);
out.push(`  generatedAt = ${luaStr(meta.generatedAt)},`);
out.push(`  meta = ${luaStr(metaRaw)},`);
out.push('  routes = {');
for (const [slug] of Object.entries(shards)) {
  out.push(`    [${luaStr(slug)}] = ${luaStr(blobs[slug])},`);
}
out.push('  },');
out.push(`  routeEnds = ${toLua(ends)},`);
out.push('}');
out.push('return M');

mkdirSync(join(ROOT, 'test'), { recursive: true });
writeFileSync(join(ROOT, 'test/mockdata.lua'), out.join('\n'), 'utf8');
console.log('test/mockdata.lua written:', (out.join('\n').length / 1024).toFixed(1), 'KB');
console.log('  meta dungeons:', Object.keys(meta.dungeons).length, '| shards:', Object.keys(shards).length);
