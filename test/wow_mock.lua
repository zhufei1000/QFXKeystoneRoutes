-- Minimal frame API, shared by offline integration checks and layout snapshots.
-- QFXWidgets itself is loaded verbatim; its controls are not mocked.
local M = { regions = {}, tickers = {}, events = {}, locale = arg[1] or 'zhCN', combat = false }
unpack = table.unpack
STANDARD_TEXT_FONT = 'Fonts\\LocaleDefault.ttf'
function GetLocale() return M.locale end
function issecretvalue(value) return type(value) == 'table' and value.secret end
function GetPhysicalScreenSize() return 1920, 1080 end
function GetCursorPosition() return 0, 0 end
function InCombatLockdown() return M.combat end

local generation = 0
local Methods = {}
local points = { TOPLEFT = {0,0}, TOP = {.5,0}, TOPRIGHT = {1,0}, LEFT = {0,.5},
    CENTER = {.5,.5}, RIGHT = {1,.5}, BOTTOMLEFT = {0,1}, BOTTOM = {.5,1}, BOTTOMRIGHT = {1,1} }
local function Region(kind, parent, name)
    local r = setmetatable({ kind = kind, parent = parent, name = name, shown = true,
        anchors = {}, scripts = {}, hooks = {}, children = {}, scale = 1,
        _frameLevel = parent and parent._frameLevel + 1 or 1 }, { __index = Methods })
    if parent then parent.children[#parent.children + 1] = r end
    M.regions[#M.regions + 1] = r
    if name then _G[name] = r end
    return r
end
function Methods:Fire(event, ...)
    if self.scripts[event] then self.scripts[event](self, ...) end
    for _, callback in ipairs(self.hooks[event] or {}) do callback(self, ...) end
end
function Methods:GetRect()
    if self._generation == generation then return unpack(self._rect) end
    assert(not self._solving, 'cyclic frame anchors: ' .. tostring(self.name or self.kind))
    self._solving = true
    local w = self.w or (self.kind == 'FontString' and self:GetStringWidth()) or 0
    local h = self.h or (self.fontSize or 14)
    local constraints = {}
    for _, a in ipairs(self.anchors) do
        local rx, ry, rw, rh = a.relative:GetRect()
        local p = points[a.relativePoint]
        constraints[#constraints + 1] = { p[1] * rw + rx + a.x, p[2] * rh + ry - a.y,
            points[a.point][1], points[a.point][2] }
    end
    for i = 1, #constraints do
        for j = i + 1, #constraints do
            local a, b = constraints[i], constraints[j]
            if a[3] ~= b[3] then w = (a[1] - b[1]) / (a[3] - b[3]) end
            if a[4] ~= b[4] then h = (a[2] - b[2]) / (a[4] - b[4]) end
        end
    end
    local a = constraints[1]
    local x, y = self.x or 0, self.y or 0
    if a then x, y = a[1] - a[3] * w, a[2] - a[4] * h end
    self._solving = nil
    self._generation, self._rect = generation, {x, y, w, h}
    return x, y, w, h
end
function Methods:GetWidth() local _, _, w = self:GetRect(); return w end
function Methods:GetHeight() local _, _, _, h = self:GetRect(); return h end
function Methods:SetSize(w, h)
    local changed = self.w ~= w or self.h ~= h
    self.w, self.h = w, h; generation = generation + 1
    if changed then self:Fire('OnSizeChanged', w, h) end
end
function Methods:SetWidth(w) self:SetSize(w, self.h) end
function Methods:SetHeight(h) self:SetSize(self.w, h) end
function Methods:SetPoint(point, relative, relativePoint, x, y)
    if type(relative) == 'number' then x, y, relative, relativePoint = relative, relativePoint, self.parent, point end
    relative = relative or self.parent or UIParent
    if type(relative) == 'string' then relative = assert(_G[relative]) end
    for i = #self.anchors, 1, -1 do
        if self.anchors[i].point == point then table.remove(self.anchors, i) end
    end
    self.anchors[#self.anchors + 1] = { point = point, relative = relative,
        relativePoint = relativePoint or point, x = x or 0, y = y or 0 }
    generation = generation + 1
end
function Methods:ClearAllPoints() self.anchors = {}; generation = generation + 1 end
function Methods:SetAllPoints(relative)
    self:ClearAllPoints(); self:SetPoint('TOPLEFT', relative); self:SetPoint('BOTTOMRIGHT', relative)
end
function Methods:SetParent(parent) self.parent = parent; generation = generation + 1 end
function Methods:GetParent() return self.parent end
function Methods:IsShown() return self.shown end
function Methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Methods:SetShown(value)
    value = value and true or false
    if value == self.shown then return end
    self.shown = value; self:Fire(value and 'OnShow' or 'OnHide')
end
function Methods:Show() self:SetShown(true) end
function Methods:Hide() self:SetShown(false) end
function Methods:SetScript(event, callback) self.scripts[event] = callback end
function Methods:GetScript(event) return self.scripts[event] end
function Methods:HookScript(event, callback)
    self.hooks[event] = self.hooks[event] or {}; table.insert(self.hooks[event], callback)
end
function Methods:RegisterEvent(event)
    M.events[event] = M.events[event] or {}; table.insert(M.events[event], self)
end
function Methods:SetFont(path, size, flags) assert(type(path) == 'string' and path ~= ''); self.font, self.fontSize = path, size end
function Methods:SetText(text) self.text = tostring(text or ''); generation = generation + 1 end
function Methods:GetText() return self.text end
function Methods:GetStringWidth()
    local width = 0
    for _, code in utf8.codes((self.text or ''):gsub('||', '|')) do
        width = width + (code > 127 and 1 or .54) * (self.fontSize or 14)
    end
    return width
end
function Methods:SetTextColor(...) self.color = {...} end
function Methods:SetColorTexture(...) self.color = {...} end
function Methods:SetVertexColor(...) self.vertexColor = {...} end
function Methods:SetAlpha(alpha) self.alpha = alpha end
function Methods:SetTexture(path) self.texture = path end
function Methods:SetJustifyH(value) self.justify = value end
function Methods:SetWordWrap(value) self.wordWrap = value end
function Methods:SetMaxLines(value) self.maxLines = value end
function Methods:SetFrameLevel(value) self._frameLevel = value end
function Methods:GetFrameLevel() return self._frameLevel end
function Methods:SetFrameStrata(value) self.strata = value end
function Methods:SetScale(value) self.scale = value; generation = generation + 1 end
function Methods:GetEffectiveScale() return self.scale * (self.parent and self.parent:GetEffectiveScale() or 1) end
function Methods:CreateTexture(name, layer, _, sub)
    local r = Region('Texture', self, name); r.layer, r.sub = layer, sub or 0; return r
end
function Methods:CreateFontString(name, layer) local r = Region('FontString', self, name); r.layer = layer; return r end
function Methods:SetScrollChild(child) self.scrollChild = child end
function Methods:SetVerticalScroll(value) self.scrollOffset = value end
function Methods:EnableMouse(value) self.mouse = value end
function Methods:EnableMouseWheel(value) self.mouseWheel = value end
function Methods:IsMouseOver() return true end
function Methods:SetClampedToScreen(value) self.clamped = value end
function Methods:SetSnapToPixelGrid() end
function Methods:SetTexelSnappingBias() end
function CreateFrame(kind, name, parent) return Region(kind or 'Frame', parent, name) end
UIParent = CreateFrame('Frame', 'UIParent'); UIParent:SetSize(1920, 1080)
C_Timer = { NewTicker = function(_, callback)
    local ticker = { callback = callback }
    function ticker:Cancel() self.cancelled = true end
    M.tickers[#M.tickers + 1] = ticker; return ticker
end }
function M.Tick()
    for _, ticker in ipairs(M.tickers) do if not ticker.cancelled then ticker.callback() end end
end
function M.Event(event, ...)
    for _, frame in ipairs(M.events[event] or {}) do frame:Fire('OnEvent', event, ...) end
end
GameTooltip = {
    SetOwner = function(self, owner) self.owner = owner end,
    SetText = function(self, text) self.text, self.lines = text, {} end,
    AddLine = function(self, text) self.lines[#self.lines + 1] = text end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
}
LibStub = function() error('The route browser must not create AceGUI widgets') end
return M
