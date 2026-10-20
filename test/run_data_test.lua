-- Byte-range and lifecycle checks for the real format-2 data pack.
local mock = dofile('test/wow_mock.lua')
local fixture = dofile('test/mockdata.lua')
local helper = dofile('test/import_mock.lua')
local passed = 0
local function check(name, condition)
    assert(condition, name); passed = passed + 1
end
C_EncodingUtil = { DecodeBase64 = function(value) return value end,
    DeserializeJSON = function(value) return fixture.blobMap[value] end }
Enum = { CompressionMethod = { Deflate = 1 } }
helper.InstallEncoding(fixture)
MyKGRoutesData = helper.Copy(fixture.pack)
MythicDungeonToolsAPI = { GetDB = function() return {} end }
local ns = {}; assert(loadfile('Core.lua'))('QFXKeystoneRoutes', ns)
local json, cbor, inflates = 0, 0, 0
local readJSON, readCBOR, inflate = C_EncodingUtil.DeserializeJSON,
    C_EncodingUtil.DeserializeCBOR, C_EncodingUtil.DecompressString
C_EncodingUtil.DeserializeJSON = function(bytes) json = json + 1; return readJSON(bytes) end
local expected
C_EncodingUtil.DeserializeCBOR = function(bytes)
    cbor = cbor + 1
    if expected then check('selected byte range is identical to the MDT CBOR', bytes == expected) end
    return readCBOR(bytes)
end
C_EncodingUtil.DecompressString = function(bytes) inflates = inflates + 1; return inflate(bytes) end
mock.Event('PLAYER_LOGIN')
check('login leaves metadata compressed', ns.Data.meta == nil and json == 0 and inflates == 0)
ns:LoadMeta()
check('metadata decoded once', json == 1 and ns:LoadMeta() == ns.Data.meta and json == 1)
check('compressed metadata is released', MyKGRoutesData.meta == nil)
check('dungeon index reuses the metadata table', ns.Data.metaBySlug == ns.Data.meta.dungeons)
local count = 0
for slug, strings in pairs(fixture.routeStrings) do
    for rank, text in ipairs(strings) do
        expected = fixture.cborByText[text]
        local before = cbor
        local preset = ns:GetRoutePreset(slug, rank)
        check('exactly one preset deserialized', cbor == before + 1 and preset ~= nil)
        count = count + 1
    end
end
expected = nil
check('all 144 routes checked', count == 144)
check('route access never deserializes a JSON route array', json == 1)
check('expanded shards are never stored', ns.Data.shards == nil and ns.Data.shardOrder == nil)
local weak = setmetatable({ ns:GetRoutePreset('kings-rest', 1) }, { __mode = 'v' })
collectgarbage('collect')
check('unused preset can be collected immediately', weak[1] == nil)
local before = inflates
for _, rank in ipairs({ -1, 0, .5, 999, '1', math.huge }) do
    check('invalid rank rejected before expansion', ns:GetRoutePreset('kings-rest', rank) == nil)
end
check('unknown dungeon rejected', ns:GetRoutePreset('unknown', 1) == nil)
check('invalid requests allocate no expanded stream', inflates == before)
C_EncodingUtil.DecompressString = function() return '' end
check('truncated stream rejected', ns:GetRoutePreset('kings-rest', 1) == nil)
C_EncodingUtil.DecompressString = function() return nil end
check('failed decompression rejected', ns:GetRoutePreset('kings-rest', 1) == nil)
C_EncodingUtil.DecompressString = inflate
MyKGRoutesData.format = 999
check('unknown pack format rejected', ns:GetRoutePreset('kings-rest', 1) == nil)
-- Keep old installations usable if just the runtime is updated first.
MyKGRoutesData.format = 1
MyKGRoutesData.routes['kings-rest'] = 'legacy-shard'
C_EncodingUtil.DeserializeJSON = function(bytes)
    if bytes == 'legacy-shard' then return fixture.routeStrings['kings-rest'] end
    return readJSON(bytes)
end
check('old JSON route packs remain readable', ns:GetRoutePreset('kings-rest', 1) ~= nil)
check('old packs do not create a shard cache', ns.Data.shards == nil)
print(string.format('RESULT: %d passed (data packing and lifecycle)', passed))
