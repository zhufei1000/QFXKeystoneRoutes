-- Integration checks use the real embedded QFXWidgets, not a mock widget factory.
local mock = dofile('test/wow_mock.lua')
local data = dofile('test/mockdata.lua')
local ImportMock = dofile('test/import_mock.lua')
local mdtDB = ImportMock.DB()
local passed = 0
local function check(name, condition)
    assert(condition, name); passed = passed + 1; print('PASS ' .. name)
end
C_EncodingUtil = {
    DecodeBase64 = function(value) return value end, DecompressString = function(value) return value end,
    DeserializeJSON = function(value) return data.blobMap[value] end,
}
Enum = { CompressionMethod = { Deflate = 1 } }
MyKGRoutesData = ImportMock.Copy(data.pack)
ImportMock.InstallEncoding(data)
local keyLevel = 12
C_ChallengeMode = { GetActiveKeystoneInfo = function() return keyLevel end }
local currentIdx = 162
local dungeons = { [17] = "King's Rest", [42] = 'Ruby Life Pools', [160] = 'Murder Row',
    [162] = 'The Blinding Vale' }
MythicDungeonToolsAPI = {
    GetDB = function() mdtDB.currentDungeonIdx = currentIdx; return mdtDB end,
    GetDungeonName = function(_, idx) return dungeons[idx] end,
    GetBackdropColor = function() return .059, .059, .059, .98 end,
}
local NS = {}
assert(loadfile('Core.lua'))('QFXKeystoneRoutes', NS)
assert(loadfile('QFXWidgets.lua'))('QFXKeystoneRoutes', NS)
assert(loadfile('Panel.lua'))('QFXKeystoneRoutes', NS)
mock.Event('PLAYER_LOGIN')
check('login waits for MDT frame', NS.Panel.frame == nil)
mock.Tick()
check('asynchronous discovery waits', NS.Panel.frame == nil)
MDTFrame = CreateFrame('Frame', 'MDTFrame', UIParent)
MDTFrame:SetSize(840, 540); MDTFrame:Hide()
mock.Tick()
check('discovery waits for sidePanel', NS.Panel.frame == nil)
MDTFrame.sidePanel = CreateFrame('Frame', nil, MDTFrame)
MDTFrame.sidePanel:SetSize(251, 600)
MDTFrame.sidePanel:SetPoint('TOPLEFT', MDTFrame, 'TOPRIGHT', 0, 30)
mock.Tick()
check('hidden MDT stops discovery', mock.tickers[#mock.tickers].cancelled)
MDTFrame:Show()
local P = NS.Panel
check('first open builds QFX browser', P.frame and P.listAPI:GetCount() == 18)
check('frame parent matches MDT', P.frame.parent == MDTFrame)
check('frame anchors to MDT right', P.frame.anchors[1].relative == MDTFrame.sidePanel and
    P.frame.anchors[1].relativePoint == 'TOPRIGHT')
check('browser matches MDT height', P.frame:GetHeight() == MDTFrame.sidePanel:GetHeight())
check('browser visible', P.frame:IsShown())
check('data picks current dungeon', NS.currentSlug == 'the-blinding-vale')
check('factory version is available', QFXWidgets.VERSION == 51)
check('only one page refresh scope', #QFXWidgets._refresh == 1)
local row = P.listAPI:GetRow(1)
check('separate route title', row.title:GetText() == row._item.t)
check('locale stock font', row.title.font == STANDARD_TEXT_FONT)
check('single line title uses native clamp', row.title.maxLines == 1 and row.title.wordWrap == false)
check('matching keystone level highlights', row.level.color[1] == QFXWidgets.Skin.good[1])
check('stats use labels rather than symbols', row.stats:GetText():find('171') ~= nil and
    not row.stats:GetText():find('♥', 1, true))
check('scrollbar needed', P.scroll:GetMaxOffset() > 0)
row:Fire('OnEnter')
check('hover shows full title', GameTooltip.shown and GameTooltip.text == row._item.t)
row:Fire('OnLeave')
check('leave hides tooltip', not GameTooltip.shown)
local importString, imported
MDTFrame.presetImportLabel = { label = { GetText = function() return MDTFrame.importError end },
    SetText = function(_, value) MDTFrame.importError = value end }
MDTFrame.presetImportBox = { SetText = function(_, value) importString = value end,
    Fire = function(_, event, value) assert(event == 'OnTextChanged'); importString = value end }
MDTFrame.presetImportButton = { Fire = function(_, event)
    assert(event == 'OnClick')
    imported = ImportMock.Commit(mdtDB, ImportMock.Decode(importString))
end }
MDTFrame.presetImportFrame = { Fire = function(_, event) assert(event == 'OnClose') end }
row:Fire('OnMouseUp', 'LeftButton')
check('click reaches native import', imported.text == 'QFX-' .. row._item.t and imported.qfxKeystoneRoutes ~= nil)
check('import selects route', row.selected:IsShown() and P.selectedRank == row._item.r)
local previousImport = imported
mock.combat = true; mock.Event('PLAYER_REGEN_DISABLED')
row:Fire('OnMouseUp', 'LeftButton')
check('combat blocks import', imported == previousImport)
check('combat has inline feedback', P.status.color[1] == QFXWidgets.Skin.danger[1])
mock.combat = false; mock.Event('PLAYER_REGEN_ENABLED')
check('combat ends restore hint', P.status.color[1] == QFXWidgets.Skin.textMuted[1])
local deserialize = C_EncodingUtil.DeserializeCBOR
C_EncodingUtil.DeserializeCBOR = function() return nil end
row:Fire('OnMouseUp', 'LeftButton')
check('invalid payload errors are visible', P.status:GetText():find('invalid MDT payload', 1, true) ~= nil)
C_EncodingUtil.DeserializeCBOR = deserialize
P.scroll:ScrollTo(136)
local offset = P.scroll:GetOffset()
P:Refresh()
check('refresh keeps scroll', P.scroll:GetOffset() == offset)
P.header:Fire('OnClick')
check('collapse shrinks panel', P.frame:GetHeight() == 64 and not P.scroll.frame:IsShown())
check('collapse retains rows', P.listAPI:GetRow(1) == row)
P.header:Fire('OnClick')
check('expand restores height and scroll', P.frame:GetHeight() == 600 and P.scroll:GetOffset() == offset)
local settings = QFXKeystoneRoutesDB.settings
settings.sortBy = 'views'; P:Refresh()
check('views order descending', P.routes[1].v >= P.routes[2].v)
settings.sortBy = 'level'; P:Refresh()
check('level order descending', P.routes[1].lm >= P.routes[2].lm)
check('sorting reuses rows', P.listAPI:GetRow(1) == row)
settings.showLevels, settings.showViews, settings.showFavs, settings.showAuthor = false, false, false, false
P:Refresh()
check('existing visibility settings respected', row.level:GetText() == '' and row.stats:GetText() == '' and row.author:GetText() == '')
settings.showLevels, settings.showViews, settings.showFavs, settings.showAuthor = true, true, true, true
settings.sortBy = 'popularity'; P:Refresh()
local oldTitle = row._item.t
row._item.t = '中文路线标题测试：完整中文字符不被截断，而且标题不会挤入统计行'
P:Refresh()
check('Chinese text kept intact', row.title:GetText() == row._item.t and utf8.len(row.title:GetText()) ~= nil)
row._item.t = oldTitle
keyLevel = { secret = true }; P:Refresh()
check('secret keystone level is ignored', P.keyLevel == nil)
keyLevel = 12
currentIdx = 999; mock.Tick()
check('unknown dungeon has empty state', P.empty:IsShown() and P.listAPI:GetCount() == 0)
check('dungeon switch resets scroll', P.scroll:GetOffset() == 0)
NS.Data.loadError = 'decode error'; P:Refresh()
check('data failure has error state', P.empty.title:GetText() ~= '' and P.empty.hint:GetText() ~= '')
NS.Data.loadError = nil
currentIdx = 160; mock.Tick()
check('dungeon switch follows public API', NS.currentSlug == 'murder-row' and P.listAPI:GetCount() == 18)
MDTFrame.sidePanel:SetHeight(500); mock.Tick()
check('MDT resizing updates panel', P.frame:GetHeight() == 500 and P.scroll.frame:GetHeight() == 354)
MDTFrame.sidePanel:SetHeight(600); mock.Tick()
MDTFrame.sidePanel:Hide(); mock.Tick()
check('hidden side panel hides browser', not P.frame:IsShown())
MDTFrame.sidePanel:Show(); mock.Tick()
MDTFrame:Hide()
check('close hides browser', not P.frame:IsShown())
check('close stops ticker', mock.tickers[#mock.tickers].cancelled)
check('close retains no expanded shard data', NS.Data.shards == nil)
MDTFrame:Show()
check('reopen reuses rows', P.listAPI:GetRow(1) == row and P.frame:IsShown())
check('refresh callbacks do not accumulate', #QFXWidgets._refresh == 1)
for _, region in ipairs(mock.regions) do
    if region.kind == 'FontString' and region:IsVisible() and region.text then
        assert(utf8.len(region.text), 'invalid UTF-8: ' .. region.text)
    end
end
print(string.format('RESULT: %d passed (%s)', passed, mock.locale))
return { mock = mock, panel = P, ns = NS }
