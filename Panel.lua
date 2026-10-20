-- MDT-attached route browser. The renderer owns no route data or MDT state.
local ADDON_NAME, ns = ...
local MDT = _G.MythicDungeonToolsAPI or _G.MythicDungeonTools
local Panel = { routes = {} }
ns.Panel = Panel

local strings = {
    enUS = {
        title = 'QFX Keystone Routes', popular = 'Popular', views = 'Views', level = 'Level',
        count = '%d routes', author = 'By %s', saves = 'Saves', updated = 'Data %s',
        hint = 'Click to replace the last QFX route', imported = 'Loaded QFX route #%d',
        failed = 'Import failed: %s', combat = 'Import is unavailable during combat',
        empty = 'No routes for this dungeon', emptyHint = 'Select another dungeon in MDT.',
        error = 'Route data could not be loaded', errorHint = 'Reinstall the addon data file.',
        unnamed = 'Untitled route', unknown = 'Unknown dungeon', collapse = 'Collapse route list',
        expand = 'Expand route list', rank = 'Rank', score = 'Popularity',
        authorLabel = 'Author', affixes = 'Affixes', mapping = 'Mapping version',
    },
    zhCN = {
        title = 'QFX 大秘境路线', popular = '热门', views = '浏览', level = '层数',
        count = '%d 条路线', author = '作者 %s', saves = '收藏', updated = '数据 %s',
        hint = '点击替换上一条 QFX 路线', imported = '已载入 QFX 路线 #%d',
        failed = '导入失败：%s', combat = '战斗中无法导入路线',
        empty = '该副本暂无路线', emptyHint = '请在 MDT 中选择其他副本。',
        error = '路线数据加载失败', errorHint = '请重新安装插件的数据文件。',
        unnamed = '未命名路线', unknown = '未知副本', collapse = '折叠路线列表',
        expand = '展开路线列表', rank = '名次', score = '热度',
        authorLabel = '作者', affixes = '词缀', mapping = '映射版本',
    },
    zhTW = {
        title = 'QFX 傳奇鑰石路線', popular = '熱門', views = '瀏覽', level = '層數',
        count = '%d 條路線', author = '作者 %s', saves = '收藏', updated = '資料 %s',
        hint = '點擊取代上一條 QFX 路線', imported = '已載入 QFX 路線 #%d',
        failed = '匯入失敗：%s', combat = '戰鬥中無法匯入路線',
        empty = '此地城尚無路線', emptyHint = '請在 MDT 中選擇其他地城。',
        error = '路線資料載入失敗', errorHint = '請重新安裝插件的資料檔案。',
        unnamed = '未命名路線', unknown = '未知地城', collapse = '收合路線列表',
        expand = '展開路線列表', rank = '排名', score = '熱門程度',
        authorLabel = '作者', affixes = '詞綴', mapping = '映射版本',
    },
}
local L = strings[GetLocale()] or strings.enUS
local WIDTH, HEADER_H, FOOTER_H, ROW_H = 320, 98, 48, 68
local COLLAPSED_H = 64
local W, T, S

local function Text(parent, size, color)
    local fs = W.Font(parent, size, unpack(color))
    -- Keep the client's locale font if another QFX host changed its font token.
    fs:SetFont(STANDARD_TEXT_FONT, size, '')
    fs:SetJustifyH('LEFT')
    fs:SetWordWrap(false)
    fs:SetMaxLines(1)
    return fs
end

local function Plain(value)
    return (tostring(value or ''):gsub('|', '||'))
end

local function TipLine(text, color)
    GameTooltip:AddLine(text, color[1], color[2], color[3], true)
end

local function GetKeyLevel()
    local level = C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo and
        C_ChallengeMode.GetActiveKeystoneInfo()
    if issecretvalue and issecretvalue(level) then return nil end
    if type(level) == 'number' and level > 0 then return level end
end

local function LevelText(route)
    if not route.lm or not route.lx then return '-' end
    if route.lm == route.lx then return '+' .. route.lm end
    return '+' .. route.lm .. ' - +' .. route.lx
end

function Panel:IsExpanded()
    return _G.QFXKeystoneRoutesDB.settings.expanded
end

function Panel:SetVisible(visible)
    if not self.frame then return end
    if visible and not self.frame:IsShown() then self:Refresh() end
    self.frame:SetShown(visible and true or false)
end

function Panel:SetStatus(text, color)
    self.status:SetText(text or L.hint)
    self.status:SetTextColor(unpack(color or S.textMuted))
end

function Panel:ShowTooltip(row)
    local route = row._item
    if not route then return end
    GameTooltip:SetOwner(row, 'ANCHOR_LEFT')
    GameTooltip:SetText(Plain(route.t or L.unnamed), unpack(S.text))
    TipLine(L.rank .. ' #' .. tostring(route.r or 0) .. '    ' .. LevelText(route), S.warmAccentHi)
    TipLine(L.authorLabel .. ': ' .. Plain(route.a or '-'), S.textMuted)
    TipLine(L.views .. ': ' .. tostring(route.v or 0) .. '    ' ..
        L.saves .. ': ' .. tostring(route.f or 0), S.textMuted)
    TipLine(L.score .. ': ' .. tostring(route.p or 0), S.textMuted)
    if route.af and #route.af > 0 then
        local names = {}
        for _, affix in ipairs(route.af) do names[#names + 1] = Plain(affix.k) end
        GameTooltip:AddLine(L.affixes .. ': ' .. table.concat(names, ', '), 1, 1, 1, true)
    end
    if route.mv then TipLine(L.mapping .. ': ' .. Plain(route.mv), S.textMuted) end
    GameTooltip:AddLine(' ')
    TipLine(InCombatLockdown() and L.combat or L.hint, S.warmAccentHi)
    GameTooltip:Show()
end

function Panel:Import(row)
    if not row._item then return end
    if InCombatLockdown() then self:SetStatus(L.combat, S.danger) return end
    local rank = row._item.r
    local ok, err = ns:ImportRoute(ns.currentSlug, rank)
    if ok then
        self.selectedSlug, self.selectedRank = ns.currentSlug, rank
        self:SetStatus(string.format(L.imported, rank or 0), S.good)
        self.listAPI.Render()
    else
        self:SetStatus(string.format(L.failed, tostring(err)), S.danger)
    end
end

function Panel:BuildRow(row)
    row:EnableMouse(true)
    row.hover = W.Surface(row, 'BACKGROUND', 1, S.rowHover)
    row.hover:SetAllPoints()
    row.hover:Hide()
    row.selected = W.Surface(row, 'ARTWORK', 0, S.warmAccentHi)
    row.selected:SetPoint('TOPLEFT', row, 'TOPLEFT', 0, -8)
    row.selected:SetPoint('BOTTOMLEFT', row, 'BOTTOMLEFT', 0, 8)
    row.selected:SetWidth(2)
    row.selected:Hide()
    row.rank = Text(row, T.noteSize, S.textMuted)
    row.rank:SetPoint('TOPLEFT', row, 'TOPLEFT', 7, -10)
    row.rank:SetSize(25, 16)
    row.title = Text(row, T.labelSize, S.text)
    row.title:SetPoint('TOPLEFT', row, 'TOPLEFT', 36, -8)
    row.title:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -8, -8)
    row.title:SetHeight(18)
    row.author = Text(row, T.noteSize, S.textMuted)
    row.author:SetPoint('TOPLEFT', row, 'TOPLEFT', 36, -29)
    row.author:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -8, -29)
    row.author:SetHeight(15)
    row.level = Text(row, T.noteSize, S.warmAccentHi)
    row.level:SetPoint('TOPLEFT', row, 'TOPLEFT', 36, -47)
    row.level:SetSize(78, 15)
    row.stats = Text(row, T.noteSize, S.textMuted)
    row.stats:SetPoint('TOPLEFT', row, 'TOPLEFT', 118, -47)
    row.stats:SetPoint('TOPRIGHT', row, 'TOPRIGHT', -8, -47)
    row.stats:SetHeight(15)
    row.stats:SetJustifyH('RIGHT')
    local line = W.Surface(row, 'BORDER', 0, T.lineColor)
    line:SetPoint('BOTTOMLEFT', row, 'BOTTOMLEFT', 7, 0)
    line:SetPoint('BOTTOMRIGHT', row, 'BOTTOMRIGHT', -7, 0)
    line:SetHeight(1)
    row:SetScript('OnEnter', function() row.hover:Show(); self:ShowTooltip(row) end)
    row:SetScript('OnLeave', function() row.hover:Hide(); GameTooltip:Hide() end)
    row:SetScript('OnMouseUp', function(_, button)
        if button == 'LeftButton' and row:IsMouseOver() then self:Import(row) end
    end)
end

function Panel:UpdateRow(row, route)
    local settings = _G.QFXKeystoneRoutesDB.settings
    row.rank:SetText(string.format('%02d', route.r or 0))
    row.title:SetText(Plain(route.t or L.unnamed))
    row.author:SetText(settings.showAuthor and string.format(L.author, Plain(route.a or '-')) or '')
    row.level:SetText(settings.showLevels and LevelText(route) or '')
    local keyLevel = self.keyLevel
    local matches = keyLevel and route.lm and route.lx and keyLevel >= route.lm and keyLevel <= route.lx
    row.level:SetTextColor(unpack(matches and S.good or S.warmAccentHi))
    local stats = {}
    if settings.showViews then stats[#stats + 1] = L.views .. ' ' .. ns.FormatNumber(route.v) end
    if settings.showFavs then stats[#stats + 1] = L.saves .. ' ' .. ns.FormatNumber(route.f) end
    row.stats:SetText(table.concat(stats, '   '))
    row.selected:SetShown(self.selectedSlug == ns.currentSlug and self.selectedRank == route.r)
end

function Panel:Build()
    if self.frame then return end
    W = _G.QFXWidgets or ns.QFXWidgets
    if not W then return end
    T, S = W.Theme, W:Tokens()
    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetSize(WIDTH, 600)
    frame:SetFrameStrata('HIGH')
    frame:SetFrameLevel(50)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    -- Neutral surface matches MDT; shared factory tokens remain unchanged.
    local background = MDT and MDT.GetBackdropColor and { MDT:GetBackdropColor() } or { unpack(S.menuBg) }
    background[4] = 0.98
    W:SkinFrame(frame, { bg = background, border = T.lineColor })
    self.frame, self.root = frame, frame
    local accent = W.Surface(frame, 'ARTWORK', 0, S.warmAccentHi)
    accent:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
    accent:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
    accent:SetHeight(2)
    self.heading = Text(frame, T.labelSize, S.warmAccentHi)
    self.heading:SetPoint('TOPLEFT', frame, 'TOPLEFT', 14, -13)
    self.heading:SetSize(WIDTH - 60, 18)
    self.heading:SetText(L.title)
    self.dungeonName = Text(frame, T.labelSize, S.text)
    self.dungeonName:SetPoint('TOPLEFT', frame, 'TOPLEFT', 14, -38)
    self.dungeonName:SetSize(WIDTH - 114, 18)
    self.count = Text(frame, T.noteSize, S.textMuted)
    self.count:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -14, -40)
    self.count:SetSize(80, 16)
    self.count:SetJustifyH('RIGHT')
    local collapse = CreateFrame('Button', nil, frame)
    collapse:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -9)
    collapse:SetSize(24, 24)
    local hover = W.Surface(collapse, 'BACKGROUND', 0, S.rowHover)
    hover:SetAllPoints()
    hover:Hide()
    -- Texture +/- avoids missing font glyphs.
    collapse.minus = W.Surface(collapse, 'ARTWORK', 0, S.textMuted)
    collapse.minus:SetSize(10, 2)
    collapse.minus:SetPoint('CENTER')
    collapse.plus = W.Surface(collapse, 'ARTWORK', 0, S.textMuted)
    collapse.plus:SetSize(2, 10)
    collapse.plus:SetPoint('CENTER')
    collapse:SetScript('OnClick', function() self:Toggle() end)
    collapse:SetScript('OnEnter', function()
        hover:Show()
        GameTooltip:SetOwner(collapse, 'ANCHOR_LEFT')
        GameTooltip:SetText(self:IsExpanded() and L.collapse or L.expand)
        GameTooltip:Show()
    end)
    collapse:SetScript('OnLeave', function() hover:Hide(); GameTooltip:Hide() end)
    self.header = collapse
    W:BeginPage(frame)
    self.tabs = W:Tabs(frame, -66, {
        { key = 'popularity', label = L.popular },
        { key = 'views', label = L.views },
        { key = 'level', label = L.level },
    }, function() return _G.QFXKeystoneRoutesDB.settings.sortBy end,
        function(key) _G.QFXKeystoneRoutesDB.settings.sortBy = key; self:Refresh() end,
        { height = 24, padX = 20, gap = 12 })
    W:EndPage()
    self.scroll = W:ScrollPage(frame, {
        width = WIDTH - 16, height = 450, point = 'TOPLEFT', x = 2, y = -HEADER_H,
        reserveBar = true, scrollStep = ROW_H,
    })
    self.list, _, self.listAPI = W:ListRows(self.scroll.content, 0, {
        items = function() return self.routes end, rowH = ROW_H,
        rowBuilder = function(row) self:BuildRow(row) end,
        rowUpdate = function(row, route) self:UpdateRow(row, route) end,
    })
    self.empty = CreateFrame('Frame', nil, self.scroll.content)
    self.empty:SetSize(WIDTH - 40, 110)
    self.empty:SetPoint('TOPLEFT', self.scroll.content, 'TOPLEFT', 14, -20)
    self.empty.title = Text(self.empty, T.labelSize, S.text)
    self.empty.title:SetPoint('TOPLEFT')
    self.empty.title:SetSize(WIDTH - 52, 20)
    self.empty.hint = Text(self.empty, T.noteSize, S.textMuted)
    self.empty.hint:SetPoint('TOPLEFT', self.empty, 'TOPLEFT', 0, -28)
    self.empty.hint:SetSize(WIDTH - 52, 40)
    self.empty.hint:SetWordWrap(true)
    self.empty.hint:SetMaxLines(2)
    self.footer = CreateFrame('Frame', nil, frame)
    self.footer:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 14, 0)
    self.footer:SetSize(WIDTH - 28, FOOTER_H)
    local divider = W.Surface(self.footer, 'ARTWORK', 0, T.lineColor)
    divider:SetPoint('TOPLEFT')
    divider:SetPoint('TOPRIGHT')
    divider:SetHeight(1)
    self.status = Text(self.footer, T.noteSize, S.textMuted)
    self.status:SetPoint('TOPLEFT', self.footer, 'TOPLEFT', 0, -8)
    self.status:SetSize(WIDTH - 28, 16)
    self.updated = Text(self.footer, T.noteSize, S.textMuted)
    self.updated:SetPoint('BOTTOMLEFT', self.footer, 'BOTTOMLEFT', 0, 6)
    self.updated:SetSize(160, 15)
    local source = Text(self.footer, T.noteSize, S.textMuted)
    source:SetPoint('BOTTOMRIGHT', self.footer, 'BOTTOMRIGHT', 0, 6)
    source:SetText('keystone.guru')
    self.footer:EnableMouse(true)
    self.footer:SetScript('OnEnter', function()
        GameTooltip:SetOwner(self.footer, 'ANCHOR_LEFT')
        GameTooltip:SetText(self.status:GetText(), S.text[1], S.text[2], S.text[3], 1, true)
        TipLine('keystone.guru / ' .. tostring(ns.Data.generatedAt or '-'), S.textMuted)
        GameTooltip:Show()
    end)
    self.footer:SetScript('OnLeave', function() GameTooltip:Hide() end)
    frame:SetScript('OnHide', function() GameTooltip:Hide() end)
    for _, event in ipairs({ 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED', 'CHALLENGE_MODE_START',
        'CHALLENGE_MODE_COMPLETED', 'CHALLENGE_MODE_RESET' }) do frame:RegisterEvent(event) end
    frame:SetScript('OnEvent', function(_, event)
        if not frame:IsShown() then return end
        if event == 'PLAYER_REGEN_DISABLED' then self:SetStatus(L.combat, S.danger)
        else self:SetStatus(); self.keyLevel = GetKeyLevel(); self.listAPI.Render() end
    end)
    self:Refresh()
end

function Panel:UpdateLayout(sidePanel)
    if not self.frame then return end
    self.sidePanel = sidePanel or self.sidePanel
    local height = self.sidePanel and self.sidePanel:GetHeight() or 600
    height = math.max(280, math.min(height, UIParent:GetHeight() - 32))
    local expanded = self:IsExpanded()
    if self.layoutHeight == height and self.layoutExpanded == expanded then return end
    self.layoutHeight, self.layoutExpanded = height, expanded
    self.frame:SetHeight(expanded and height or COLLAPSED_H)
    self.tabs:SetShown(expanded)
    self.scroll.frame:SetShown(expanded)
    self.footer:SetShown(expanded)
    self.header.plus:SetShown(not expanded)
    local scrollHeight = height - HEADER_H - FOOTER_H
    if self.scroll.frame:GetHeight() ~= scrollHeight then
        self.scroll.frame:SetHeight(scrollHeight)
        self.scroll:Refresh()
    end
end

function Panel:Refresh()
    if not self.frame then return end
    local settings = _G.QFXKeystoneRoutesDB.settings
    local oldSlug = self.shownSlug
    self.shownSlug = ns.currentSlug
    local idx = ns:GetCurrentDungeonIndex()
    local dungeonName = idx and MDT and MDT:GetDungeonName(idx)
    self.dungeonName:SetText(Plain(dungeonName or L.unknown))
    local dungeon = ns.currentSlug and ns.Data.metaBySlug and ns.Data.metaBySlug[ns.currentSlug]
    self.routes = {}
    for _, route in ipairs(dungeon and dungeon.routes or {}) do self.routes[#self.routes + 1] = route end
    table.sort(self.routes, function(a, b)
        local key = settings.sortBy == 'views' and 'v' or (settings.sortBy == 'level' and 'lm' or 'p')
        if (a[key] or 0) ~= (b[key] or 0) then return (a[key] or 0) > (b[key] or 0) end
        return (a.r or 0) < (b.r or 0)
    end)
    self.keyLevel = GetKeyLevel()
    self.listAPI.Render()
    self.count:SetText(string.format(L.count, #self.routes))
    local failed = ns.Data.loadError ~= nil
    self.empty:SetShown(#self.routes == 0)
    self.empty.title:SetText(failed and L.error or L.empty)
    self.empty.hint:SetText(failed and L.errorHint or L.emptyHint)
    self.scroll:SetContentHeight(#self.routes > 0 and self.list:GetHeight() or 140)
    if oldSlug ~= ns.currentSlug then self.scroll:ScrollTo(0) end
    self.updated:SetText(string.format(L.updated, tostring(ns.Data.generatedAt or '-'):sub(1, 10)))
    self:SetStatus(InCombatLockdown() and L.combat or nil, InCombatLockdown() and S.danger or nil)
    W:Refresh(self.frame)
    self:UpdateLayout()
end

function Panel:Toggle()
    local settings = _G.QFXKeystoneRoutesDB.settings
    settings.expanded = not settings.expanded
    self:UpdateLayout()
    GameTooltip:Hide()
end

function ns:OnDataChanged()
    Panel:Refresh()
end
