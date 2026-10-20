--[[
    QFXKeystoneRoutes — Core

    职责:
      1. 解码压缩数据包(元数据延迟加载 / 单条路线按需反序列化)
      2. 与 MDT 联动(监听副本切换 -> 切换面板数据)
      3. 提供导入接口

    数据格式(data/Data.lua):
      _G.MyKGRoutesData = {
        version    = "20261020T052555Z",
        generatedAt= "2026-10-20T05:25:55Z",
        meta       = "<base64(rawDeflate(json))>",
        format     = 2,
        routes     = { ["<slug>"] = "<base64(rawDeflate(concatCBOR))>", ... },
        routeEnds  = { ["<slug>"] = { <cumulative byte ends>, ... }, ... },
      }
]]

local ADDON_NAME, ns = ...
ns.name = ADDON_NAME

local MDT = _G.MythicDungeonToolsAPI or _G.MythicDungeonTools

--------------------------------------------------------------------------------
-- 常量
--------------------------------------------------------------------------------
local POSITION_TICK    = 0.25    -- 跟随 MDT 窗口的位置刷新间隔(秒)

--------------------------------------------------------------------------------
-- 工具
--------------------------------------------------------------------------------
local function trim(s)
  return (tostring(s or ''):gsub('^%s+', ''):gsub('%s+$', ''))
end

--- 去掉所有非字母数字, 用于跨语言/跨站点的副本名匹配
--- "King's Rest"      -> "kingsrest"
--- "kings-rest"       -> "kingsrest"
local function NormalizeName(s)
  s = trim(s):lower()
  s = s:gsub('[^%a%d]+', '')
  return s
end

local function FormatNumber(n)
  n = tonumber(n) or 0
  if n >= 1000000 then return string.format('%.1fM', n / 1000000) end
  if n >= 1000    then return string.format('%.1fK', n / 1000) end
  return tostring(n)
end

--------------------------------------------------------------------------------
-- 数据层
--------------------------------------------------------------------------------
ns.Data = {
  meta      = nil,     -- 解码后的元数据(常驻)
  metaBySlug= nil,     -- slug -> 副本记录
  slugByKey = nil,     -- NormalizeName(slug) -> slug
  version   = nil,
  generatedAt = nil,
  loadError = nil,
}

local function InflateBlob(blob)
  if not blob or blob == '' then return nil end
  if not C_EncodingUtil or not C_EncodingUtil.DecodeBase64 then
    -- 极老客户端兜底(理论上不会走到, MDT 6.x 要求 12.x)
    return nil
  end
  local raw = C_EncodingUtil.DecodeBase64(blob)
  if not raw then return nil end
  return C_EncodingUtil.DecompressString(raw, Enum.CompressionMethod.Deflate)
end

function ns:DecodeBlob(blob)
  local dec = InflateBlob(blob)
  if not dec then return nil end
  local ok, res = pcall(C_EncodingUtil.DeserializeJSON, dec)
  if not ok then return nil end
  return res
end

function ns:LoadMeta()
  if self.Data.meta then return self.Data.meta end
  local pack = _G.MyKGRoutesData
  if not pack then
    self.Data.loadError = 'no data pack'
    return nil
  end
  self.Data.version    = pack.version
  self.Data.generatedAt = pack.generatedAt
  local meta = self:DecodeBlob(pack.meta)
  if not meta or type(meta) ~= 'table' or type(meta.dungeons) ~= 'table' then
    self.Data.loadError = 'decode meta failed'
    return nil
  end
  self.Data.meta = meta
  self.Data.metaBySlug = meta.dungeons
  self.Data.slugByKey = {}
  for slug in pairs(meta.dungeons) do
    self.Data.slugByKey[NormalizeName(slug)] = slug
  end
  pack.meta = nil -- The decoded metadata is the only runtime copy we need.
  self.Data.loadError = nil
  return meta
end

--------------------------------------------------------------------------------
-- MDT 联动
--------------------------------------------------------------------------------
local hooked = false

local function MDTDungeonCandidates(idx)
  local out = {}
  local function add(s)
    if type(s) == 'string' and s ~= '' then out[#out + 1] = s end
  end
  local ok, name = pcall(function() return MDT:GetDungeonName(idx, true) end)
  if ok then add(name) end
  if MDT.knownDungeons then add(MDT.knownDungeons[idx]) end
  if MDT.mapInfo and MDT.mapInfo[idx] then add(MDT.mapInfo[idx].englishName) end
  if MDT.dungeonList then add(MDT.dungeonList[idx]) end
  return out
end

--- MDT 的副本索引 -> keystone slug
function ns:GetSlugForIndex(idx)
  if not idx or not self.Data.meta then return nil end
  for _, cand in ipairs(MDTDungeonCandidates(idx)) do
    local slug = self.Data.slugByKey[NormalizeName(cand)]
    if slug then return slug end
  end
  return nil
end

--- 当前 MDT 副本索引
function ns:GetCurrentDungeonIndex()
  if not MDT or not MDT.GetDB then return nil end
  local db = MDT:GetDB()
  return db and db.currentDungeonIdx or nil
end

function ns:GetMDTMainFrame()
  -- MDT 6.3.9 的 UI namespace 是私有的，但主框体仍有全局名称。
  return _G.MDTFrame or (MDT and MDT.main_frame)
end

function ns:OnDungeonChanged(idx)
  idx = idx or self:GetCurrentDungeonIndex()
  local slug = self:GetSlugForIndex(idx)
  if slug == self.currentSlug and idx == self.currentDungeonIdx then return end
  self.currentSlug = slug
  self.currentDungeonIdx = idx
  if ns.OnDataChanged then ns:OnDataChanged(slug) end
end

local function InstallMDTHook()
  if hooked or not MDT or not MDT.UpdateToDungeon then return end
  local orig = MDT.UpdateToDungeon
  MDT.UpdateToDungeon = function(self, dungeonIdx, ...)
    local r = orig(self, dungeonIdx, ...)
    if self == MDT then
      local ok, err = pcall(function() ns:OnDungeonChanged(dungeonIdx) end)
      if not ok then print('|cffff0000QFXKR|r hook error: ' .. tostring(err)) end
    end
    return r
  end
  hooked = true
end

--------------------------------------------------------------------------------
-- 导入
--------------------------------------------------------------------------------
local ROUTE_PREFIX = 'QFX-'
local ENCODING_PREFIX = '!~MDT2~'

local function DecodeRoute(text)
  if MDT.StringToTable then return MDT:StringToTable(text) end
  if text:sub(1, #ENCODING_PREFIX) ~= ENCODING_PREFIX then return nil end
  local raw = C_EncodingUtil.DecodeBase64(text:sub(#ENCODING_PREFIX + 1))
  if not raw then return nil end
  local decoded = C_EncodingUtil.DecompressString(raw, Enum.CompressionMethod.Deflate)
  return decoded and C_EncodingUtil.DeserializeCBOR(decoded)
end

-- Inflate one dungeon temporarily, but deserialize only the requested CBOR record.
-- Nothing from the expanded stream or the resulting preset is cached here.
function ns:GetRoutePreset(slug, rank)
  local pack = _G.MyKGRoutesData
  if type(rank) ~= 'number' or rank < 1 or rank % 1 ~= 0 then return nil end
  if not pack or not pack.routes or not pack.routes[slug] then return nil end
  if pack.format == 2 then
    local ends = pack.routeEnds and pack.routeEnds[slug]
    if not ends or not ends[rank] then return nil end
    local first, last = (ends[rank - 1] or 0) + 1, ends[rank]
    local bytes = InflateBlob(pack.routes[slug])
    if not bytes or first < 1 or last < first or last > #bytes then return nil end
    return C_EncodingUtil.DeserializeCBOR(bytes:sub(first, last))
  end
  if pack.format ~= nil and pack.format ~= 1 then return nil end
  -- Read old data packs during an update without keeping a whole expanded array.
  local strings = self:DecodeBlob(pack.routes[slug])
  local text = type(strings) == 'table' and strings[rank]
  if type(text) ~= 'string' or text == '' then return nil end
  return DecodeRoute(text)
end

local function EncodeRoute(preset)
  if MDT.TableToString then return MDT:TableToString(preset) end
  local serialized = C_EncodingUtil.SerializeCBOR(preset)
  local compressed = C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate)
  return ENCODING_PREFIX .. C_EncodingUtil.EncodeBase64(compressed)
end

-- Match the last route we created, not every route whose name starts with QFX-.
-- Renaming it without the prefix lets the player keep that route permanently.
local function RemovePreviousRoute(db, previous, imported)
  if type(previous) ~= 'table' or type(previous.uid) ~= 'string' then return false end
  local list = db.presets[previous.dungeonIdx]
  if type(list) ~= 'table' then return false end
  for i = #list - 1, 2, -1 do
    local route = list[i]
    if type(route) == 'table' and route ~= imported and route.uid == previous.uid and
        type(route.qfxKeystoneRoutes) == 'table' and
        route.qfxKeystoneRoutes.serial == previous.serial and
        type(route.text) == 'string' and route.text:sub(1, #ROUTE_PREFIX) == ROUTE_PREFIX and
        type(route.value) == 'table' then
      table.remove(list, i)
      local selected = db.currentPreset[previous.dungeonIdx] or 1
      if selected > i then db.currentPreset[previous.dungeonIdx] = selected - 1
      elseif selected == i then db.currentPreset[previous.dungeonIdx] = 1 end
      return true
    end
  end
  return false
end

--- 导入某个副本的第 rank 条路线
--- @param slug string  副本 slug
--- @param rank number 1-based 名次
--- @return boolean ok, string|nil err
function ns:ImportRoute(slug, rank)
  if not MDT then return false, 'MDT not loaded' end
  if InCombatLockdown() then return false, 'in combat' end

  local db = MDT.GetDB and MDT:GetDB()
  if not db or type(db.presets) ~= 'table' or type(db.currentPreset) ~= 'table' then
    return false, 'MDT route storage not ready'
  end
  local mf = self:GetMDTMainFrame()
  local nativeUI = not MDT.ImportPreset
  if nativeUI and (not mf or not mf.presetImportBox or not mf.presetImportButton or
      not mf.presetImportLabel or not mf.presetImportFrame) then
    return false, 'MDT import UI not ready'
  end
  local okDecode, preset = pcall(self.GetRoutePreset, self, slug, rank)
  if not okDecode or type(preset) ~= 'table' or type(preset.text) ~= 'string' or
      type(preset.value) ~= 'table' or type(preset.value.currentDungeonIdx) ~= 'number' or
      type(preset.value.pulls) ~= 'table' then
    return false, 'invalid MDT payload'
  end

  local state = _G.QFXKeystoneRoutesDB or {}
  _G.QFXKeystoneRoutesDB = state
  state.managedImportSerial = (state.managedImportSerial or 0) + 1
  local serial, previous = state.managedImportSerial, state.managedRoute
  preset.text = ROUTE_PREFIX .. preset.text:gsub('^QFX%-', '')
  preset.uid = nil -- Imported source UIDs must never overwrite a player's saved route.
  preset.qfxKeystoneRoutes = { serial = serial }
  local dungeonIdx = preset.value.currentDungeonIdx

  if nativeUI then
    local okEncode, encoded = pcall(EncodeRoute, preset)
    if not okEncode or type(encoded) ~= 'string' then return false, 'encode MDT payload failed' end
    mf.presetImportLabel:SetText('')
    mf.presetImportBox:SetText(encoded)
    mf.presetImportBox:Fire('OnTextChanged', encoded)
    local okImport, err = pcall(mf.presetImportButton.Fire, mf.presetImportButton, 'OnClick')
    if not okImport then return false, tostring(err) end
    local err = mf.presetImportLabel.label:GetText()
    if err and err ~= '' then return false, err end
  else
    local okImport, err = pcall(MDT.ImportPreset, MDT, preset)
    if not okImport then return false, tostring(err) end
  end

  -- AceGUI callbacks can swallow errors; verify the committed route before deleting anything.
  local list = db.presets[dungeonIdx]
  local selected = db.currentPreset[dungeonIdx]
  local imported = type(list) == 'table' and selected and list[selected]
  if type(imported) ~= 'table' or type(imported.qfxKeystoneRoutes) ~= 'table' or
      imported.qfxKeystoneRoutes.serial ~= serial or type(imported.uid) ~= 'string' or
      type(imported.text) ~= 'string' or
      imported.text:sub(1, #ROUTE_PREFIX) ~= ROUTE_PREFIX then
    return false, 'MDT did not save the route'
  end
  RemovePreviousRoute(db, previous, imported)
  state.managedRoute = { dungeonIdx = dungeonIdx, uid = imported.uid, serial = serial }
  -- The native import-close callback refreshes dropdown labels/indices and delete-button state.
  if mf and mf.presetImportFrame then mf.presetImportFrame:Fire('OnClose')
  elseif MDT.UpdatePresetDropDown then MDT:UpdatePresetDropDown() end
  if nativeUI then
    mf.presetImportBox:SetText('')
    mf.presetImportBox:Fire('OnTextChanged', '')
  end
  return true
end

--------------------------------------------------------------------------------
-- 生命周期
--------------------------------------------------------------------------------
local ticker = nil
local attachedFrame = nil
local attachedSidePanel = nil

local function StopTicker()
  if ticker then ticker:Cancel() ticker = nil end
end

local UpdatePanelPosition
local function StartTicker()
  if ticker then return end
  ticker = C_Timer.NewTicker(POSITION_TICK, function()
    UpdatePanelPosition()
  end)
end

UpdatePanelPosition = function()
  if not ns.Panel then return end
  local mf = ns:GetMDTMainFrame()
  if not mf then ns.Panel:SetVisible(false) return end
  local sp = mf.sidePanel
  if not sp then ns.Panel:SetVisible(false) return end

  if attachedFrame ~= mf then
    attachedFrame = mf
    mf:HookScript('OnShow', function()
      StartTicker()
      UpdatePanelPosition()
    end)
    mf:HookScript('OnHide', function()
      ns.Panel:SetVisible(false)
      StopTicker()
    end)
  end

  if not mf:IsShown() then
    ns.Panel:SetVisible(false)
    StopTicker()
    return
  end

  ns:LoadMeta()
  ns:OnDungeonChanged(ns:GetCurrentDungeonIndex())
  ns.Panel:Build()
  if not ns.Panel.frame then return end
  if attachedSidePanel ~= sp then
    attachedSidePanel = sp
    ns.Panel.frame:SetParent(mf)
    ns.Panel.frame:ClearAllPoints()
    ns.Panel.frame:SetPoint('TOPLEFT', sp, 'TOPRIGHT', 6, 0)
  end
  ns.Panel:UpdateLayout(sp)
  ns.Panel:SetVisible(sp:IsShown())
end

function ns:OnInitialize()
  local db = _G.QFXKeystoneRoutesDB or {}
  _G.QFXKeystoneRoutesDB = db
  db.settings = db.settings or {
    expanded   = true,
    showViews  = true,
    showFavs   = true,
    showLevels = true,
    showAuthor = true,
    sortBy     = 'popularity',   -- popularity | views | level
  }

  InstallMDTHook()

  -- 首次打开 MDT 时框体才异步创建；挂载完成后，仅在窗口打开时检查副本。
  StartTicker()
end

function ns:OnEnable()
  self:OnInitialize()
  UpdatePanelPosition()
end

function ns:OnDisable()
  StopTicker()
  if ns.Panel then ns.Panel:SetVisible(false) end
end

--------------------------------------------------------------------------------
-- 事件
--------------------------------------------------------------------------------
local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:RegisterEvent('PLAYER_LOGIN')

frame:SetScript('OnEvent', function(_, event, arg1)
  if event == 'ADDON_LOADED' and arg1 == ADDON_NAME then
    -- 等 MDT 完全就绪
    if MDT and MDT.IsMapSectionActive then
      -- MDT 已加载
    end
    return
  end
  if event == 'PLAYER_LOGIN' then
    if not MDT then
      print('|cffff0000QFXKR|r 需要 Mythic Dungeon Tools')
      return
    end
    ns:OnEnable()
  end
end)

--------------------------------------------------------------------------------
-- 导出
--------------------------------------------------------------------------------
_G.QFXKeystoneRoutes = ns
ns.NormalizeName = NormalizeName
ns.FormatNumber = FormatNumber
