-- Export the actual native-frame tree produced by Panel + real QFXWidgets.
local result = dofile('test/run_panel_test.lua')
local panel, mock = result.panel, result.mock
local function Json(value)
    local kind = type(value)
    if kind == 'nil' then return 'null' end
    if kind == 'boolean' or kind == 'number' then return tostring(value) end
    if kind == 'string' then
        local escaped = value:gsub('[%z\1-\31\\"]', function(c)
            if c == '"' then return '\\"' end
            if c == '\\' then return '\\\\' end
            return string.format('\\u%04x', c:byte())
        end)
        return '"' .. escaped .. '"'
    end
    local fields = {}
    if #value > 0 then
        for _, v in ipairs(value) do fields[#fields + 1] = Json(v) end
        return '[' .. table.concat(fields, ',') .. ']'
    end
    for key, v in pairs(value) do fields[#fields + 1] = Json(key) .. ':' .. Json(v) end
    return '{' .. table.concat(fields, ',') .. '}'
end
local px, py, pw, ph = panel.frame:GetRect()
local nodes = {}
local function Descends(region)
    while region do
        if region == panel.frame then return true end
        region = region.parent
    end
end
for order, region in ipairs(mock.regions) do
    if (region.kind == 'Texture' or region.kind == 'FontString') and region:IsVisible() and Descends(region) then
        local x, y, w, h = region:GetRect()
        local offset = 0
        local clips = {{0, 0, pw, ph}}
        local parent = region.parent
        while parent and parent ~= panel.frame do
            if parent.kind == 'ScrollFrame' then
                local cx, cy, cw, ch = parent:GetRect()
                clips[#clips + 1] = {cx - px, cy - py, cw, ch}
                offset = offset + (parent.scrollOffset or 0)
            end
            parent = parent.parent
        end
        nodes[#nodes + 1] = { kind = region.kind, rect = {x - px, y - py - offset, w, h},
            text = region.text, color = region.color, size = region.fontSize, justify = region.justify,
            clamp = region.w ~= nil or #region.anchors > 1,
            clips = clips, level = region.parent:GetFrameLevel(), layer = region.layer or 'OVERLAY',
            sub = region.sub or 0, order = order, alpha = region.alpha or 1 }
    end
end
local output = { width = pw, height = ph, locale = mock.locale, nodes = nodes }
local file = assert(io.open('test/output/layout-' .. mock.locale .. '.json', 'wb'))
file:write(Json(output)); file:close()
print('Exported layout: ' .. mock.locale)
