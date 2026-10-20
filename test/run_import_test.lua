-- Run against the installed MDT Presets.lua so insertion and UID behavior are source-backed.
local presetsSource = assert(arg[1], 'Pass the MDT Modules/Presets.lua path')
local mock = dofile('test/wow_mock.lua')
local fixture = dofile('test/mockdata.lua')
local helpers = dofile('test/import_mock.lua')
local passed = 0
local function check(name, condition)
    assert(condition, name); passed = passed + 1; print('PASS ' .. name)
end
C_EncodingUtil = { DecodeBase64 = function(v) return v end, DecompressString = function(v) return v end,
    DeserializeJSON = function(v) return fixture.blobMap[v] end }
local payloads = helpers.InstallEncoding(fixture)
Enum = { CompressionMethod = { Deflate = 1 } }
MyKGRoutesData = helpers.Copy(fixture.pack)
local db = helpers.DB()
local MDT = { L = setmetatable({}, { __index = function(_, key) return key end }),
    GetDefaultSavedVariables = function() return {} end, GetDB = function() return db end,
    dungeonList = { [17] = true, [160] = true, [162] = true } }
assert(loadfile(presetsSource))('MythicDungeonTools_UI', MDT)
MDT.StringToTable = function(_, value) return helpers.Decode(value) end
MDT.AreFramesInitialized = function() return true end
local ui = { refreshes = 0, prompts = 0 }
MDT.SetDungeonList = function(_, _, idx) db.currentDungeonIdx = idx; helpers.Ensure(db, idx) end
MDT.UpdateDungeonDropDown = function() end
MDT.UpdateToDungeon = function() end
MDT.UpdatePresetDropDown = function()
    ui.refreshes = ui.refreshes + 1
    ui.list = helpers.Copy(db.presets[db.currentDungeonIdx])
    ui.selected = db.currentPreset[db.currentDungeonIdx]
end
MDT.UpdateMap = function()
    check('map points at a saved route', type(db.presets[db.currentDungeonIdx][db.currentPreset[db.currentDungeonIdx]].value) == 'table')
end
MDT.SetUniqueID = function(_, preset)
    if not preset.uid then db._nextUid = (db._nextUid or 0) + 1; preset.uid = 'mdt-generated-' .. db._nextUid end
end
MDT.OpenConfirmationFrame = function() ui.prompts = ui.prompts + 1; error('Unexpected UID overwrite prompt') end
local input
local mf = {
    presetImportBox = { SetText = function(_, value) input = value end,
        Fire = function(_, event, value) assert(event == 'OnTextChanged'); input = value end },
    presetImportLabel = { label = { GetText = function() return ui.error end },
        SetText = function(_, value) ui.error = value end },
    presetImportFrame = { Fire = function(_, event) assert(event == 'OnClose'); MDT:UpdatePresetDropDown() end },
}
local function NativeImport()
    local preset = MDT:StringToTable(input)
    if MDT:ValidateImportPreset(preset) then MDT:ImportPreset(preset)
    else ui.error = 'invalid import string' end
end
mf.presetImportButton = { Fire = NativeImport }
MDT.main_frame = mf
_G.MDTFrame = mf
_G.MythicDungeonToolsAPI = { GetDB = function() return db end }
local function LoadCore()
    MyKGRoutesData = helpers.Copy(fixture.pack)
    local ns = {}; assert(loadfile('Core.lua'))('QFXKeystoneRoutes', ns); ns:LoadMeta(); return ns
end
local ns = LoadCore()
local function Import(slug, rank)
    local ok, err = ns:ImportRoute(slug, rank)
    check('import ' .. slug .. ' #' .. rank .. ': ' .. tostring(err), ok)
end
local function Current(idx) return db.presets[idx][db.currentPreset[idx]] end
local function Contains(idx, preset)
    for _, v in ipairs(db.presets[idx]) do if v == preset then return true end end
    return false
end
local list = helpers.Ensure(db, 17)
local default, sentinel = list[1], list[#list]
local source = ns:GetRoutePreset('kings-rest', 1)
local personal = { text = source.text, uid = source.uid, value = { pulls = {} } }
table.insert(list, 2, personal)
Import('kings-rest', 1)
check('successful import clears MDT input and its callback state', input == '')
local first = Current(17)
check('new title gets QFX prefix', first.text == 'QFX-' .. source.text)
check('source UID is replaced', first.uid ~= personal.uid)
check('existing source route is untouched', Contains(17, personal) and personal.text == source.text)
check('first managed import adds exactly one route', #list == 4)
Import('kings-rest', 2)
local second = Current(17)
check('second click replaces first route', #list == 4 and not Contains(17, first) and Contains(17, second))
check('new route stays selected after index shift', db.currentPreset[17] == 3 and ui.selected == 3)
check('dropdown list refreshes after removal', #ui.list == #list and ui.list[3].uid == second.uid)
for rank = 3, 8 do Import('kings-rest', rank) end
check('many clicks keep route count fixed', #list == 4)
check('default and new-preset sentinel stay intact', list[1] == default and list[#list] == sentinel)
Import('murder-row', 1)
local last = Current(160)
check('cross-dungeon replacement removes previous managed route', #list == 3 and #db.presets[160] == 3)
check('old dungeon selection stays valid', db.currentPreset[17] == 1)
check('old personal route remains', list[2] == personal)
check('UID overwrite prompts are avoided', ui.prompts == 0)

local savedState = helpers.Copy(QFXKeystoneRoutesDB.managedRoute)
local function OldRouteSurvives(name, ok)
    check(name .. ' reports failure', not ok)
    check(name .. ' preserves old route', Contains(160, last))
    check(name .. ' preserves ownership record', QFXKeystoneRoutesDB.managedRoute.uid == savedState.uid)
end
local deserialize = C_EncodingUtil.DeserializeCBOR
C_EncodingUtil.DeserializeCBOR = function() error('malformed CBOR') end
OldRouteSurvives('malformed payload', ns:ImportRoute('murder-row', 2))
C_EncodingUtil.DeserializeCBOR = deserialize
local sourcePreset = payloads[fixture.cborByText[fixture.routeStrings['murder-row'][2]]]
sourcePreset.value.currentPull = nil
OldRouteSurvives('native validation failure', ns:ImportRoute('murder-row', 2))
sourcePreset.value.currentPull = 1
local serialize = C_EncodingUtil.SerializeCBOR
C_EncodingUtil.SerializeCBOR = function() error('encode failure') end
OldRouteSurvives('serialization failure', ns:ImportRoute('murder-row', 2))
C_EncodingUtil.SerializeCBOR = serialize
mf.presetImportButton.Fire = function() end
OldRouteSurvives('swallowed native callback failure', ns:ImportRoute('murder-row', 2))
mf.presetImportButton.Fire = function() error('native failure') end
OldRouteSurvives('native exception', ns:ImportRoute('murder-row', 2))
mf.presetImportButton.Fire = NativeImport
mock.combat = true
OldRouteSurvives('combat', ns:ImportRoute('murder-row', 2))
mock.combat = false
check('failure cases do not grow the route list', #db.presets[160] == 3)

last.text = 'My saved route'
Import('murder-row', 2)
check('removing prefix preserves a route', Contains(160, last) and last.text == 'My saved route')
local managed = Current(160)
local copied = helpers.Copy(managed); copied.uid = 'user-copy'
local prefixedPersonal = { text = 'QFX-My own route', uid = 'personal-prefixed', value = {} }
table.insert(db.presets[160], #db.presets[160], copied)
table.insert(db.presets[160], #db.presets[160], prefixedPersonal)
Import('murder-row', 3)
check('copied QFX route is preserved by UID', Contains(160, copied))
check('prefix alone never authorizes deletion', Contains(160, prefixedPersonal))
local beforeReload = Current(160)
ns = LoadCore()
Import('murder-row', 4)
check('ownership survives reload', not Contains(160, beforeReload) and QFXKeystoneRoutesDB.managedRoute.uid == Current(160).uid)
local active = Current(160)
local activeIndex = db.currentPreset[160]
table.remove(db.presets[160], activeIndex)
db.currentPreset[160] = 1
Import('murder-row', 5)
check('manual deletion of previous route is supported', Current(160) ~= active and db.currentPreset[160] > 1)

-- Deletion can shift a personal selection in another dungeon: preserve the selected object.
local oldList = db.presets[160]
local selectedManaged = Current(160)
table.remove(oldList, db.currentPreset[160]); table.insert(oldList, 2, selectedManaged)
db.currentPreset[160] = 3
local selectedPersonal = Current(160)
Import('kings-rest', 2)
check('index shifts preserve other dungeon selection', Current(160) == selectedPersonal and db.currentPreset[160] == 2)
check('old managed route removed across dungeons', not Contains(160, selectedManaged))
check('personal and sentinel routes still exist', Contains(17, personal) and oldList[#oldList].value == 0)
local duplicateTitlePayload = payloads[fixture.cborByText[fixture.routeStrings['kings-rest'][3]]]
local originalTitle = duplicateTitlePayload.text
duplicateTitlePayload.text = 'QFX-' .. originalTitle
Import('kings-rest', 3)
check('existing QFX prefix is not duplicated', Current(17).text == 'QFX-' .. originalTitle)
duplicateTitlePayload.text = originalTitle
local beforeMissingUI = Current(17)
mf.presetImportFrame = nil
check('missing native UI fails safely', not ns:ImportRoute('kings-rest', 4) and Current(17) == beforeMissingUI)
mf.presetImportFrame = { Fire = function() MDT:UpdatePresetDropDown() end }
_G.MythicDungeonToolsAPI = nil
_G.MythicDungeonTools = MDT
ns = LoadCore()
Import('kings-rest', 4)
check('legacy direct importer also replaces previous route', not Contains(17, beforeMissingUI))
print(string.format('RESULT: %d passed (real MDT ImportPreset + ValidateImportPreset)', passed))
