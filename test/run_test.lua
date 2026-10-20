--[[
    QFXKeystoneRoutes — Lua 端集成测试 (mock WoW 环境)

    验证:
      1. NormalizeName 副本名归一化
      2. LoadMeta 数据解码
      3. GetSlugForIndex: MDT 副本索引 -> keystone slug
      4. OnDungeonChanged: 副本切换联动
      5. GetRoutePreset: 仅反序列化选中的路线，无分片缓存
      6. ImportRoute: 调用 MDT:ImportPreset 且 preset 正确
]]

local PASS, FAIL = 0, 0
local function check(name, cond, extra)
  if cond then
    PASS = PASS + 1
    print(('  PASS  %s'):format(name))
  else
    FAIL = FAIL + 1
    print(('  FAIL  %s   %s'):format(name, extra and tostring(extra) or ''))
  end
end

--------------------------------------------------------------------------------
-- Mock 环境
--------------------------------------------------------------------------------
local MOCK = dofile('test/mockdata.lua')
local ImportMock = dofile('test/import_mock.lua')
local mdtDB = ImportMock.DB()

LibStub = setmetatable({}, {
  __call = function(self, name) return self[name] end,
})
LibStub['AceGUI-3.0'] = { Create = function(kind) return nil end }

C_EncodingUtil = {
  DecodeBase64 = function(blob) return blob end,            -- mock: 直接透传
  DecompressString = function(s) return s end,               -- mock: 直接透传
  CompressString = function(s) return s end,                 -- mock: 直接透传
  DeserializeJSON = function(s) return MOCK.blobMap[s] end,  -- mock: 查表
}
_G.MyKGRoutesData = ImportMock.Copy(MOCK.pack)
ImportMock.InstallEncoding(MOCK)
Enum = { CompressionMethod = { Deflate = 1 } }

UIParent = { GetWidth = function() return 1920 end, GetHeight = function() return 1080 end }

local tickers = {}
C_Timer = {
  NewTicker = function(interval, fn) local t = { Cancel = function() end }; tickers[#tickers + 1] = { interval = interval, fn = fn }; return t end,
}

function InCombatLockdown() return false end

local eventHandlers = {}
function CreateFrame()
  local f = {}
  f.RegisterEvent = function(self, ev) eventHandlers[ev] = true end
  f.SetScript = function(self, kind, fn) self['On' .. kind] = fn end
  f.HookScript = function() end
  f.Show = function() end
  f.Hide = function() end
  f.SetPoint = function() end
  f.ClearAllPoints = function() end
  f.SetWidth = function() end
  f.SetHeight = function() end
  f.SetParent = function() end
  f.SetShown = function() end
  f.EnableMouse = function() end
  f.SetPoint = function() end
  f.GetRight = function() return 1600 end
  f.GetTop = function() return 900 end
  f.SetScale = function() end
  f.SetFrameStrata = function() end
  f.SetFrameLevel = function() end
  f.SetAllPoints = function() end
  f.SetToplevel = function() end
  return f
end

-- Mock MDT
local IMPORTED = {}
local MDT = {
  knownDungeons = {
    [17] = "King's Rest", [20] = 'Temple of Sethraliss', [42] = 'Ruby Life Pools',
    [160] = 'Murder Row', [161] = 'Den of Nalorakk', [162] = 'The Blinding Vale',
    [163] = 'Voidscar Arena', [164] = 'Altar of Fangs',
  },
  dungeonList = {},
  mapInfo = {},
  currentDungeonIdx = 162,
  GetDB = function(self) return mdtDB end,
  GetDungeonName = function(self, idx, forceEnglish) return self.knownDungeons[idx] end,
  StringToTable = function(self, s)
    if type(s) ~= 'string' or #s < 7 then return 'bad' end
    return ImportMock.Decode(s)
  end,
  ImportPreset = function(self, preset) IMPORTED[#IMPORTED + 1] = ImportMock.Commit(mdtDB, preset) return true end,
}
_G.MythicDungeonTools = MDT

_G.QFXKeystoneRoutesDB = nil

--------------------------------------------------------------------------------
-- 加载被测代码
--------------------------------------------------------------------------------
local NS = {}
local chunk = assert(loadfile('Core.lua'))
chunk('QFXKeystoneRoutes', NS)

print('== 1. NormalizeName ==')
check("King's Rest -> kingsrest", NS.NormalizeName("King's Rest") == 'kingsrest', NS.NormalizeName("King's Rest"))
check('kings-rest -> kingsrest', NS.NormalizeName('kings-rest') == 'kingsrest')
check('The Blinding Vale -> theblindingvale', NS.NormalizeName('The Blinding Vale') == 'theblindingvale')

print('== 2. LoadMeta ==')
local meta = NS:LoadMeta()
check('meta loaded', type(meta) == 'table')
check('8 dungeons', meta and (function() local n = 0 for _ in pairs(meta.dungeons) do n = n + 1 end return n end)() == 8)
check('version present', meta and type(meta.version) == 'string')
check('metaBySlug built', NS.Data.metaBySlug and NS.Data.metaBySlug['kings-rest'] ~= nil)

print('== 3. GetSlugForIndex (MDT index -> slug) ==')
local expect = {
  [17] = 'kings-rest', [20] = 'temple-of-sethraliss', [42] = 'ruby-life-pools',
  [160] = 'murder-row', [161] = 'den-of-nalorakk', [162] = 'the-blinding-vale',
  [163] = 'voidscar-arena', [164] = 'altar-of-fangs',
}
for idx, slug in pairs(expect) do
  local got = NS:GetSlugForIndex(idx)
  check(string.format('idx %-3d -> %s', idx, slug), got == slug, 'got ' .. tostring(got))
end
check('unknown idx -> nil', NS:GetSlugForIndex(999) == nil)

print('== 4. OnDungeonChanged 联动 ==')
NS.currentSlug = nil
NS:OnDungeonChanged(42)
check('switch to 42 sets slug', NS.currentSlug == 'ruby-life-pools', tostring(NS.currentSlug))
NS:OnDungeonChanged(160)
check('switch to 160 sets slug', NS.currentSlug == 'murder-row', tostring(NS.currentSlug))
NS:OnDungeonChanged(160)
check('same idx is idempotent', NS.currentSlug == 'murder-row')

print('== 5. 单条路线反序列化 ==')
local s1 = NS:GetRoutePreset('kings-rest', 1)
check('selected route decoded', type(s1) == 'table' and type(s1.value.pulls) == 'table')
check('correct selected route', s1.text == meta.dungeons['kings-rest'].routes[1].t)
check('no shared mutable preset', NS:GetRoutePreset('kings-rest', 1) ~= s1)
NS:GetRoutePreset('murder-row', 2)
check('no expanded shard cache', NS.Data.shards == nil and NS.Data.shardOrder == nil)

print('== 6. ImportRoute ==')
IMPORTED = {}
local ok, err = NS:ImportRoute('kings-rest', 1)
check('import succeeded', ok == true, err)
check('MDT.ImportPreset called once', #IMPORTED == 1, #IMPORTED)
check('preset is table', type(IMPORTED[1]) == 'table')
check('preset has value.pulls', type(IMPORTED[1].value.pulls) == 'table')
local ok2, err2 = NS:ImportRoute('kings-rest', 999)
check('out-of-range rank fails', ok2 == false, err2)
local ok3, err3 = NS:ImportRoute('no-such-dungeon', 1)
check('unknown slug fails', ok3 == false, err3)

print('== 7. FormatNumber ==')
check('171835 -> 171.8K', NS.FormatNumber(171835) == '171.8K', NS.FormatNumber(171835))
check('59 -> 59', NS.FormatNumber(59) == '59')
check('1200000 -> 1.2M', NS.FormatNumber(1200000) == '1.2M', NS.FormatNumber(1200000))

print(('\n== RESULT: %d passed, %d failed =='):format(PASS, FAIL))
os.exit(FAIL == 0 and 0 or 1)
