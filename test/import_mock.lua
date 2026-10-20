-- Encoding boundary mock and MDT's documented default / saved / new-preset list contract.
local M = {}
function M.Copy(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = M.Copy(item) end
    return copy
end
function M.InstallEncoding(fixture)
    local map, nextEncoded = {}, 0
    local indexes = { [17] = 'kings-rest', [20] = 'temple-of-sethraliss', [42] = 'ruby-life-pools',
        [160] = 'murder-row', [161] = 'den-of-nalorakk', [162] = 'the-blinding-vale',
        [163] = 'voidscar-arena', [164] = 'altar-of-fangs' }
    local meta = fixture.blobMap[fixture.pack.meta]
    for idx, slug in pairs(indexes) do
        local shard = fixture.routeStrings[slug]
        for rank, text in ipairs(shard) do
            local preset = { text = meta.dungeons[slug].routes[rank].t,
                uid = 'source-' .. slug .. rank,
                value = { currentDungeonIdx = idx, currentPull = 1, currentSublevel = 1,
                    pulls = { { [1] = {rank} } } } }
            map[text:sub(8)] = preset
            map[fixture.cborByText[text]] = preset
        end
    end
    C_EncodingUtil.DecompressString = function(value) return fixture.rawByBlob[value] or value end
    C_EncodingUtil.DeserializeCBOR = function(value) return M.Copy(map[value]) end
    C_EncodingUtil.SerializeCBOR = function(value)
        nextEncoded = nextEncoded + 1
        local token = 'encoded-' .. nextEncoded
        map[token] = M.Copy(value); return token
    end
    C_EncodingUtil.CompressString = function(value) return value end
    C_EncodingUtil.EncodeBase64 = function(value) return value end
    return map
end
function M.Decode(value)
    if value:sub(1, 7) ~= '!~MDT2~' then return nil end
    return C_EncodingUtil.DeserializeCBOR(value:sub(8))
end
function M.Encode(value) return '!~MDT2~' .. C_EncodingUtil.SerializeCBOR(value) end
function M.DB()
    return { presets = {}, currentPreset = {}, currentDungeonIdx = 162 }
end
function M.Ensure(db, idx)
    if not db.presets[idx] then
        db.presets[idx] = { { text = 'Default', value = {} }, { text = '<New Preset>', value = 0 } }
        db.currentPreset[idx] = 1
    end
    return db.presets[idx]
end
function M.Commit(db, preset)
    local idx = preset.value.currentDungeonIdx
    local list = M.Ensure(db, idx)
    local nextIndex = #list
    table.insert(list, nextIndex, preset)
    db._nextUid = (db._nextUid or 0) + 1
    preset.uid = preset.uid or ('generated-' .. db._nextUid)
    db.currentDungeonIdx, db.currentPreset[idx] = idx, nextIndex
    return preset
end
return M
