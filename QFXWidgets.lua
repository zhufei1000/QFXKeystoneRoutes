--[[============================================================================
QFXWidgets -- drop-in settings widget factory for QFX addons (single file).

HOW TO USE
  1. Copy this file into your addon folder and add it to the .toc.
     Ship Media/addon-power.blp + LICENSE-lucide.txt for addonToggle icons;
     W:SetAddonPowerTexture(path) selects embedded host media.
     Ship Media/addon-default-icon.blp for missing addon icons;
     W:SetDefaultAddonIcon(path) selects a host's default artwork.
     Ship Media/close-x.blp + LICENSE-lucide.txt for texture close icons;
     W:SetCloseTexture(path) selects host media, false draws a non-text X.
  2. In every file:
        local addonName, ns = ...
        local W = QFXWidgets          -- or ns.QFXWidgets
  3. Build rows against any parent frame (your own panel / scroll child):
        local row, h = W:SectionHeader(parent, "GENERAL", y); y = y - h
        row, h = W:DualRow(parent, y,
            { type = "toggle", text = "Enable", getValue = ..., setValue = ... },
            { type = "slider", text = "Size", min = 10, max = 40, step = 1,
              getValue = ..., setValue = ... }); y = y - h
        row, h = W:WideButton(parent, "Open Full Settings", y, onClick); y = y - h
        y = W:Note(parent, y, "Some hint text.")
  4. On page refresh / reopen call W:Refresh() (re-reads every getValue and
     re-applies disabled states). Call W:ClearRefreshes() before rebuilding a page.
  5. For a scrollable page (own window / long page):
        local page = W:ScrollPage(parent)          -- parent must already be sized
        local y = -W.Theme.pad
        ... build rows into page.content ...
        page:SetContentHeight(-y + W.Theme.pad)    -- shows the scrollbar if needed
     The scrollbar is self-drawn (wheel + thumb drag) and hides when all fits.

CFG TYPES (DualRow left/right slot)
  { type = "label",  text }
  { type = "toggle", text, getValue, setValue, tooltip, disabled, disabledTooltip }
      -- ordinary feature settings ONLY; retains the rectangular switch
  { type = "addonToggle", text, getText, icon, getIcon, getValue, setValue,
    enableText, disableText, scopeTooltip, reloadTooltip, disabled, disabledTooltip }
      -- addon enable/disable; also used for builtin middle tiles by project rule
      -- getIcon() -> texture, optional atlas, optional texture coordinates
  W:AddonButtons(parent, y, leftCfg, rightCfg, { height = 60 })
      -- two equal addon buttons; full-height original icon, name, power button
      -- middle-column rule: builtin modules also always display power
      -- cfg.onSelect(), cfg.isSelected(), cfg.tooltip select/show addon details
      -- optional cfg.getBadges() -> { { text, color?, texture? }, ... } overlays corner badges
  W:SpeechBubble(anchor, { width = 236 })
      -- factory callout above a button; SetText(text), Show(), Hide()
  W:StatusTicker(parent, { items = function, width, height, speed, stateTexts })
      -- compact measured statuses; native right-to-left loop, hover pause
  { type = "slider", text, min, max, step, getValue, setValue, tooltip,
    trackWidth, valueSuffix, steppers = true, disabled, disabledTooltip }
      -- default: no +/- column because the value box accepts direct input;
      -- set steppers = true only when a page explicitly needs click nudging
  { type = "dropdown", text, values, order, getValue, setValue, tooltip,
    width, disabled, disabledTooltip }
  { type = "segmented", text, values, order, getValue, setValue, minWidth,
    tooltip, onSelect, disabled, disabledTooltip }
      -- 2-4 mutually exclusive pills, right-aligned, active = accent fill
  { type = "button", text, onClick, width, disabled, disabledTooltip }
  { type = "buttonRow", gap, buttons = { { text, onClick, width, tooltip,
    disabled, disabledTooltip }, ... } }  -- right-aligned cluster (nudge pads)
  { type = "color",  text, getValue, setValue, tooltip, alpha = true }
      -- get/set r, g, b [, a]; alpha = true shows the alpha channel in the picker
  { type = "colorMode", text, modes, order, customKey = "custom", getMode, setMode,
    getColor, setColor, defaultColor, defaultMode, alpha, tooltip, resetTooltip }
      -- mode dropdown + color swatch (visible while mode == customKey) + reset
  { type = "keybind", text, getValue, setValue, tooltip, width, noneText,
    captureText, conflicts, clearOnRightClick }
      -- click to capture (keyboard / mouse wheel / side buttons), Esc cancels,
      -- right-click clears; conflicts(key) -> name turns the label red
  { type = "input",  text, getValue, setValue, tooltip, width, numeric, layout }
      -- layout = "stacked": full-width content row, title above the input;
      -- use as the only slot; width follows the parent instead of cfg.width

EXTRA CONTROLS
  W:ResetRows(parent)   optional: restart the zebra stripes at a page start
                        (SectionHeader also resets them automatically).
  W:CheckboxDropdown(parent, width, frameLevel, items, getFn, setFn, opts)
      items = { { key, label, tooltip }, ... }; getFn(key) -> bool;
      setFn(key, value). Returns dropdownButton, refreshFn.
  W:ColorSwatch(parent, frameLevel, getFn, setFn, opts)
      getFn -> r, g, b; setFn(r, g, b). Returns swatchButton.
  W:Tabs(parent, y, items, getActive, onSelect, opts)      -- frame, height
  W:CheckGrid(parent, y, columns, entries, opts)           -- frame, height
  W:ReorderList(parent, y, { items, onChange, rowH })      -- frame, height
  W:Cog(anchor, { title, rows, width, onReset })           -- cog, openFn
  W:SearchableDropdown(parent, width, level, items, getValue, setValue, opts)
      -- dd, refreshFn; items table or function, re-read on every open.
      -- items = { { key, label, tooltip, group, action = { text | icon,
      --   tooltip, onClick(key) } }, ... } -- groups render as headings;
      -- action renders a small right-aligned button (preview/test/remove)
  W:Segmented(parent, level, values, order, getValue, setValue, opts)
      -- region, refreshFn, firstBtn (caller anchors the region)
  W:ScrollPage(parent, opts)     -- page { frame, content, SetContentHeight(h), ... }
  W:MultilineBox(parent, y, cfg) -- frame, height (GetText/SetText/Commit)
  W:Confirm(opts | text)         -- modal confirm dialog (accept/cancel callbacks)
  W:CopyDialog(text, opts)       -- modal factory-drawn copy dialog: dim,
      -- panel, preselected read-only EditBox, footer close; Esc/backdrop/X
      -- dismiss. opts = { title, hint, closeText, closeTooltip, width,
      -- height, multiline, selectAll = true, onClose }; dialog.editBox,
      -- dialog:Close()
  W:MediaList(kind) / W:MediaValues(kind) / W:FetchMedia(kind, name)
  W:PreviewSound(name, channel)  -- SharedMedia helpers (all optional)
  W:StatusRow(parent, y, { label, getText, color, wrap })  -- frame, height
  W:ResetRow(parent, y, { label, buttons = { { text, onReset, confirm } } })
  W:TabPanel(parent, y, { tabs = { { key, label, build,
      subtabs = { { key, label, build }, ... } } }, getActive, onSelect })
      -- one- or two-level tabs: frame, height, api; GetContent(key[, subKey]),
      -- Show(key[, subKey]), GetActiveSub(key), Refresh()
  W:ListRows(parent, y, { items, rowH, columns, header, rowBuilder, rowUpdate })
      -- frame, height, api (Render(), GetRow(i), GetCount(), ColumnX(i))
  W:CheckGrid(parent, y, cols, entries, { maxSelected, limitTooltip, groups })
      -- entries may carry group, icon, help; maxSelected dims/blocks extras
  W:ColorGrid(parent, y, cols, entries, opts)  -- per-cell color swatches
  W:Slider(parent, y, cfg)       -- full-width slider, label above the track
  W:IconPicker(parent, level, getValue, setValue, { items, tooltip, size })
      -- icon button + searchable menu; items may carry .icon
  W:SpellIconItems({ id | { id, label }, ... }) -- items with spell textures
  W:MakeMenu(anchor, spec)       -- custom menu (see spec at its definition):
      -- item lists scroll past maxH/maxVisible, rows may set disabled /
      -- disabledTooltip, spec.dynamic + anchor._invalidateMenu() rebuild rows.
  W:BeginPage(owner) ... W:EndPage()  -- scope RegisterRefresh calls to a page;
      -- BeginPage also drops that page's old callbacks. W:RefreshPage(owner)
      -- refreshes one page, W:Refresh() still refreshes everything.
  W:IsCombatLocked() / W:InCombatLocked() -- true while the client is locked
  W:IsDisabled(cfg) -- explicit disabled OR cfg.blockInCombat in combat
  W.SkinFrame(frame, opts) -- factory bg + border on a host window
  W:Perimeter(frame, opts) -- warm-into-accent gradient frame border (the QFX
      -- brand hand-off: warm top-left, accent blue body, warm bottom-right
      -- corner); re-fits the host on resize
  W:CloseButton(parent, opts) -- warm-orange texture X; no translatable glyph
  W:IconButton(parent, { texture, size, alpha, hoverAlpha, tint, tooltip,
      tooltipText, onClick, point, relPoint, x, y })
      -- small glyph button for host chrome (titles/headers); the host anchors
      -- it itself unless opts.point is given, and can tint btn._icon
  W.Surface / W.Border -- raw draw helpers for custom chrome
  W.IsSecret(v) -- 12.x secret-value guard for custom measured text

SKIN
  ONE custom-drawn renderer (QFXUI blue/navy). Controls use solid-color layers,
  square switch thumbs, circular slider thumbs, and a compact dropdown
  chevron; Blizzard assets are only used for the color picker popup and the
  options gear texture.
    W:SetArrowTexture(path | false)  -- default: bundled white chevron; a path
                                    -- overrides it, false uses the V fallback
    W:SetCloseTexture(path | false)  -- white-alpha X; false or missing media
                                    -- draws two lines, never a font glyph
    W:SetCircleTexture(path | false) -- anti-aliased circle for rounded primitives
    W:SetPillTexture(path | false)   -- legacy anti-aliased 2:1 capsule texture
    W:SetSliderThumbTexture(path | false) -- precomposed disc slider thumb
    W:SetMediaFormat("png" | "blp")  -- bundled art format (default blp: the .blp
                                     -- twins carry 2x resolution and a pre-baked
                                     -- mip chain, sampled with TRILINEAR)
    W:SetSkin{ accent = {...}, controlBg = {...} }  -- override any token
      -- Stock section title bars use the warm amber hand-off and the zebra
      -- rows a raised blue wash; both are plain skin tokens
      -- (sectionBarFrom/To/Edge, rowBgOdd/Even) a host may override.
    W:Banner(frame, { logo, watermark, glow, ... })  -- brand header for a host
                                     -- window: left logo (kept clear of text),
                                     -- faded right watermark behind the labels,
                                     -- auto-fitted to the host's size
    W:SetSkin{ checkFill = {...}, thumb = {...} }   -- selection mark / slider
                                 -- thumb tint; the check mark defaults to the
                                 -- warm accent, the thumb to the neutral knob
                                 -- colour, and the dropdown arrow only turns
                                 -- warm while hovered
    W:SetSkin()                                     -- restore stock skin
  Layout tokens live in W.Theme (row heights, paddings, zebra, label gap).

NOTES
  * No AceGUI, no external media.
  * English-first sizing: labels live in the left column, controls are
    right-anchored; long labels ellipsize and show the full text on hover
    (the clamp retries one frame later if the row was not sized yet).
  * Combat: pass blockInCombat = true on a cfg to keep it read-only while the
    client is locked (optional combatTooltip for the reason). Call W:Refresh()
    on PLAYER_REGEN_ENABLED so the control comes back when combat ends.
  * Pages: wrap the build in W:BeginPage(owner)/W:EndPage() and rebuilds stay
    leak-free (old callbacks of that owner are dropped first); W:Refresh(owner)
    / W:RefreshPage(owner) refresh only one page.
  * Menus sit on FULLSCREEN_DIALOG level 200 and close through a full-screen
    click catcher (deterministic; no GetMouseFocus guessing). Lists longer
    than maxH/maxVisible scroll with a self-drawn bar.
  * Singleton: if another copy already loaded, this file reuses it (version
    checked), so copying it into several addons never duplicates memory.
  * No SavedVariables. Event and OnUpdate handlers are limited to open popups,
    key capture, animations and active drags; idle controls do no per-frame work.
    Persistent state stays in your addon's getValue/setValue closures.

TODO -- NOT IMPLEMENTED YET (build only when a page needs it)
  * self-drawn color picker popup (HSV / hex / recent / favorites) -- the color
    controls currently open Blizzard's ColorPickerFrame
  * self-drawn reset icon for the colorMode row (currently a text "R")
  * scroll page: smooth/clamped wheel only -- no keyboard (PgUp/PgDn) support
  * TripleRow / free-width column layouts
  * icon picker: atlas / item-icon sources (spell list works via SpellIconItems)
  * self-drawn tooltip skin (GameTooltip stays native)
  * ReorderList: internal scroll + auto-scroll while dragging long lists
  * reorder strip for icon rows (drag-to-reorder preview with an optional fixed
    middle item, live preview of the configured bar) -- hosts build their own
    today; EllesmereUI has no equivalent control to model it on
  * ListRows: optional drag-reorder / row selection / built-in zebra restart
    (call W:ResetRows(listFrame) before api.Render() to restart stripes)
  * SearchableDropdown: arrow-key row navigation (Enter picks the first match)
============================================================================]]

local addonName, ns = ...

-- Disabled/blocked hover reasons arrive as a string, a number, or a function
-- returning either. A predicate that reports "disabled" without a reason makes
-- that function return nil, so resolving it with `fn() or fn` would hand the
-- function itself to GameTooltip:SetText and raise
-- "bad argument #2 to '?' (Usage: self:SetText(text [, color, alpha, wrap]))".
-- Resolve to a non-empty string or nil and skip the tooltip otherwise.
local function ResolveTooltipText(value)
    if type(value) == "function" then
        local ok, result = pcall(value)
        value = ok and result or nil
    end
    if type(value) == "number" then value = tostring(value) end
    if type(value) ~= "string" or value == "" then return nil end
    return value
end

-- Item getters may be functions as well; a nil result must become an empty list
-- instead of the function itself (#/ipairs on a function raises).
local function ResolveList(value)
    if type(value) == "function" then
        local ok, result = pcall(value)
        value = ok and result or nil
    end
    if type(value) ~= "table" then return {} end
    return value
end

-- AddonButtons is the project's middle-column factory: every tile uses power.
-- Ordinary settings rows keep the existing rectangular toggle renderer.
local function InstallAddonToggle(W)
    local previousRevision = tonumber(W.ADDON_TOGGLE_REVISION) or 0
    if previousRevision >= 14
        and W.MIDDLE_POWER_ONLY
        and type(W.AddonButtons) == "function"
        and type(W.SetDefaultAddonIcon) == "function"
        and W.Skin and type(W.Skin.addonToggle) == "function"
        and W.Skins and W.Skins.qfx and type(W.Skins.qfx.addonToggle) == "function" then return end
    local function BundledTexture(name)
        local provider
        if addonName == "QFXAddonManager" or addonName == "QFXWidgets" then provider = addonName
        elseif C_AddOns and C_AddOns.DoesAddOnExist then
            if C_AddOns.DoesAddOnExist("QFXAddonManager") then provider = "QFXAddonManager"
            elseif C_AddOns.DoesAddOnExist("QFXWidgets") then provider = "QFXWidgets" end
        end
        if not provider then return false end
        local format = W.MediaFormat == "png" and "png" or "blp"
        return "Interface\\AddOns\\" .. provider .. "\\Media\\" .. name .. "." .. format
    end
    local function DefaultIcon()
        return W.DefaultAddonIcon or BundledTexture("addon-default-icon") or "Interface\\Icons\\INV_Misc_Gear_01"
    end
    local function BuildAddonToggle(region, frame, cfg)
        local S, T = W:Tokens(), W.Theme
        local button = CreateFrame("Button", nil, region)
        button:SetSize(S.addonPowerSize or T.controlH, S.addonPowerSize or T.controlH)
        local rightPad = cfg.tile and T.sidePad or T.rightPad
        button:SetPoint("RIGHT", region, "RIGHT", -rightPad, 0)
        button._qfx = "addonToggle"
        button:EnableMouse(true)
        button:RegisterForClicks("LeftButtonUp")

        -- Bundled Lucide power icon: white artwork with alpha, not EUI media.
        local glyph = W.NoSnap(button:CreateTexture(nil, "OVERLAY"))
        local glyphSize = S.addonPowerIconSize or 18
        glyph:SetSize(glyphSize, glyphSize)
        glyph:SetPoint("CENTER", button, "CENTER", 0, 0)
        button._powerIcon = glyph
        -- An embedding host that ships no media still gets a visible control.
        local fallback = button:CreateFontString(nil, "OVERLAY")
        fallback:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        fallback:SetPoint("CENTER", button, "CENTER", 0, 0)
        button._powerFallback = fallback
        local function PowerTexture()
            if W.AddonPowerTexture ~= nil then return W.AddonPowerTexture end
            return BundledTexture("addon-power")
        end

        local icon
        if cfg.icon or cfg.getIcon then
            icon = region:CreateTexture(nil, "ARTWORK")
            local size = S.addonIconSize or T.controlH
            icon:SetSize(size, size)
            icon:SetPoint("LEFT", region, "LEFT", cfg.tile and 0 or T.sidePad, 0)
            region._icon = icon
        end
        local blocked = CreateFrame("Frame", nil, button)
        blocked:SetAllPoints()
        blocked:SetFrameLevel(button:GetFrameLevel() + 10)
        blocked:EnableMouse(true)
        local hovering = false
        local function Read(v)
            if type(v) == "function" then return v() end
            return v
        end
        local function CurrentText() return Read(cfg.getText) or cfg.text or "" end
        local function ShowTooltip(owner)
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            local on = cfg.getValue and cfg.getValue()
            local action = Read(on and cfg.disableText or cfg.enableText) or (on and "Disable addon" or "Load addon")
            GameTooltip:SetText(action, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
        local function Render()
            local currentButton = button
            region._control = button
            local on = cfg.getValue and cfg.getValue() and true or false
            local loaded = on
            if cfg.getLoaded then loaded = cfg.getLoaded() and true or false end
            local off = W:IsDisabled(cfg)
            button._state = on
            local path = PowerTexture()
            if path then glyph:SetTexture(path, "CLAMP", "CLAMP", "TRILINEAR") end
            glyph:SetShown(path and true or false)
            fallback:SetShown(not path)
            fallback:SetText(on and "ON" or "OFF")
            -- Reflect saved enablement immediately; loaded state only styles the tile.
            local tint = on and S.good or S.addonPowerOff
            glyph:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 1)
            fallback:SetTextColor(tint[1], tint[2], tint[3], tint[4] or 1)
            glyph:SetAlpha(1)
            fallback:SetAlpha(1)
            button._loaded = loaded
            button:SetAlpha(off and 0.35 or 1)
            blocked:SetShown(off)
            button._blocked = off
            local label = region._label
            local inset = T.sidePad
            if icon then
                local texture, atlas, coords
                if cfg.getIcon then texture, atlas, coords = cfg.getIcon() else texture, atlas, coords = cfg.icon, cfg.iconAtlas, cfg.iconCoords end
                texture = tonumber(texture) or texture
                if texture == "" then texture = nil end
                if atlas == "" then atlas = nil end
                if not texture and not atlas then coords = nil end
                local atlasApplied = false
                if atlas and icon.SetAtlas then
                    local ok = pcall(icon.SetAtlas, icon, atlas, false)
                    atlasApplied = ok
                    if not ok then icon:SetTexture(texture or DefaultIcon(), "CLAMP", "CLAMP", "TRILINEAR") end
                else
                    icon:SetTexture(texture or DefaultIcon(), "CLAMP", "CLAMP", "TRILINEAR")
                end
                if coords then icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                elseif not atlasApplied then icon:SetTexCoord(0, 1, 0, 1) end
                local size = cfg.tile and region:GetHeight() or (S.addonIconSize or T.controlH)
                icon:SetSize(size, size)
                inset = cfg.tile and (size + T.sidePad) or (inset + size + (S.addonIconGap or 6))
            end
            if label then
                local subLabel = region._subLabel
                local subText = Read(cfg.getSubText) or cfg.subText or ""
                local width = math.max(1, region:GetWidth() - inset - rightPad - currentButton:GetWidth() - T.labelGap)
                label:ClearAllPoints()
                if type(subText) == "string" and subText ~= "" and subText ~= CurrentText() and subLabel then
                    -- Dual-line tile name: Chinese first line, English below. Both
                    -- lines keep the full label width (icon edge to power button).
                    label:SetPoint("LEFT", region, "LEFT", inset, 7)
                    subLabel:ClearAllPoints()
                    subLabel:SetPoint("LEFT", region, "LEFT", inset, -7)
                    subLabel:SetPoint("RIGHT", currentButton, "LEFT", -T.labelGap, 0)
                    subLabel:SetJustifyH("LEFT")
                    subLabel:SetWordWrap(false)
                    W.TruncateToFit(subLabel, subText, width)
                    subLabel:Show()
                else
                    label:SetPoint("LEFT", region, "LEFT", inset, 0)
                    if subLabel then subLabel:Hide() end
                end
                label:SetPoint("RIGHT", currentButton, "LEFT", -T.labelGap, 0)
                label:SetJustifyH("LEFT")
                label:SetWordWrap(false)
                W.TruncateToFit(label, CurrentText(), width)
            end
        end
        button:SetScript("OnClick", function()
            if W:IsDisabled(cfg) then return end
            if cfg.setValue then cfg.setValue(not (cfg.getValue and cfg.getValue())) end
            Render()
            if hovering then ShowTooltip(button) end
        end)
        local function Hover(value)
            hovering = value
            if region._setAddonHover then region._setAddonHover(value) end
            Render()
        end
        button:SetScript("OnEnter", function(self) Hover(true); ShowTooltip(self) end)
        button:SetScript("OnLeave", function() Hover(false); GameTooltip:Hide() end)
        blocked:SetScript("OnEnter", function(self) Hover(true); ShowTooltip(self) end)
        blocked:SetScript("OnLeave", function() Hover(false); GameTooltip:Hide() end)
        region._control = button
        region._addonRefresh = Render
        W:RegisterRefresh(Render)
        Render()
        return button
    end
    local defaults = {
        addonPowerSize = 20, addonPowerIconSize = 18,
        addonPowerOff = { 0.75, 0.75, 0.75, 1 },
        addonBadgeCross = { 1, 0, 0, 1 },
        addonIconSize = 20, addonIconGap = 6,
        subLabelSize = 12,
        addonTileHover = { 0.035, 0.210, 0.360, 1 },
        addonTileUnloadedAlpha = 0.75, addonTileBorderSize = 2,
    }
    local function Extend(skin)
        if not skin then return end
        skin.addonToggle = BuildAddonToggle
        -- Upgrade the old built-in outline while retaining custom skin sizes.
        if previousRevision < 5 and skin.addonTileBorderSize == 1 then skin.addonTileBorderSize = 2 end
        for key, value in pairs(defaults) do if skin[key] == nil then skin[key] = value end end
    end
    Extend(W.Skins and W.Skins.qfx)
    Extend(W.Skin)
    W.Theme.navRowH = W.Theme.navRowH or 30
    W.Theme.addonTileGap = W.Theme.addonTileGap or 4
    W.Theme.addonTileColumnGap = W.Theme.addonTileColumnGap or 8
    W.ADDON_TOGGLE_REVISION = 14
    W.MIDDLE_POWER_ONLY = true
    W.EnsureAddonToggle = InstallAddonToggle
    function W:SetAddonPowerTexture(path)
        self.AddonPowerTexture = path
        return path
    end
    function W:SetDefaultAddonIcon(path)
        self.DefaultAddonIcon = path
        return path
    end
    -- Paired addon buttons use the full row height for original addon icons.
    -- The body selects details; the nested power button changes enablement.
    function W:AddonButtons(parent, y, leftCfg, rightCfg, opts)
        opts = opts or {}
        local T, S = self.Theme, self:Tokens()
        local height = opts.height or T.navRowH * 2
        local gap = opts.columnGap or T.addonTileColumnGap
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(self.ContentWidth(parent), height)
        frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
        local columns = opts.columns or 2
        local function Build(cfg)
            if not cfg then return nil end
            cfg.tile = true
            local region = CreateFrame("Button", nil, frame)
            region:SetSize(math.max(1, (frame:GetWidth() - gap) / 2), height)
            region:SetFrameLevel(frame:GetFrameLevel() + 6)
            region:EnableMouse(true)
            region:RegisterForClicks("LeftButtonUp")
            region._qfx = "addonButton"
            region._label = self.Font(region, T.labelSize, S.text[1], S.text[2], S.text[3], 1)
            region._label:SetText(cfg.text or "")
            region._subLabel = self.Font(region, T.subLabelSize or math.max(10, T.labelSize - 2), S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
            region._subLabel:SetText("")
            region._subLabel:Hide()
            local bg = self.Surface(region, "BACKGROUND", 0, S.controlBg)
            bg:SetAllPoints()
            region._bg = bg
            local sheen = self.Surface(region, "BACKGROUND", 1, S.buttonSheen or { 1, 1, 1, 0.04 })
            sheen:SetPoint("TOPLEFT", region, "TOPLEFT", 2, -2)
            sheen:SetPoint("TOPRIGHT", region, "TOPRIGHT", -2, -2)
            sheen:SetHeight(6)
            local border = self.Border(region, region:GetFrameLevel(), S.border, 1, S.addonTileBorderSize)
            border:EnableMouse(false)
            region._border = border
            local hover = false
            local function Paint()
                local selected = cfg.isSelected and cfg.isSelected()
                local loaded = not cfg.getLoaded or cfg.getLoaded() and true or false
                -- Share NavList's warm selection palette, including unloaded items.
                local color = selected and (S.closeBgHi or S.selectedFill or S.accent)
                    or (hover and S.addonTileHover or S.controlBg)
                local edge = selected and (S.warmAccent or S.borderHi or S.border) or (hover and S.borderHi or S.border)
                local function Gray(c)
                    if loaded or selected then return c end
                    local gray = c[1] * 0.2126 + c[2] * 0.7152 + c[3] * 0.0722
                    return { gray, gray, gray, c[4] or 1 }
                end
                color, edge = Gray(color), Gray(edge)
                if cfg.motion and self.AnimateColor then
                    self:AnimateColor(bg, color, "surface", region)
                    self:AnimateColor(border, edge, "border", region)
                else
                    bg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
                    border._setBorder(edge)
                end
                region:SetAlpha((loaded or selected) and 1 or S.addonTileUnloadedAlpha)
                if region._icon then region._icon:SetDesaturated(not loaded) end
                local text = selected and (S.warmAccentHi or S.text) or (loaded and S.text or S.textMuted)
                if cfg.motion and self.AnimateColor then
                    self:AnimateColor(region._label, text, "text", region)
                else
                    region._label:SetTextColor(text[1], text[2], text[3], text[4] or 1)
                end
                if region._subLabel then
                    local sub = S.textMuted
                    region._subLabel:SetTextColor(sub[1], sub[2], sub[3], (sub[4] or 1) * 0.9)
                end
                region._selected, region._loaded, region._hover = selected and true or false, loaded, hover
            end
            region._setAddonHover = function(value) hover = value; Paint() end
            BuildAddonToggle(region, frame, cfg)
            -- Optional static corner badges share the tile refresh and pool.
            -- Hosts provide labels/state; the factory owns drawing and placement.
            if cfg.getBadges then
                local badges = {}
                region._badges = badges
                self:RegisterRefresh(function()
                    local data = cfg.getBadges() or {}
                    local badgeAnchor = region._icon or region
                    local badgeSize = (region._icon and region._icon:GetWidth() or region:GetHeight()) / 2
                    for index = 1, math.max(#data, #badges) do
                        local badge = badges[index]
                        if data[index] and not badge then
                            badge = CreateFrame("Frame", nil, region)
                            badge:SetSize(badgeSize, badgeSize)
                            badge:EnableMouse(false)
                            local icon = badge:CreateTexture(nil, "ARTWORK", nil, 7)
                            icon:SetAllPoints()
                            icon:SetVertexColor(1, 1, 1, 1)
                            local ring = badge:CreateTexture(nil, "ARTWORK", nil, 2)
                            ring:SetAllPoints()
                            ring:SetTexture(BundledTexture("circle-crisp"))
                            local center = badge:CreateTexture(nil, "ARTWORK", nil, 3)
                            center:SetSize(18, 18)
                            center:SetPoint("CENTER")
                            center:SetTexture(BundledTexture("circle-crisp"))
                            local text = self.Font(badge, T.labelSize, 1, 1, 1, 1)
                            text:SetPoint("CENTER", 0, 0)
                            local cross = {}
                            for strokeIndex, angle in ipairs({ math.pi / 4, -math.pi / 4 }) do
                                local stroke = self.Surface(badge, "OVERLAY", 7, S.addonBadgeCross)
                                stroke:SetSize(17, 3)
                                stroke:SetPoint("CENTER", badge, "CENTER", 0, 0)
                                stroke:SetRotation(angle)
                                cross[strokeIndex] = stroke
                            end
                            badge.ring, badge.center, badge.text, badge.cross = ring, center, text, cross
                            badge.icon = icon
                            badges[index] = badge
                        end
                        if badge then
                            badge:SetShown(data[index] ~= nil)
                            if data[index] then
                                badge:SetSize(badgeSize, badgeSize)
                                badge:ClearAllPoints()
                                if index <= 2 then
                                    badge:SetPoint("BOTTOMLEFT", badgeAnchor, "BOTTOMLEFT", (index - 1) * badgeSize, 0)
                                else
                                    badge:SetPoint("TOPLEFT", badgeAnchor, "TOPLEFT", (index - 3) * badgeSize, 0)
                                end
                                local textured = data[index].texture and true or false
                                badge.icon:SetShown(textured)
                                if textured then
                                    badge.icon:SetTexture(data[index].texture, "CLAMP", "CLAMP", "TRILINEAR")
                                end
                                badge.ring:SetShown(not textured)
                                badge.center:SetShown(not textured)
                                badge.text:SetShown(not textured)
                                local tint = data[index].color or S.warmAccent or S.accent
                                badge.ring:SetVertexColor(tint[1], tint[2], tint[3], 1)
                                badge.center:SetVertexColor(S.controlBg[1], S.controlBg[2], S.controlBg[3], 1)
                                badge.text:SetText(data[index].text or "")
                                badge.text:SetTextColor(tint[1], tint[2], tint[3], 1)
                                for _, stroke in ipairs(badge.cross) do
                                    stroke:SetShown(not textured)
                                    local crossColor = S.addonBadgeCross
                                    stroke:SetColorTexture(crossColor[1], crossColor[2], crossColor[3], 1)
                                end
                            end
                        end
                    end
                end)
            end
            if region._icon then
                local separator = self.Surface(region, "OVERLAY", 1, S.border)
                separator:SetWidth(1)
                separator:SetPoint("TOPLEFT", region._icon, "TOPRIGHT", 0, -2)
                separator:SetPoint("BOTTOMLEFT", region._icon, "BOTTOMRIGHT", 0, 2)
                separator:SetAlpha(0.55)
            end
            region:SetScript("OnClick", function() if cfg.onSelect then cfg.onSelect() end end)
            region:SetScript("OnEnter", function(owner)
                region._setAddonHover(true)
                GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
                GameTooltip:SetText((cfg.getText and cfg.getText()) or cfg.text or "", 1, 1, 1, 1, true)
                local tip = ResolveTooltipText(cfg.tooltip)
                if tip then GameTooltip:AddLine(tip, 1, 1, 1, true) end
                GameTooltip:Show()
            end)
            region:SetScript("OnLeave", function() region._setAddonHover(false); GameTooltip:Hide() end)
            self:RegisterRefresh(Paint)
            Paint()
            return region
        end
        frame._leftRegion, frame._rightRegion = Build(leftCfg), Build(rightCfg)
        local function Layout()
            local width = math.max(1, (frame:GetWidth() - (columns == 2 and gap or 0)) / columns)
            for i, region in ipairs({ frame._leftRegion, frame._rightRegion }) do
                region:SetSize(width, height)
                region:ClearAllPoints()
                region:SetPoint(i == 1 and "TOPLEFT" or "TOPRIGHT", frame, i == 1 and "TOPLEFT" or "TOPRIGHT", 0, 0)
                region._addonRefresh()
            end
        end
        frame:SetScript("OnSizeChanged", Layout)
        frame:SetScript("OnShow", Layout)
        frame._layout = Layout
        function frame:SetColumns(value) columns = value == 1 and 1 or 2; Layout() end
        Layout()
        return frame, height
    end
end

-- Additive motion capability. Hosts own state; the factory owns all effects.
local function InstallMotion(W)
    if (tonumber(W.MOTION_REVISION) or 0) >= 3 and W.MOTION_NATIVE_SWEEP and W.MOTION_NATIVE_ALPHA then return end
    local enabled = W.MotionEnabled
    if W.SetMotionEnabled then W:SetMotionEnabled(false) end
    W.MotionEnabled = enabled
    local tint = { 1, 0.92, 0.72, 0.45 }
    local meteorTint = { 0.55, 0.85, 1, 0.65 }
    if W.Skin and not W.Skin.brandSheen then W.Skin.brandSheen = tint end
    if W.Skins and W.Skins.qfx and not W.Skins.qfx.brandSheen then W.Skins.qfx.brandSheen = tint end
    if W.Skin and not W.Skin.brandMeteor then W.Skin.brandMeteor = meteorTint end
    if W.Skins and W.Skins.qfx and not W.Skins.qfx.brandMeteor then W.Skins.qfx.brandMeteor = meteorTint end
    local jobs, driver = {}, W.MotionDriver
    local function Visible(owner)
        return owner and owner:IsVisible()
    end
    local function Descendant(owner, ancestor)
        while owner do
            if owner == ancestor then return true end
            owner = owner:GetParent()
        end
        return false
    end
    local function Idle()
        if driver and not next(jobs) then
            driver:SetScript("OnUpdate", nil)
            driver:Hide()
        end
    end
    local function Stop(key, settle)
        local job = jobs[key]
        if not job then return end
        jobs[key] = nil
        if job.finish then job.finish(false, settle) end
        Idle()
    end
    local function Update(_, elapsed)
        for key, job in pairs(jobs) do
            if not Visible(job.owner) then
                Stop(key, true)
            else
                job.elapsed = job.elapsed + elapsed
                local t = job.elapsed - job.delay
                if t >= 0 then
                    local p = job.loop and t or math.min(1, t / job.duration)
                    job.step(job.loop and p or (1 - (1 - p) * (1 - p)))
                    if not job.loop and p >= 1 and jobs[key] == job then
                        jobs[key] = nil
                        if job.finish then job.finish(true) end
                    end
                end
            end
        end
        Idle()
    end
    local function Run(key, owner, duration, delay, step, finish, loop)
        Stop(key)
        if not W:MotionAllowed() or not Visible(owner) then
            if not loop then step(1) end
            if finish then finish(false) end
            return
        end
        jobs[key] = { owner = owner, duration = math.max(0.01, duration), delay = delay or 0,
            elapsed = 0, step = step, finish = finish, loop = loop }
        if not owner._qfxMotionCleanup then
            owner._qfxMotionCleanup = true
            owner:HookScript("OnHide", function(self) W:StopMotion(self) end)
        end
        if not driver then
            driver = CreateFrame("Frame", nil, UIParent)
            driver:EnableMouse(false)
            W.MotionDriver = driver
        end
        driver:Show()
        driver:SetScript("OnUpdate", Update)
    end
    function W:MotionAllowed() return self.MotionEnabled ~= false end
    function W:SetMotionEnabled(enabled)
        self.MotionEnabled = enabled and true or false
        if not self.MotionEnabled then
            for key in pairs(jobs) do Stop(key, true) end
            if self._motionBrands then
                for holder in pairs(self._motionBrands) do if holder.StopSheen then holder:StopSheen() end end
            end
        elseif self._motionBrands then
            for holder in pairs(self._motionBrands) do holder:PlaySheen() end
        end
    end
    function W:StopMotion(owner)
        for key, job in pairs(jobs) do
            if Descendant(job.owner, owner) then Stop(key, true) end
        end
        if self._motionBrands then
            for holder in pairs(self._motionBrands) do
                if holder.StopSheen and Descendant(holder.frame, owner) then holder:StopSheen() end
            end
        end
    end
    function W:GetMotionActivity()
        local count = 0
        for _ in pairs(jobs) do count = count + 1 end
        return count
    end
    -- A reusable color tween samples its current color when redirected.
    function W:AnimateColor(target, color, kind, owner)
        local state = target._qfxColorMotion
        local function Paint(c)
            if kind == "border" then target._setBorder(c)
            elseif kind == "text" then target:SetTextColor(c[1], c[2], c[3], c[4])
            else target:SetColorTexture(c[1], c[2], c[3], c[4]) end
        end
        if not state then
            state = { current = {}, from = {}, to = {} }
            target._qfxColorMotion = state
            for i = 1, 4 do state.current[i], state.to[i] = color[i] or 1, color[i] or 1 end
            Paint(state.current)
            return
        end
        local same = true
        for i = 1, 4 do if state.to[i] ~= (color[i] or 1) then same = false end end
        if same then return end
        Stop(state)
        for i = 1, 4 do
            state.from[i], state.to[i] = state.current[i], color[i] or 1
        end
        Run(state, owner, 0.16, 0, function(p)
            for i = 1, 4 do state.current[i] = state.from[i] + (state.to[i] - state.from[i]) * p end
            Paint(state.current)
        end, function(completed, settle)
            if completed or settle or not W:MotionAllowed() or not Visible(owner) then
                for i = 1, 4 do state.current[i] = state.to[i] end
                Paint(state.current)
            end
        end)
    end
    local function Anchors(frame)
        local points = {}
        for i = 1, frame:GetNumPoints() do points[i] = { frame:GetPoint(i) } end
        return points
    end
    local function Place(frame, points, y)
        frame:ClearAllPoints()
        for _, point in ipairs(points) do
            frame:SetPoint(point[1], point[2], point[3], point[4], point[5] + y)
        end
    end
    function W:AnimateEntrance(frame, opts)
        opts = opts or {}
        local state = frame._qfxEntrance or {}
        frame._qfxEntrance = state
        Stop(state)
        if not self:MotionAllowed() or not Visible(frame) then return end
        local points, alpha = Anchors(frame), frame:GetAlpha()
        local distance, from = opts.distance or 8, opts.fromAlpha or 0
        frame:SetAlpha(alpha * from)
        Place(frame, points, -distance)
        Run(state, frame, opts.duration or 0.22, opts.delay or 0, function(p)
            frame:SetAlpha(alpha * (from + (1 - from) * p))
            Place(frame, points, -distance * (1 - p))
        end, function()
            frame:SetAlpha(alpha)
            Place(frame, points, 0)
        end)
    end
    -- Stagger only rows intersecting the scroll viewport; recycled rows reuse state.
    function W:RevealRows(api, page, opts)
        opts = opts or {}
        if not page._qfxMotionScroll then
            page._qfxMotionScroll = true
            page.viewport:HookScript("OnVerticalScroll", function() W:StopMotion(page.content) end)
        end
        local offset = page:GetOffset()
        local height = page.frame:GetHeight()
        local rowH, index = opts.rowH or 64, 0
        for i = 1, api:GetCount() do
            local row = api:GetRow(i)
            local top = (i - 1) * rowH
            if top < offset + height and top + rowH > offset then
                self:AnimateEntrance(row._settings or row, { duration = 0.22,
                    distance = 8, delay = index * 0.025 })
                index = index + 1
            end
        end
    end
    function W:WindowMotion(frame)
        if frame._qfxWindowMotion then return end
        frame._qfxWindowMotion = true
        local rawHide, rawShow, close = frame.Hide, frame.Show, {}
        frame:HookScript("OnShow", function(self)
            self._qfxClosing = nil
            W:AnimateEntrance(self, { duration = 0.26, distance = 14 })
        end)
        frame:HookScript("OnDragStart", function(self) W:StopMotion(self) end)
        frame:HookScript("OnDragStop", function(self)
            if W._motionBrands then
                for holder in pairs(W._motionBrands) do
                    if Descendant(holder.frame, self) then holder:PlaySheen() end
                end
            end
        end)
        frame.Show = function(self)
            if self._qfxClosing then
                local currentAlpha, currentY = self:GetAlpha(), close.y or 0
                W:StopMotion(self)
                rawShow(self)
                W:AnimateEntrance(self, { duration = 0.22, distance = -currentY, fromAlpha = currentAlpha })
                if W._motionBrands then
                    for holder in pairs(W._motionBrands) do
                        if Descendant(holder.frame, self) then holder:PlaySheen() end
                    end
                end
            else
                rawShow(self)
            end
        end
        frame.Hide = function(self)
            if not Visible(self) or not W:MotionAllowed() then
                W:StopMotion(self)
                rawHide(self)
                return
            end
            if self._qfxClosing then return end
            W:StopMotion(self)
            self._qfxClosing = true
            local points, alpha = Anchors(self), self:GetAlpha()
            Run(close, self, 0.18, 0, function(p)
                close.y = -10 * p
                self:SetAlpha(alpha * (1 - p))
                Place(self, points, close.y)
            end, function(completed)
                self:SetAlpha(alpha)
                Place(self, points, 0)
                self._qfxClosing = nil
                if completed or not W:MotionAllowed() or not Visible(self) then rawHide(self) end
            end)
        end
    end
    -- The original art stays intact; the factory owns every masked highlight.
    function W:BrandSheen(holder, opts)
        if (holder._sheenRevision == 3 and holder._sheenNativeAlpha) or (not holder.logo and not holder.nameplate and not holder.watermark) then return end
        opts = opts or {}
        local parent = holder.frame
        local maskPath = opts.mask or (self.Brand and self.Brand.sheenMask)
        if not maskPath then return end
        local hadSheen = holder.sheen ~= nil
        local function CreateSweep(art, key, layer, sub, color)
            if not art then return nil end
            local sheen, mask = holder[key], holder[key .. "Mask"]
            if not sheen then
                local host = art:GetParent()
                sheen = self.NoSnap(host:CreateTexture(nil, layer, nil, sub))
                mask = self.NoSnap(host:CreateMaskTexture(nil, layer))
                mask:SetTexture(maskPath, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
                sheen:AddMaskTexture(mask)
                holder[key], holder[key .. "Mask"] = sheen, mask
            end
            sheen:SetTexture(art:GetTexture(), "CLAMP", "CLAMP", "TRILINEAR")
            if art._qfxBrandTexCoord then sheen:SetTexCoord((unpack or table.unpack)(art._qfxBrandTexCoord)) end
            sheen:SetAllPoints(art)
            sheen:SetBlendMode("ADD")
            sheen:SetVertexColor(color[1], color[2], color[3], 1)
            sheen:SetAlpha(0)
            local group = mask:CreateAnimationGroup()
            group:SetLooping("REPEAT")
            local translation = group:CreateAnimation("Translation")
            translation:SetSmoothing("NONE")
            local fadeIn, fadeOut
            if opts.sequence then
                fadeIn, fadeOut = group:CreateAnimation("Alpha"), group:CreateAnimation("Alpha")
                fadeIn:SetTarget(sheen); fadeOut:SetTarget(sheen)
                fadeIn:SetSmoothing("NONE"); fadeOut:SetSmoothing("NONE")
                fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(color[4])
                fadeOut:SetFromAlpha(color[4]); fadeOut:SetToAlpha(0)
            end
            return { art = art, sheen = sheen, mask = mask, color = color, active = false,
                group = group, translation = translation, fadeIn = fadeIn, fadeOut = fadeOut }
        end
        local S = self:Tokens()
        local logo = CreateSweep(holder.logo, "sheen", "ARTWORK", 2,
            opts.sequence and { 1, 1, 1, 0.42 } or S.brandSheen or tint)
        local title = CreateSweep(holder.nameplate, "nameplateSheen", "ARTWORK", 2, { 1, 1, 1, 0.30 })
        -- Background layer stays underneath header text and toolbar controls.
        local meteor = opts.watermark ~= false and CreateSweep(holder.watermark,
            "watermarkSheen", "BACKGROUND", 3,
            opts.sequence and { 1, 1, 1, 0.55 } or S.brandMeteor or meteorTint) or nil
        local effects = {}
        for _, effect in pairs({ logo = logo, title = title, watermark = meteor }) do effects[#effects + 1] = effect end
        local function Clear()
            for _, effect in ipairs(effects) do
                effect.group:Stop()
                effect.sheen:SetAlpha(0); effect.active = false
            end
        end
        -- The header's linear alpha envelope shares the mask animation group.
        -- Standalone sine sweeps retain their existing exact Lua curve.
        local function Place(effect, relative, point, x, y, band, height, distance, period, duration, delay)
            if not effect then return end
            effect.group:Stop()
            effect.mask:SetSize(band, height * 1.25)
            effect.mask:ClearAllPoints()
            effect.mask:SetPoint("CENTER", relative, point, x, y)
            effect.translation:SetOffset(distance, 0)
            effect.translation:SetDuration(duration)
            effect.translation:SetStartDelay(delay or 0)
            effect.translation:SetEndDelay(math.max(0, period - duration - (delay or 0)))
            if effect.fadeIn then
                effect.fadeIn:SetDuration(duration * 0.06)
                effect.fadeOut:SetDuration(duration * 0.06)
                effect.fadeOut:SetStartDelay(duration * 0.94)
            end
            effect.group:Play()
        end
        local function PlaceMasks()
            if opts.sequence then
                local duration = math.max(0.01, tonumber(opts.duration) or 4)
                local period = math.max(duration, tonumber(opts.period) or 6.5)
                local band, height = math.max(1, tonumber(opts.bandWidth) or 80), tonumber(opts.height) or 118
                local start = tonumber(opts.startX) or 0
                local finish = math.max(start, parent:GetWidth() - (tonumber(opts.rightInset) or 14))
                for _, effect in ipairs(effects) do
                    Place(effect, parent, "TOPLEFT", start - band / 2, -height / 2, band, height,
                        finish - start + band, period, duration, 0)
                end
            else
                local function Layout(effect, period, duration, delay, widthRatio)
                    if not effect then return end
                    local width, height = effect.art:GetWidth(), effect.art:GetHeight()
                    local band = width * widthRatio
                    Place(effect, effect.art, "LEFT", -band / 2, 0, band, height, width + band,
                        period, duration, delay)
                end
                Layout(logo, opts.period or 4.8, opts.duration or 1.05, 0, 0.55)
                Layout(meteor, opts.watermarkPeriod or 7.2, opts.watermarkDuration or 1.45,
                    opts.watermarkDelay or 1.45, 0.20)
            end
        end
        local function Sweep(effect, elapsed, period, duration, delay, widthRatio, isMeteor)
            if not effect then return end
            local phase = elapsed >= delay and ((elapsed - delay) % period) or duration
            if phase >= duration then
                if effect.active then effect.sheen:SetAlpha(0); effect.active = false end
                return
            end
            local p = phase / duration
            local fade = isMeteor and math.min(1, p / 0.14, (1 - p) / 0.12) or math.sin(math.pi * p)
            effect.sheen:SetAlpha(effect.color[4] * fade)
            effect.active = true
        end
        local state = {}
        function holder:StopSheen() Stop(state); Clear() end
        function holder:PlaySheen()
            Stop(state)
            if not W:MotionAllowed() or not Visible(parent) then Clear(); return end
            PlaceMasks()
            if opts.sequence then return end
            Run(state, parent, 1, 0, function(elapsed)
                Sweep(logo, elapsed, opts.period or 4.8, opts.duration or 1.05, 0, 0.55, false)
                Sweep(meteor, elapsed, opts.watermarkPeriod or 7.2, opts.watermarkDuration or 1.45,
                    opts.watermarkDelay or 1.45, 0.20, true)
            end, Clear, true)
        end
        if not holder._sheenShowHook and not hadSheen then parent:HookScript("OnShow", function() holder:PlaySheen() end) end
        holder._sheenShowHook = true
        holder._sheenRevision, holder._motionOpts, holder._sheenNative = 3, opts, true
        holder._sheenNativeAlpha = true
        if not holder._sheenHideHook then
            holder._sheenHideHook = true
            parent:HookScript("OnHide", function() holder:StopSheen() end)
        end
        holder._sheenEffects = effects
        if not holder._sheenSizeHook then
            holder._sheenSizeHook = true
            parent:HookScript("OnSizeChanged", function() if Visible(parent) then holder:PlaySheen() end end)
        end
        self._motionBrands = self._motionBrands or setmetatable({}, { __mode = "k" })
        self._motionBrands[holder] = true
        if Visible(parent) then holder:PlaySheen() end
    end
    local banner = W._MotionBannerOriginal or W.Banner
    W._MotionBannerOriginal = banner
    W.Banner = function(self, parent, opts)
        local holder = banner(self, parent, opts)
        if opts and opts.motion then self:BrandSheen(holder, type(opts.motion) == "table" and opts.motion or nil) end
        return holder
    end
    W.MOTION_REVISION = 3
    W.MOTION_NATIVE_SWEEP = true
    W.MOTION_NATIVE_ALPHA = true
    W.EnsureMotion = InstallMotion
    if W._motionBrands then
        for holder in pairs(W._motionBrands) do W:BrandSheen(holder, holder._motionOpts) end
    end
end

-- Additive callout capability also works when an embedded singleton loaded first.
local function InstallSpeechBubble(W)
    if W.SpeechBubble then return end
    function W:SpeechBubble(anchor, opts)
        opts = opts or {}
        local T, S = self.Theme, self:Tokens()
        local bubble = CreateFrame("Frame", nil, anchor)
        bubble:SetSize(opts.width or 236, 1)
        bubble:SetPoint("BOTTOM", anchor, "TOP", 0, 10)
        bubble:SetFrameStrata("TOOLTIP")
        bubble:SetClampedToScreen(true)
        bubble:EnableMouse(false)
        self:SkinFrame(bubble, { border = S.warmAccent })
        local tailBorder = self.Surface(bubble, "BACKGROUND", 0, S.warmAccent)
        tailBorder:SetSize(10, 10)
        tailBorder:SetPoint("CENTER", bubble, "BOTTOM", 0, 0)
        tailBorder:SetRotation(math.pi / 4)
        local tail = self.Surface(bubble, "BACKGROUND", 1, S.menuBg)
        tail:SetSize(8, 8)
        tail:SetPoint("CENTER", tailBorder, "CENTER", 0, 1)
        tail:SetRotation(math.pi / 4)
        local _, note = self:Note(bubble, -T.pad, "", { size = T.noteSize })
        function bubble:SetText(text)
            note._text:SetText(text or "")
            local height = math.max(18, note._text:GetStringHeight() + 6)
            note:SetHeight(height)
            self:SetHeight(height + T.pad * 2)
        end
        anchor:HookScript("OnHide", function() bubble:Hide() end)
        bubble:Hide()
        return bubble
    end
end

-- Native translation keeps the ticker on the factory motion policy without
-- adding a Lua update driver or replacing an already-loaded motion singleton.
local function InstallStatusTicker(W)
    if type(W.StatusTicker) == "function" and W._statusTickerMotionBound == W.SetMotionEnabled then return end
    local tickers = W._statusTickers or setmetatable({}, { __mode = "k" })
    W._statusTickers = tickers
    local function Under(frame, owner)
        while frame do
            if frame == owner then return true end
            frame = frame:GetParent()
        end
        return false
    end
    local function Read(value)
        if type(value) == "function" then return value() end
        return value
    end
    function W:StatusTicker(parent, opts)
        opts = opts or {}
        local T = self.Theme
        local viewport = CreateFrame("ScrollFrame", nil, parent)
        viewport:SetSize(opts.width or parent:GetWidth(), opts.height or T.controlH)
        viewport:EnableMouse(true)
        viewport:EnableMouseWheel(true)
        viewport._qfx = "statusTicker"
        local track = CreateFrame("Frame", nil, viewport)
        track:SetSize(1, viewport:GetHeight())
        track:EnableMouse(false)
        viewport:SetScrollChild(track)
        local group = track:CreateAnimationGroup()
        group:SetLooping("REPEAT")
        local translation = group:CreateAnimation("Translation")
        viewport.track, viewport.group, viewport.translation = track, group, translation
        viewport.rows, viewport.pool = {}, {}
        local function Place(x)
            track:ClearAllPoints()
            track:SetPoint("TOPLEFT", viewport, "TOPLEFT", x, 0)
        end
        function viewport:StopTicker()
            group:Stop()
            self.playing, self.paused = false, false
            Place(0)
            self:SetHorizontalScroll(0)
        end
        function viewport:StartTicker()
            if not W:MotionAllowed() or not self:IsVisible() or #self.rows == 0 then self:StopTicker(); return end
            if self.hovered or self.playing then return end
            if not self.paused then Place(self:GetWidth()); self:SetHorizontalScroll(0) end
            group:Play()
            self.playing, self.paused = true, false
        end
        local function NewRow()
            local row = CreateFrame("Frame", nil, track)
            row:EnableMouse(false)
            row._label = W.Font(row, T.labelSize)
            row._value = W.Font(row, T.labelSize)
            for _, text in ipairs({ row._label, row._value }) do
                text:SetJustifyH("LEFT")
                text:SetWordWrap(false)
            end
            row._label:SetPoint("LEFT", row, "LEFT", 0, 0)
            return row
        end
        function viewport:Refresh()
            local items, S = Read(opts.items) or {}, W:Tokens()
            local rows, x, signature = {}, 0, {}
            local gap = opts.gap or T.sidePad * 2
            for index, cfg in ipairs(items) do
                local key = cfg.key or index
                local row = self.pool[key]
                if not row then row = NewRow(); self.pool[key] = row end
                rows[#rows + 1], row.key = row, key
                local label, value = tostring(Read(cfg.label) or ""), tostring(Read(cfg.getText) or "")
                row._label:SetText(label)
                row._label:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4] or 1)
                local labelWidth = row._label:GetStringWidth()
                local valueWidth = 0
                for _, text in ipairs(opts.stateTexts or { value }) do
                    row._value:SetText(text)
                    valueWidth = math.max(valueWidth, row._value:GetStringWidth())
                end
                row._value:SetText(value)
                local c = Read(cfg.color) or S.text
                row._value:SetTextColor(c[1], c[2], c[3], c[4] or 1)
                local width = math.ceil(labelWidth + T.labelGap + valueWidth)
                row:SetSize(width, self:GetHeight())
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", track, "TOPLEFT", x, 0)
                row._value:ClearAllPoints()
                row._value:SetPoint("LEFT", row, "LEFT", labelWidth + T.labelGap, 0)
                row:Show()
                signature[#signature + 1] = tostring(key) .. ":" .. tostring(width)
                x = x + width + gap
            end
            local visible = {}
            for _, row in ipairs(rows) do visible[row] = true end
            for _, row in pairs(self.pool) do if not visible[row] then row:Hide() end end
            self.rows = rows
            self.trackWidth = math.max(1, x - (#rows > 0 and gap or 0))
            track:SetSize(self.trackWidth, self:GetHeight())
            local layout = table.concat(signature, "|") .. ":" .. tostring(self:GetWidth())
            if self.layout ~= layout then
                self.layout = layout
                self:StopTicker()
                local distance = self:GetWidth() + self.trackWidth
                translation:SetOffset(-distance, 0)
                translation:SetDuration(distance / math.max(1, opts.speed or 42))
            end
            self:StartTicker()
        end
        viewport:SetScript("OnEnter", function(self)
            self.hovered = true
            if self.playing then group:Pause(); self.playing, self.paused = false, true end
        end)
        viewport:SetScript("OnLeave", function(self) self.hovered = false; self:StartTicker() end)
        viewport:SetScript("OnMouseWheel", function(self, delta)
            if W:MotionAllowed() then return end
            local offset = self:GetHorizontalScroll() - delta * 40
            self:SetHorizontalScroll(math.max(0, math.min(math.max(0, self.trackWidth - self:GetWidth()), offset)))
        end)
        viewport:HookScript("OnShow", function(self) self:Refresh() end)
        viewport:HookScript("OnHide", function(self) self.hovered = false; self:StopTicker() end)
        viewport:HookScript("OnSizeChanged", function(self) self:Refresh() end)
        local ancestor = parent
        while ancestor and ancestor ~= UIParent do
            if ancestor._qfxWindowMotion and not ancestor._qfxTickerShow then
                ancestor._qfxTickerShow = true
                local show = ancestor.Show
                ancestor.Show = function(owner)
                    show(owner)
                    for ticker in pairs(tickers) do if Under(ticker, owner) then ticker:StartTicker() end end
                end
            end
            if not ancestor._qfxTickerDrag then
                ancestor._qfxTickerDrag = true
                ancestor:HookScript("OnDragStop", function(owner)
                    for ticker in pairs(tickers) do if Under(ticker, owner) then ticker:StartTicker() end end
                end)
            end
            ancestor = ancestor:GetParent()
        end
        tickers[viewport] = true
        local scope = W._refreshScope
        W._refreshScope = viewport
        W:RegisterRefresh(function() viewport:Refresh() end)
        W._refreshScope = scope
        viewport:Refresh()
        return viewport
    end
    local setEnabled, stopMotion, activity = W.SetMotionEnabled, W.StopMotion, W.GetMotionActivity
    function W:SetMotionEnabled(enabled)
        setEnabled(self, enabled)
        for ticker in pairs(tickers) do
            if enabled then ticker:StartTicker() else ticker:StopTicker() end
        end
    end
    function W:StopMotion(owner)
        stopMotion(self, owner)
        for ticker in pairs(tickers) do if Under(ticker, owner) then ticker:StopTicker() end end
    end
    function W:GetMotionActivity()
        local count = activity(self)
        for ticker in pairs(tickers) do if ticker.playing then count = count + 1 end end
        return count
    end
    W._statusTickerMotionBound = W.SetMotionEnabled
end

-- Image titles share the brand contract without replacing an existing factory.
local function InstallBrandImages(W)
    if (tonumber(W.BRAND_IMAGES_REVISION) or 0) >= 1 and W.BRAND_IMAGE_COORDS and W.BRAND_TITLE_SCOPED then return end
    function W:BrandNameplate(parent, opts)
        opts = opts or {}
        local brand = self.Brand or {}
        local path = opts.image
        if path == nil then path = brand.nameplate end
        if not path or path == false then return nil end
        local ratio = math.max(0.01, tonumber(opts.ratio or brand.nameplateRatio) or 4)
        local frame = CreateFrame("Frame", nil, parent)
        frame:EnableMouse(false)
        local texture = self.NoSnap(frame:CreateTexture(nil, "ARTWORK", nil, 1))
        texture:SetAllPoints()
        if type(path) == "string" and path:lower():match("%.blp$") then
            texture:SetTexture(path, "CLAMP", "CLAMP", "TRILINEAR")
        else
            texture:SetTexture(path)
        end
        local coords = opts.texCoord
        if coords == nil and opts.image == nil then coords = brand.nameplateTexCoord end
        if coords then texture:SetTexCoord((unpack or table.unpack)(coords)) end
        texture._qfxBrandTexCoord = coords or nil
        frame.texture = texture
        function frame:Layout()
            local x, y = tonumber(opts.x) or 0, tonumber(opts.y) or 0
            local available = math.max(1, parent:GetWidth() - x - (tonumber(opts.rightInset) or 40))
            local height = math.max(1, tonumber(opts.height) or 64)
            local width = math.min(height * ratio, available, tonumber(opts.maxWidth) or available)
            self:SetSize(width, width / ratio)
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
        end
        parent:HookScript("OnSizeChanged", function() frame:Layout() end)
        frame:Layout()
        return frame
    end
    W.BRAND_IMAGES_REVISION = 1
    W.BRAND_IMAGE_COORDS = true
    W.BRAND_TITLE_SCOPED = true
    W.EnsureBrandImages = InstallBrandImages
end

-- Additive detached controls for hosts which retain their own editor layout.
-- State, labels and callbacks remain owned by the host; rendering stays here.
local function InstallDetachedControls(W)
    if (W.DETACHED_CONTROLS_REVISION or 0) >= 7 then return end

    -- Menu-row checkbox matching the CheckGrid cell: a bordered box with an
    -- inset fill. Only public factory methods are used so an upgraded legacy
    -- singleton receives the same mark.
    local function RowCheck(parent, size)
        local S = W:Tokens()
        local box = CreateFrame("Frame", nil, parent)
        local boxSize = size or 16
        if W.SnapUI then boxSize = W.SnapUI(box, boxSize) end
        box:SetSize(boxSize, boxSize)
        local bg = W.Surface(box, "BACKGROUND", 0, S.controlBg)
        bg:SetAllPoints()
        local brd = W.Border(box, box:GetFrameLevel(), S.border, 1, 1)
        local inset = 3
        if W.SnapUI then inset = W.SnapUI(box, inset) end
        local mark = W.Surface(box, "ARTWORK", 1, S.checkFill or S.warmAccent or S.accent)
        mark:SetPoint("TOPLEFT", box, "TOPLEFT", inset, -inset)
        mark:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -inset, inset)
        if W.NoSnap then W.NoSnap(bg); W.NoSnap(mark) end
        box._bg, box._brd, box._mark = bg, brd, mark
        return box, mark, brd
    end
    W.RowCheck = RowCheck

    -- Menu rows reusing factory buttons: strip the standalone button chrome
    -- (packed background, border, sheen) and paint the shared row language
    -- instead. With an item index the row also carries the factory zebra
    -- stripe (context menus); without one the row stays transparent so the
    -- host list's own stripe shows (pickers over ListRows).
    function W:StyleMenuRow(row, index)
        if not (row and row._bg and row._bg.SetColorTexture) then return row end
        local S = self:Tokens()
        local hover = S.rowHover or {0, 0.625, 1, 0.13}
        local idle = {0, 0, 0, 0}
        local n = tonumber(index)
        if n then
            local stripe
            if n % 2 == 1 then
                stripe = S.rowBgOdd or S.rowBgEven
            else
                stripe = S.rowBgEven or S.rowBgOdd
            end
            if stripe then idle = {stripe[1], stripe[2], stripe[3], stripe[4] or 1} end
        end
        row._bg:SetColorTexture(idle[1], idle[2], idle[3], idle[4])
        row:SetScript("OnEnter", function()
            row._bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4] or 1)
        end)
        row:SetScript("OnLeave", function()
            row._bg:SetColorTexture(idle[1], idle[2], idle[3], idle[4])
        end)
        if row._brd and row._brd.Hide then row._brd:Hide() end
        if row._sheen and row._sheen.Hide then row._sheen:Hide() end
        return row
    end

    function W:DetachedControl(parent, kind, opts)
        opts = opts or {}
        local control
        local cfg = { type = kind, text = opts.text or "", width = opts.width or 180,
            numeric = opts.numeric,
            getValue = function() return control and control:GetText() or "" end }
        local owner = {}
        self:BeginPage(owner)
        local row = self:DualRow(parent, 0, cfg)
        self:EndPage()
        control = row._leftRegion._control
        control:SetParent(parent)
        control:ClearAllPoints()
        control:SetSize(opts.width or 180, opts.height or self.Theme.controlH)
        row:Hide()
        local label
        if kind == "button" or kind == "dropdown" then
            for _, region in ipairs({control:GetRegions()}) do
                if region:GetObjectType() == "FontString" then label = region; break end
            end
            control.GetFontString = function() return label end
            control.qfxsaLabel, control.Text = label, label
            control.SetText = function(_, text) label:SetText(text or "") end
            control.GetText = function() return label:GetText() end
        end
        control._qfxDetached = kind
        return control
    end

    function W:DetachedCheck(parent, text, width)
        local checked = false
        local entry = { label = text or "", getValue = function() return checked end }
        local owner = {}
        self:BeginPage(owner)
        local grid = self:CheckGrid(parent, 0, 1, {entry})
        self:EndPage()
        local cell = select(1, grid:GetChildren())
        local button = select(1, cell:GetChildren())
        local label
        for _, region in ipairs({cell:GetRegions()}) do
            if region:GetObjectType() == "FontString" then label = region; break end
        end
        button:SetParent(parent)
        label:SetParent(button)
        label:ClearAllPoints()
        label:SetPoint("LEFT", button, "RIGHT", 4, 0)
        label:SetWidth(width or 180)
        button:ClearAllPoints()
        button.Text, button.text, button.qfxsaLabel = label, label, label
        grid:Hide()
        button.GetChecked = function() return checked end
        button.SetChecked = function(_, value)
            checked = value and true or false
            self:Refresh(owner)
        end
        local setScript = button.SetScript
        local click
        button.SetScript = function(b, event, fn)
            if event == "OnClick" then click = fn else setScript(b, event, fn) end
        end
        setScript(button, "OnClick", function(b, ...)
            b:SetChecked(not checked)
            if click then click(b, ...) end
        end)
        button:SetHitRectInsets(0, -(width or 180), 0, 0)
        button._qfxDetached = "checkbox"
        return button
    end

    function W:LayoutSlider(parent, name, opts)
        opts = opts or {}
        local S = self:Tokens()
        local slider = CreateFrame("Slider", name, parent)
        slider:SetSize(opts.width or 180, opts.height or 20)
        slider:SetOrientation(opts.orientation or "HORIZONTAL")
        slider:SetMinMaxValues(opts.minValue or 0, opts.maxValue or 1)
        slider:SetValueStep(opts.valueStep or 1)
        slider:SetObeyStepOnDrag(opts.obeyStepOnDrag == true)
        local track = self.Surface(slider, "BACKGROUND", 0, S.trackBg or S.controlBg)
        local thumb = slider:CreateTexture(nil, "ARTWORK")
        thumb:SetColorTexture(unpack(S.thumb or S.knob or S.border))
        slider:SetThumbTexture(thumb)
        local function Layout()
            track:ClearAllPoints()
            if slider:GetOrientation() == "VERTICAL" then
                track:SetPoint("TOP", 0, 0); track:SetPoint("BOTTOM", 0, 0)
                track:SetWidth(4); thumb:SetSize(math.max(8, slider:GetWidth()), 24)
            else
                track:SetPoint("LEFT", 0, 0); track:SetPoint("RIGHT", 0, 0)
                track:SetHeight(4); thumb:SetSize(12, 16)
            end
        end
        slider:HookScript("OnSizeChanged", Layout)
        slider:HookScript("OnShow", Layout)
        Layout()
        slider:SetValue(opts.value or 0)
        slider._qfxDetached = "slider"
        return slider
    end

    -- Ordinary owned frames only; never replaces the global CreateFrame.
    function W:LayoutFrame(kind, name, parent, template)
        if kind == "Button" then
            local button
            if template and template:find("CloseButton", 1, true) then
                button = self:CloseButton(parent)
            else
                button = self:DetachedControl(parent, "button")
            end
            if name then _G[name] = button end
            return button
        elseif kind == "EditBox" then
            local box = self:DetachedControl(parent, "input")
            if name then _G[name] = box end
            return box
        elseif kind == "CheckButton" then
            local button = self:DetachedCheck(parent, "")
            if name then _G[name] = button end
            return button
        elseif kind == "Slider" then
            return self:LayoutSlider(parent, name)
        end
        local frame = CreateFrame(kind, name, parent)
        if template and template:find("BackdropTemplate", 1, true) then self:SkinFrame(frame) end
        local createFont = frame.CreateFontString
        frame.CreateFontString = function(owner, fontName, layer, fontTemplate)
            local label = createFont(owner, fontName, layer)
            local S = self:Tokens()
            local muted = fontTemplate and (fontTemplate:find("Disable", 1, true) or fontTemplate:find("Small", 1, true))
            label:SetFont(self.Theme.font, self.Theme.labelSize, "")
            label:SetTextColor(unpack(muted and S.textMuted or S.text))
            return label
        end
        return frame
    end

    function W:DecorateListRow(row)
        local S = self:Tokens()
        local function Surface(key, layer, color)
            local texture = self.Surface(row, layer, 0, color)
            row[key] = texture
            return texture
        end
        local bg = Surface("bg", "BACKGROUND", {0, 0, 0, 0}); bg:SetAllPoints()
        local hover = Surface("hover", "HIGHLIGHT", S.rowHover); hover:SetAllPoints()
        local dropBG = Surface("dropBG", "OVERLAY", S.selectedFill); dropBG:SetAllPoints(); dropBG:Hide()
        local dropLine = Surface("dropLine", "OVERLAY", S.warmAccent); dropLine:SetHeight(4); dropLine:Hide()
        local accent = Surface("accent", "ARTWORK", S.accent)
        accent:SetPoint("TOPLEFT", 2, -3); accent:SetPoint("BOTTOMLEFT", 2, 3); accent:SetWidth(3)
        local divider = Surface("divider", "ARTWORK", S.line)
        divider:SetPoint("BOTTOMLEFT", 8, 0); divider:SetPoint("BOTTOMRIGHT", -8, 0); divider:SetHeight(1)
        row.statusDot = self.Font(row, self.Theme.labelSize, unpack(S.text)); row.statusDot:SetText("●")
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(20, 20); row.icon:SetPoint("LEFT", 12, 0)
        row.main = self.Font(row, self.Theme.labelSize, unpack(S.text))
        row.main:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
        row.main:SetPoint("RIGHT", row, "RIGHT", -12, 0)
        row.main:SetJustifyH("LEFT"); row.main:SetWordWrap(false); row.main:SetMaxLines(1)
        row.text = row.main
    end

    function W:InteractiveListRow(parent, height)
        local button
        local holder = self:ListRows(parent, 0, { rowH = height or 28, items = {true},
            rowBuilder = function(row)
                button = CreateFrame("Button", nil, row)
                self:DecorateListRow(button)
            end })
        button:SetParent(parent)
        holder:Hide()
        return button
    end

    -- Dynamic searchable picker, including multiple selection and unavailable
    -- items. Selection semantics are supplied entirely by the consumer.
    function W:EditorDropdown(parent, opts)
        opts = opts or {}
        local S = self:Tokens()
        local button
        if self.LayoutDropdownButton then
            button = self:LayoutDropdownButton(parent, opts.width or 180)
            button.GetFontString = function() return button._label end
            button.SetText = function(_, text) button._label:SetText(text or "") end
            button.GetText = function() return button._label:GetText() end
        else
            button = self:DetachedControl(parent, "dropdown", {width = opts.width or 180})
        end
        -- The host supplies the complete legacy layout. A retained RIGHT
        -- anchor would stretch controls placed with LEFT/TOPLEFT across peers.
        button:ClearAllPoints()
        button:RegisterForClicks("LeftButtonUp")
        button:EnableMouse(true)
        local label = button:GetFontString()
        label:ClearAllPoints(); label:SetPoint("LEFT", 6, 0); label:SetPoint("RIGHT", -22, 0)
        label:SetJustifyH("LEFT"); label:SetWordWrap(false); label:SetMaxLines(1)
        local menu = CreateFrame("Frame", nil, UIParent)
        menu:SetFrameStrata("FULLSCREEN_DIALOG"); menu:SetFrameLevel(300)
        menu:SetClampedToScreen(true); menu:EnableMouse(true); menu:Hide()
        self:SkinFrame(menu)
        local catcher = CreateFrame("Frame", nil, UIParent)
        catcher:SetAllPoints(); catcher:SetFrameStrata("FULLSCREEN_DIALOG"); catcher:SetFrameLevel(290)
        catcher:EnableMouse(true); catcher:Hide()
        catcher:SetScript("OnMouseDown", function() menu:Hide() end)
        local function LiftMenu()
            local owner, highest = button, 0
            while owner do
                local level = owner:GetFrameLevel()
                if type(level) == "number" and not self.IsSecret(level) then highest = math.max(highest, level) end
                local parent = owner:GetParent()
                if not parent or parent == UIParent then break end
                owner = parent
            end
            -- Raise() and automatic top-level promotion can move the editor
            -- above an earlier fixed popup level, including its nested panels.
            if owner and owner.GetHighestFrameLevel then
                local level = owner:GetHighestFrameLevel(true)
                if type(level) == "number" and not self.IsSecret(level) then highest = math.max(highest, level) end
            end
            -- The host strata must not be trusted: in tainted execution the
            -- strata/level getters can return secret values, and a SetToplevel
            -- editor is promoted above any popup sharing its strata whatever
            -- the popup level is. Like the native QFXSkillAlerts popup, the
            -- palette therefore always uses TOOLTIP so no host window can
            -- cover it. Level still orders palettes among themselves.
            local level = math.max(300, highest + 30)
            catcher:SetFrameStrata("TOOLTIP"); catcher:SetFrameLevel(level - 10)
            menu:SetFrameStrata("TOOLTIP"); menu:SetFrameLevel(level)
        end
        local query, display, rowsAPI, rowsHolder, page = "", {}
        local search = self:DetachedControl(menu, "input", {width = opts.width or 180})
        search:SetPoint("TOPLEFT", 6, -6)
        local function Pick(item)
            if not item or item.disabled or (opts.disabled and opts.disabled()) then return end
            local keep = opts.onPick and opts.onPick(item.key)
            if not keep then menu:Hide() end
        end
        local function Render()
            display = {}
            for _, item in ipairs(opts.items() or {}) do
                local text = tostring(item.searchText or item.label or ""):lower()
                if query == "" or text:find(query, 1, true) then display[#display + 1] = item end
            end
            if #display == 0 then display[1] = {label = opts.emptyText or "No results", disabled = true} end
            if rowsAPI then
                rowsAPI:Render()
                local width = math.max(1, page.content:GetWidth() - self.Theme.pad * 2)
                rowsHolder:SetWidth(width)
                for i = 1, rowsAPI:GetCount() do rowsAPI:GetRow(i):SetWidth(width) end
            end
            if page then page:SetContentHeight(#display * 22 + 4) end
            if menu:IsShown() then LiftMenu() end
        end
        local host = CreateFrame("Frame", nil, menu)
        host:SetPoint("TOPLEFT", 6, -32); host:SetPoint("BOTTOMRIGHT", -6, 6)
        page = self:ScrollPage(host, {reserveBar = true, scrollStep = 44})
        rowsHolder, _, rowsAPI = self:ListRows(page.content, 0, {rowH = 22,
            items = function() return display end,
            rowBuilder = function(row)
                local hit = self:DetachedControl(row, "button")
                hit:SetAllPoints(row)
                -- ListRows paints the zebra wash on the row: the shared menu
                -- row style drops the standalone button chrome so the stripe
                -- stays visible and hover uses the shared row highlight.
                W:StyleMenuRow(hit)
                local text = hit:GetFontString()
                text:ClearAllPoints(); text:SetPoint("LEFT", 28, 0); text:SetPoint("RIGHT", -4, 0)
                text:SetJustifyH("LEFT"); text:SetWordWrap(false); text:SetMaxLines(1)
                -- The row mark is the factory checkbox, matching CheckGrid.
                local check, mark = W.RowCheck(hit, 16)
                check:SetPoint("LEFT", hit, "LEFT", 6, 0)
                hit:SetScript("OnClick", function() Pick(row._item); Render() end)
                row.hit, row.mark, row.box = hit, mark, check
            end,
            rowUpdate = function(row, item)
                row.hit:SetText(item.label or tostring(item.key))
                row.hit:SetEnabled(not item.disabled)
                row.hit:SetAlpha(item.disabled and .35 or 1)
                row.mark:SetShown(opts.checked and opts.checked(item.key) or false)
            end})
        search:SetScript("OnTextChanged", function()
            query = tostring(search:GetText() or ""):match("^%s*(.-)%s*$"):lower()
            Render(); page:ScrollTo(0)
        end)
        search:SetScript("OnEnterPressed", function()
            for _, item in ipairs(display) do if not item.disabled then Pick(item); Render(); break end end
        end)
        search:SetScript("OnEscapePressed", function() menu:Hide() end)
        menu:SetScript("OnHide", function()
            catcher:Hide(); search:ClearFocus()
            if self._editorDropdownMenu == menu then self._editorDropdownMenu = nil end
        end)
        button:HookScript("OnHide", function() menu:Hide() end)
        local function Open()
            if opts.disabled and opts.disabled() then return end
            if self._editorDropdownMenu and self._editorDropdownMenu ~= menu then self._editorDropdownMenu:Hide() end
            self._editorDropdownMenu = menu
            LiftMenu()
            local width = math.max(120, button:GetWidth())
            menu:SetSize(width, 260); search:SetWidth(width - 12)
            menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
            menu:SetScale(button:GetEffectiveScale() / UIParent:GetEffectiveScale())
            search:SetText(""); query = ""; Render(); page:ScrollTo(0)
            for i, item in ipairs(display) do
                if opts.checked and opts.checked(item.key) then page:ScrollTo((i-1)*22); break end
            end
            catcher:Show(); menu:Show()
            if opts.searchable and opts.searchable() then search:SetFocus() end
        end
        button:SetScript("OnClick", function() if menu:IsShown() then menu:Hide() else Open() end end)
        button._menu, button._openMenu = menu, Open
        button._editorRender, button._editorSearch, button._editorCatcher = Render, search, catcher
        return button
    end

    -- A native Slider remains an invisible event bridge for an existing list
    -- controller. The visible scrollbar, clipping and scrolling are factory owned.
    function W:EditorScroll(parent, opts)
        opts = opts or {}
        local host = CreateFrame("Frame", nil, parent)
        host:SetSize(opts.contentWidth or 700, 300)
        local driver = CreateFrame("Slider", nil, host)
        driver:SetSize(1, 1); driver:EnableMouse(false); driver:Hide()
        local setValue, setRange = driver.SetValue, driver.SetMinMaxValues
        local syncing = false
        local page = self:ScrollPage(host, {scrollStep = opts.wheelStep or 78,
            onScroll = function(value)
                if syncing then return end
                syncing = true; setValue(driver, value); syncing = false
            end})
        local rangeMax = 0
        driver.SetMinMaxValues = function(_, low, high)
            rangeMax = math.max(0, (tonumber(high) or 0) - (tonumber(low) or 0))
            setRange(driver, low or 0, high or 0)
            page:SetContentHeight(page.viewport:GetHeight() + rangeMax)
        end
        driver.SetValue = function(_, value)
            if syncing then return end
            syncing = true
            setValue(driver, math.max(0, math.min(tonumber(value) or 0, rangeMax)))
            page:ScrollTo(driver:GetValue())
            syncing = false
        end
        driver.Show = function() end
        driver.Hide = function() end
        page.content:SetHeight(opts.contentHeight or 1)
        function host:SetContentHeight(height)
            page:SetContentHeight((tonumber(height) or 1) + (opts.bottomPadding or 30))
            rangeMax = page:GetMaxOffset(); setRange(driver, 0, rangeMax)
        end
        function host:UpdateScrollRange() self:SetContentHeight(page.content:GetHeight()) end
        function host:ScrollBy(delta) driver:SetValue(driver:GetValue() - (delta or 0) * (opts.wheelStep or 78)) end
        host.scrollFrame, host.content, host.slider, host.page = page.viewport, page.content, driver, page
        driver:SetMinMaxValues(0, 0); driver:SetValue(0)
        return host, page.content, page.viewport, driver
    end

    function W:PreviewHitRegion(parent)
        local S = self:Tokens()
        local button = CreateFrame("Button", nil, parent)
        local border = self.Border(button, button:GetFrameLevel(), S.warmAccent, 1, 2)
        local hover = self.Surface(button, "HIGHLIGHT", 0, S.rowHover)
        hover:SetAllPoints()
        button._brd = border
        return button
    end

    function W:ListRowState(row, opts)
        opts = opts or {}
        local S = self:Tokens()
        local color = opts.selected and S.warmAccent or S.accent
        row.bg:SetColorTexture(color[1], color[2], color[3], opts.selected and .18 or opts.group and .06 or 0)
        row.accent:SetColorTexture(color[1], color[2], color[3], opts.muted and 0 or opts.selected and .95 or opts.group and .55 or .18)
        row.main:SetTextColor(unpack(opts.muted and S.textMuted or opts.selected and S.selectedText or opts.group and S.sectionText or S.text))
    end

    function W:ControlLabelState(label, enabled)
        local S = self:Tokens()
        label:SetTextColor(unpack(enabled and S.sectionText or S.textMuted))
    end

    W.DETACHED_CONTROLS_REVISION = 7
end

-- Additive host-chrome capability: a small white-alpha glyph button for
-- window titles and headers. The host anchors it itself unless opts.point is
-- given; hover only brightens the alpha, so the host can flash a tint on the
-- returned btn._icon without fighting the hover scripts.
--   opts = { texture, size = 16, alpha = 0.45, hoverAlpha = 0.9,
--            tint = { r, g, b, a }, tooltip, tooltipText, onClick,
--            point, relPoint, x, y }
local function InstallIconButton(W)
    if (tonumber(W.ICON_BUTTON_REVISION) or 0) >= 1 then return end

    function W:IconButton(parent, opts)
        opts = opts or {}
        local button = CreateFrame("Button", nil, parent)
        local size = tonumber(opts.size) or 16
        button:SetSize(size, size)
        if opts.point then
            button:SetPoint(opts.point, parent, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
        end
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        if opts.texture then
            icon:SetTexture(opts.texture, "CLAMP", "CLAMP", "TRILINEAR")
            if icon.SetSnapToPixelGrid then icon:SetSnapToPixelGrid(false) end
            if icon.SetTexelSnappingBias then icon:SetTexelSnappingBias(0) end
        end
        if opts.tint then
            icon:SetVertexColor(opts.tint[1], opts.tint[2], opts.tint[3], opts.tint[4] or 1)
        end
        local alpha = tonumber(opts.alpha) or 0.45
        local hoverAlpha = tonumber(opts.hoverAlpha) or 0.9
        button:SetAlpha(alpha)
        button:SetScript("OnEnter", function(self2) self2:SetAlpha(hoverAlpha) end)
        button:SetScript("OnLeave", function(self2) self2:SetAlpha(alpha) end)
        button:SetScript("OnClick", function(self2, mouseButton)
            if mouseButton and mouseButton ~= "LeftButton" then return end
            if opts.onClick then opts.onClick(self2) end
        end)
        if self.AttachTooltip then self.AttachTooltip(button, opts.tooltip, opts.tooltipText) end
        button._icon = icon
        button._qfx = "iconButton"
        return button
    end

    W.ICON_BUTTON_REVISION = 1
end

-- Shared footer button for factory modal dialogs. Resolved through the public
-- drawing helpers so it stays usable from capability installers that must
-- work on an already-loaded singleton.
local function QfxDialogButton(W, parent, txt, xOff, base, onClick)
    local S = W:Tokens()
    local button = CreateFrame("Button", nil, parent)
    local bw, bh = 92, 24
    button:SetSize(bw, bh)
    button:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", xOff, 12)
    local bg = W.Surface(button, "BACKGROUND", 0, base)
    bg:SetAllPoints()
    local brd = W.Border(button, button:GetFrameLevel(), S.border, 1, 1)
    local sheen = W.Surface(button, "ARTWORK", 0, S.buttonSheen)
    sheen:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
    sheen:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -2)
    sheen:SetHeight(math.max(1, math.floor((button:GetHeight() or 20) * 0.34)))
    local lbl = W.Font(button, S.textSize, 0.98, 0.99, 1, 1)
    lbl:SetPoint("CENTER", button, "CENTER", 0, 0)
    lbl:SetText(txt)
    button:SetScript("OnEnter", function()
        bg:SetColorTexture(base[1] * 1.25, base[2] * 1.25, base[3] * 1.25, base[4] or 1)
        brd._setBorder(S.borderHi or S.border)
    end)
    button:SetScript("OnLeave", function()
        bg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
        brd._setBorder(S.border)
    end)
    button:SetScript("OnClick", function(self2) onClick(self2) end)
    button._bg, button._brd, button._sheen, button._lbl = bg, brd, sheen, lbl
    return button
end

-- Optional confirm reuse keeps repeated event-driven notices bounded.
local function InstallReusableConfirm(W)
    if (tonumber(W.CONFIRM_REUSE_REVISION) or 0) >= 1 and type(W.Confirm) == "function" then return end
    function W:Confirm(opts)
        if type(opts) == "string" then opts = { text = opts } end
        opts = opts or {}
        if opts.reuse and opts.reuse._qfxConfirmStyle == (opts.danger and "danger" or "normal")
            and type(opts.reuse.ShowWithOptions) == "function" then
            return opts.reuse:ShowWithOptions(opts)
        end
        local S = self:Tokens()
        local T = self.Theme

        local dim = CreateFrame("Frame", nil, UIParent)
        dim:SetAllPoints()
        dim:SetFrameStrata("DIALOG")
        dim:EnableMouse(true)
        if dim.EnableKeyboard then dim:EnableKeyboard(true) end
        local dimTex = dim:CreateTexture(nil, "BACKGROUND")
        dimTex:SetAllPoints()
        dimTex:SetColorTexture(0, 0, 0, 0.45)

        local w = opts.width or 360
        local panel = CreateFrame("Frame", nil, dim)
        panel:SetSize(w, 10)
        panel:SetPoint("CENTER", dim, "CENTER", 0, 0)
        panel:EnableMouse(true)
        local bg = self.Surface(panel, "BACKGROUND", 0, S.menuBg)
        bg:SetAllPoints()
        self.Border(panel, panel:GetFrameLevel(), S.border, 1, 1)

        local title = self.Font(panel, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)

        local text = self.Font(panel, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        text:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
        text:SetJustifyH("LEFT")
        if text.SetWordWrap then text:SetWordWrap(true) end

        local closed = false
        local function Finish(accepted)
            if closed then return end
            closed = true
            dim:Hide()
            if accepted then
                if opts.onAccept then opts.onAccept() end
            else
                if opts.onCancel then opts.onCancel() end
            end
        end

        local close = self:CloseButton(panel, {
            size = 22,
            insetX = -10,
            insetY = -9,
            tooltip = opts.closeTooltip or "Close",
            onClick = function() Finish(false) end,
        })

        local accept = QfxDialogButton(self, panel, opts.acceptText or "Confirm", -14,
            (opts.danger and S.danger) or S.accent, function() Finish(true) end)
        local cancel = QfxDialogButton(self, panel, opts.cancelText or "Cancel", -114,
            S.buttonBg, function() Finish(false) end)

        dim:SetScript("OnKeyDown", function(_, k)
            if k == "ESCAPE" then Finish(false) end
        end)
        dim:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then Finish(false) end
        end)
        dim._accept, dim._cancel, dim._close, dim._panel = accept, cancel, close, panel
        dim.Close = function(_, accepted) Finish(accepted and true or false) end
        dim._qfxConfirmStyle = opts.danger and "danger" or "normal"
        function dim:ShowWithOptions(nextOptions)
            opts = nextOptions
            closed = false
            panel:SetWidth(opts.width or 360)
            title:SetText(opts.title or "Confirm")
            text:SetText(opts.text or "")
            accept._lbl:SetText(opts.acceptText or "Confirm")
            cancel._lbl:SetText(opts.cancelText or "Cancel")
            local height = math.max(16, (text.GetStringHeight and text:GetStringHeight()) or 20)
            panel:SetHeight(12 + 16 + 10 + height + 12 + 24 + 12)
            self:Show()
            return self
        end
        return dim:ShowWithOptions(opts)
    end
    W.CONFIRM_REUSE_REVISION = 1
end

-- Additive capability: modal, factory-drawn copy dialog (dim backdrop, panel,
-- title, hint, preselected read-only EditBox, footer close button). Esc,
-- backdrop clicks and the X all dismiss it; no Blizzard popup involved.
local function InstallCopyDialog(W)
    if (tonumber(W.COPY_DIALOG_REVISION) or 0) >= 1 then return end
    local Font, QfxSurface, QfxBorder = W.Font, W.Surface, W.Border

    --   opts = { title, hint, closeText, closeTooltip, width, height,
    --            multiline, selectAll = true, onClose }
    -- Returns the dialog; dialog.editBox is the box, dialog:Close() hides it.
    function W:CopyDialog(text, opts)
        opts = opts or {}
        local T = self.Theme
        local S = self:Tokens()

        local dim = CreateFrame("Frame", nil, UIParent)
        dim:SetAllPoints()
        dim:SetFrameStrata("DIALOG")
        dim:EnableMouse(true)
        if dim.EnableKeyboard then dim:EnableKeyboard(true) end
        local dimTex = dim:CreateTexture(nil, "BACKGROUND")
        dimTex:SetAllPoints()
        dimTex:SetColorTexture(0, 0, 0, 0.45)

        local w = opts.width or 420
        local panel = CreateFrame("Frame", nil, dim)
        panel:SetSize(w, 10)
        panel:SetPoint("CENTER", dim, "CENTER", 0, 0)
        panel:EnableMouse(true)
        local bg = QfxSurface(panel, "BACKGROUND", 0, S.menuBg)
        bg:SetAllPoints()
        QfxBorder(panel, panel:GetFrameLevel(), S.border, 1, 1)

        local closed = false
        local function Finish()
            if closed then return end
            closed = true
            dim:Hide()
            if opts.onClose then opts.onClose() end
        end

        local title = Font(panel, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        title:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
        title:SetText(opts.title or "Copy")

        local hint = Font(panel, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
        hint:SetPoint("RIGHT", panel, "RIGHT", -14, 0)
        hint:SetJustifyH("LEFT")
        if hint.SetWordWrap then hint:SetWordWrap(true) end
        hint:SetText(opts.hint or "")
        local hintH = (hint.GetStringHeight and hint:GetStringHeight()) or 16
        if hintH < 14 then hintH = 14 end

        local boxH = tonumber(opts.height) or 26
        local box = CreateFrame("EditBox", nil, panel)
        box:SetSize(w - 28, boxH)
        box:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -10)
        box:SetAutoFocus(false)
        if box.SetMultiLine then box:SetMultiLine(opts.multiline and true or false) end
        if box.SetMaxLetters then box:SetMaxLetters(0) end
        if box.SetJustifyV then box:SetJustifyV("MIDDLE") end
        local boxBg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
        boxBg:SetAllPoints()
        local boxBrd = QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
        box:SetFont(T.font, S.textSize, "")
        box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
        box:SetJustifyH("LEFT")
        box:SetTextInsets(6, 6, 4, 4)
        box:SetText(text or "")
        box:SetScript("OnChar", function() end) -- display only; selection still copies
        box:SetScript("OnEscapePressed", function(self2) self2:ClearFocus(); Finish() end)
        box:SetScript("OnEditFocusGained", function(self2)
            boxBrd._setBorder(S.borderHi or S.border)
            if opts.selectAll ~= false and self2.HighlightText then self2:HighlightText() end
        end)
        box:SetScript("OnEditFocusLost", function() boxBrd._setBorder(S.border) end)

        local close = self:CloseButton(panel, { size = 22, insetX = -10, insetY = -9,
            tooltip = opts.closeTooltip, onClick = Finish })
        local okButton = QfxDialogButton(self, panel, opts.closeText or rawget(_G, "OKAY") or "OK",
            -14, S.accent, Finish)

        panel:SetHeight(12 + 16 + 8 + hintH + 10 + boxH + 12 + 24 + 12)
        dim:SetScript("OnKeyDown", function(_, key) if key == "ESCAPE" then Finish() end end)
        dim:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" then Finish() end end)
        dim:Show()
        if box.SetFocus then box:SetFocus() end
        if opts.selectAll ~= false and box.HighlightText then box:HighlightText() end
        dim.editBox, dim._button, dim._close, dim._panel = box, okButton, close, panel
        dim.Close = function(_, accepted) Finish() end
        return dim
    end

    W.COPY_DIALOG_REVISION = 1
end


-- Upgrade old embedded singletons without changing the factory version.
local function InstallDynamicReorder(W)
    if W.REORDER_DYNAMIC_ITEMS then return end
    local ContentWidth, Font, TruncateToFit = W.ContentWidth, W.Font, W.TruncateToFit
    local QfxSurface, QfxBorder = W.Surface, W.Border
    local function EvalFlag(value)
        if type(value) == "function" then return value() and true or false end
        return value and true or false
    end
    local function QfxSheen(parent, color)
        local texture = QfxSurface(parent, "ARTWORK", 0, color or {1, 1, 1, 0.06})
        texture:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
        texture:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -2)
        texture:SetHeight(math.max(1, math.floor((parent:GetHeight() or 20) * 0.34)))
        return texture
    end
function W:ReorderList(parent, y, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local rowH = tonumber(opts.rowH) or 24
    local gap = tonumber(opts.gap) or 2
    local contentW = ContentWidth(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local order, rows = {}, {}
    local draggingIndex, draggingRow, dragBoundary
    local ghost, insertLine

    local function Source()
        return (type(opts.items) == "function" and opts.items()) or opts.items or {}
    end

    local function Load()
        local src = Source()
        for i = 1, #src do order[i] = src[i] end
        for i = #src + 1, #order do order[i] = nil end
    end

    local function EnsureInsertLine()
        if insertLine then return insertLine end
        insertLine = QfxSurface(frame, "OVERLAY", 7, S.warmAccent or S.accent)
        insertLine:SetHeight(2)
        insertLine:Hide()
        return insertLine
    end

    local function EnsureGhost()
        if ghost then return ghost end
        ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("TOOLTIP")
        if ghost.SetFrameLevel then ghost:SetFrameLevel(500) end
        local gbg = QfxSurface(ghost, "BACKGROUND", 0, S.menuBg)
        gbg:SetAllPoints()
        QfxBorder(ghost, ghost:GetFrameLevel(), S.warmAccent or S.border, 1, 1)
        local sheen = QfxSheen(ghost, S.buttonSheen)
        sheen:SetHeight(6)
        ghost.icon = ghost:CreateTexture(nil, "ARTWORK")
        ghost.icon:SetPoint("LEFT", ghost, "LEFT", 6, 0)
        ghost.icon:SetSize(rowH - 8, rowH - 8)
        ghost.icon:Hide()
        ghost.label = Font(ghost, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        ghost.label:SetPoint("LEFT", ghost, "LEFT", 10, 0)
        ghost.label:SetPoint("RIGHT", ghost, "RIGHT", -8, 0)
        ghost.label:SetJustifyH("LEFT")
        if ghost.label.SetWordWrap then ghost.label:SetWordWrap(false) end
        if ghost.label.SetMaxLines then ghost.label:SetMaxLines(1) end
        ghost:Hide()
        return ghost
    end

    local function ApplyVisual(row, item)
        local leftOffset = 26
        if item.icon then
            row._icon:SetTexture(item.icon)
            local c = item.coords
            if c then
                row._icon:SetTexCoord(c[1], c[2], c[3], c[4])
            else
                row._icon:SetTexCoord(0, 1, 0, 1)
            end
            row._icon:Show()
            leftOffset = 24 + (rowH - 8) + 6
        else
            row._icon:Hide()
        end

        local reserved = leftOffset + 8
        local rightTarget, rightOffset = row, -8
        if item.edit then
            row._edit:Show()
            if not row._edit:HasFocus() then
                local v = item.edit.getValue and item.edit.getValue() or ""
                row._edit:SetText(tostring(v or ""))
            end
            rightTarget, rightOffset = row._edit, -6
            reserved = reserved + (tonumber(opts.editWidth) or 150) + 6
            row._sub:Hide()
        else
            row._edit:Hide()
            if item.sub ~= nil and item.sub ~= "" then
                row._sub:SetText(tostring(item.sub))
                row._sub:Show()
                rightTarget, rightOffset = row._sub, -6
                reserved = reserved + 64
            else
                row._sub:SetText("")
                row._sub:Hide()
            end
        end

        row._label:ClearAllPoints()
        row._label:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
        if rightTarget == row then
            row._label:SetPoint("RIGHT", row, "RIGHT", rightOffset, 0)
        else
            row._label:SetPoint("RIGHT", rightTarget, "LEFT", rightOffset, 0)
        end
        TruncateToFit(row._label, item.label or tostring(item.key), math.max(40, contentW - reserved))

        row._locked = item.locked and true or false
        if row._locked then
            local mc = S.textMuted or S.text
            row._handle:SetText("x")
            row._handle:SetTextColor(mc[1], mc[2], mc[3], 0.45)
        else
            local mc = S.textMuted or S.text
            row._handle:SetText("=")
            row._handle:SetTextColor(mc[1], mc[2], mc[3], 1)
        end
    end

    local function FinishDrag()
        frame:SetScript("OnUpdate", nil)
        local from = draggingIndex
        local boundary = dragBoundary
        if draggingRow then draggingRow:SetAlpha(1) end
        draggingIndex, draggingRow, dragBoundary = nil, nil, nil
        if insertLine then insertLine:Hide() end
        if ghost then ghost:Hide() end
        if not from or not boundary or from < 1 then return end
        local finalIndex = boundary
        if finalIndex > from then finalIndex = finalIndex - 1 end
        if finalIndex < 1 then finalIndex = 1 end
        if finalIndex > #order then finalIndex = #order end
        if finalIndex == from then return end
        table.insert(order, finalIndex, table.remove(order, from))
        table.insert(rows, finalIndex, table.remove(rows, from))
        frame:Render()
        if opts.onChange then
            local keys = {}
            for i = 1, #order do keys[i] = order[i].key end
            opts.onChange(keys)
        end
    end

    local function UpdateInsertion()
        if not draggingIndex then return end
        local _, cy = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        if not scale or scale == 0 then scale = 1 end
        cy = cy / scale

        local boundary = #order + 1
        for i = 1, #order do
            local row = rows[i]
            if row and cy > ((row:GetTop() or 0) + (row:GetBottom() or 0)) / 2 then
                boundary = i
                break
            end
        end
        dragBoundary = boundary

        local finalIndex = boundary
        if finalIndex > draggingIndex then finalIndex = finalIndex - 1 end
        local line = EnsureInsertLine()
        if finalIndex == draggingIndex then
            line:Hide()
            return
        end
        line:ClearAllPoints()
        local atRow = (boundary <= #order) and rows[boundary] or nil
        if atRow then
            line:SetPoint("BOTTOMLEFT", atRow, "TOPLEFT", 0, gap / 2)
            line:SetPoint("BOTTOMRIGHT", atRow, "TOPRIGHT", 0, gap / 2)
        else
            local last = rows[#order]
            if last then
                line:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -gap / 2)
                line:SetPoint("TOPRIGHT", last, "BOTTOMRIGHT", 0, -gap / 2)
            else
                line:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
                line:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            end
        end
        line:Show()
    end

    local function BeginDrag(index)
        local row, item = rows[index], order[index]
        if not row or not item or item.locked then return end
        draggingIndex, draggingRow, dragBoundary = index, row, index
        row:SetAlpha(0.32)

        local g = EnsureGhost()
        g:SetSize(math.min(contentW, 260), rowH + 2)
        if item.icon then
            g.icon:SetTexture(item.icon)
            local c = item.coords
            if c then g.icon:SetTexCoord(c[1], c[2], c[3], c[4]) else g.icon:SetTexCoord(0, 1, 0, 1) end
            g.icon:Show()
            g.label:ClearAllPoints()
            g.label:SetPoint("LEFT", g.icon, "RIGHT", 6, 0)
            g.label:SetPoint("RIGHT", g, "RIGHT", -8, 0)
        else
            g.icon:Hide()
            g.label:ClearAllPoints()
            g.label:SetPoint("LEFT", g, "LEFT", 10, 0)
            g.label:SetPoint("RIGHT", g, "RIGHT", -8, 0)
        end
        g.label:SetText(item.label or tostring(item.key))
        g:Show()

        frame:SetScript("OnUpdate", function()
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                FinishDrag()
                return
            end
            local cx, cy = GetCursorPosition()
            local us = (UIParent and UIParent:GetEffectiveScale()) or 1
            if us == 0 then us = 1 end
            g:ClearAllPoints()
            g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / us, cy / us)
            UpdateInsertion()
        end)
    end

    local function EnsureRow(i)
        local row = rows[i]
        if row then return row end

        row = CreateFrame("Button", nil, frame)
        row:SetFrameLevel(frame:GetFrameLevel() + 1)
        local bg = QfxSurface(row, "BACKGROUND", 0, S.controlBg)
        bg:SetAllPoints()
        bg:SetAlpha(0.5)
        local handle = Font(row, T.labelSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        handle:SetPoint("LEFT", row, "LEFT", 8, 0)
        handle:SetWidth(10)
        handle:SetText("=")
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("LEFT", row, "LEFT", 24, 0)
        icon:SetSize(rowH - 8, rowH - 8)
        icon:Hide()
        local lbl = Font(row, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        lbl:SetPoint("LEFT", row, "LEFT", 26, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        if lbl.SetWordWrap then lbl:SetWordWrap(false) end
        if lbl.SetMaxLines then lbl:SetMaxLines(1) end
        local sub = Font(row, 12, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        sub:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        sub:SetJustifyH("RIGHT")
        sub:Hide()

        local edit = CreateFrame("EditBox", nil, row)
        edit:SetSize(tonumber(opts.editWidth) or 150, rowH - 8)
        edit:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        edit:SetAutoFocus(false)
        local ebg = QfxSurface(edit, "BACKGROUND", 0, S.controlBg)
        ebg:SetAllPoints()
        QfxBorder(edit, edit:GetFrameLevel(), S.border, 1, 1)
        edit:SetFont(T.font, S.textSize, "")
        edit:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        edit:SetJustifyH("LEFT")
        edit:SetTextInsets(5, 4, 0, 0)
        edit:Hide()
        edit:SetScript("OnEscapePressed", function(self2)
            self2._qfxCancel = true
            self2:ClearFocus()
        end)
        edit:SetScript("OnEnterPressed", function(self2) self2:ClearFocus() end)
        edit:SetScript("OnEditFocusLost", function(self2)
            if self2._qfxCancel then
                self2._qfxCancel = nil
                return
            end
            local item = order[self2._parentRow and self2._parentRow._index or 0]
            if item and item.edit and item.edit.setValue then
                item.edit.setValue(self2:GetText() or "")
            end
            frame:Render()
        end)

        row._bg, row._handle, row._icon, row._label, row._sub, row._edit = bg, handle, icon, lbl, sub, edit
        edit._parentRow = row

        row:SetScript("OnEnter", function(self2)
            if draggingIndex then return end
            self2._bg:SetAlpha(0.95)
            local item = order[self2._index]
            if item then
                GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                GameTooltip:SetText(item.label or tostring(item.key), 1, 1, 1)
                local itemTip = ResolveTooltipText(item.tooltip)
                if itemTip then GameTooltip:AddLine(itemTip, 1, 1, 1, true) end
                if opts.dragHint then GameTooltip:AddLine(opts.dragHint, 0.75, 0.85, 1, true) end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self2)
            self2._bg:SetAlpha(0.5)
            GameTooltip:Hide()
        end)
        row:SetScript("OnMouseDown", function(self2, button)
            if button ~= "LeftButton" then return end
            if EvalFlag(opts.disabled) then return end
            local item = order[self2._index]
            if not item or item.locked then return end
            local startX, startY = GetCursorPosition()
            self2:SetScript("OnUpdate", function(armed)
                if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
                    armed:SetScript("OnUpdate", nil)
                    return
                end
                local x, y = GetCursorPosition()
                if math.abs(x - startX) >= 3 or math.abs(y - startY) >= 3 then
                    armed:SetScript("OnUpdate", nil)
                    BeginDrag(armed._index)
                end
            end)
        end)
        row:SetScript("OnMouseUp", function(self2)
            self2:SetScript("OnUpdate", nil)
        end)
        row:SetScript("OnHide", function()
            if draggingIndex then FinishDrag() end
        end)
        rows[i] = row
        return row
    end

    function frame:Render()
        if draggingIndex then return end
        local stripe = 0
        for i = 1, #rows do
            local row = rows[i]
            local item = order[i]
            if item then
                row._index = i
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -((i - 1) * (rowH + gap)))
                row:SetSize(contentW, rowH)
                -- zebra wash + a slightly stronger odd row
                stripe = stripe + 1
                local c = (stripe % 2 == 1) and (S.rowBgOdd or S.rowBgEven) or (S.rowBgEven or S.rowBgOdd)
                row._bg:SetColorTexture(c[1], c[2], c[3], (c[4] or 0.05) * 2.2)
                ApplyVisual(row, item)
                row:Show()
            else
                row._index = nil
                row:Hide()
            end
        end
        frame:SetSize(contentW, math.max(1, #order) * (rowH + gap) + gap)
    end

    Load()
    local count = #order
    for i = 1, count do
        EnsureRow(i)
    end
    frame:Render()
    return frame, frame:GetHeight(), { Render = function()
        if draggingIndex then return end
        Load()
        for i = 1, #order do EnsureRow(i) end
        frame:Render()
    end }
end

    W.REORDER_DYNAMIC_ITEMS = true
end

local function InstallContentInput(W)
    if (tonumber(W.CONTENT_INPUT_REVISION) or 0) >= 1 then return end
    local dualRow = W.DualRow
    if type(dualRow) ~= "function" then return end
    function W:DualRow(parent, y, leftCfg, rightCfg)
        if rightCfg or not leftCfg or leftCfg.type ~= "input" or leftCfg.layout ~= "stacked" then
            return dualRow(self, parent, y, leftCfg, rightCfg)
        end
        local row = dualRow(self, parent, y, leftCfg)
        local T, S = self.Theme, self.Skin
        local height = T.rowH * 2
        row:SetHeight(height)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -T.pad, y)
        local region = row._leftRegion
        region:SetAllPoints(row)
        local label, box = region._label, region._control
        local left, right = T.sidePad or T.pad, T.rightPad or T.pad
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", region, "TOPLEFT", left, 0)
        label:SetPoint("TOPRIGHT", region, "TOPRIGHT", -right, 0)
        label:SetHeight(T.rowH)
        box:ClearAllPoints()
        local inputY = -T.rowH - (T.rowH - (S.rowControlH or T.controlH)) / 2
        box:SetPoint("TOPLEFT", region, "TOPLEFT", left, inputY)
        box:SetPoint("TOPRIGHT", region, "TOPRIGHT", -right, inputY)
        local function FitTitle()
            self.TruncateToFit(label, leftCfg.text or "", label:GetWidth())
        end
        FitTitle()
        row:HookScript("OnSizeChanged", FitTitle)
        self.AttachTooltip(label, leftCfg.text, leftCfg.tooltip)
        self.AttachTooltip(box, leftCfg.text, leftCfg.tooltip)
        return row, height
    end
    W.CONTENT_INPUT_REVISION = 1
end

-- Close chrome must never pass its X through globally hooked text methods.
-- Install before the singleton guard as well, so an older embedded factory
-- receives the same renderer without replacing its table or other controls.
local function InstallCloseButton(W)
    if (tonumber(W.CLOSE_BUTTON_REVISION) or 0) >= 1 then return end

    function W:SetCloseTexture(path)
        self.CloseTexture = path
        return path
    end

    function W:CloseButton(parent, opts)
        opts = opts or {}
        local S = self:Tokens()
        local size = tonumber(opts.size) or 26
        local warm = S.warmAccent or S.danger
        local warmHi = S.warmAccentHi or warm
        local base = S.closeBg or S.menuBg
        local hover = S.closeBgHi or S.controlBgHi
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(size, size)
        if opts.anchor ~= false then
            btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", opts.insetX or -8, opts.insetY or -8)
        end
        local bg = self.Surface(btn, "BACKGROUND", 0, base)
        bg:SetAllPoints()
        local brd = self.Border(btn, btn:GetFrameLevel(), warm, 1, 1)
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(math.max(12, size - 4), math.max(12, size - 4))
        icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
        local path = self.CloseTexture
        if path == nil then
            local provider
            if addonName == "QFXAddonManager_Config" or addonName == "QFXAddonManager" then
                provider = "QFXAddonManager"
            elseif addonName == "QFXWidgets" then
                provider = "QFXWidgets"
            elseif C_AddOns and C_AddOns.DoesAddOnExist and C_AddOns.DoesAddOnExist("QFXAddonManager") then
                provider = "QFXAddonManager"
            end
            if provider then
                local format = self.MediaFormat == "png" and "png" or "blp"
                path = "Interface\\AddOns\\" .. provider .. "\\Media\\close-x." .. format
            end
        end
        local lines
        if not path or icon:SetTexture(path, "CLAMP", "CLAMP", "TRILINEAR") == false then
            icon:Hide()
            lines = {}
            local half = math.max(4, (size - 10) / 2)
            for i = 1, 2 do
                local line = btn:CreateLine(nil, "ARTWORK")
                line:SetThickness(2)
                line:SetStartPoint("CENTER", btn, -half, i == 1 and half or -half)
                line:SetEndPoint("CENTER", btn, half, i == 1 and -half or half)
                lines[i] = line
            end
        else
            if icon.SetSnapToPixelGrid then icon:SetSnapToPixelGrid(false) end
            if icon.SetTexelSnappingBias then icon:SetTexelSnappingBias(0) end
        end
        local function SetIconColor(r, g, b, a)
            icon:SetVertexColor(r, g, b, a)
            if lines then
                for i = 1, #lines do lines[i]:SetColorTexture(r, g, b, a) end
            end
        end
        SetIconColor(warmHi[1], warmHi[2], warmHi[3], warmHi[4] or 1)
        btn:SetScript("OnEnter", function()
            bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4] or 1)
            brd._setBorder(warmHi)
            SetIconColor(1, 0.88, 0.65, 1)
        end)
        btn:SetScript("OnLeave", function()
            bg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
            brd._setBorder(warm)
            SetIconColor(warmHi[1], warmHi[2], warmHi[3], warmHi[4] or 1)
        end)
        btn:SetScript("OnClick", function(self2)
            if opts.onClick then opts.onClick(self2) elseif parent.Hide then parent:Hide() end
        end)
        btn._bg, btn._brd, btn._icon, btn._closeLines = bg, brd, icon, lines
        self.AttachTooltip(btn, opts.tooltip or (rawget(_G, "CLOSE") or "Close"), nil)
        return btn
    end
    W.CLOSE_BUTTON_REVISION = 1
end

local VERSION = 51 -- factory singleton version; additive capabilities have their own revisions
local F = rawget(_G, "QFXWidgets")

if type(F) == "table" and (tonumber(F.VERSION) or 0) >= VERSION then
    InstallAddonToggle(F) -- add the capability without replacing an existing singleton
    InstallMotion(F)
    InstallDynamicReorder(F)
    InstallSpeechBubble(F)
    InstallStatusTicker(F)
    InstallBrandImages(F)
    InstallDetachedControls(F)
    InstallIconButton(F)
    InstallCopyDialog(F)
    InstallReusableConfirm(F)
    InstallContentInput(F)
    InstallCloseButton(F)
    if ns then ns.QFXWidgets = F end
    return -- newer copy already loaded: reuse it (no duplicate tables/frames)
end

F = type(F) == "table" and F or {}
_G.QFXWidgets = F
F.VERSION = VERSION
if ns then ns.QFXWidgets = F end

local floor = math.floor

-------------------------------------------------------------------------------
-- Theme (host must call :SetTheme before building rows to restyle)
-------------------------------------------------------------------------------
F.Theme = F.Theme or {
    font         = (rawget(_G, "STANDARD_TEXT_FONT") or "Fonts\\FRIZQT__.TTF"),
    rowH         = 32, -- compact rows
    sliderRowH   = 38, -- slider rows are taller: min/max labels sit under the track
    wideButtonH  = 34,
    headerH      = 28, -- fallback header row when the gradient bar is disabled
    sectionBarH  = 24, -- gradient title bar height
    labelSize    = 14,
    labelColor   = { 1, 1, 1, 0.9 },
    mutedColor   = { 1, 1, 1, 0.45 },
    sectionSize  = 15, -- section title; stays one step above the 14px row labels
    noteSize     = 12,
    sectionColor = { 0.05, 0.82, 0.62, 1 },
    lineColor    = { 1, 1, 1, 0.08 },
    pad          = 10,
    sidePad      = 10,
    rightPad     = 16,
    labelGap     = 8,  -- gap between the clamped label and its control
    trackWidth   = 110,
    controlH     = 20,
    -- alternating row background (nil entry = no zebra)
    rowBgOdd     = { 1, 1, 1, 0.02 },
    rowBgEven    = { 1, 1, 1, 0.01 },
}

function F:SetTheme(t)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do self.Theme[k] = v end
end

-------------------------------------------------------------------------------
-- Refresh registry
-------------------------------------------------------------------------------
F._refresh = F._refresh or {}

function F:RegisterRefresh(fn)
    if type(fn) ~= "function" then return end
    self._refresh[#self._refresh + 1] = { fn = fn, owner = self._refreshScope }
end

-- Drop refresh callbacks: no argument clears everything, an owner clears only
-- that owner's callbacks (used by BeginPage on rebuild).
function F:ClearRefreshes(owner)
    if owner == nil then
        local l = self._refresh
        for i = #l, 1, -1 do l[i] = nil end
        return
    end
    local out = {}
    for i = 1, #self._refresh do
        local e = self._refresh[i]
        if e.owner ~= owner then out[#out + 1] = e end
    end
    self._refresh = out
end

-- Refresh(owner): no argument refreshes every page, an owner refreshes only
-- that page's callbacks. Errors are counted (F.lastRefreshError) instead of
-- being silently swallowed forever.
function F:Refresh(owner)
    local l = self._refresh
    for i = 1, #l do
        local e = l[i]
        if owner == nil or e.owner == owner then
            local ok, err = pcall(e.fn)
            if not ok then self.lastRefreshError = err end
        end
    end
end

-- Page scoping: call BeginPage(owner) before rebuilding a page and EndPage()
-- after; every RegisterRefresh inside gets that owner, old callbacks of the
-- same owner are dropped first, and RefreshPage(owner) refreshes just that page.
function F:BeginPage(owner)
    if owner == nil then return end
    self:ClearRefreshes(owner)
    self._refreshScope = owner
end

function F:EndPage()
    self._refreshScope = nil
end

function F:RefreshPage(owner)
    self:Refresh(owner)
end

-------------------------------------------------------------------------------
-- Small helpers
-------------------------------------------------------------------------------
local function Font(parent, size, r, g, b, a)
    local T = F.Theme
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(T.font, size or T.labelSize, "")
    if r then fs:SetTextColor(r, g, b, a or 1) end
    return fs
end
F.Font = Font

local function ContentWidth(parent)
    local T = F.Theme
    local w = parent and parent.GetWidth and parent:GetWidth() or 0
    w = (tonumber(w) or 0) - T.pad * 2
    if w < 120 then w = 120 end
    return w
end
F.ContentWidth = ContentWidth

local function AttachTooltip(target, title, text)
    if not (target and (title or text)) then return end
    -- Compose with existing hover scripts instead of replacing them: several
    -- builders install their hover visuals before attaching the tooltip.
    local prevEnter = target.GetScript and target:GetScript("OnEnter")
    local prevLeave = target.GetScript and target:GetScript("OnLeave")
    target:SetScript("OnEnter", function(self)
        if prevEnter then prevEnter(self) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title or "", 1, 1, 1)
        if text then GameTooltip:AddLine(text, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    target:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if prevLeave then prevLeave(self) end
    end)
end
F.AttachTooltip = AttachTooltip

-------------------------------------------------------------------------------
-- Alternating row backgrounds (zebra) + label clamp
-------------------------------------------------------------------------------
F._rowCounts = F._rowCounts or setmetatable({}, { __mode = "k" })
-- last finished section per parent page (W:LastSectionHeader), weak so pages can
-- be discarded without keeping them alive
F._lastHeader = F._lastHeader or setmetatable({}, { __mode = "k" })

-- Optional: call at page start so every page begins on the same stripe.
function F:ResetRows(parent)
    self._rowCounts[parent] = 0
end

local function RowBg(frame, parent, self)
    local count = (self._rowCounts[parent] or 0) + 1
    self._rowCounts[parent] = count
    local S = self.Skin
    local color
    if count % 2 == 1 then
        color = (S and S.rowBgOdd) or self.Theme.rowBgOdd
    else
        color = (S and S.rowBgEven) or self.Theme.rowBgEven
    end
    if not color then return end
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

-- 12.x secret values: any comparison/size made from one must be skipped.
local function IsSecret(v)
    return issecretvalue and issecretvalue(v) and true or false
end
F.IsSecret = IsSecret

-- Ellipsize `fs` to `maxW`: sets the text and returns the shown string, truncated.
local function TruncateToFit(fs, text, maxW)
    text = text or ""
    fs:SetText(text)
    if not (maxW and maxW > 0) then return text, false end
    if IsSecret(maxW) then return text, false end
    local w = fs:GetStringWidth()
    if IsSecret(w) then return text, false end
    if (w or 0) <= maxW then return text, false end
    local ell = "..."
    local lo, hi = 0, #text
    while lo < hi do
        local mid = floor((lo + hi + 1) / 2)
        fs:SetText(text:sub(1, mid) .. ell)
        local mw = fs:GetStringWidth()
        if IsSecret(mw) then break end
        if (mw or 0) <= maxW then lo = mid else hi = mid - 1 end
    end
    fs:SetText(text:sub(1, lo) .. ell)
    return text:sub(1, lo) .. ell, true
end
F.TruncateToFit = TruncateToFit

-- Bind a row label to its control's left edge, ellipsize on overflow, and show
-- the full text (plus the cfg tooltip) on hover. When the row is not sized yet
-- (width 0 right after building) the clamp is deferred one frame and retried,
-- so long / CJK labels always ellipsize instead of overrunning the control.
local function FitLabel(region, cfg, self)
    local label = region._label
    if not label then return end
    local T = self.Theme
    local control = region._control
    local gap = T.labelGap or 8
    label:SetJustifyH("LEFT")
    if label.SetWordWrap then label:SetWordWrap(false) end
    if label.SetMaxLines then label:SetMaxLines(1) end
    if control then
        label:SetPoint("RIGHT", control, "LEFT", -gap, 0)
    else
        label:SetPoint("RIGHT", region, "RIGHT", -(T.rightPad or 16), 0)
    end
    local full = cfg.text or ""
    local function Clamp()
        local w = label:GetWidth()
        if w == nil or w <= 0 then return false end
        local _, truncated = TruncateToFit(label, full, w)
        region._labelTruncated = truncated or nil
        local tip = cfg.tooltip
        if truncated then
            AttachTooltip(label, full, tip)
        elseif tip and tip ~= "" then
            AttachTooltip(label, nil, tip)
        end
        return true
    end
    if not Clamp() and C_Timer and C_Timer.After then
        C_Timer.After(0, Clamp)
    end
end

local function ResolveLabel(values, order, key)
    local v = values and values[key]
    if type(v) == "table" then return v.text or tostring(key) end
    if v ~= nil then return v end
    return tostring(key)
end
F.ResolveLabel = ResolveLabel

-- Dim + block a control (optional reason tooltip on the blocker).
-- Combat lockdown convention: cfg.blockInCombat keeps a control read-only in
-- combat (the standard cause of taint on protected writes). Hosts should also
-- call W:Refresh() on PLAYER_REGEN_ENABLED so the state updates when combat ends.
local function IsCombatLocked()
    return (InCombatLockdown and InCombatLockdown()) and true or false
end
F.IsCombatLocked = IsCombatLocked
F.InCombatLocked = IsCombatLocked

-- Option flags accept either a boolean or a predicate. This keeps the public
-- config tables convenient while retaining dynamic disabled states.
local function EvalFlag(value, ...)
    if type(value) == "function" then return value(...) and true or false end
    return value and true or false
end

-- Is this cfg disabled right now (explicit disabled() or combat lockdown)?
local function ConfigDisabled(cfg)
    if not cfg then return false end
    if EvalFlag(cfg.disabled) then return true end
    if cfg.blockInCombat and IsCombatLocked() then return true end
    return false
end
-- Is this cfg disabled right now? (method form for hosts: W:IsDisabled(cfg))
function F:IsDisabled(cfg)
    return ConfigDisabled(cfg)
end

local function ApplyDisabled(region, control, cfg)
    local disabled = cfg and cfg.disabled
    local tip = cfg and cfg.disabledTooltip
    local blockInCombat = cfg and cfg.blockInCombat
    if not disabled and not tip and not blockInCombat then return end
    local block
    local function Refresh()
        local off = EvalFlag(disabled)
        local combat = blockInCombat and IsCombatLocked() or false
        if combat then off = true end
        if not block then
            block = CreateFrame("Frame", nil, region)
            block:SetAllPoints()
            block:SetFrameLevel(region:GetFrameLevel() + 12)
            block:EnableMouse(true)
            block:Hide()
            block:SetScript("OnEnter", function(self)
                local reason
                if combat then
                    reason = (cfg and cfg.combatTooltip) or "Not available in combat"
                elseif type(tip) == "function" then
                    reason = tip()
                else
                    reason = tip
                end
                if reason and reason ~= "" then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            block:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        if control and control.SetAlpha then control:SetAlpha(off and 0.35 or 1) end
        local extra = region and region._dimTargets
        if extra then
            for i = 1, #extra do
                local f = extra[i]
                if f and f.SetAlpha then f:SetAlpha(off and 0.35 or 1) end
            end
        end
        block:SetShown(off)
    end
    F:RegisterRefresh(Refresh)
    Refresh()
end

-------------------------------------------------------------------------------
-- Thin strips (1px borders/dividers) must never round to 0 and vanish at
-- fractional UI scales; disable pixel snapping on them (EUI does the same).
local function NoSnap(t)
    if t and t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
    if t and t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
    return t
end
F.NoSnap = NoSnap

-- Snap a UI-space measurement to a whole physical screen pixel. EllesmereUI
-- applies this discipline to every compact control; it prevents 4px rails,
-- 1px insets and small knobs from landing between pixels at fractional scale.
local function OnePixelUI(frame)
    local es = 1
    if frame and frame.GetEffectiveScale then
        local ok, v = pcall(frame.GetEffectiveScale, frame)
        if ok and type(v) == "number" and v > 0 then es = v end
    end
    local physicalH = 1080
    if GetPhysicalScreenSize then
        local ok, _, h = pcall(GetPhysicalScreenSize)
        if ok and type(h) == "number" and h > 0 then physicalH = h end
    end
    return (768 / physicalH) / es
end

local function SnapUI(frame, value)
    value = tonumber(value) or 0
    if value == 0 then return 0 end
    local onePixel = OnePixelUI(frame)
    local pixels = value / onePixel
    pixels = value > 0 and math.floor(pixels + 0.001) or math.ceil(pixels - 0.001)
    if pixels == 0 then pixels = value > 0 and 1 or -1 end
    return pixels * onePixel
end

-- SectionHeader / Note / Spacer / WideButton
-------------------------------------------------------------------------------
-- Gradient fills need a different call per branch: SetGradient takes ColorMixin
-- objects on 10.0+, SetGradientAlpha is the older signature, a solid fill is the
-- last resort so the title bar never disappears. It filters the texture's own
-- colour (SetVertexColor family), so a white base must be set first or the
-- gradient has nothing to shade and stays invisible.
local function GradientTexture(tex, from, to)
    tex:SetColorTexture(1, 1, 1, 1)
    if CreateColor and tex.SetGradient then
        local ok = pcall(tex.SetGradient, tex, "HORIZONTAL",
            CreateColor(from[1], from[2], from[3], from[4] or 1),
            CreateColor(to[1], to[2], to[3], to[4] or 1))
        if ok then return end
    end
    if tex.SetGradientAlpha then
        local ok = pcall(tex.SetGradientAlpha, tex, "HORIZONTAL",
            from[1], from[2], from[3], from[4] or 1,
            to[1], to[2], to[3], to[4] or 1)
        if ok then return end
    end
    tex:SetColorTexture(from[1], from[2], from[3], from[4] or 1)
end

-- Section title. opts = { size, bar = true, barHeight, from, to, note (string or
-- list of strings), noteSize, noteGap, line = true, lineGap, height }.
-- The description belongs to the section, so the divider is drawn under every
-- note line. A hint that arrives later can join it:
--   local hdr, flowY = W:LastSectionHeader(parent)
--   if hdr and math.abs(flowY - y) < 0.5 then y = y - hdr:AddNote(text) end
function F:SectionHeader(parent, text, y, opts)
    opts = opts or {}
    local T = self.Theme
    local S = self.Skin or {}
    local sc = S.sectionText or T.sectionColor
    local lc = S.line or T.lineColor
    self._rowCounts[parent] = 0 -- every section restarts the zebra stripes

    local withBar = opts.bar ~= false
    local withLine = opts.line ~= false
    local barH = tonumber(opts.barHeight) or tonumber(opts.height) or T.sectionBarH or 24
    local noteGap = tonumber(opts.noteGap) or 4
    local lineGap = tonumber(opts.lineGap) or 6
    local noteSize = tonumber(opts.noteSize) or T.noteSize or 12
    local size = tonumber(opts.size) or math.max(T.sectionSize or 14, noteSize + 2)
    local textLeft = withBar and 12 or 0

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    frame:SetSize(ContentWidth(parent), 1) -- width first: the note wraps to it

    local label = Font(frame, size, sc[1], sc[2], sc[3], sc[4] or 1)
    local h = withBar and barH or (T.headerH or 28)
    if withBar then
        local from = opts.from or S.sectionBarFrom or { 0.090, 0.430, 0.760, 0.98 }
        local to = opts.to or S.sectionBarTo or { 0.024, 0.086, 0.150, 0.55 }
        local bar = NoSnap(frame:CreateTexture(nil, "BACKGROUND"))
        bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        bar:SetHeight(h)
        GradientTexture(bar, from, to)
        local ec = S.sectionBarEdge or { 0.000, 0.670, 1.000, 0.85 }
        local edge = NoSnap(frame:CreateTexture(nil, "BACKGROUND", nil, 1))
        edge:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
        edge:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
        edge:SetWidth(math.max(1, SnapUI(frame, 2)))
        edge:SetColorTexture(ec[1], ec[2], ec[3], ec[4] or 1)
        -- anchor the title to the bar itself: one anchor per axis, so it stays
        -- vertically centred on the bar instead of drifting into the note
        label:SetPoint("LEFT", bar, "LEFT", textLeft, 0)
        label:SetPoint("RIGHT", bar, "RIGHT", -8, 0)
        label:SetJustifyH("LEFT")
        if label.SetJustifyV then label:SetJustifyV("MIDDLE") end
        frame._bar, frame._edge = bar, edge
    else
        label:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 8)
    end
    label:SetText(text or "")
    frame._label = label

    if withLine then
        local line = NoSnap(frame:CreateTexture(nil, "ARTWORK"))
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        line:SetColorTexture(lc[1], lc[2], lc[3], lc[4] or 1)
        frame._divider = line
    end

    frame._contentH = h
    frame._noteGap, frame._lineGap, frame._withLine, frame._textLeft = noteGap, lineGap, withLine, textLeft

    local function AddNoteLine(note)
        local mc = S.textMuted or T.mutedColor
        local ns = Font(frame, noteSize, mc[1], mc[2], mc[3], mc[4] or 1)
        ns:SetPoint("TOPLEFT", frame, "TOPLEFT", textLeft, -(frame._contentH + noteGap))
        ns:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
        ns:SetJustifyH("LEFT")
        if ns.SetWordWrap then ns:SetWordWrap(true) end
        ns:SetText(note)
        local nh = math.max(14, (ns.GetStringHeight and ns:GetStringHeight()) or 14)
        frame._contentH = frame._contentH + noteGap + nh
        frame._notes = frame._notes or {}
        frame._notes[#frame._notes + 1] = ns
        return nh
    end
    local function Relayout()
        local total = frame._contentH + (withLine and (lineGap + 1) or 0)
        frame:SetHeight(total)
        return total
    end

    -- fold a later hint into this section; returns the height it consumed
    function frame:AddNote(note)
        if not note or note == "" then return 0 end
        local consumed = noteGap + AddNoteLine(note)
        Relayout()
        local rec = F._lastHeader[parent]
        if rec and rec.frame == frame then rec.flowY = rec.flowY - consumed end
        return consumed
    end

    if opts.note then
        if type(opts.note) == "table" then
            for i = 1, #opts.note do
                if opts.note[i] then AddNoteLine(opts.note[i]) end
            end
        else
            AddNoteLine(opts.note)
        end
    end
    local total = Relayout()
    frame._refresh = function() end
    F._lastHeader[parent] = { frame = frame, flowY = y - total }
    return frame, total
end

-- The section that most recently finished on this parent, for folding a page
-- hint into it (see the SectionHeader contract above).
function F:LastSectionHeader(parent)
    local rec = self._lastHeader and self._lastHeader[parent]
    if not rec or not rec.frame then return nil end
    return rec.frame, rec.flowY
end

function F:Note(parent, y, text, opts)
    opts = opts or {}
    local T = self.Theme
    local S = self.Skin
    local mc = (S and S.textMuted) or T.mutedColor
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    frame:SetSize(ContentWidth(parent), 1) -- wrapped text needs a width before measuring
    local fs = Font(frame, opts.size or 12, mc[1], mc[2], mc[3], mc[4] or 1)
    fs:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    fs:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    fs:SetJustifyH("LEFT")
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    fs:SetText((opts.textFn and opts.textFn()) or text or "")
    local h = (fs.GetStringHeight and fs:GetStringHeight()) or 16
    h = math.max(18, h + 6)
    frame:SetHeight(h)
    frame._text = fs
    frame._refresh = function()
        if fs.SetText and frame._textFn then fs:SetText(frame._textFn() or "") end
    end
    if opts.textFn then
        frame._textFn = opts.textFn
        self:RegisterRefresh(frame._refresh)
    end
    return y - h, frame -- second return is for hosts that keep row references
end

function F:Spacer(parent, y, height)
    return y - (height or 12)
end

function F:WideButton(parent, text, y, onClick, opts)
    opts = opts or {}
    local T = self.Theme
    local h = opts.height or T.wideButtonH or 34
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h + 8)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    RowBg(frame, parent, self)
    local S = self.Skin
    if S and S.wideButton then
        S.wideButton(frame, text or "", onClick, opts)
    end
    frame._refresh = function() end
    return frame, h + 8
end

-------------------------------------------------------------------------------
-- DualRow + slot controls
-------------------------------------------------------------------------------
local function BuildLabel(region, cfg)
    local T = F.Theme
    local label = Font(region, T.labelSize, T.labelColor[1], T.labelColor[2], T.labelColor[3], T.labelColor[4])
    label:SetPoint("LEFT", region, "LEFT", T.sidePad, 0)
    label:SetJustifyH("LEFT")
    if label.SetWordWrap then label:SetWordWrap(false) end
    if label.SetMaxLines then label:SetMaxLines(1) end
    label:SetText(cfg.text or "")
    region._label = label
    return label
end

-------------------------------------------------------------------------------
-- QFXUI skin: ALL controls are custom-drawn here (layered solid-colour surfaces
-- plus masked circular primitives; no Blizzard templates besides the vanilla
-- chat arrow and options gear textures). A host can override any token with
--   W:SetSkin{ accent = {...}, controlBg = {...}, rowControlH = 20, ... }
-- Everything not overridden keeps the defaults below.
-------------------------------------------------------------------------------
local QFXSkin = {
    name = "qfxui",

    -- surfaces
    controlBg    = { 0.025, 0.075, 0.130, 0.96 }, -- deep navy glass
    controlBgHi  = { 0.045, 0.150, 0.245, 0.99 }, -- brighter hover glass
    border       = { 0.030, 0.285, 0.490, 0.95 }, -- electric-blue frame
    borderHi     = { 0.000, 0.670, 1.000, 1 },    -- cyan hover / focus frame
    trackBg      = { 1.000, 1.000, 1.000, 0.14 }, -- EUI-style quiet neutral rail
    trackFill    = { 0.000, 0.625, 1.000, 0.82 }, -- accent without neon clipping
    knob         = { 0.900, 0.965, 1.000, 1 },
    knobInner    = { 0.000, 0.625, 1.000, 1 },
    accent       = { 0.000, 0.625, 1.000, 1 },
    accentDim    = { 0.000, 0.625, 1.000, 0.35 },
    selected     = { 0.000, 0.625, 1.000, 0.18 }, -- selected row wash
    danger       = { 1.000, 0.320, 0.240, 1 },
    warmAccent   = { 1.000, 0.550, 0.130, 1 },    -- logo's orange arc
    warmAccentHi = { 1.000, 0.720, 0.300, 1 },
    closeBg      = { 0.055, 0.080, 0.105, 0.98 },
    closeBgHi    = { 0.210, 0.105, 0.035, 1 },
    good         = { 0.30, 0.90, 0.45, 1 },
    buttonBg     = { 0.040, 0.145, 0.245, 0.97 },
    buttonBgHi   = { 0.055, 0.235, 0.380, 1 },
    buttonBorder = { 0.035, 0.350, 0.580, 0.98 },
    buttonSheen  = { 0.300, 0.760, 1.000, 0.085 },
    text         = { 0.925, 0.965, 1.000, 1 },
    textMuted    = { 0.610, 0.735, 0.850, 1 },
    arrow        = { 1.000, 1.000, 1.000, 1 },
    menuBg       = { 0.018, 0.050, 0.090, 0.985 },
    rowHover     = { 0.000, 0.625, 1.000, 0.13 },
    sectionText  = { 0.720, 0.890, 1.000, 1 },    -- section headers / category text
    -- gradient section title bar: the logo's warm amber fading into the panel
    -- with a muted bright edge on the left (a fully saturated warm start read as
    -- too loud against the navy panel)
    sectionBarFrom = { 0.620, 0.320, 0.070, 0.92 },
    sectionBarTo   = { 0.100, 0.048, 0.020, 0.38 },
    sectionBarEdge = { 0.860, 0.520, 0.160, 0.85 },
    line         = { 0.030, 0.360, 0.600, 0.58 }, -- separator line

    rowBgOdd     = { 0.000, 0.625, 1.000, 0.070 }, -- zebra: raised blue wash so
    rowBgEven    = { 0.000, 0.625, 1.000, 0.018 }, -- the row rhythm stays readable

    -- sizes (compact)
    textSize    = 14,
    menuRowH    = 20,
    toggleW     = 40,
    toggleH     = 20,
    -- Equal 2px insets around the square thumb, matching the EUI proportions.
    togglePad   = 2,
    toggleAnim  = true,
    toggleAnimDur = 0.075,
    -- OFF must read as a switch: a near-background track looked like a bare block
    toggleBorder   = { 0.450, 0.800, 1.000, 0.32 },
    toggleTrackOff = { 0.267, 0.267, 0.267, 0.65 },
    toggleTrackOn  = { 0.000, 0.625, 1.000, 0.82 },
    toggleKnobOff  = { 1.000, 1.000, 1.000, 0.60 },
    toggleKnobOn   = { 1.000, 1.000, 1.000, 1.00 },
    toggleKnobRing = { 0.900, 0.965, 1.000, 1.00 },
    knobSize    = 14,
    trackH      = 4,
    thumbW      = 16,
    thumbH      = 16,
    valueBoxW   = 44,
    rowControlH = 20,
    buttonH     = 20,
    buttonMinW  = 88,
    stepperW    = 18, -- slider +/- column (flush right of the value box)
    stepperGap  = 0,  -- gap between the value box and the stepper column
    segMinW     = 38, -- segmented pill: min width / text padding / gap
    segPadX     = 16,
    segGap      = 1,
    -- selected fills remain quieter than the full-bright cyan accent
    selectedFill = { 0.025, 0.250, 0.410, 0.98 },
    selectedLine = { 1.000, 0.550, 0.130, 1 }, -- warm-orange active tab underline
    selectedText = { 0.920, 0.960, 1.000, 1 },
    segOnText   = { 0.920, 0.960, 1.000, 1 }, -- text on the selected pill
    -- selection marks: the warm accent is used only where a mark reports an
    -- active state; the slider thumb and toggle knob stay neutral by default
    checkFill   = { 1.000, 0.550, 0.130, 1.00 }, -- checkbox / selection mark
}

local function QfxSurface(parent, layer, sub, c)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
    if c then t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) else t:SetColorTexture(0, 0, 0, 0) end
    return t
end

-- Rounded control primitives. WoW has no rounded-frame primitive, so the
-- factory masks white textures into circles and joins them with a centre
-- strip. Older clients without texture masks keep a clean rectangular
-- fallback instead of failing to build the settings page.
local WHITE_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local ROUND_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"

-- Bundled media for the rounded controls. The .blp twins are the standard: the
-- same shapes at 2x resolution with a pre-baked mip chain, which is what keeps
-- them smooth when the client samples them with TRILINEAR. The PNG files remain
-- as the explicit fallback (W:SetMediaFormat("png")) and for hosts that ship
-- only the PNG art.
F.MediaFormat = "blp"

function F:SetMediaFormat(format)
    format = (format == "blp") and "blp" or "png"
    self.MediaFormat = format
    self.CircleTexture, self.PillTexture, self.SliderThumbTexture = nil, nil, nil
    return format
end

-- Resolves a bundled media file, or false when the library addon itself is not
-- installed (a host addon that only embeds this file falls back to mask drawing).
local function MediaPath(name)
    local fmt = F.MediaFormat == "blp" and "blp" or "png"
    local exists = false
    if C_AddOns and C_AddOns.DoesAddOnExist then
        exists = C_AddOns.DoesAddOnExist("QFXWidgets") and true or false
    elseif IsAddOnLoaded then
        exists = IsAddOnLoaded("QFXWidgets") ~= nil
    end
    if not exists then return false end
    return "Interface\\AddOns\\QFXWidgets\\Media\\" .. name .. "." .. fmt
end

-- filterMode (8.0.1+) drives the mip chain of the .blp media; on the PNG files
-- it is a no-op because they only have one level.
local function SetMediaTexture(tex, path)
    tex:SetTexture(path, "CLAMP", "CLAMP", "TRILINEAR")
    if tex.SetSnapToPixelGrid then tex:SetSnapToPixelGrid(false) end
    if tex.SetTexelSnappingBias then tex:SetTexelSnappingBias(0) end
    return tex
end

local function QfxCircle(parent, layer, sub, c)
    local t = parent:CreateTexture(nil, layer or "ARTWORK", nil, sub or 0)
    local circlePath = F.CircleTexture
    if circlePath == nil then
        circlePath = MediaPath("circle-crisp")
        F.CircleTexture = circlePath
    end
    if circlePath then
        SetMediaTexture(t, circlePath)
    else
        if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
        if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
        t:SetTexture(WHITE_TEXTURE)
    end
    -- A real MaskTexture remains the single-file/legacy fallback. The bundled
    -- circle is already anti-aliased, so masking it again with the portrait mask
    -- would multiply two different alpha edges into a rough outline.
    if not circlePath and parent.CreateMaskTexture and t.AddMaskTexture then
        local ok, mask = pcall(parent.CreateMaskTexture, parent)
        if ok and mask then
            mask:SetTexture(ROUND_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(t)
            if mask.SetSnapToPixelGrid then mask:SetSnapToPixelGrid(false) end
            if mask.SetTexelSnappingBias then mask:SetTexelSnappingBias(0) end
            if pcall(t.AddMaskTexture, t, mask) then t._mask = mask end
        end
    elseif not circlePath and t.SetMask then
        pcall(t.SetMask, t, ROUND_MASK) -- legacy client fallback
    end
    function t:_setColor(color)
        color = color or { 1, 1, 1, 1 }
        self:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
    end
    t:_setColor(c)
    return t
end

local function QfxSheen(parent, color)
    color = color or { 1, 1, 1, 0.06 }
    local t = QfxSurface(parent, "ARTWORK", 0, color)
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -2)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -2)
    t:SetHeight(math.max(1, math.floor((parent:GetHeight() or 20) * 0.34)))
    return t
end

local function QfxBorder(parent, level, c, alpha, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetAllPoints()
    f:SetFrameLevel((level or parent:GetFrameLevel()) + 5)
    local bs = size or 1
    -- EUI-style pixel sizing: express the border in PHYSICAL pixels at the
    -- frame's effective scale, so a 1px border never rounds away or gets shaved
    -- at fractional UI scales / positions.
    local function PixelSize()
        return SnapUI(f, bs)
    end
    local s = PixelSize()
    local edges = {}
    local function Edge()
        local t = f:CreateTexture(nil, "OVERLAY")
        if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
        if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
        edges[#edges + 1] = t
        return t
    end
    -- Horizontal strips cover the full top/bottom edges. Only the vertical
    -- strips inset by s, avoiding double-painted corners. Offsetting the
    -- horizontal strips too would shorten the visible outline by 2s.
    local top = Edge()
    top:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    top:SetHeight(s)
    local bottom = Edge()
    bottom:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    bottom:SetHeight(s)
    local left = Edge()
    left:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -s)
    left:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, s)
    left:SetWidth(s)
    local right = Edge()
    right:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, -s)
    right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, s)
    right:SetWidth(s)

    local function SetBorderColor(color, a)
        local aa = (color[4] or 1) * (a or 1)
        for i = 1, #edges do
            edges[i]:SetColorTexture(color[1], color[2], color[3], aa)
        end
    end
    if c then SetBorderColor(c, alpha) end
    f._setBorder = SetBorderColor
    return f
end

-- Drawing helpers for host windows (panels, nav buttons, custom chrome).
F.Surface = QfxSurface
F.Border = QfxBorder
F.SnapUI = SnapUI

-- W:SkinFrame(frame, opts): factory background + border on an existing frame
-- (replaces SetBackdrop for host windows). opts = { bg, border, alpha,
-- borderSize, inset }. Uses the active skin tokens when a color is omitted.
function F:SkinFrame(frame, opts)
    opts = opts or {}
    local S = self:Tokens()
    local tex = QfxSurface(frame, "BACKGROUND", 0, opts.bg or S.menuBg)
    if opts.inset then
        tex:SetPoint("TOPLEFT", frame, "TOPLEFT", opts.inset, -opts.inset)
        tex:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -opts.inset, opts.inset)
    else
        tex:SetAllPoints()
    end
    QfxBorder(frame, frame:GetFrameLevel(), opts.border or S.border, opts.alpha or 1, opts.borderSize or 1)
    frame._skinBg = tex
    return frame
end

-- QFX perimeter border: the logo's warm accent starts at the top-left, hands
-- off to the accent blue around the first third of the frame, and the warm
-- colour returns in the bottom-right corner while the other edges stay blue.
-- Drawn as ten thin gradient strips on the host's BORDER layer so the host's
-- own OVERLAY text and controls stay on top; the strips re-lay out from the
-- host's size, so a resized window keeps a correctly fitted perimeter.
--   W:Perimeter(frame, {
--       warmHoldRatio = 0.20,   -- warm run along the top-left before the hand-off
--       warmEndRatio  = 1 / 3,  -- point where the top/bottom hand-off finishes
--       cornerRatio   = 0.16,   -- warm return run in the bottom-right corner
--       opacity       = 1,      -- multiplies both edge colours (0.72 for inner panels)
--       thickness     = nil,    -- edge width in physical pixels (default: one pixel)
--       warm = { r, g, b, a }, accent = { r, g, b, a },
--   })
function F:Perimeter(frame, opts)
    if not frame then return end
    opts = opts or {}
    local S = self:Tokens()
    local sourceWarm = opts.warm or S.warmAccent or { 1.00, 0.55, 0.13, 1 }
    local sourceAccent = opts.accent or S.accent or { 0.00, 0.63, 1.00, 1 }
    local opacity = tonumber(opts.opacity) or 1
    local warm = { sourceWarm[1], sourceWarm[2], sourceWarm[3], (sourceWarm[4] or 1) * opacity }
    local accent = { sourceAccent[1], sourceAccent[2], sourceAccent[3], (sourceAccent[4] or 1) * opacity }
    local warmHoldRatio = tonumber(opts.warmHoldRatio) or 0.20
    local warmEndRatio = tonumber(opts.warmEndRatio) or (1 / 3)
    local cornerRatio = tonumber(opts.cornerRatio) or 0.16

    local strips = frame._qfxPerimeter
    if not strips then
        strips = {}
        frame._qfxPerimeter = strips
    end
    local function Ensure(index)
        local texture = strips[index]
        if not texture then
            texture = frame:CreateTexture(nil, "BORDER", nil, 7)
            texture:SetTexture(WHITE_TEXTURE)
            strips[index] = texture
        end
        texture:Show()
        return texture
    end
    local function Solid(texture, color)
        texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    end
    local function Gradient(texture, orientation, fromColor, toColor)
        texture:SetColorTexture(1, 1, 1, 1)
        local colorFactory = rawget(_G, "CreateColor")
        if colorFactory and texture.SetGradient then
            local ok = pcall(texture.SetGradient, texture, orientation,
                colorFactory(fromColor[1], fromColor[2], fromColor[3], fromColor[4] or 1),
                colorFactory(toColor[1], toColor[2], toColor[3], toColor[4] or 1))
            if ok then return end
        end
        if texture.SetGradientAlpha then
            local legacy = orientation == "Horizontal" and "HORIZONTAL" or "VERTICAL"
            local ok = pcall(texture.SetGradientAlpha, texture, legacy,
                fromColor[1], fromColor[2], fromColor[3], fromColor[4] or 1,
                toColor[1], toColor[2], toColor[3], toColor[4] or 1)
            if ok then return end
        end
        Solid(texture, toColor)
    end

    local topWarm, topBlend, topBlue = Ensure(1), Ensure(2), Ensure(3)
    local leftWarm = Ensure(4)
    local rightBlue, rightBlend = Ensure(5), Ensure(6)
    local bottomWarm, bottomLeft, bottomBlue, bottomRight = Ensure(7), Ensure(8), Ensure(9), Ensure(10)
    Solid(topWarm, warm)
    Gradient(topBlend, "Horizontal", warm, accent)
    Solid(topBlue, accent)
    Solid(leftWarm, warm)
    Solid(rightBlue, accent)
    -- vertical gradients run from the bottom colour to the top colour
    Gradient(rightBlend, "Vertical", warm, accent)
    Solid(bottomWarm, warm)
    Gradient(bottomLeft, "Horizontal", warm, accent)
    Solid(bottomBlue, accent)
    Gradient(bottomRight, "Horizontal", accent, warm)

    local function Layout()
        local width = math.max(1, frame:GetWidth() or 0)
        local height = math.max(1, frame:GetHeight() or 0)
        local thickness = tonumber(opts.thickness)
        if not thickness then
            local physicalH = 1080
            if GetPhysicalScreenSize then
                local ok, _, screenH = pcall(GetPhysicalScreenSize)
                if ok and type(screenH) == "number" and screenH > 0 then physicalH = screenH end
            end
            local scale = 1
            if frame.GetEffectiveScale then
                local ok, value = pcall(frame.GetEffectiveScale, frame)
                if ok and type(value) == "number" and value > 0 then scale = value end
            end
            thickness = (768 / physicalH) / scale
        end
        local px = math.max(0.5, thickness)
        local warmHoldW = width * warmHoldRatio
        local warmEndW = math.max(warmHoldW, width * warmEndRatio)
        local blendW = math.max(1, warmEndW - warmHoldW)

        topWarm:ClearAllPoints()
        topWarm:SetPoint("TOPLEFT", frame, "TOPLEFT", px, -px)
        topWarm:SetSize(warmHoldW, px)
        topBlend:ClearAllPoints()
        topBlend:SetPoint("LEFT", topWarm, "RIGHT", 0, 0)
        topBlend:SetSize(blendW, px)
        topBlue:ClearAllPoints()
        topBlue:SetPoint("LEFT", topBlend, "RIGHT", 0, 0)
        topBlue:SetPoint("RIGHT", frame, "RIGHT", -px, 0)
        topBlue:SetHeight(px)

        leftWarm:ClearAllPoints()
        leftWarm:SetPoint("TOPLEFT", frame, "TOPLEFT", px, -px)
        leftWarm:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", px, px)
        leftWarm:SetWidth(px)

        rightBlue:ClearAllPoints()
        rightBlue:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -px, -px)
        rightBlue:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -px, height * 0.25)
        rightBlue:SetWidth(px)
        rightBlend:ClearAllPoints()
        rightBlend:SetPoint("TOPRIGHT", rightBlue, "BOTTOMRIGHT", 0, 0)
        rightBlend:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -px, px)
        rightBlend:SetWidth(px)

        bottomWarm:ClearAllPoints()
        bottomWarm:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", px, px)
        bottomWarm:SetSize(warmHoldW, px)
        bottomLeft:ClearAllPoints()
        bottomLeft:SetPoint("LEFT", bottomWarm, "RIGHT", 0, 0)
        bottomLeft:SetSize(blendW, px)
        bottomRight:ClearAllPoints()
        bottomRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -px, px)
        bottomRight:SetSize(width * cornerRatio, px)
        bottomBlue:ClearAllPoints()
        bottomBlue:SetPoint("LEFT", bottomLeft, "RIGHT", 0, 0)
        bottomBlue:SetPoint("RIGHT", bottomRight, "LEFT", 0, 0)
        bottomBlue:SetHeight(px)
    end

    frame._qfxPerimeterLayout = Layout
    if not frame._qfxPerimeterHooked then
        frame._qfxPerimeterHooked = true
        frame:HookScript("OnSizeChanged", function()
            if frame._qfxPerimeterLayout then frame._qfxPerimeterLayout() end
        end)
        frame:HookScript("OnShow", function()
            if frame._qfxPerimeterLayout then frame._qfxPerimeterLayout() end
        end)
    end
    Layout()
    return frame
end

-- Unified brand art for every QFX addon. Set it once per session and every
-- W:Banner call inherits it, so hosts only pass the header height:
--   W:SetBrand{ logo = path, watermark = path, watermarkTint = {...},
--               watermarkFit = "right" | "width" }
-- The stock art ships in QFXWidgets\Media (the .blp twins) and is applied
-- below when that addon is installed.
-- The stock ratios are defaults: a host that never passes them still gets an
-- unsquashed square emblem and explicit watermark strip (16:1) even when the texture size
-- is not readable yet at layout time.
F.Brand = F.Brand or {}
if F.Brand.logoRatio == nil then F.Brand.logoRatio = 2 end
if F.Brand.watermarkRatio == nil then F.Brand.watermarkRatio = 16 end
if F.Brand.watermarkTint == nil then F.Brand.watermarkTint = { 1, 1, 1, 0.78 } end

function F:SetBrand(t)
    if type(t) ~= "table" then return self.Brand end
    for k, v in pairs(t) do self.Brand[k] = v end
    return self.Brand
end

-- Stock brand: resolved once, only when the library addon ships it.
local function StockBrand()
    if F._stockBrand ~= nil then return F._stockBrand end
    local exists = false
    if C_AddOns and C_AddOns.DoesAddOnExist then
        exists = C_AddOns.DoesAddOnExist("QFXWidgets") and true or false
    elseif IsAddOnLoaded then
        exists = IsAddOnLoaded("QFXWidgets") ~= nil
    end
    F._stockBrand = exists and "Interface\\AddOns\\QFXWidgets\\Media\\" or false
    return F._stockBrand
end

-- Brand banner for a host window header: an addon logo on the left and an
-- optional watermark on the right, both drawn on the HOST frame's own layers so
-- they interleave with the host's art instead of covering its labels:
--   BACKGROUND sub 2 -> watermark (behind every label and control)
--   ARTWORK  sub 1   -> logo + glow (still below the host's OVERLAY text/buttons)
-- Everything re-lays out from the host's size, so a resized window keeps the
-- banner fitted to the header area.
--   local banner = W:Banner(frame, {
--       height = 72,                        -- the header area height
--       logo = path, logoSize = 34, logoX = 24, logoY = 18,   -- defaults: W.Brand
--       watermark = path, watermarkFit = "width",   -- "right" (default) or "width"
--       watermarkHeight = 56, watermarkRatio = 3.4, -- width / height; measured if omitted
--       watermarkX = 14, watermarkY = 6,
--       watermarkTint = { r, g, b, a },     -- stock art: white at 0.78 alpha
--       watermarkFade = true,
--       glow = path, glowSize = 20, glowX = 0, glowY = 0, glowTint, glowBlend,
--   })
--   banner.textLeft -> safe x for the host title (right of the logo)
function F:Banner(parent, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local brand = self.Brand or {}
    -- resolve each layer: caller -> W:SetBrand -> stock art; an explicit false
    -- means "do not draw this layer" while the file stays shipped in Media
    local function Path(kind)
        local v = opts[kind]
        if v == nil then v = brand[kind] end
        if v == nil then
            local stock = StockBrand()
            if stock then
                -- the .blp twins carry a mip chain (crisp when minified); the
                -- PNG build sources live in tools/brand-source, outside Media
                v = kind == "logo" and (stock .. "brand-extension-emblem.blp") or (stock .. "brand-watermark-v3.blp")
            end
        end
        return (v ~= false) and v or nil
    end
    opts.logo, opts.watermark = Path("logo"), Path("watermark")
    if opts.logoRatio == nil then opts.logoRatio = brand.logoRatio end
    if opts.watermarkRatio == nil then opts.watermarkRatio = brand.watermarkRatio end
    if opts.watermarkFit == nil then opts.watermarkFit = brand.watermarkFit or "width" end
    opts.watermarkTint = opts.watermarkTint or brand.watermarkTint
    opts.glow = opts.glow or brand.glow

    local holder = { textLeft = 0 }
    -- .blp brand art carries a baked mip chain: sample it with TRILINEAR like
    -- the rounded-control media, so a banner minified to the header height
    -- stays crisp instead of aliasing (PNG/TGA have no mip chain and keep the
    -- default sampling).
    local function BrandTexture(layer, sub, path)
        local tex = NoSnap(parent:CreateTexture(nil, layer, nil, sub))
        if type(path) == "string" and path:lower():match("%.blp$") then
            tex:SetTexture(path, "CLAMP", "CLAMP", "TRILINEAR")
        else
            tex:SetTexture(path)
        end
        return tex
    end
    local function Num(v, fallback)
        v = tonumber(v)
        return v or fallback
    end
    local function Size()
        local w = (parent.GetWidth and parent:GetWidth()) or 0
        local h = (tonumber(opts.height)) or ((parent.GetHeight and parent:GetHeight()) or 0)
        if h <= 0 then h = 72 end
        if w <= 0 then w = 600 end
        return w, h
    end

    local logoInset = Num(opts.logoX, 22)
    local logoY = Num(opts.logoY, 6)
    local logoSize = tonumber(opts.logoSize)

    if opts.logo then
        local tex = BrandTexture("ARTWORK", 1, opts.logo)
        holder.logo = tex
        holder._logoRatio = opts.logoRatio or brand.logoRatio
    else
        holder.textLeft = logoInset
    end

    local function WatermarkTint()
        local c = opts.watermarkTint or S.watermarkTint
        if not c then
            local a = S.accent or S.sectionText
            c = { a[1], a[2], a[3], 0.22 }
        end
        return c
    end
    local function ApplyFade(tex)
        -- a designed full-width strip already carries its own fade, so the extra
        -- gradient is only for standalone right-hand marks
        local want = opts.watermarkFade
        if want == nil then want = opts.watermarkFit ~= "width" end
        if not want then return end
        if not (CreateColor and tex.SetGradient) then return end
        -- fade towards the title text; the gradient filters the vertex colour,
        -- alpha included
        pcall(tex.SetGradient, tex, "HORIZONTAL",
            CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 1))
    end

    if opts.watermark then
        local tex = BrandTexture("BACKGROUND", 2, opts.watermark)
        local c = WatermarkTint()
        if tex.SetVertexColor then tex:SetVertexColor(c[1], c[2], c[3], c[4] or 1) end
        ApplyFade(tex)
        holder.watermark = tex
        holder._watermarkPath = opts.watermark
        holder._ratio = opts.watermarkRatio
    end

    if opts.glow then
        local tex = BrandTexture("ARTWORK", 0, opts.glow)
        local g = Num(opts.glowSize, 20)
        tex:SetSize(SnapUI(parent, g), SnapUI(parent, g))
        if tex.SetBlendMode and opts.glowBlend then tex:SetBlendMode(opts.glowBlend) end
        local gc = opts.glowTint or S.warmAccentHi or S.warmAccent
        if gc and tex.SetVertexColor then tex:SetVertexColor(gc[1], gc[2], gc[3], gc[4] or 1) end
        holder.glow = tex
    end

    local function Layout()
        local w, h = Size()
        if holder.logo then
            -- the logo fills the header height unless a fixed logoSize is given.
            -- WoW textures cannot report their pixel size (GetSize returns the
            -- layout size, 0 before the first layout), so the aspect always
            -- comes from the explicit / brand ratio; the stock emblem is 2:1, and
            -- a host with different art must pass logoRatio.
            local ratio = tonumber(holder._logoRatio) or tonumber(brand.logoRatio) or 2
            if ratio <= 0 then ratio = 2 end
            local lh = logoSize or math.max(12, h - logoY * 2)
            local lw = lh * ratio
            holder.logo:SetSize(SnapUI(parent, lw), SnapUI(parent, lh))
            holder.logo:ClearAllPoints()
            holder.logo:SetPoint("TOPLEFT", parent, "TOPLEFT",
                SnapUI(parent, logoInset), -SnapUI(parent, logoY))
            holder.logoWidth = lw
            holder.textLeft = logoInset + lw + Num(opts.logoGap, 10)
        end
        if holder.watermark then
            -- same rule as the logo: the strip ratio is declared, never read
            -- from the texture; the stock strip is 16:1
            local ratio = tonumber(holder._ratio) or tonumber(brand.watermarkRatio) or 16
            if ratio <= 0 then ratio = 16 end
            local insetX = Num(opts.watermarkX, 14)
            local insetY = Num(opts.watermarkY, 6)
            local mh, mw
            if opts.watermarkFit == "width" then
                -- banner strip baked into one wide image: fill the header width
                -- and let the height follow the art, but never squash it -- if the
                -- art is taller than the header it shrinks and stays right-anchored
                local availW = math.max(8, w - insetX * 2)
                local availH = math.max(8, h - insetY * 2)
                mw = availW
                mh = (ratio > 0) and (mw / ratio) or availH
                local anchor = "TOPLEFT"
                if mh > availH then
                    mh = availH
                    mw = math.max(8, mh * ratio)
                    anchor = "TOPRIGHT"
                end
                holder.watermark:SetSize(SnapUI(parent, mw), SnapUI(parent, mh))
                holder.watermark:ClearAllPoints()
                holder.watermark:SetPoint(anchor, parent, anchor,
                    anchor == "TOPRIGHT" and -SnapUI(parent, insetX) or SnapUI(parent, insetX),
                    -SnapUI(parent, insetY))
            else
                mh = Num(opts.watermarkHeight, h - insetY * 2)
                mh = math.max(8, math.min(mh, math.max(8, h - insetY * 2)))
                mw = math.max(8, mh * ratio)
                holder.watermark:SetSize(SnapUI(parent, mw), SnapUI(parent, mh))
                holder.watermark:ClearAllPoints()
                holder.watermark:SetPoint("TOPRIGHT", parent, "TOPRIGHT",
                    -SnapUI(parent, insetX), -SnapUI(parent, insetY))
            end
            if holder.glow then
                holder.glow:ClearAllPoints()
                holder.glow:SetPoint("TOPRIGHT", holder.watermark, "TOPRIGHT",
                    SnapUI(parent, Num(opts.glowX, 6)), -SnapUI(parent, Num(opts.glowY, 0)))
            end
        end
        return w, h
    end

    function holder:Layout() return Layout() end
    function holder:SetWatermarkTint(color, fade)
        if not holder.watermark or not color then return end
        opts.watermarkTint = color
        if holder.watermark.SetVertexColor then
            holder.watermark:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
        end
        if fade ~= nil then opts.watermarkFade = fade and true or false end
        ApplyFade(holder.watermark)
    end
    function holder:SetWatermark(path, ratio)
        if not holder.watermark then return end
        opts.watermark, holder._ratio = path, ratio
        holder.watermark:SetTexture(path)
        Layout()
    end

    -- keep the banner fitted when the host resizes, without clobbering a script
    -- the host may already own
    local prev = parent.GetScript and parent:GetScript("OnSizeChanged")
    parent:SetScript("OnSizeChanged", function(self2)
        if prev then prev(self2) end
        Layout()
    end)

    Layout()
    -- the art ratio is only known once the texture loads, so re-fit once more
    -- after the first frame instead of showing a wrongly shaped logo
    if C_Timer and C_Timer.After then C_Timer.After(0, Layout) end
    holder.frame = parent
    return holder
end

local function IsDescendantOf(frame, ancestor)
    local f, guard = frame, 0
    while f and guard < 24 do
        if f == ancestor then return true end
        f = f:GetParent()
        guard = guard + 1
    end
    return false
end

-- Shared custom menu. spec = { items (table|function), width, maxH, maxVisible,
-- multi, dynamic, checked(key), disabled(key), disabledTooltip(key),
-- labelFor(key), onPick(key), refresh() }. Long item lists scroll (self-drawn
-- bar, wheel + thumb drag); items may disable themselves (item.disabled /
-- item.disabledTooltip); the menu matches the dropdown's scale and sits on the
-- FULLSCREEN_DIALOG strata. Returns menu, refresh. dd._invalidateMenu()
-- rebuilds the rows from spec.items (use it with spec.dynamic for lists that
-- change at runtime).
-- Shared custom menu. spec = { items (table|function), width, maxH, maxVisible,
-- multi, dynamic, checked(key), disabled(key), disabledTooltip(key),
-- labelFor(key), onPick(key), refresh() }. Lists that fit render directly in
-- the menu (like the pre-scroll version); long lists switch to a ScrollFrame
-- with a self-drawn bar, wheel and thumb drag. Items may disable themselves
-- (item.disabled / item.disabledTooltip). Returns menu, refresh.
-- dd._invalidateMenu() rebuilds the rows from spec.items.
local function MakeQfxMenu(dd, S, spec)
    local rowH = S.menuRowH
    local pad = 4
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    if menu.SetFrameLevel then menu:SetFrameLevel(200) end
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:Hide()

    local bg = QfxSurface(menu, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(menu, menu:GetFrameLevel(), S.border, 1, 1)

    local rows = {}
    local maxH = spec.maxH or ((spec.maxVisible or 14) * rowH + pad * 2)
    local contentH, viewH, offset = 0, 0, 0
    local scrollMode = false
    local viewport, content, bar, thumb

    local function Items()
        local it = spec.items
        if type(it) == "function" then it = it() end
        return it or {}
    end
    local function ItemDisabled(item, key)
        if EvalFlag(spec.disabled, key) then return true end
        local d = item.disabled
        return EvalFlag(d, key)
    end
    local function ItemDisabledTip(item, key)
        local t = item.disabledTooltip
        if type(t) == "function" then return t(key) end
        return t or spec.disabledTooltip
    end

    local hostRefresh = spec.refresh -- caller hook, kept separate from row repaint
    local RefreshRows
    local Layout -- forward declaration (used by the scrollbar thumb below)

    -- long lists get a viewport + self-drawn scrollbar (created on first need)
    local function EnsureScrollUi()
        if viewport then return end
        viewport = CreateFrame("ScrollFrame", nil, menu)
        viewport:SetPoint("TOPLEFT", menu, "TOPLEFT", pad, -pad)
        viewport:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -(pad + 6), pad)
        content = CreateFrame("Frame", nil, viewport)
        if viewport.SetScrollChild then viewport:SetScrollChild(content) end
        bar = CreateFrame("Frame", nil, menu)
        bar:SetWidth(4)
        bar:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -pad, -pad)
        bar:SetPoint("BOTTOMRIGHT", menu, "BOTTOMRIGHT", -pad, pad)
        local barBg = QfxSurface(bar, "BACKGROUND", 0, S.controlBg)
        barBg:SetAllPoints()
        bar:Hide()
        thumb = CreateFrame("Button", nil, bar)
        thumb:SetWidth(4)
        local thumbTex = QfxSurface(thumb, "ARTWORK", 0, S.border)
        thumbTex:SetAllPoints()
        thumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(S.borderHi[1], S.borderHi[2], S.borderHi[3], S.borderHi[4] or 1) end)
        thumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(S.border[1], S.border[2], S.border[3], S.border[4] or 1) end)
        local dragging, dragY, dragOffset
        local UpdateThumb
        local function StopDrag()
            dragging = false
            thumb:SetScript("OnUpdate", nil)
        end
        thumb:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" or contentH <= viewH then return end
            dragging, dragY, dragOffset = true, select(2, GetCursorPosition()), offset
            thumb:SetScript("OnUpdate", UpdateThumb)
        end)
        UpdateThumb = function()
            if not dragging then return end
            if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then StopDrag() return end
            local _, cy = GetCursorPosition()
            local scale = thumb:GetEffectiveScale() or 1
            local travel = viewH - (thumb:GetHeight() or 0)
            if travel <= 0 then return end
            local maxOff = math.max(0, contentH - viewH)
            offset = floor(math.max(0, math.min(maxOff, dragOffset + ((dragY - cy) / scale) * (maxOff / travel))) + 0.5)
            if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
            Layout()
        end
        thumb:SetScript("OnMouseUp", StopDrag)
        thumb:SetScript("OnHide", StopDrag)
    end

    function Layout()
        local width = spec.width or 210
        if bar then bar:SetShown(scrollMode) end
        local h = (contentH > 0 and contentH or rowH) + pad * 2
        if h > maxH then h = maxH end
        menu:SetSize(width, h)
        viewH = h - pad * 2
        local maxOff = math.max(0, contentH - viewH)
        if offset > maxOff then offset = maxOff end
        if offset < 0 then offset = 0 end
        if scrollMode and content then
            content:SetSize(math.max(1, width - pad * 2 - 6), math.max(1, contentH))
            if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
        end
        local container = scrollMode and content or menu
        local inset = scrollMode and 0 or pad
        for i = 1, #rows do
            local r = rows[i]
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", container, "TOPLEFT", inset, -(i - 1) * rowH - inset)
            r:SetPoint("TOPRIGHT", container, "TOPRIGHT", -inset, -(i - 1) * rowH - inset)
        end
        if scrollMode and thumb then
            local thumbH = math.max(20, viewH * (viewH / contentH))
            thumb:SetHeight(math.min(viewH, thumbH))
            local travel = math.max(0, viewH - thumb:GetHeight())
            local ratio = maxOff > 0 and (offset / maxOff) or 0
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -travel * ratio)
        end
    end

    local function Build()
        local items = Items()
        scrollMode = (#items * rowH + pad * 2) > maxH
        if scrollMode then EnsureScrollUi() end
        local container = scrollMode and content or menu
        for i = #items + 1, #rows do
            rows[i]:Hide()
            rows[i] = nil
        end
        for i = 1, #items do
            local item = items[i]
            local row = rows[i]
            if not row then
                row = CreateFrame("Button", nil, container)
                row:SetHeight(rowH)
                local hl = row:CreateTexture(nil, "HIGHLIGHT")
                hl:SetAllPoints()
                hl:SetColorTexture(S.rowHover[1], S.rowHover[2], S.rowHover[3], S.rowHover[4])
                local check = QfxSurface(row, "ARTWORK", 0, S.accent)
                check:SetSize(10, 10)
                check:SetPoint("LEFT", row, "LEFT", 8, 0)
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(14, 14)
                icon:SetPoint("LEFT", check, "RIGHT", 6, 0)
                icon:Hide()
                local lbl = Font(row, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
                lbl:SetPoint("LEFT", check, "RIGHT", 8, 0)
                lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                lbl:SetJustifyH("LEFT")
                if lbl.SetWordWrap then lbl:SetWordWrap(false) end
                if lbl.SetMaxLines then lbl:SetMaxLines(1) end
                row._hl, row._check, row._label = hl, check, lbl
                row._icon = icon
                row:SetScript("OnClick", function(self2)
                    if self2._disabledNow then return end
                    if spec.onPick then spec.onPick(self2._key) end
                    if not spec.multi then menu:Hide() end
                    RefreshRows()
                end)
                row:SetScript("OnEnter", function(self2)
                    local it = self2._item
                    if not it then return end
                    local tip = ResolveTooltipText(it.tooltip)
                    if self2._disabledNow then tip = ResolveTooltipText(ItemDisabledTip(it, self2._key)) or tip end
                    if tip then
                        GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                        GameTooltip:SetText(it.label or tostring(self2._key), 1, 1, 1)
                        GameTooltip:AddLine(tip, 1, 1, 1, true)
                        GameTooltip:Show()
                    end
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)
                rows[i] = row
            elseif row:GetParent() ~= container then
                row:SetParent(container)
            end
            row._key, row._item = item.key, item
            row._label:SetText(item.label or tostring(item.key))
            row:Show()
        end
        contentH = #items * rowH
        offset = 0
        Layout()
    end

    menu:SetScript("OnMouseWheel", function(_, delta)
        if not scrollMode then return end
        local maxOff = math.max(0, contentH - viewH)
        if maxOff <= 0 then return end
        offset = math.max(0, math.min(maxOff, offset - delta * 24))
        if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
        Layout()
    end)

    RefreshRows = function()
        for i = 1, #rows do
            local r = rows[i]
            local item = r._item
            if item then
                local dis = ItemDisabled(item, r._key)
                r._disabledNow = dis
                r:SetAlpha(dis and 0.4 or 1)
                if spec.checked then
                    r._check:SetShown(spec.checked(r._key) and true or false)
                else
                    r._check:Hide()
                end
                if spec.labelFor then r._label:SetText(spec.labelFor(r._key) or "") end
            end
        end
        if hostRefresh then hostRefresh() end
    end

    Build()
    RefreshRows()

    local function Close()
        if menu:IsShown() then menu:Hide() end
    end
    -- Outside-click catcher: a full-screen frame one level BELOW the menu.
    -- Deterministic (no GetMouseFocus guessing) and it cannot steal the menu's
    -- own clicks because the menu sits at a higher frame level.
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints()
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    if catcher.SetFrameLevel then catcher:SetFrameLevel(190) end
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function() menu:Hide() end)
    menu:HookScript("OnHide", function() catcher:Hide() end)

    local function Open()
        if spec.dynamic then Build() end
        RefreshRows()
        Layout()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
        if menu.SetScale and dd.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
            local ds, us = dd:GetEffectiveScale(), UIParent:GetEffectiveScale()
            if ds and us and us > 0 then menu:SetScale(ds / us) end
        end
        if F._openMenu and F._openMenu ~= menu then F._openMenu:Hide() end
        F._openMenu = menu
        catcher:Show()
        menu:Show()
    end

    menu._rows = rows
    menu._bar, menu._thumb, menu._viewport, menu._content = bar, thumb, viewport, content
    menu._catcher = catcher
    menu:HookScript("OnHide", function(self2)
        if F._openMenu == self2 then F._openMenu = nil end
    end)
    dd:HookScript("OnHide", Close)
    local host = dd:GetParent()
    if host and host.HookScript then host:HookScript("OnHide", Close) end
    dd._menu = menu
    dd._openMenu = Open
    dd._closeMenu = Close
    dd._invalidateMenu = Build
    dd._refreshMenu = RefreshRows
    return menu, RefreshRows
end

-- Public custom menu (for pickers the factory does not cover): F:MakeMenu(anchor,
-- spec) -> menu, refresh. spec = { items (table|function), width, maxH,
-- maxVisible, multi, dynamic, checked(key), disabled(key), disabledTooltip(key),
-- labelFor(key), onPick(key), refresh() }. anchor._invalidateMenu() rebuilds.
function F:MakeMenu(anchor, spec)
    return MakeQfxMenu(anchor, self:Tokens(), spec or {})
end

-- White V fallback for dropdowns. A font glyph remains cleaner than a tiny
-- staircase of solid pixels at the compact EUI row height.
local function MakeChevron(parent, w, color)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(14, 14)
    local glyph = Font(frame, math.max(10, math.floor(w or 11)), color[1], color[2], color[3], color[4] or 1)
    glyph:SetPoint("CENTER", frame, "CENTER", 0, 1)
    glyph:SetText("V")
    function frame:_setColor(c)
        glyph:SetTextColor(c[1], c[2], c[3], c[4] or 1)
    end
    frame._glyph = glyph
    return frame
end

-- Bundled white Lucide chevron on a compact square canvas. The BLP mip chain
-- keeps the stroke smooth at fractional UI scales. An embedded host without
-- media, or W:SetArrowTexture(false), retains the glyph fallback.
-- Returns (arrowObject, labelRightInset).
local function MakeDropdownArrow(parent, S)
    local path = F.ArrowTexture
    if path == nil then
        path = MediaPath("dropdown-chevron")
    end
    local tint = S.arrow or S.text
    if path then
        local tex = parent:CreateTexture(nil, "ARTWORK")
        SetMediaTexture(tex, path)
        tex:SetSize(20, 20)
        tex:SetPoint("RIGHT", parent, "RIGHT", -3, 0)
        tex:SetVertexColor(tint[1], tint[2], tint[3], tint[4] or 1)
        function tex:_setColor(c)
            self:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
        end
        return tex, 26
    end
    local chev = MakeChevron(parent, 12, tint)
    chev:SetPoint("RIGHT", parent, "RIGHT", -5, 0)
    return chev, 22
end

function F:SetArrowTexture(path)
    self.ArrowTexture = path == false and false or path
    return self.ArrowTexture
end

function F:SetCircleTexture(path)
    self.CircleTexture = path == false and false or path
    return self.CircleTexture
end

function F:SetPillTexture(path)
    self.PillTexture = path == false and false or path
    return self.PillTexture
end

function F:SetSliderThumbTexture(path)
    self.SliderThumbTexture = path == false and false or path
    return self.SliderThumbTexture
end

local function MakeQfxDropdownButton(region, S, width)
    local btn = CreateFrame("Button", nil, region)
    btn:SetSize(width, S.rowControlH)
    btn:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.border, 1, 1)
    local sheen = QfxSheen(btn, S.buttonSheen)
    local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    local arrow, labelInset = MakeDropdownArrow(btn, S)
    lbl:SetPoint("LEFT", btn, "LEFT", 8, 0)
    lbl:SetPoint("RIGHT", btn, "RIGHT", -(labelInset or 20), 0)
    lbl:SetJustifyH("LEFT")
    if lbl.SetWordWrap then lbl:SetWordWrap(false) end
    if lbl.SetMaxLines then lbl:SetMaxLines(1) end
    btn._bg, btn._label, btn._brd, btn._chevron = bg, lbl, brd, arrow
    btn._sheen = sheen
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4])
        brd._setBorder(S.borderHi or S.border)
        if arrow._setColor then arrow:_setColor(S.arrowHi or S.warmAccentHi or S.text) end
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4])
        brd._setBorder(S.border)
        if arrow._setColor then arrow:_setColor(S.arrow or S.text) end
    end)
    return btn
end

function F:LayoutDropdownButton(parent, width)
    return MakeQfxDropdownButton(parent, self:Tokens(), width or 180)
end

-- EUI-style rectangular switch. Solid textures keep both endpoints on the
-- same vertical bounds; the square thumb has equal top and bottom insets.
local function QfxToggle(region, frame, cfg)
    local S = F.Skin
    local btn = CreateFrame("Button", nil, region)
    local TH = SnapUI(region, S.toggleH)
    -- Derive width from the snapped height to preserve the 2:1 proportions.
    local TW = SnapUI(region, TH * S.toggleW / S.toggleH)
    btn:SetSize(TW, TH)
    btn:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local track = NoSnap(QfxSurface(btn, "BACKGROUND", 0, S.trackBg))
    track:SetAllPoints()
    -- Truncating a 2-unit inset at a fractional scale can leave only 1 screen
    -- pixel, making the white thumb visually swallow the track at that end.
    local onePixel = OnePixelUI(btn)
    local padPixels = math.max(2, math.floor((S.togglePad or 2) / onePixel + 0.5))
    local pad = padPixels * onePixel
    local knob = NoSnap(QfxSurface(btn, "ARTWORK", 1, S.toggleKnobOff or S.knob))
    local knobSize = math.max(SnapUI(btn, 6), TH - pad * 2)
    local offT = S.toggleTrackOff or S.trackBg
    local onT = S.toggleTrackOn or S.accent
    local offK = S.toggleKnobOff or S.knob
    local onK = S.toggleKnobOn or S.knob
    local hovered = false
    local function Lerp(a, b, p) return a + (b - a) * p end
    local function Apply(p)
        local x = Lerp(pad, TW - pad - knobSize, p)
        knob:ClearAllPoints()
        knob:SetPoint("TOPLEFT", btn, "TOPLEFT", x, -pad)
        knob:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", x, pad)
        knob:SetWidth(knobSize)
        local lift = hovered and 0.055 or 0
        track:SetColorTexture(
            math.min(1, Lerp(offT[1], onT[1], p) + lift),
            math.min(1, Lerp(offT[2], onT[2], p) + lift),
            math.min(1, Lerp(offT[3], onT[3], p) + lift),
            Lerp(offT[4] or 1, onT[4] or 1, p))
        knob:SetColorTexture(
            Lerp(offK[1], onK[1], p), Lerp(offK[2], onK[2], p),
            Lerp(offK[3], onK[3], p), Lerp(offK[4] or 1, onK[4] or 1, p))
    end
    local progress = (cfg.getValue and cfg.getValue()) and 1 or 0
    local target = progress
    local function Snap()
        local on = cfg.getValue and cfg.getValue() and true or false
        if btn._state == on then return end
        btn._state = on
        progress, target = on and 1 or 0, on and 1 or 0
        btn:SetScript("OnUpdate", nil)
        Apply(progress)
    end
    Snap()
    btn._qfx, btn._track, btn._knob = "toggle", track, knob
    btn._outline = track
    btn:SetScript("OnEnter", function()
        hovered = true
        Apply(progress)
    end)
    btn:SetScript("OnLeave", function()
        hovered = false
        Apply(progress)
    end)
    btn:SetScript("OnClick", function()
        local on = not (cfg.getValue and cfg.getValue())
        if cfg.setValue then cfg.setValue(on and true or false) end
        btn._state = on
        target = on and 1 or 0
        if S.toggleAnim == false then
            progress = target
            Apply(progress)
            return
        end
        local dur = S.toggleAnimDur or 0.075
        btn._acc = 0
        btn:SetScript("OnUpdate", function(self2, elapsed)
            self2._acc = (self2._acc or 0) + elapsed
            local p = math.min(1, self2._acc / dur)
            progress = (target == 1) and p or (1 - p)
            Apply(progress)
            if p >= 1 then self2:SetScript("OnUpdate", nil) end
        end)
    end)
    AttachTooltip(btn, cfg.text, cfg.tooltip)
    region._control = btn
    ApplyDisabled(region, btn, cfg)
    F:RegisterRefresh(Snap)
    return btn
end

local function QfxSlider(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local minV = tonumber(cfg.min) or 0
    local maxV = tonumber(cfg.max) or 100
    local step = tonumber(cfg.step) or 1
    local trackW = SnapUI(region, cfg.trackWidth or T.trackWidth)
    local suffix = cfg.valueSuffix or ""
    local withSteppers = cfg.steppers == true
    local stepperW = withSteppers and (tonumber(cfg.stepperWidth) or S.stepperW or 13) or 0

    local box = CreateFrame("EditBox", nil, region)
    box:SetSize(S.valueBoxW, S.rowControlH)
    box:SetPoint("RIGHT", region, "RIGHT", -(T.rightPad + (stepperW > 0 and (stepperW + (S.stepperGap or 2)) or 0)), 0)
    box:SetAutoFocus(false)
    local boxBg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
    boxBg:SetAllPoints()
    local boxBrd = QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
    box:SetFont(T.font, S.textSize, "")
    box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    box:SetJustifyH("CENTER")
    box:SetTextInsets(2, 2, 0, 0)
    box._qfx = "valueBox"

    local slider = CreateFrame("Slider", nil, region)
    local labelsBelow = cfg.labelsBelow == true
    slider:SetOrientation("HORIZONTAL")
    slider:SetSize(trackW, SnapUI(region, S.rowControlH))
    if labelsBelow then
        slider:SetPoint("RIGHT", box, "LEFT", -8, 0)
    end
    slider:SetMinMaxValues(minV, maxV)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end

    -- EUI deliberately uses pixel-snapped rectangular rails here. At only four
    -- pixels high, a masked/pill end cap is less precise than a solid strip.
    local track = QfxSurface(slider, "BACKGROUND", 0, S.trackBg)
    track:SetHeight(SnapUI(slider, S.trackH))
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetPoint("CENTER", slider, "CENTER", 0, 0)
    local fill = QfxSurface(slider, "ARTWORK", 0, S.trackFill)
    fill:SetHeight(SnapUI(slider, S.trackH))
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)

    local thumbPath = F.SliderThumbTexture
    if thumbPath == nil then
        thumbPath = MediaPath("slider-thumb-crisp")
        F.SliderThumbTexture = thumbPath
    end
    local thumb
    if thumbPath then
        thumb = slider:CreateTexture(nil, "ARTWORK", nil, 2)
        SetMediaTexture(thumb, thumbPath)
        -- the shipped thumb art is a neutral grey disc; it stays untinted unless
        -- a host asks for a colour through S.thumb
        local tc = S.thumb
        if tc and thumb.SetVertexColor then
            thumb:SetVertexColor(tc[1], tc[2], tc[3], tc[4] or 1)
        end
    else
        thumb = QfxCircle(slider, "ARTWORK", 2, S.knob)
    end
    local thumbW, thumbH = SnapUI(slider, S.thumbW), SnapUI(slider, S.thumbH)
    thumb:SetSize(thumbW, thumbH)
    slider:SetThumbTexture(thumb)
    local thumbCore
    if not thumbPath then
        thumbCore = QfxCircle(slider, "OVERLAY", 2, S.knobInner or S.trackFill)
        thumbCore:SetSize(math.max(SnapUI(slider, 4), thumbW - SnapUI(slider, 4)),
            math.max(SnapUI(slider, 4), thumbH - SnapUI(slider, 4)))
        thumbCore:SetPoint("CENTER", thumb, "CENTER", 0, 0)
    end
    slider._track, slider._fill = track, fill
    slider._thumb, slider._thumbCore = thumb, thumbCore

    -- min/max sit beside the track and share its vertical centre; the old
    -- stacked-below layout is still available with cfg.labelsBelow = true
    local low = Font(region, 10, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
    local high = Font(region, 10, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
    low:SetText(tostring(minV))
    high:SetText(tostring(maxV))
    local gap = 5
    if labelsBelow then
        low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
        high:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    else
        low:SetPoint("RIGHT", slider, "LEFT", -gap, 0)
        high:SetPoint("LEFT", slider, "RIGHT", gap, 0)
        local highW = (high.GetStringWidth and high:GetStringWidth()) or 8
        -- shift the rail left so the max number stays inside the cluster
        slider:SetPoint("RIGHT", box, "LEFT", -(8 + highW + gap), 0)
    end

    local function Format(v)
        if IsSecret(v) then return "" end
        if step % 1 ~= 0 then
            local decimals = (step < 0.1) and 2 or 1
            return string.format("%." .. decimals .. "f", v) .. suffix
        end
        return tostring(v) .. suffix
    end
    -- snap anchored at min (a step like 2 with min 1 must still reach 1, 3, 5...)
    local function Snap(v)
        v = tonumber(v) or minV
        if step > 0 then v = minV + floor((v - minV) / step + 0.5) * step end
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end
    local function Read()
        local v = cfg.getValue and cfg.getValue() or minV
        v = tonumber(v) or minV
        if v < minV then v = minV elseif v > maxV then v = maxV end
        return v
    end
    local function Render(v)
        local ratio = (maxV > minV) and ((v - minV) / (maxV - minV)) or 0
        if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
        -- whole-pixel fill width (EUI does the same): a fractional width makes
        -- the fill edge shimmer while dragging
        fill:SetWidth(math.max(SnapUI(slider, 1), SnapUI(slider, trackW * ratio)))
        if not box:HasFocus() then box:SetText(Format(v)) end
    end
    local function Push(v)
        if cfg.setValue then cfg.setValue(v) end
    end

    -- +/- steppers: stacked flush right of the value box (the pair is exactly
    -- as tall as the box); nudge by one step, clamped, dimmed at both ends
    local upBtn, downBtn
    local function SyncSteppers(v)
        if upBtn then upBtn._dim:SetTextColor((v >= maxV) and S.textMuted[1] or S.text[1], (v >= maxV) and S.textMuted[2] or S.text[2], (v >= maxV) and S.textMuted[3] or S.text[3], 1) end
        if downBtn then downBtn._dim:SetTextColor((v <= minV) and S.textMuted[1] or S.text[1], (v <= minV) and S.textMuted[2] or S.text[2], (v <= minV) and S.textMuted[3] or S.text[3], 1) end
    end
    if stepperW > 0 then
        local btnH = floor(S.rowControlH / 2)
        local function MakeStepper(glyph, dir)
            local b = CreateFrame("Button", nil, region)
            b:SetSize(stepperW, btnH)
            -- the +/- pair covers exactly the value box's height, flush right
            if dir > 0 then
                b:SetPoint("TOPLEFT", box, "TOPRIGHT", 0, 0)
            else
                b:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 0, 0)
            end
            -- borderless (the buttons are tiny; an outline ate the glyph)
            local bg = QfxSurface(b, "BACKGROUND", 0, S.controlBg)
            bg:SetAllPoints()
            local fs = Font(b, math.max(12, S.textSize), S.text[1], S.text[2], S.text[3], S.text[4])
            fs:SetPoint("CENTER", b, "CENTER", 0, 0)
            fs:SetText(glyph)
            b._step = dir
            b._dim = fs
            local function SetBg(c)
                bg:SetColorTexture(c[1], c[2], c[3], c[4] or 1)
            end
            b:SetScript("OnEnter", function()
                if not ConfigDisabled(cfg) then SetBg(S.controlBgHi) end
            end)
            b:SetScript("OnLeave", function() SetBg(S.controlBg) end)
            b:SetScript("OnMouseDown", function() if not ConfigDisabled(cfg) then SetBg(S.controlBgHi) end end)
            b:SetScript("OnMouseUp", function() SetBg(S.controlBg) end)
            b:SetScript("OnClick", function()
                if ConfigDisabled(cfg) then return end
                local v = Snap(Read() + dir * step)
                slider._updating = true
                slider:SetValue(v)
                slider._updating = nil
                Render(v)
                SyncSteppers(v)
                Push(v)
            end)
            return b
        end
        upBtn = MakeStepper("+", 1)
        downBtn = MakeStepper("-", -1)
        region._dimTargets = { upBtn, downBtn }
    end
    slider._updating = true
    slider:SetValue(Read())
    slider._updating = nil
    Render(Read())
    SyncSteppers(Read())

    -- Drag handling (EUI-style): while dragging, only the visual follows; on
    -- release the value is committed once and the page refreshes once, so the
    -- host never gets a sweep per drag tick.
    local pageOwner = F._refreshScope
    local function StopDrag(commit)
        if not slider._dragging then return end
        slider._dragging = nil
        slider:SetScript("OnUpdate", nil)
        if not commit then
            slider._dragValue = nil
            return
        end
        local v = slider._dragValue or Snap(Read())
        slider._dragValue = nil
        slider._updating = true
        slider:SetValue(v)
        slider._updating = nil
        Render(v)
        SyncSteppers(v)
        Push(v)                              -- final commit once
        if pageOwner then F:Refresh(pageOwner) end -- one page refresh, not per tick
    end
    local function UpdateDrag()
        if slider._dragging and IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then
            StopDrag(true)
        end
    end
    slider:SetScript("OnMouseDown", function(_, button)
        if button and button ~= "LeftButton" then return end
        slider._dragging = true
        slider._dragValue = nil
        slider:SetScript("OnUpdate", UpdateDrag)
    end)
    slider:SetScript("OnHide", function() StopDrag(false) end)
    slider:SetScript("OnMouseUp", function() StopDrag(true) end)
    slider:SetScript("OnValueChanged", function(_, value)
        if slider._updating then return end
        local v = Snap(value)
        if slider._dragging then slider._dragValue = v end
        Render(v)
        SyncSteppers(v)
        if slider._dragging then return end
        Push(v)
    end)

    local function CommitBox()
        local v = Snap(tonumber(box:GetText()) or Read())
        slider._updating = true
        slider:SetValue(v)
        slider._updating = nil
        Render(v)
        SyncSteppers(v)
        Push(v)
    end
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self)
        Render(Read())
        SyncSteppers(Read())
        self._qfxCancelFocusCommit = true
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusGained", function(self)
        boxBrd._setBorder(S.borderHi or S.border)
        if self.HighlightText then self:HighlightText() end
    end)
    box:SetScript("OnEditFocusLost", function()
        boxBrd._setBorder(S.border)
        if box._qfxCancelFocusCommit then
            box._qfxCancelFocusCommit = nil
        else
            CommitBox()
        end
    end)

    AttachTooltip(region._label or slider, cfg.text, cfg.tooltip)
    region._control = slider
    ApplyDisabled(region, slider, cfg)
    F:RegisterRefresh(function()
        if slider._dragging then return end -- never fight an in-progress drag
        local v = Read()
        slider._updating = true
        slider:SetValue(v)
        slider._updating = nil
        Render(v)
        SyncSteppers(v)
    end)
    return slider
end

-- Segmented pills: one row of adjacent buttons, exactly one active (accent fill).
local function QfxSegmented(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local values = cfg.values or {}
    local order = cfg.order
    if not order then
        order = {}
        for k in pairs(values) do order[#order + 1] = k end
        table.sort(order, function(a, b) return tostring(a) < tostring(b) end)
    end
    if #order == 0 then return end

    local gap = S.segGap or 1
    local meas = Font(region, S.textSize, 1, 1, 1, 1)
    meas:Hide()
    local widths, total = {}, 0
    for i = 1, #order do
        local labelText = ResolveLabel(values, order, order[i])
        meas:SetText(labelText)
        local mw = meas:GetStringWidth()
        if IsSecret(mw) or not mw then mw = #tostring(labelText) * 8 end
        local w = math.max(cfg.minWidth or S.segMinW or 38, mw + (S.segPadX or 16))
        widths[i] = w
        total = total + w + (i > 1 and gap or 0)
    end

    local btns = {}
    local cum = 0
    for i = #order, 1, -1 do
        local key = order[i]
        local b = CreateFrame("Button", nil, region)
        b:SetSize(widths[i], S.rowControlH)
        b:SetPoint("RIGHT", region, "RIGHT", -(T.rightPad + cum), 0)
        cum = cum + widths[i] + gap
        local bg = QfxSurface(b, "BACKGROUND", 0, S.controlBg)
        bg:SetAllPoints()
        -- borderless pills: the active one is an accent fill, the rest a flat surface
        local fs = Font(b, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        fs:SetPoint("CENTER", b, "CENTER", 0, 0)
        fs:SetText(ResolveLabel(values, order, key))
        b._key = key
        b._qfx = "segmented"
        b._bg, b._fs = bg, fs
        local keyTip = type(values[key]) == "table" and values[key].tooltip or nil
        local tipText = ResolveTooltipText(keyTip or cfg.tooltip)
        b:SetScript("OnEnter", function(self)
            if not b._active then
                bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4] or 1)
            end
            if cfg.text or tipText then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(cfg.text or "", 1, 1, 1)
                if tipText then GameTooltip:AddLine(tipText, 1, 1, 1, true) end
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave", function()
            if not b._active then
                bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4] or 1)
            end
            GameTooltip:Hide()
        end)
        b:SetScript("OnClick", function()
            if ConfigDisabled(cfg) then return end
            if cfg.setValue then cfg.setValue(key) end
            if cfg.onSelect then cfg.onSelect(key) end
            region._refresh()
        end)
        btns[i] = b
    end
    region._refresh = function()
        local cur = cfg.getValue and cfg.getValue()
        for i = 1, #order do
            local b = btns[i]
            local on = (cur == b._key)
            b._active = on
            local bgC = on and (S.selectedFill or S.accent) or S.controlBg
            b._bg:SetColorTexture(bgC[1], bgC[2], bgC[3], bgC[4] or 1)
            local tc = on and (S.segOnText or S.text) or S.text
            b._fs:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1)
        end
    end
    region._dimTargets = btns
    region._control = btns[#btns]
    ApplyDisabled(region, btns[#btns], cfg)
    F:RegisterRefresh(region._refresh)
    region._refresh()
    return btns[1]
end

local function QfxDropdown(region, frame, cfg)
    local S = F.Skin
    local dd = MakeQfxDropdownButton(region, S, cfg.width or 170)
    -- Hosts may pass a resolver function or a { { key, label }, ... } list;
    -- normalize here so foreign models never reach pairs() as functions.
    local values = cfg.values
    if type(values) == "function" then
        local ok, result = pcall(values)
        values = ok and result or nil
    end
    if type(values) ~= "table" then values = {} end
    local order = cfg.order
    if not order then
        order = {}
        if type(values[1]) == "table" and values[1].key ~= nil then
            local map = {}
            for i = 1, #values do
                local item = values[i]
                if item.key ~= nil then
                    map[item.key] = item.label
                    order[#order + 1] = item.key
                end
            end
            values = map
        else
            local keys = {}
            for k in pairs(values) do keys[#keys + 1] = k end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for i = 1, #keys do order[i] = keys[i] end
        end
    end
    local function Current()
        local v = cfg.getValue and cfg.getValue()
        if v == nil then v = order[1] end
        return v
    end
    local function UpdateText()
        local text = ResolveLabel(values, order, Current())
        if dd._lastText == text then return end -- unchanged: no relayout per refresh
        dd._lastText = text
        dd._label:SetText(text)
    end
    local items = {}
    for i = 1, #order do
        local key = order[i]
        items[i] = {
            key = key,
            label = ResolveLabel(values, order, key),
            tooltip = type(values[key]) == "table" and values[key].tooltip or nil,
        }
    end
    local menu, refresh = MakeQfxMenu(dd, S, {
        items = items,
        width = cfg.menuWidth or math.max(170, cfg.width or 170),
        checked = function(k) return Current() == k end,
        onPick = function(k)
            if cfg.setValue then cfg.setValue(k) end
            UpdateText()
        end,
    })
    UpdateText()
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else dd._openMenu() end
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._control = dd
    ApplyDisabled(region, dd, cfg)
    F:RegisterRefresh(UpdateText)
    return dd
end

local function QfxCheckboxDropdown(region, frame, cfg)
    local S = F.Skin
    local dd = MakeQfxDropdownButton(region, S, cfg.width or 190)
    local items = cfg.items or {}
    local getFn, setFn = cfg.getFn, cfg.setFn
    local function Summary()
        if cfg.summaryFn then return cfg.summaryFn() end
        local n = 0
        for i = 1, #items do
            if getFn and getFn(items[i].key) then n = n + 1 end
        end
        if n == 0 then return cfg.noneText or "None" end
        return tostring(n) .. " / " .. tostring(#items)
    end
    local menu, refresh = MakeQfxMenu(dd, S, {
        items = items,
        width = cfg.menuWidth or math.max(190, cfg.width or 190),
        multi = true,
        checked = function(k) return getFn and getFn(k) end,
        onPick = function(k)
            if setFn then setFn(k, not (getFn and getFn(k))) end
            dd._label:SetText(Summary())
        end,
    })
    dd._label:SetText(Summary())
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else dd._openMenu() end
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._control = dd
    ApplyDisabled(region, dd, cfg)
    F:RegisterRefresh(function()
        dd._label:SetText(Summary())
        refresh()
    end)
    return dd, refresh
end

local function QfxButton(region, frame, cfg)
    local S = F.Skin
    local base = S.buttonBg or S.controlBg
    local hover = S.buttonBgHi or S.controlBgHi
    local btn = CreateFrame("Button", nil, region)
    btn:SetSize(cfg.width or S.buttonMinW, S.buttonH)
    btn:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, base)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
    local sheen = QfxSheen(btn, S.buttonSheen)
    local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    lbl:SetPoint("CENTER")
    lbl:SetText(cfg.text or "")
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
        brd._setBorder(S.borderHi or S.buttonBorder or S.border)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(base[1], base[2], base[3], base[4])
        brd._setBorder(S.buttonBorder or S.border)
    end)
    btn:SetScript("OnClick", function(self) if cfg.onClick then cfg.onClick(self) end end)
    btn._bg, btn._brd, btn._sheen = bg, brd, sheen
    AttachTooltip(btn, cfg.text, cfg.tooltip)
    region._control = btn
    ApplyDisabled(region, btn, cfg)
    F:RegisterRefresh(function() end)
    return btn
end

-- Right-aligned cluster of small buttons in one slot (nudge pads, Apply/Reset
-- pairs, ...). cfg = { gap, buttons = { { text, onClick, width, tooltip,
-- disabled, disabledTooltip }, ... } }. The last entry sits at the slot's right
-- edge; earlier entries stack leftwards. Returns the first button.
local function QfxButtonRow(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local gap = cfg.gap or 4
    local specs = cfg.buttons or {}
    local btns = {}
    local xOff = -T.rightPad
    for i = #specs, 1, -1 do
        local spec = specs[i]
        local btn = CreateFrame("Button", nil, region)
        local w = spec.width or 60
        btn:SetSize(w, S.rowControlH)
        btn:SetPoint("RIGHT", region, "RIGHT", xOff, 0)
        xOff = xOff - w - gap
        local base = S.buttonBg or S.controlBg
        local hover = S.buttonBgHi or S.controlBgHi
        local bg = QfxSurface(btn, "BACKGROUND", 0, base)
        bg:SetAllPoints()
        local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
        local sheen = QfxSheen(btn, S.buttonSheen)
        local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(spec.text or "")
        btn._bg, btn._brd, btn._lbl = bg, brd, lbl
        btn._sheen = sheen
        btn._qfx = "rowButton"
        local function Blocked()
            if EvalFlag(spec.disabled) then return true end
            if ConfigDisabled(cfg) then return true end
            return false
        end
        btn:SetScript("OnEnter", function(self2)
            if Blocked() then
                local reason = ResolveTooltipText(spec.disabledTooltip)
                if not reason and ConfigDisabled(cfg) then
                    if cfg.blockInCombat and IsCombatLocked() then
                        reason = ResolveTooltipText(cfg.combatTooltip) or "Not available in combat"
                    else
                        reason = ResolveTooltipText(cfg.disabledTooltip)
                    end
                end
                if reason then
                    GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                    GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
                return
            end
            bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4] or 1)
            brd._setBorder(S.borderHi or S.buttonBorder or S.border)
            if spec.tooltip then
                GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                GameTooltip:SetText(spec.text or "", 1, 1, 1)
                GameTooltip:AddLine(spec.tooltip, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            bg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
            brd._setBorder(S.buttonBorder or S.border)
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", function(self2)
            if Blocked() then return end
            if spec.onClick then spec.onClick(self2) end
        end)
        btns[i] = btn
    end
    region._dimTargets = btns
    ApplyDisabled(region, btns[1], cfg)
    F:RegisterRefresh(function()
        for i = 1, #btns do
            local spec = specs[i]
            local off = EvalFlag(spec.disabled) or ConfigDisabled(cfg)
            btns[i]:SetAlpha(off and 0.35 or 1)
        end
    end)
    return btns[1]
end

local function QfxInput(region, frame, cfg)
    local S = F.Skin
    local box = CreateFrame("EditBox", nil, region)
    box:SetSize(cfg.width or 100, S.rowControlH)
    box:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    box:SetAutoFocus(false)
    local bg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
    box:SetFont(F.Theme.font, S.textSize, "")
    box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    box:SetJustifyH("LEFT")
    box:SetTextInsets(6, 4, 0, 0)
    local function Read()
        local v = cfg.getValue and cfg.getValue()
        return tostring(v or "")
    end
    box:SetText(Read())
    local function Commit()
        local text = box:GetText() or ""
        if cfg.numeric then
            local n = tonumber(text)
            if n == nil then box:SetText(Read()) return end
            text = n
        end
        if cfg.setValue then cfg.setValue(text) end
    end
    box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", function(self)
        if self._qfxCancelFocusCommit then
            self._qfxCancelFocusCommit = nil
        else
            Commit()
        end
    end)
    box:SetScript("OnEscapePressed", function(self)
        self:SetText(Read())
        self._qfxCancelFocusCommit = true
        self:ClearFocus()
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._control = box
    ApplyDisabled(region, box, cfg)
    F:RegisterRefresh(function()
        if not box:HasFocus() then box:SetText(Read()) end
    end)
    return box
end

-- Color swatch with optional alpha (opt.alpha). getFn -> r, g, b [, a];
-- setFn(r, g, b [, a]). Returns the button; call btn._update() to repaint.
local function MakeQfxColorSwatch(parent, size, getFn, setFn, opts)
    opts = opts or {}
    local S = F.Skin
    local sw = CreateFrame("Button", nil, parent)
    sw:SetSize(size or 22, size or 22)
    local tex = QfxSurface(sw, "ARTWORK", 0, { 1, 1, 1, 1 })
    tex:SetAllPoints()
    -- no outline at rest (it shrank the colour area); the hover outline is the
    -- EUI "lazy border" idea
    local brd = QfxBorder(sw, sw:GetFrameLevel(), S.borderHi or S.border, 1, 1)
    brd:Hide()
    local function Read()
        local r, g, b, a
        if getFn then r, g, b, a = getFn() end
        return r or 1, g or 1, b or 1, a or 1
    end
    local function Update()
        local r, g, b, a = Read()
        local shown = opts.alpha and a or 1
        if sw._r == r and sw._g == g and sw._b == b and sw._a == shown then return end
        sw._r, sw._g, sw._b, sw._a = r, g, b, shown
        tex:SetColorTexture(r, g, b, shown)
    end
    sw._update = Update
    sw._qfx = "swatch"
    Update()
    sw:SetScript("OnClick", function()
        local r, g, b, a = Read()
        local function Apply()
            local nr, ng, nb
            if ColorPickerFrame.GetColorRGB then
                nr, ng, nb = ColorPickerFrame:GetColorRGB()
            else
                local c = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker
                if c and c.GetColorRGB then nr, ng, nb = c:GetColorRGB() end
            end
            local na = a
            if opts.alpha and ColorPickerFrame.GetColorAlpha then
                na = ColorPickerFrame:GetColorAlpha() or a
            end
            if nr and setFn then setFn(nr, ng, nb, na) end
            Update()
        end
        local function Cancel()
            if setFn then setFn(r, g, b, a) end
            Update()
        end
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b, opacity = a, hasOpacity = opts.alpha and true or false,
                swatchFunc = Apply, opacityFunc = Apply, cancelFunc = Cancel,
            })
        else
            ColorPickerFrame.func = Apply
            ColorPickerFrame.cancelFunc = Cancel
            ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
            ColorPickerFrame:SetColorRGB(r, g, b)
            ColorPickerFrame:Show()
        end
    end)
    sw:SetScript("OnEnter", function(self2)
        brd:Show()
        if opts.text or opts.tooltip then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(opts.text or "", 1, 1, 1)
            if opts.tooltip then GameTooltip:AddLine(opts.tooltip, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    sw:SetScript("OnLeave", function()
        brd:Hide()
        GameTooltip:Hide()
    end)
    return sw, Update
end

local function QfxColor(region, frame, cfg)
    local sw, Update = MakeQfxColorSwatch(region, 22, cfg.getValue, cfg.setValue,
        { alpha = cfg.alpha, text = cfg.text, tooltip = cfg.tooltip })
    sw:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    region._control = sw
    ApplyDisabled(region, sw, cfg)
    F:RegisterRefresh(Update)
    return sw, Update
end

-- Dropdown mode (class color / original / custom ...) + custom color swatch +
-- reset. cfg = { text, tooltip, modes = { key = label }, order, customKey,
-- getMode, setMode, getColor, setColor, defaultColor, defaultMode, alpha,
-- width, resetTooltip, disabled, disabledTooltip }. The swatch only shows while
-- the mode is customKey; clicking it opens the picker (which also works if the
-- host switches to the custom mode itself).
local function QfxColorMode(region, frame, cfg)
    local S = F.Skin
    local T = F.Theme
    local values = cfg.modes or {}
    local order = cfg.order
    if not order then
        order = {}
        for k in pairs(values) do order[#order + 1] = k end
        table.sort(order, function(a, b) return tostring(a) < tostring(b) end)
    end
    local customKey = cfg.customKey or "custom"

    local reset = CreateFrame("Button", nil, region)
    reset:SetSize(16, 16)
    reset:SetPoint("RIGHT", region, "RIGHT", -T.rightPad, 0)
    reset._qfx = "reset"
    local resetLbl = Font(reset, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
    resetLbl:SetPoint("CENTER", reset, "CENTER", 0, 0)
    resetLbl:SetText("R")
    reset:SetScript("OnEnter", function() resetLbl:SetTextColor(S.text[1], S.text[2], S.text[3], 1) end)
    reset:SetScript("OnLeave", function() resetLbl:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], 1) end)
    reset:SetScript("OnClick", function()
        if cfg.setColor and cfg.defaultColor then
            local d = cfg.defaultColor
            if type(d) == "function" then d = d() end
            if type(d) == "table" then cfg.setColor(d[1], d[2], d[3], d[4]) end
        end
        if cfg.setMode and cfg.defaultMode then cfg.setMode(cfg.defaultMode) end
        region._refresh()
    end)
    AttachTooltip(reset, cfg.text, cfg.resetTooltip or "Reset to default")

    local swatch
    if cfg.getColor and cfg.setColor then
        swatch = MakeQfxColorSwatch(region, 20, cfg.getColor, cfg.setColor, { alpha = cfg.alpha })
        swatch:SetPoint("RIGHT", reset, "LEFT", -4, 0)
    end

    local dd = MakeQfxDropdownButton(region, S, cfg.width or 104)
    dd:ClearAllPoints()
    dd:SetPoint("RIGHT", swatch and swatch or reset, "LEFT", -4, 0)
    local function Current()
        local m = cfg.getMode and cfg.getMode()
        if m == nil then m = order[1] end
        return m
    end
    local items = {}
    for i = 1, #order do
        items[i] = { key = order[i], label = ResolveLabel(values, order, order[i]) }
    end
    local function UpdateText()
        dd._label:SetText(ResolveLabel(values, order, Current()))
        if swatch then swatch:SetShown(Current() == customKey) end
    end
    local menu, refresh = MakeQfxMenu(dd, S, {
        items = items,
        width = cfg.menuWidth or math.max(140, cfg.width or 104),
        checked = function(k) return Current() == k end,
        onPick = function(k)
            if cfg.setMode then cfg.setMode(k) end
            UpdateText()
        end,
    })
    UpdateText()
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else dd._openMenu() end
    end)
    AttachTooltip(region._label, cfg.text, cfg.tooltip)
    region._refresh = function()
        UpdateText()
        refresh()
    end
    region._control = dd
    region._dimTargets = { reset, swatch }
    ApplyDisabled(region, dd, cfg)
    F:RegisterRefresh(region._refresh)
    return dd
end

-- Keybind capture button. cfg = { text, tooltip, getValue, setValue, width,
-- noneText, captureText, conflicts = function(key) -> name|nil, clearOnRightClick
-- (default true), disabled, disabledTooltip }. Keys are stored WoW-style
-- ("CTRL-SHIFT-A", "BUTTON4", "MOUSEWHEELUP"); "" means unbound.
local KeybindModKeys = {
    LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, UNKNOWN = true,
}
local function QfxKeybind(region, frame, cfg)
    local S = F.Skin
    local key = CreateFrame("Button", nil, region)
    key:SetSize(cfg.width or 120, S.rowControlH)
    key:SetPoint("RIGHT", region, "RIGHT", -F.Theme.rightPad, 0)
    if key.RegisterForClicks then key:RegisterForClicks("AnyUp") end
    local bg = QfxSurface(key, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(key, key:GetFrameLevel(), S.border, 1, 1)
    local lbl = Font(key, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    lbl:SetPoint("CENTER", key, "CENTER", 0, 0)
    if lbl.SetWordWrap then lbl:SetWordWrap(false) end
    if lbl.SetMaxLines then lbl:SetMaxLines(1) end

    local catcher = CreateFrame("Frame", nil, key)
    catcher:SetAllPoints()
    if catcher.EnableKeyboard then catcher:EnableKeyboard(true) end
    if catcher.EnableMouse then catcher:EnableMouse(true) end
    if catcher.EnableMouseWheel then catcher:EnableMouseWheel(true) end
    catcher:Hide()
    key._catcher = catcher
    key._label = lbl
    key._bg, key._brd = bg, brd

    local function Read() return cfg.getValue and cfg.getValue() or "" end
    local function Display(v)
        if not v or v == "" then return cfg.noneText or "Not Bound" end
        return (v:gsub("-", "+"))
    end
    local capturing = false
    local function Repaint()
        if capturing then
            lbl:SetText(cfg.captureText or "Press a key...")
            brd._setBorder(S.borderHi or S.border)
            return
        end
        local v = Read()
        local conflict = (v ~= "" and cfg.conflicts) and cfg.conflicts(v) or nil
        if conflict then
            lbl:SetTextColor(S.danger[1], S.danger[2], S.danger[3], S.danger[4] or 1)
        else
            lbl:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        end
        lbl:SetText(Display(v))
        brd._setBorder(S.border)
    end
    local function Mods()
        local out = ""
        if IsControlKeyDown and IsControlKeyDown() then out = out .. "CTRL-" end
        if IsShiftKeyDown and IsShiftKeyDown() then out = out .. "SHIFT-" end
        if IsAltKeyDown and IsAltKeyDown() then out = out .. "ALT-" end
        return out
    end
    local function StopCapture()
        if not capturing then return end
        capturing = false
        catcher:Hide()
        if catcher.SetPropagateKeyboardInput then catcher:SetPropagateKeyboardInput(true) end
        Repaint()
    end
    local function Commit(v)
        if cfg.setValue then cfg.setValue(v or "") end
        StopCapture()
    end

    key:HookScript("OnHide", StopCapture)

    local function StartCapture()
        if ConfigDisabled(cfg) then return end
        capturing = true
        catcher:Show()
        if catcher.SetPropagateKeyboardInput then catcher:SetPropagateKeyboardInput(false) end
        Repaint()
    end
    key:SetScript("OnClick", function(_, button)
        if button == "RightButton" and cfg.clearOnRightClick ~= false then
            Commit("")
        else
            StartCapture()
        end
    end)
    key:SetScript("OnEnter", function(self2)
        bg:SetColorTexture(S.controlBgHi[1], S.controlBgHi[2], S.controlBgHi[3], S.controlBgHi[4] or 1)
        brd._setBorder(S.borderHi or S.border)
        if cfg.text or cfg.tooltip then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(cfg.text or "", 1, 1, 1)
            if cfg.tooltip then GameTooltip:AddLine(cfg.tooltip, 1, 1, 1, true) end
            GameTooltip:Show()
        end
    end)
    key:SetScript("OnLeave", function()
        bg:SetColorTexture(S.controlBg[1], S.controlBg[2], S.controlBg[3], S.controlBg[4] or 1)
        if not capturing then brd._setBorder(S.border) end
        GameTooltip:Hide()
    end)

    catcher:SetScript("OnKeyDown", function(_, k)
        if not capturing then return end
        local up = strupper and strupper(k or "") or string.upper(k or "")
        if up == "ESCAPE" then StopCapture() return end
        if KeybindModKeys[up] then return end
        Commit(Mods() .. up)
    end)
    catcher:SetScript("OnMouseWheel", function(_, delta)
        if not capturing then return end
        Commit(Mods() .. ((delta or 0) > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN"))
    end)
    catcher:SetScript("OnMouseDown", function(_, button)
        if not capturing then return end
        if button == "LeftButton" or button == "RightButton" then return end
        Commit(Mods() .. (strupper and strupper(button) or string.upper(button)))
    end)
    catcher:RegisterEvent("GLOBAL_MOUSE_DOWN")
    catcher:SetScript("OnEvent", function(self2)
        if not capturing then return end
        local focus = GetMouseFocus and GetMouseFocus() or nil
        if focus and (IsDescendantOf(focus, key) or IsDescendantOf(focus, self2)) then return end
        StopCapture()
    end)

    Repaint()
    region._control = key
    ApplyDisabled(region, key, cfg)
    F:RegisterRefresh(Repaint)
    return key
end

QFXSkin.wideButton = function(frame, text, onClick, opts)
    local S = F.Skin
    local base = S.buttonBg or S.controlBg
    local hover = S.buttonBgHi or S.controlBgHi
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(opts.width or math.min(280, frame:GetWidth()), 24)
    btn:SetPoint("CENTER", frame, "CENTER", 0, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, base)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
    local sheen = QfxSheen(btn, S.buttonSheen)
    local lbl = Font(btn, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    lbl:SetPoint("CENTER")
    lbl:SetText(text or "")
    btn:SetScript("OnEnter", function()
        bg:SetColorTexture(hover[1], hover[2], hover[3], hover[4])
        brd._setBorder(S.borderHi or S.buttonBorder or S.border)
    end)
    btn:SetScript("OnLeave", function()
        bg:SetColorTexture(base[1], base[2], base[3], base[4])
        brd._setBorder(S.buttonBorder or S.border)
    end)
    btn:SetScript("OnClick", function(self2) if onClick then onClick(self2) end end)
    btn._bg, btn._brd, btn._sheen = bg, brd, sheen
    frame._button = btn
end

QFXSkin.toggle = QfxToggle
QFXSkin.slider = QfxSlider
QFXSkin.segmented = QfxSegmented
QFXSkin.dropdown = QfxDropdown
QFXSkin.checkboxDropdown = QfxCheckboxDropdown
QFXSkin.button = QfxButton
QFXSkin.buttonRow = QfxButtonRow
QFXSkin.input = QfxInput
QFXSkin.color = QfxColor
QFXSkin.colorMode = QfxColorMode
QFXSkin.keybind = QfxKeybind

F.Skins = { qfx = QFXSkin }

-- Skin token override: pass a table and any token not supplied keeps the QFXUI
-- default. Passing nil/"qfx" restores the stock skin.
function F:SetSkin(skin)
    if type(skin) == "table" then
        local merged = {}
        for k, v in pairs(QFXSkin) do merged[k] = v end
        for k, v in pairs(skin) do merged[k] = v end
        self.Skin = merged
    else
        self.Skin = QFXSkin
    end
    return self.Skin
end

F.Skin = QFXSkin

local function BuildSlot(self, skin, region, cfg)
    if type(cfg) ~= "table" then return end
    local label = BuildLabel(region, cfg)
    if cfg.type == "label" or cfg.type == nil then
        region._control = nil
        FitLabel(region, cfg, self)
        return
    end
    local builder = skin and skin[cfg.type]
    if builder then
        builder(region, region:GetParent(), cfg)
    else
        label:SetText((cfg.text or "") .. " (?)")
    end
    FitLabel(region, cfg, self)
end

function F:DualRow(parent, y, leftCfg, rightCfg)
    local T = self.Theme
    local totalW = ContentWidth(parent)
    local h = T.rowH
    local function TallRow(cfg)
        return cfg and cfg.type == "slider" and cfg.labelsBelow == true
    end
    if TallRow(leftCfg) or TallRow(rightCfg) then
        h = math.max(h, T.sliderRowH or 46)
    end
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(totalW, h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local halfW = floor(totalW / 2)
    local leftRegion = CreateFrame("Frame", nil, frame)
    leftRegion:SetSize(rightCfg and halfW or totalW, h)
    leftRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    local rightRegion = CreateFrame("Frame", nil, frame)
    rightRegion:SetSize(halfW, h)
    rightRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame._leftRegion = leftRegion
    frame._rightRegion = rightRegion

    RowBg(frame, parent, self)
    local skin = self.Skin
    BuildSlot(self, skin, leftRegion, leftCfg)
    BuildSlot(self, skin, rightRegion, rightCfg)

    if rightCfg then
        local div = NoSnap(frame:CreateTexture(nil, "ARTWORK"))
        div:SetColorTexture(T.lineColor[1], T.lineColor[2], T.lineColor[3], T.lineColor[4])
        div:SetWidth(1)
        div:SetPoint("TOP", frame, "TOP", 0, -4)
        div:SetPoint("BOTTOM", frame, "BOTTOM", 0, 4)
    end

    frame._refresh = function()
        -- Per-control refreshers are registered globally; this hook exists so a
        -- host that keeps row references can refresh one row on demand.
    end
    return frame, h
end

-------------------------------------------------------------------------------
-- Standalone: checkbox dropdown / color swatch (right-anchored helpers)
-------------------------------------------------------------------------------
function F:CheckboxDropdown(parent, width, frameLevel, items, getFn, setFn, opts)
    opts = opts or {}
    local T = self.Theme
    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(width or 190, T.controlH)
    if opts.point and opts.relPoint then
        region:SetPoint(opts.point, parent, opts.relPoint, opts.x or 0, opts.y or 0)
    else
        region:SetPoint("RIGHT", parent, "RIGHT", -T.rightPad, opts.y or 0)
    end
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)
    local maker = (self.Skin and self.Skin.checkboxDropdown) or QFXSkin.checkboxDropdown
    return maker(region, parent, {
        width = width or 190,
        items = items,
        getFn = getFn,
        setFn = setFn,
        summaryFn = opts.summaryFn,
        noneText = opts.noneText,
        tooltip = opts.tooltip,
        text = opts.text,
        disabled = opts.disabled,
        disabledTooltip = opts.disabledTooltip,
        blockInCombat = opts.blockInCombat,
        combatTooltip = opts.combatTooltip,
    })
end

function F:ColorSwatch(parent, frameLevel, getFn, setFn, opts)
    opts = opts or {}
    local T = self.Theme
    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(opts.width or 24, opts.height or 24)
    region:SetPoint(opts.point or "RIGHT", parent, opts.relPoint or opts.point or "RIGHT", opts.x or -T.rightPad, opts.y or 0)
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)
    local maker = (self.Skin and self.Skin.color) or QFXSkin.color
    local sw, refresh = maker(region, parent, {
        getValue = getFn, setValue = setFn, text = opts.text, tooltip = opts.tooltip,
        alpha = opts.alpha, disabled = opts.disabled, disabledTooltip = opts.disabledTooltip,
        blockInCombat = opts.blockInCombat, combatTooltip = opts.combatTooltip,
    })
    return sw, refresh
end

-- Standalone segmented pills: F:Segmented(parent, frameLevel, values, order,
-- getValue, setValue, opts) -> region, refresh, firstButton. The caller anchors
-- the returned region; the pills right-align to its right edge.
function F:Segmented(parent, frameLevel, values, order, getValue, setValue, opts)
    opts = opts or {}
    local T = self.Theme
    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(opts.width or 160, (self.Skin and self.Skin.rowControlH) or T.controlH)
    if opts.point and opts.relPoint then
        region:SetPoint(opts.point, parent, opts.relPoint, opts.x or 0, opts.y or 0)
    else
        region:SetPoint("RIGHT", parent, "RIGHT", -T.rightPad, opts.y or 0)
    end
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)
    local first = QfxSegmented(region, parent, {
        values = values,
        order = order,
        getValue = getValue,
        setValue = setValue,
        minWidth = opts.minWidth,
        text = opts.text,
        tooltip = opts.tooltip,
        disabled = opts.disabled,
        disabledTooltip = opts.disabledTooltip,
        onSelect = opts.onSelect,
    })
    return region, region._refresh, first
end

-------------------------------------------------------------------------------
-- Advanced controls (custom-drawn, drawn with the active skin tokens).
-------------------------------------------------------------------------------

-- Active drawing tokens (kept as a function for callers that build custom rows).
function F:Tokens()
    return self.Skin or QFXSkin
end

-- Tabs / segmented row. items = { { key, label }, ... };
-- getActive() -> key; onSelect(key). Returns frame, height.
function F:Tabs(parent, y, items, getActive, onSelect, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local h = opts.height or 24
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h + 2)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local btns = {}
    local function Refresh()
        local active = getActive and getActive()
        for i = 1, #btns do
            local b = btns[i]
            local on = b._key == active
            b._label:SetTextColor(on and S.sectionText[1] or S.textMuted[1],
                on and S.sectionText[2] or S.textMuted[2],
                on and S.sectionText[3] or S.textMuted[3], 1)
            b._underline:SetShown(on)
        end
    end

    local x = 0
    for i = 1, #items do
        local it = items[i]
        local btn = CreateFrame("Button", nil, frame)
        local lbl = Font(btn, T.labelSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
        lbl:SetText(it.label or tostring(it.key))
        local w = math.max(48, (lbl:GetStringWidth() or 40) + (opts.padX or 22))
        btn:SetSize(w, h)
        btn:SetPoint("LEFT", frame, "LEFT", x, 0)
        x = x + w + (opts.gap or 4)
        local ul = btn:CreateTexture(nil, "ARTWORK")
        ul:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 6, 0)
        ul:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 0)
        ul:SetHeight(2)
        local sc = S.selectedLine or S.borderHi or S.accent
        ul:SetColorTexture(sc[1], sc[2], sc[3], 1)
        ul:Hide()
        btn._key, btn._label, btn._underline = it.key, lbl, ul
        btn:SetScript("OnEnter", function() lbl:SetTextColor(S.text[1], S.text[2], S.text[3], 1) end)
        btn:SetScript("OnLeave", function() Refresh() end)
        btn:SetScript("OnClick", function()
            if onSelect then onSelect(it.key) end
            Refresh()
        end)
        btns[#btns + 1] = btn
    end
    Refresh()
    self:RegisterRefresh(Refresh)
    return frame, h + 2
end

-- Tab panel: a Tabs strip with real content switching (each tab owns a content
-- frame that is built once and then shown/hidden). A tab may also carry
-- subtabs, which render a second Tabs strip under the main one with their own
-- content frames (one control for one- and two-level navigation).
--   local panel, h, api = W:TabPanel(parent, y, {
--       tabs = { { key = "a", label = "A", build = function(content, key)
--                    local cy = 0
--                    ... build rows into content, decreasing cy ...
--                    return -cy end,
--                 -- optional second level (Tabs strip under the first one):
--                 subtabs = { { key = "a1", label = "A1", build = function(content, key)
--                    ... end }, ... } }, ... },
--       getActive = function() return state.tab end,
--       onSelect  = function(key) state.tab = key end,
--       getSubActive = function(tabKey) return state.sub[tabKey] end,  -- optional
--       onSubSelect  = function(tabKey, subKey) ... end,               -- optional
--       height = 220,   -- optional fixed content height (else auto from build)
--       onResize = function(panel, totalH) end })
--   api.GetContent(tabKey[, subKey]) returns the tab (or subtab) content frame;
--   api.Show(tabKey[, subKey]) switches programmatically.
function F:TabPanel(parent, y, opts)
    opts = opts or {}
    local tabs = opts.tabs or {}

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(parent:GetWidth() or 0, 1)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, y)

    local contentFrames, subContentFrames, maxH = {}, {}, 0
    local subStrips, activeSub = {}, {}
    local pageOwner = self._refreshScope
    local currentSubH, mainStripH = 0, 0

    local function FindTab(key)
        for i = 1, #tabs do
            if tabs[i].key == key then return tabs[i] end
        end
    end

    local function Layout()
        local h = mainStripH + 4 + (currentSubH > 0 and currentSubH + 4 or 0) + (opts.height or maxH)
        frame:SetHeight(h)
        if opts.onResize then opts.onResize(frame, h) end
    end

    local function BuildContent(cf, entry, key)
        local ch = 0
        if entry and entry.build then
            -- A tab can be built long after the page's EndPage call. Keep its
            -- refresh callbacks owned by the page without clearing the
            -- callbacks already registered by sibling tabs.
            local previousScope = self._refreshScope
            self._refreshScope = pageOwner
            local ok, result = pcall(entry.build, cf, key)
            self._refreshScope = previousScope
            if not ok then error(result, 0) end
            ch = result or 0
        end
        if ch > maxH then maxH = ch end
        cf:SetHeight(opts.height or math.max(1, ch))
    end

    local function ContentFrame(key, subKey, entry)
        local cf
        if subKey then
            subContentFrames[key] = subContentFrames[key] or {}
            cf = subContentFrames[key][subKey]
        else
            cf = contentFrames[key]
        end
        if cf then return cf end
        cf = CreateFrame("Frame", nil, frame)
        local top = mainStripH + 4
        local rec = subKey and subStrips[key]
        if subKey then top = top + (rec and rec.height or 0) + 4 end
        cf:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -top)
        cf:SetWidth(frame:GetWidth())
        BuildContent(cf, entry, key)
        if subKey then subContentFrames[key][subKey] = cf else contentFrames[key] = cf end
        return cf
    end

    local Show -- forward: a subtab click re-enters the switcher

    local function EnsureSubStrip(tab)
        local rec = subStrips[tab.key]
        if rec then return rec end
        rec = {}
        rec.strip, rec.height = self:Tabs(frame, -(mainStripH + 4), tab.subtabs, function()
            return (opts.getSubActive and opts.getSubActive(tab.key)) or activeSub[tab.key]
        end, function(subKey)
            Show(tab.key, subKey)
            if opts.onSubSelect then opts.onSubSelect(tab.key, subKey) end
        end, opts.subTabOpts)
        rec.strip:Hide()
        subStrips[tab.key] = rec
        return rec
    end

    Show = function(key, subKey)
        local tab = FindTab(key)
        if not tab then return end
        for _, cf in pairs(contentFrames) do cf:Hide() end
        for _, map in pairs(subContentFrames) do for _, cf in pairs(map) do cf:Hide() end end
        for _, rec in pairs(subStrips) do rec.strip:Hide() end

        if tab.subtabs and #tab.subtabs > 0 then
            local rec = EnsureSubStrip(tab)
            local entry
            local wanted = subKey or (opts.getSubActive and opts.getSubActive(tab.key)) or activeSub[tab.key]
            for i = 1, #tab.subtabs do
                if tab.subtabs[i].key == wanted then entry = tab.subtabs[i] end
            end
            if not entry then entry = tab.subtabs[1] end
            activeSub[tab.key] = entry.key
            rec.strip:Show()
            currentSubH = rec.height
            ContentFrame(tab.key, entry.key, entry):Show()
        else
            currentSubH = 0
            ContentFrame(tab.key, nil, tab):Show()
        end
        Layout()
    end

    local strip, stripH = self:Tabs(frame, 0, tabs, opts.getActive, function(key)
        Show(key)
        if opts.onSelect then opts.onSelect(key) end
    end, opts.tabOpts)
    mainStripH = stripH
    frame._strip = strip

    frame._api = {
        Show = function(_, key, subKey) Show(key, subKey) end,
        GetContent = function(_, key, subKey)
            if subKey then
                return subContentFrames[key] and subContentFrames[key][subKey]
            end
            return contentFrames[key]
        end,
        GetActiveSub = function(_, key) return activeSub[key] end,
        Refresh = function() Layout() end,
    }
    local current = (opts.getActive and opts.getActive()) or (tabs[1] and tabs[1].key)
    if current then Show(current) end
    Layout()
    return frame, frame:GetHeight(), frame._api
end

-- Vertical navigation list: two sidebar standards in one factory control.
--
--   FIXED (mode = "fixed", the QFXSystemBar standard): every item is a top row
--   and clicking selects the page. No groups, no expand indicators.
--
--   EXPANDABLE (mode = "expandable", default when any item has group = true;
--   the QFXToolBox standard): a group row carries a "+" / "-" indicator and
--   toggles its children; children (parent = groupKey) render as sub-tabs -
--   no frame, the factory zebra wash carries the row (renumbered on every
--   re-layout) and the active one gets a W:Tabs-style underline.
--
-- In both modes the top rows use the chrome-button treatment (Surface + Border
-- + sheen); the active row keeps the logo's warm orange, hover stays electric
-- blue. Rows are laid out from (x, y) inside the given parent, which supplies
-- the panel background (for example W:SkinFrame + W:Perimeter).
--   local nav = W:NavList(parent, {
--       mode = "expandable",                         -- or "fixed"
--       x = 8, y = -10, width = 150, rowH = 26, childH = 22, indent = 16, gap = 2,
--       expanded = "grp:cvars",                      -- optional initial group
--       getActive = function() return "module:foo" end,
--       -- NOTE: getActive must read the SAME state the host's page switcher
--       -- updates. Reading a stale copy (a variable the switcher never writes)
--       -- silently freezes the highlight and the sub-tab underline.
--       onSelect = function(key) ... end,            -- row click (top/group/child)
--       onToggle = function(key, expanded) ... end,  -- optional, after a toggle
--   })
--   nav:SetItems({
--       { key = "general", label = "Basic" },
--       { key = "grp:cvars", label = "CVar", group = true },
--       { key = "module:foo", label = "Foo", parent = "grp:cvars" },
--   })
--   nav:SetExpanded("grp:cvars" | nil)  -- a group click toggles it too
--   nav:Refresh()                       -- re-read active/expanded, re-layout
--   nav.buttons[key]                    -- row handles
function F:NavList(parent, opts)
    opts = opts or {}
    -- mode = "fixed" is the QFXSystemBar sidebar (no groups); the default
    -- expandable mode is the QFXToolBox sidebar (+/- categories + sub-tabs)
    local expandable = opts.mode ~= "fixed"
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetAllPoints(parent)
    if holder.EnableMouse then holder:EnableMouse(false) end
    -- keep the rows above the panel's decorative chrome (skin borders sit at
    -- parent level + 5), so a border frame can never shadow a row
    if holder.SetFrameLevel and parent.GetFrameLevel then
        holder:SetFrameLevel((parent:GetFrameLevel() or 1) + 6)
    end

    local nav = {
        frame = holder,
        buttons = {},
        items = {},
        expanded = opts.expanded,
    }
    local rowH = tonumber(opts.rowH) or 26
    local childH = tonumber(opts.childH) or 22
    local gap = tonumber(opts.gap) or 2
    local indent = tonumber(opts.indent) or 16
    local width = tonumber(opts.width) or 150

    local Refresh -- assigned below; rows report click errors through it

    local function MakeRow()
        local btn = CreateFrame("Button", nil, holder)
        btn._qfx = "navRow"
        return btn
    end

    local function StyleRow(btn, item)
        local S = F.Skin or QFXSkin
        local isChild = expandable and (item.parent ~= nil)
        btn._key = item.key
        btn._isChild = isChild
        btn._group = item.group and true or false

        local bg, brd, sheen, line, sign
        local textLeft = isChild and 24 or 10
        if isChild then
            bg = QfxSurface(btn, "BACKGROUND", 0, S.rowBgEven)
            bg:SetAllPoints()
            local lc = S.selectedLine or S.borderHi or S.accent
            -- the underline rides the very top draw layer of the row: nothing a
            -- row draws can ever cover the active marker
            line = QfxSurface(btn, "OVERLAY", 7, lc)
            line:SetHeight(2)
            line:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 20, 0)
            line:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -6, 0)
            line:Hide()
        else
            bg = QfxSurface(btn, "BACKGROUND", 0, S.controlBg)
            bg:SetAllPoints()
            brd = QfxBorder(btn, btn:GetFrameLevel(), S.border, 1, 1)
            sheen = QfxSheen(btn, S.buttonSheen)
            sheen:SetHeight(6)
            if item.group and expandable then
                sign = Font(btn, 13, S.warmAccent[1], S.warmAccent[2], S.warmAccent[3], 1)
                sign:SetPoint("LEFT", btn, "LEFT", 6, 0)
                sign:SetWidth(11)
                sign:SetJustifyH("CENTER")
                sign:SetText("+")
                textLeft = 20
            end
        end

        local label = Font(btn, isChild and 13 or F.Theme.labelSize, S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        label:SetPoint("LEFT", btn, "LEFT", textLeft, 0)
        label:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        if label.SetWordWrap then label:SetWordWrap(false) end
        if label.SetMaxLines then label:SetMaxLines(1) end
        label:SetJustifyH("LEFT")
        label:SetJustifyV("MIDDLE")

        btn._bg, btn._brd, btn._sheen, btn._line, btn._sign = bg, brd, sheen, line, sign
        btn._label = label
        btn._stripe = S.rowBgEven
        btn._selected = false

        local function Paint(target, color, kind)
            if opts.motion and F.AnimateColor then
                F:AnimateColor(target, color, kind, btn)
            elseif kind == "border" then target._setBorder(color)
            elseif kind == "text" then target:SetTextColor(color[1], color[2], color[3], color[4] or 1)
            else target:SetColorTexture(color[1], color[2], color[3], color[4] or 1) end
        end

        local function ApplyIdle()
            local S2 = F.Skin or QFXSkin
            if isChild then
                line:Hide()
                local c = btn._stripe or S2.rowBgEven
                Paint(bg, { c[1], c[2], c[3], c[4] or 1 }, "surface")
                local mc = S2.textMuted or S2.text
                Paint(label, { mc[1], mc[2], mc[3], mc[4] or 1 }, "text")
            else
                Paint(bg, { S2.controlBg[1], S2.controlBg[2], S2.controlBg[3], S2.controlBg[4] or 1 }, "surface")
                if brd then Paint(brd, S2.border, "border") end
                if sheen and S2.buttonSheen then
                    sheen:SetColorTexture(S2.buttonSheen[1], S2.buttonSheen[2], S2.buttonSheen[3], S2.buttonSheen[4] or 0.08)
                end
                Paint(label, { S2.text[1], S2.text[2], S2.text[3], S2.text[4] or 1 }, "text")
                if sign then sign:SetTextColor(S2.warmAccent[1], S2.warmAccent[2], S2.warmAccent[3], 1) end
            end
        end

        function btn.SetSelected(self, on)
            self._selected = on and true or false
            local S2 = F.Skin or QFXSkin
            if not self._selected then
                ApplyIdle()
                return
            end
            if isChild then
                line:Show()
                local tc = S2.selectedText or S2.text
                Paint(label, { tc[1], tc[2], tc[3], tc[4] or 1 }, "text")
            else
                local bgc = S2.closeBgHi or S2.selectedFill or S2.accent
                Paint(bg, { bgc[1], bgc[2], bgc[3], bgc[4] or 1 }, "surface")
                if brd then Paint(brd, S2.warmAccent or S2.borderHi or S2.border, "border") end
                if sheen then
                    local shine = S2.warmAccentHi or S2.text
                    sheen:SetColorTexture(shine[1], shine[2], shine[3], 0.12)
                end
                local tc = S2.warmAccentHi or S2.text
                Paint(label, { tc[1], tc[2], tc[3], tc[4] or 1 }, "text")
                if sign then sign:SetTextColor(tc[1], tc[2], tc[3], tc[4] or 1) end
            end
        end

        function btn.SetExpanded(self, expanded)
            if self._sign then self._sign:SetText(expanded and "-" or "+") end
        end

        function btn.SetStripe(self, index)
            if not isChild then return end
            local S2 = F.Skin or QFXSkin
            local c
            if index % 2 == 1 then
                c = S2.rowBgOdd or S2.rowBgEven
            else
                c = S2.rowBgEven or S2.rowBgOdd
            end
            self._stripe = c
            if not self._selected then Paint(bg, { c[1], c[2], c[3], c[4] or 1 }, "surface") end
        end

        function btn.SetText(self, text)
            self._fullText = tostring(text or "")
            local reserved = (sign and 22 or 0) + (isChild and 24 or 14)
            local w = self:GetWidth() or 0
            -- the row is usually not sized yet on the first SetText (SetItems
            -- runs before the first layout): fall back to the list width so the
            -- label is never clamped to a tiny width and truncated to "..."
            if w < 60 then w = width end
            TruncateToFit(label, self._fullText, math.max(30, w - reserved))
        end

        -- Interaction layer: the whole row must be clickable. A dedicated hit
        -- frame above every decorative child guarantees the hit rect is exactly
        -- the row rect (border/sheen sub-frames, or any future row art, can
        -- never shrink or shadow it), and it also carries the row tooltip.
        local hit = CreateFrame("Button", nil, btn)
        hit:SetAllPoints()
        hit:SetFrameLevel(btn:GetFrameLevel() + 12)
        if hit.RegisterForClicks then hit:RegisterForClicks("LeftButtonDown", "RightButtonDown") end
        btn._hit = hit

        local function ApplyHover()
            if btn._selected then return end
            local S2 = F.Skin or QFXSkin
            if isChild then
                local hc = S2.rowHover or S2.controlBgHi
                Paint(bg, { hc[1], hc[2], hc[3], hc[4] or 1 }, "surface")
                Paint(label, { S2.text[1], S2.text[2], S2.text[3], S2.text[4] or 1 }, "text")
            else
                Paint(bg, { S2.controlBgHi[1], S2.controlBgHi[2], S2.controlBgHi[3], S2.controlBgHi[4] or 1 }, "surface")
                if brd then Paint(brd, S2.borderHi or S2.border, "border") end
                Paint(label, { S2.text[1], S2.text[2], S2.text[3], S2.text[4] or 1 }, "text")
            end
        end

        local function Activate(_, button)
            if button and button ~= "LeftButton" then return end
            local ok, err = pcall(function()
                if btn._group and expandable then
                    nav:Toggle(btn._key)
                elseif opts.onSelect then
                    opts.onSelect(btn._key)
                end
            end)
            if not ok then
                F.lastNavError = err
                -- never leave the click chain broken: re-highlight at least
                Refresh()
            end
        end

        hit:SetScript("OnEnter", ApplyHover)
        hit:SetScript("OnLeave", function() btn:SetSelected(btn._selected) end)
        hit:SetScript("OnMouseDown", Activate)
        AttachTooltip(hit, item.label, item.tooltip)

        -- the row itself no longer takes mouse input: the hit layer owns it
        if btn.EnableMouse then btn:EnableMouse(false) end
        return btn
    end

    function Refresh()
        local active = opts.getActive and opts.getActive()
        local x = tonumber(opts.x) or 0
        local y = tonumber(opts.y) or 0
        local stripeIndex = 0
        for i = 1, #nav.items do
            local item = nav.items[i]
            local btn = nav.buttons[item.key]
            if btn then
                -- fixed mode shows every item as a top row; expandable mode
                -- hides children until their group is expanded
                local visible = true
                if expandable and item.parent ~= nil then
                    visible = (nav.expanded == item.parent)
                end
                btn:SetShown(visible)
                if visible then
                    local child = expandable and (item.parent ~= nil)
                    if child then
                        stripeIndex = stripeIndex + 1
                        btn:SetStripe(stripeIndex)
                    end
                    btn:SetSize(width - (child and indent or 0), child and childH or rowH)
                    btn:ClearAllPoints()
                    btn:SetPoint("TOPLEFT", holder, "TOPLEFT", x + (child and indent or 0), y)
                    -- now that the row has its final width, re-clamp the label
                    if btn._fullText then btn:SetText(btn._fullText) end
                    y = y - (child and childH or rowH) - gap
                    btn:SetSelected(active == item.key)
                    if item.group and expandable then btn:SetExpanded(nav.expanded == item.key) end
                end
            end
        end
    end

    function nav:SetItems(items)
        nav.items = items or {}
        for i = 1, #nav.items do
            local item = nav.items[i]
            if item.key ~= nil and not nav.buttons[item.key] then
                nav.buttons[item.key] = StyleRow(MakeRow(), item)
            end
        end
        -- hide rows that no longer have an item
        for key, btn in pairs(nav.buttons) do
            local found
            for i = 1, #nav.items do
                if nav.items[i].key == key then found = true break end
            end
            if not found then btn:Hide() end
        end
        for i = 1, #nav.items do
            local item = nav.items[i]
            local btn = nav.buttons[item.key]
            if btn then
                btn:SetText(item.label or tostring(item.key))
                if btn._sign then btn:SetExpanded(false) end
            end
        end
        Refresh()
    end

    function nav:SetExpanded(key)
        nav.expanded = key
        Refresh()
    end

    function nav:GetExpanded()
        return nav.expanded
    end

    function nav:Toggle(key)
        if nav.expanded == key then
            nav.expanded = nil
        else
            nav.expanded = key
        end
        if opts.onToggle then opts.onToggle(key, nav.expanded == key) end
        Refresh()
        if opts.onSelect then opts.onSelect(key) end
    end

    function nav:Refresh()
        Refresh()
    end

    if opts.items then nav:SetItems(opts.items) end
    return nav
end

-- Multi-column checkbox grid. entries = { { label, getValue, setValue,
-- tooltip | help, disabled, disabledTooltip, group, icon }, ... }.
-- opts = { gap, rowH, groupH, maxSelected (number|function), limitTooltip }.
-- Grouped entries render a full-width heading whenever e.group changes;
-- maxSelected dims (and blocks) unchecked cells once the limit is reached.
function F:CheckGrid(parent, y, columns, entries, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local cols = math.max(1, tonumber(columns) or 2)
    local contentW = ContentWidth(parent)
    local gap = opts.gap or 12
    local cellW = floor((contentW - gap * (cols - 1)) / cols)
    local cellH = opts.rowH or 22
    local groupH = opts.groupH or 20
    entries = entries or {}

    local layout, yOff, col = {}, 0, 0
    local lastGroup
    for i = 1, #entries do
        local e = entries[i]
        if e.group ~= nil and e.group ~= lastGroup then
            lastGroup = e.group
            if col ~= 0 then yOff = yOff + cellH; col = 0 end
            layout[#layout + 1] = { kind = "group", label = e.group, top = yOff }
            yOff = yOff + groupH
        end
        layout[#layout + 1] = { kind = "cell", entry = e, col = col, top = yOff }
        col = col + 1
        if col >= cols then col = 0; yOff = yOff + cellH end
    end
    local totalH = yOff + (col > 0 and cellH or 0) + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(contentW, totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    frame._qfx = "checkGrid"

    local function MaxN()
        local m = opts.maxSelected
        if type(m) == "function" then m = m() end
        return tonumber(m)
    end
    local function Count()
        local n = 0
        for i = 1, #entries do
            if entries[i].getValue and entries[i].getValue() then n = n + 1 end
        end
        return n
    end
    local renders = {}
    local function RenderAll()
        local selected = Count()
        for i = 1, #renders do renders[i](selected) end
    end

    for i = 1, #layout do
        local item = layout[i]
        if item.kind == "group" then
            local gl = Font(frame, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
            gl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -item.top - 2)
            gl:SetText(tostring(item.label or ""))
        else
            local e = item.entry
            local cell = CreateFrame("Frame", nil, frame)
            cell:SetSize(cellW, cellH)
            cell:SetPoint("TOPLEFT", frame, "TOPLEFT", item.col * (cellW + gap), -item.top - 2)

            local icon
            local x = 0
            if e.icon then
                icon = cell:CreateTexture(nil, "ARTWORK")
                local iconSize = SnapUI(cell, 14)
                icon:SetSize(iconSize, iconSize)
                icon:SetPoint("LEFT", cell, "LEFT", 0, 0)
                icon:SetTexture(e.icon)
                x = 18
            end
            local cb = CreateFrame("Button", nil, cell)
            cb._qfx = "checkcell"
            -- whole physical pixels on both axes: a 16x16 UI box rounds to a
            -- non-square 22x23 at fractional scales, which reads as a wobbly box
            local boxSize = SnapUI(cell, 16)
            cb:SetSize(boxSize, boxSize)
            cb:SetPoint("LEFT", cell, "LEFT", x, 0)
            local box = NoSnap(QfxSurface(cb, "BACKGROUND", 0, S.controlBg))
            box:SetAllPoints()
            local brd = QfxBorder(cb, cb:GetFrameLevel(), S.border, 1, 1)
            local markInset = SnapUI(cb, 3)
            local mark = NoSnap(QfxSurface(cb, "ARTWORK", 1, S.checkFill or S.warmAccent or S.accent))
            mark:SetPoint("TOPLEFT", cb, "TOPLEFT", markInset, -markInset)
            mark:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", -markInset, markInset)

            local lbl = Font(cell, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
            lbl:SetPoint("LEFT", cb, "RIGHT", 6, 0)
            lbl:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
            lbl:SetJustifyH("LEFT")
            TruncateToFit(lbl, e.label or e.text or "", cellW - 26 - x)

            local block
            local function EnsureBlock()
                if block then return end
                block = CreateFrame("Frame", nil, cell)
                block:SetAllPoints()
                block:SetFrameLevel(cell:GetFrameLevel() + 8)
                block:EnableMouse(true)
                block:Hide()
                block:SetScript("OnEnter", function(self2)
                    local reason
                    if EvalFlag(e.disabled) and e.disabledTooltip then
                        reason = ResolveTooltipText(e.disabledTooltip)
                    elseif cb._blocked then
                        reason = ResolveTooltipText(opts.limitTooltip) or "Selection limit reached"
                    end
                    if reason then
                        GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                        GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                        GameTooltip:Show()
                    end
                end)
                block:SetScript("OnLeave", function() GameTooltip:Hide() end)
            end
            local function Render(selected)
                local on = e.getValue and e.getValue() and true or false
                local off = EvalFlag(e.disabled)
                local limit = MaxN()
                local overLimit = limit ~= nil and not on and (selected or Count()) >= limit
                mark:SetShown(on)
                cb._blocked = overLimit or off
                local a = (overLimit or off) and 0.35 or 1
                cb:SetAlpha(a)
                lbl:SetAlpha(a)
                if icon then icon:SetAlpha(a) end
                if off or (overLimit and opts.limitTooltip) then
                    EnsureBlock()
                    block:SetShown(true)
                elseif block then
                    block:Hide()
                end
            end
            renders[#renders + 1] = Render
            Render(Count())

            cb:SetScript("OnEnter", function() brd._setBorder(S.borderHi or S.border) end)
            cb:SetScript("OnLeave", function() brd._setBorder(S.border) end)
            cb:SetScript("OnClick", function()
                if cb._blocked then return end
                if e.setValue then e.setValue(not (e.getValue and e.getValue())) end
                RenderAll()
            end)
            if e.tooltip or e.help then AttachTooltip(lbl, e.label, e.tooltip or e.help) end
        end
    end

    frame.Count = function() return Count() end
    self:RegisterRefresh(RenderAll)
    return frame, totalH
end

-- Searchable dropdown for long lists (spell / media pickers).
-- itemsTableOrFn -> { { key, label, tooltip }, ... } (re-evaluated on open).
-- Returns dropdownButton, refreshFn.
function F:SearchableDropdown(parent, width, frameLevel, itemsTableOrFn, getValue, setValue, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme
    local ddW = width or 220

    local region = CreateFrame("Frame", nil, parent)
    region:SetSize(ddW, T.controlH)
    if opts.point then
        region:SetPoint(opts.point, parent, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
    else
        region:SetPoint("RIGHT", parent, "RIGHT", -T.rightPad, opts.y or 0)
    end
    region:SetFrameLevel((frameLevel or parent:GetFrameLevel()) + 2)

    local dd = MakeQfxDropdownButton(region, S, ddW)

    local function Source()
        return ResolveList(itemsTableOrFn)
    end
    local function LabelFor(key)
        local src = Source()
        for i = 1, #src do
            if src[i].key == key then return src[i].label or tostring(key) end
        end
        return tostring(key or "")
    end
    local function UpdateLabel()
        local key = getValue and getValue()
        dd._label:SetText(key ~= nil and LabelFor(key) or (opts.placeholder or ""))
    end
    UpdateLabel()

    local rowH = S.menuRowH
    local maxRows = math.max(3, opts.maxVisible or 10)
    local SEARCH_H = 22
    local menuW = opts.menuWidth or ddW
    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    if menu.SetFrameLevel then menu:SetFrameLevel(200) end
    if menu.SetClampedToScreen then menu:SetClampedToScreen(true) end
    menu:EnableMouse(true)
    menu:EnableMouseWheel(true)
    menu:Hide()
    local catcher = CreateFrame("Frame", nil, UIParent)
    catcher:SetAllPoints()
    catcher:SetFrameStrata("FULLSCREEN_DIALOG")
    if catcher.SetFrameLevel then catcher:SetFrameLevel(190) end
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function() menu:Hide() end)
    menu:SetSize(menuW, SEARCH_H + rowH * maxRows + 8)
    if menu.SetScale and dd.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
        local ds, us = dd:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if ds and us and us > 0 then menu:SetScale(ds / us) end
    end
    local bg = QfxSurface(menu, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(menu, menu:GetFrameLevel(), S.border, 1, 1)

    local search = CreateFrame("EditBox", nil, menu)
    search:SetSize(menuW - 12, SEARCH_H - 4)
    search:SetPoint("TOPLEFT", menu, "TOPLEFT", 6, -4)
    search:SetAutoFocus(false)
    search:SetFont(T.font, S.textSize, "")
    search:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    search:SetTextInsets(4, 4, 0, 0)
    local searchBg = QfxSurface(search, "BACKGROUND", 0, S.controlBg)
    searchBg:SetAllPoints()
    QfxBorder(search, search:GetFrameLevel(), S.border, 1, 1)

    local rowTop = -(SEARCH_H + 4)
    local rowFrames = {}
    for i = 1, maxRows do
        local row = CreateFrame("Button", nil, menu)
        row:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, rowTop - (i - 1) * rowH)
        row:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -4, rowTop - (i - 1) * rowH)
        row:SetHeight(rowH)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(S.rowHover[1], S.rowHover[2], S.rowHover[3], S.rowHover[4])
        local check = QfxSurface(row, "ARTWORK", 0, S.accent)
        check:SetSize(8, 8)
        check:SetPoint("LEFT", row, "LEFT", 8, 0)
        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", check, "RIGHT", 6, 0)
        icon:Hide()
        local lbl = Font(row, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
        lbl:SetPoint("LEFT", check, "RIGHT", 8, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        local act = CreateFrame("Button", nil, row)
        act:SetSize(16, 16)
        act:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        local actIcon = act:CreateTexture(nil, "ARTWORK")
        actIcon:SetAllPoints()
        actIcon:Hide()
        local actText = Font(act, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
        actText:SetPoint("CENTER", act, "CENTER", 0, 0)
        actText:Hide()
        act:Hide()
        act:SetScript("OnEnter", function(self2)
            actText:SetTextColor(S.text[1], S.text[2], S.text[3], 1)
            local tip = ResolveTooltipText(row._action and row._action.tooltip)
            if tip then
                GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                GameTooltip:SetText(tip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        act:SetScript("OnLeave", function()
            actText:SetTextColor(S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
            GameTooltip:Hide()
        end)
        act:SetScript("OnClick", function()
            if row._action and row._action.onClick and row._key ~= nil then
                row._action.onClick(row._key)
            end
        end)
        row._hl, row._check, row._label = hl, check, lbl
        row._icon = icon
        row._actionBtn, row._actionIcon, row._actionText = act, actIcon, actText
        row:SetScript("OnClick", function(self2)
            if self2._kind == "item" and self2._key ~= nil and setValue then setValue(self2._key) end
            if self2._kind == "item" then
                UpdateLabel()
                menu:Hide()
            end
        end)
        row:SetScript("OnEnter", function(self2)
            local it = self2._item
            local itTip = it and ResolveTooltipText(it.tooltip)
            if itTip then
                GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                GameTooltip:SetText(it.label or tostring(it.key), 1, 1, 1)
                GameTooltip:AddLine(itTip, 1, 1, 1, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        rowFrames[i] = row
    end

    local filtered, display, offset, selIndex = {}, {}, 0, 0
    local function RefreshList()
        local q = (search:GetText() or ""):lower()
        local src = Source()
        filtered = {}
        for i = 1, #src do
            local it = src[i]
            local label = it.label or tostring(it.key)
            if q == "" or label:lower():find(q, 1, true) then
                filtered[#filtered + 1] = it
            end
        end
        display = {}
        local lastGroup
        for i = 1, #filtered do
            local it = filtered[i]
            if opts.groups ~= false and it.group ~= nil and it.group ~= lastGroup then
                display[#display + 1] = { kind = "group", label = it.group }
            end
            lastGroup = it.group
            display[#display + 1] = { kind = "item", item = it }
        end
        if offset > math.max(0, #display - maxRows) then
            offset = math.max(0, #display - maxRows)
        end
        if offset < 0 then offset = 0 end
        if selIndex >= #display then selIndex = math.max(0, #display - 1) end
        local current = getValue and getValue()
        for i = 1, maxRows do
            local row = rowFrames[i]
            local d = display[offset + i]
            if d and d.kind == "group" then
                row._kind, row._key, row._action, row._item = "group", nil, nil, nil
                row._check:Hide()
                row._icon:Hide()
                row._actionBtn:Hide()
                row._label:ClearAllPoints()
                row._label:SetPoint("LEFT", row, "LEFT", 8, 0)
                row._label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                row._label:SetTextColor(S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
                TruncateToFit(row._label, d.label or "", menuW - 24)
                row:Show()
            elseif d then
                local it = d.item
                local hasAction = it.action and true or false
                row._kind, row._key, row._action, row._item = "item", it.key, it.action, it
                row._check:Show()
                row._label:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
                row._label:ClearAllPoints()
                if it.icon then
                    row._icon:SetTexture(it.icon)
                    row._icon:Show()
                    row._label:SetPoint("LEFT", row._icon, "RIGHT", 6, 0)
                else
                    row._icon:Hide()
                    row._label:SetPoint("LEFT", row._check, "RIGHT", 8, 0)
                end
                if hasAction then
                    row._label:SetPoint("RIGHT", row._actionBtn, "LEFT", -4, 0)
                else
                    row._label:SetPoint("RIGHT", row, "RIGHT", -8, 0)
                end
                TruncateToFit(row._label, it.label or tostring(it.key),
                    menuW - 34 - (hasAction and 22 or 0) - (it.icon and 20 or 0))
                row._check:SetShown(current == it.key)
                if hasAction then
                    row._actionBtn:Show()
                    if it.action.icon then
                        row._actionIcon:SetTexture(it.action.icon)
                        row._actionIcon:Show()
                        row._actionText:Hide()
                    else
                        row._actionIcon:Hide()
                        row._actionText:SetText(it.action.text or opts.actionText or ">")
                        row._actionText:Show()
                    end
                else
                    row._actionBtn:Hide()
                end
                row:Show()
            else
                row._kind, row._key, row._action, row._item = nil, nil, nil, nil
                row:Hide()
            end
        end
    end

    local function OpenMenu()
        search:SetText("")
        offset, selIndex = 0, 0
        RefreshList()
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
        if menu.SetScale and dd.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
            local ds, us = dd:GetEffectiveScale(), UIParent:GetEffectiveScale()
            if ds and us and us > 0 then menu:SetScale(ds / us) end
        end
        if F._openMenu and F._openMenu ~= menu then F._openMenu:Hide() end
        F._openMenu = menu
        catcher:Show()
        menu:Show()
        search:SetFocus()
        menu._shown = true
    end
    dd:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() else OpenMenu() end
    end)

    search:SetScript("OnTextChanged", function()
        offset, selIndex = 0, 0
        RefreshList()
    end)
    search:SetScript("OnEscapePressed", function(self2)
        self2:ClearFocus()
        menu:Hide()
    end)
    search:SetScript("OnEnterPressed", function()
        for i = 1, #display do
            local d = display[i]
            if d.kind == "item" then
                if setValue then setValue(d.item.key) end
                UpdateLabel()
                break
            end
        end
        menu:Hide()
    end)
    menu:SetScript("OnMouseWheel", function(_, delta)
        local maxOff = math.max(0, #display - maxRows)
        offset = math.max(0, math.min(maxOff, offset - delta))
        RefreshList()
    end)
    menu:HookScript("OnHide", function(self2)
        catcher:Hide()
        if search:HasFocus() then search:ClearFocus() end
        if F._openMenu == self2 then F._openMenu = nil end
    end)
    local function CloseMenu() menu:Hide() end
    dd:HookScript("OnHide", CloseMenu)
    local host = dd:GetParent()
    if host and host.HookScript then host:HookScript("OnHide", CloseMenu) end

    dd._menu = menu
    dd._search = search
    dd._refreshList = RefreshList
    dd._openMenu = OpenMenu
    region._control = dd
    AttachTooltip(dd, nil, opts.tooltip)
    ApplyDisabled(region, dd, opts)
    F:RegisterRefresh(UpdateLabel)
    return dd, UpdateLabel
end

-- Data-driven list rows (tables / editors with several controls per row).
--   local list, h, api = W:ListRows(parent, y, {
--       items = function() return data end,       -- or a table
--       rowH = 24,
--       columns = { 120, 90, 70 },                -- optional widths
--       header  = { "Spell", "Type", "Voice" },   -- optional header labels
--       rowBuilder = function(row, item, index, api) ... build row controls ... end,
--       rowUpdate  = function(row, item, index, api) ... refresh row ... end,
--   })
--   api.Render() re-reads items, repositions rows and calls rowUpdate;
--   api.GetRow(i), api.GetCount(), api.ColumnX(i), api.ColumnW(i) are provided.
-- rowBuilder runs once per row frame (keep closures reading row._item);
-- rowUpdate runs on every Render for now visible rows.
function F:ListRows(parent, y, opts)
    opts = opts or {}
    local T = self.Theme
    local rowH = opts.rowH or 24
    local contentW = ContentWidth(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local columns = opts.columns or {}
    local colX, colW = {}, {}
    local cx = 0
    for i = 1, #columns do
        local c = columns[i]
        local w = (type(c) == "table" and c.width) or c
        colX[i], colW[i] = cx, w
        cx = cx + (tonumber(w) or 0) + (opts.columnGap or 8)
    end

    local headerH = 0
    local header
    if opts.header then
        headerH = opts.headerH or 20
        header = CreateFrame("Frame", nil, frame)
        header:SetSize(contentW, headerH)
        header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        for i = 1, #opts.header do
            local lbl = Font(header, T.labelSize, 0.62, 0.83, 1, 1)
            lbl:SetPoint("LEFT", header, "LEFT", colX[i] or 0, 0)
            lbl:SetText(tostring(opts.header[i] or ""))
        end
    end

    local rows = {}
    local currentCount = 0
    local api = {
        GetRow = function(_, i) return rows[i] end,
        GetCount = function() return currentCount end,
        ColumnX = function(_, i) return colX[i] or 0 end,
        ColumnW = function(_, i) return colW[i] end,
        Render = function() end,
    }
    local function Render()
        local src = (type(opts.items) == "function" and opts.items()) or opts.items or {}
        currentCount = #src
        for i = 1, math.max(#src, #rows) do
            local row, item = rows[i], src[i]
            if item and not row then
                row = CreateFrame("Frame", nil, frame)
                row:SetSize(contentW, rowH)
                RowBg(row, frame, self)
                row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -headerH - (i - 1) * rowH - 2)
                rows[i] = row
                if opts.rowBuilder then opts.rowBuilder(row, item, i, api) end
            end
            if row then
                row._item, row._index = item, i
                if item then
                    row:Show()
                    if opts.rowUpdate then opts.rowUpdate(row, item, i, api) end
                else
                    row:Hide()
                end
            end
        end
        frame:SetSize(contentW, headerH + #src * rowH + 4)
    end
    api.Render = function() Render() end
    Render()
    return frame, frame:GetHeight(), api
end

-- Drag-to-reorder list (the shared QFX drag language: 3px drag threshold,
-- orange insertion line, cursor ghost, locked rows cannot be picked up).
-- Rows may carry an icon (with optional texcoords), a label, a sub-label and an
-- inline edit box; the zebra wash carries the rows.
--   opts = {
--       items = table | function -> {
--           { key, label, sub, icon, coords, locked, tooltip,
--             edit = { getValue, setValue, tooltip, placeholder, width } }, ... },
--       onChange(keys),   -- new key order after a drop
--       rowH = 24, gap = 2, disabled, editWidth,
--   }
-- Returns frame, height, api (api.Render() re-reads items).
-- Cog button + popup settings for one row. opts = { title, rows = {...DualRow
-- left cfgs...}, width, onReset, resetText, size, x, y }. Returns cog, openFn.
function F:Cog(anchor, opts)
    opts = opts or {}
    local S = self:Tokens()
    local T = self.Theme

    local btn = CreateFrame("Button", nil, anchor)
    local sz = opts.size or 16
    btn:SetSize(sz, sz)
    if opts.point then
        btn:SetPoint(opts.point, anchor, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
    else
        btn:SetPoint("RIGHT", anchor, "RIGHT", opts.x or -T.rightPad, opts.y or 0)
    end
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    icon:SetDesaturated(true)
    btn:SetAlpha(0.45)
    btn:SetScript("OnEnter", function(self2) self2:SetAlpha(0.85) end)
    btn:SetScript("OnLeave", function(self2) if not (opts.keepAlpha) then self2:SetAlpha(0.45) end end)

    local popup = CreateFrame("Frame", nil, UIParent)
    popup:SetFrameStrata("FULLSCREEN_DIALOG")
    if popup.SetFrameLevel then popup:SetFrameLevel(200) end
    if popup.SetClampedToScreen then popup:SetClampedToScreen(true) end
    popup:EnableMouse(true)
    popup:Hide()
    local popupW = opts.width or 250
    popup:SetSize(popupW, 20)
    if popup.SetScale and btn.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
        local ds, us = btn:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if ds and us and us > 0 then popup:SetScale(ds / us) end
    end
    local bg = QfxSurface(popup, "BACKGROUND", 0, S.menuBg)
    bg:SetAllPoints()
    QfxBorder(popup, popup:GetFrameLevel(), S.border, 1, 1)
    if opts.title then
        local title = Font(popup, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        title:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -8)
        title:SetText(opts.title)
    end

    self._rowCounts[popup] = 0
    local py = -28
    if opts.rows then
        for i = 1, #opts.rows do
            local row, h = self:DualRow(popup, py, opts.rows[i], nil)
            py = py - h
        end
    end
    if opts.onReset then
        local _, h = self:WideButton(popup, opts.resetText or "Reset", py - 2, function()
            opts.onReset()
            self:Refresh()
        end)
        py = py - h
    end
    popup:SetHeight(math.abs(py) + 8)

    local function Open()
        popup:ClearAllPoints()
        popup:SetPoint("TOPRIGHT", btn, "BOTTOMLEFT", 0, 4)
        if popup.SetScale and btn.GetEffectiveScale and UIParent and UIParent.GetEffectiveScale then
            local ds, us = btn:GetEffectiveScale(), UIParent:GetEffectiveScale()
            if ds and us and us > 0 then popup:SetScale(ds / us) end
        end
        popup:Show()
        self:Refresh()
    end
    btn:SetScript("OnClick", function()
        if popup:IsShown() then popup:Hide() else Open() end
    end)
    popup:RegisterEvent("GLOBAL_MOUSE_DOWN")
    popup:SetScript("OnEvent", function(self2)
        if not self2:IsShown() then return end
        local focus = GetMouseFocus and GetMouseFocus() or nil
        if focus and (IsDescendantOf(focus, self2) or IsDescendantOf(focus, btn)) then return end
        self2:Hide()
    end)
    popup:HookScript("OnHide", function() if not opts.keepAlpha then btn:SetAlpha(0.45) end end)
    btn:HookScript("OnHide", function() popup:Hide() end)
    if anchor.HookScript then anchor:HookScript("OnHide", function() popup:Hide() end) end

    return btn, Open
end

-------------------------------------------------------------------------------
-- Scrollable page (self-drawn scrollbar: wheel + thumb drag, no templates)
-------------------------------------------------------------------------------
-- Standard flow:
--   local page = W:ScrollPage(parent)              -- or { width, height }
--   local y = -W.Theme.pad
--   ... build rows into page.content, decreasing y ...
--   page:SetContentHeight(-y + W.Theme.pad)
-- page.frame is the container (anchor it yourself unless opts.point given);
-- page.content is the frame rows are built into; the scrollbar hides itself
-- when everything fits. opts: { width, height, point, relPoint, x, y, padding,
-- barWidth, scrollStep, onScroll(offset, maxOffset) }.
-- Scrollable page (real scroll frame -> content is CLIPPED to the page; the
-- scrollbar itself is self-drawn: wheel + thumb drag, no templates).
-------------------------------------------------------------------------------
-- Standard flow:
--   local page = W:ScrollPage(parent)              -- or { width, height }
--   local y = -W.Theme.pad
--   ... build rows into page.content, decreasing y ...
--   page:SetContentHeight(-y + W.Theme.pad)
-- page.frame is the container (anchor it yourself unless opts.point given);
-- page.content is the frame rows are built into; the scrollbar hides itself
-- when everything fits (opts.reserveBar keeps its width reserved so row widths
-- never change). opts: { width, height, point, relPoint, x, y, padding,
-- barWidth, scrollStep, reserveBar, onScroll(offset, maxOffset) }.
function F:ScrollPage(parent, opts)
    opts = opts or {}
    local T = self.Theme
    local S = self:Tokens()
    local barW = opts.barWidth or 4
    local step = opts.scrollStep or 40
    local reserveBar = opts.reserveBar and true or false

    local holder = CreateFrame("Frame", nil, parent)
    if opts.width and opts.height then
        holder:SetSize(opts.width, opts.height)
    else
        holder:SetAllPoints(parent)
    end
    if opts.point then
        holder:SetPoint(opts.point, parent, opts.relPoint or opts.point, opts.x or 0, opts.y or 0)
    end
    holder:EnableMouseWheel(true)
    holder._qfx = "scrollPage"

    local viewport = CreateFrame("ScrollFrame", nil, holder)
    viewport:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    local content = CreateFrame("Frame", nil, viewport)
    content:SetPoint("TOPLEFT", viewport, "TOPLEFT", 0, 0)
    if viewport.SetScrollChild then viewport:SetScrollChild(content) end

    local bar = CreateFrame("Frame", nil, holder)
    bar:SetWidth(barW)
    bar:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 0)
    local barBg = QfxSurface(bar, "BACKGROUND", 0, S.controlBg)
    barBg:SetAllPoints()
    local thumb = CreateFrame("Button", nil, bar)
    thumb:SetWidth(barW)
    local thumbTex = QfxSurface(thumb, "ARTWORK", 0, S.border)
    thumbTex:SetAllPoints()
    thumb:SetScript("OnEnter", function() thumbTex:SetColorTexture(S.borderHi[1], S.borderHi[2], S.borderHi[3], S.borderHi[4] or 1) end)
    thumb:SetScript("OnLeave", function() thumbTex:SetColorTexture(S.border[1], S.border[2], S.border[3], S.border[4] or 1) end)
    bar:Hide()

    local offset, maxOffset, contentH, viewH = 0, 0, 0, 0

    local function Layout()
        local w = holder:GetWidth() or 0
        viewH = holder:GetHeight() or 0
        maxOffset = math.max(0, contentH - viewH)
        local barShown = maxOffset > 0.5
        bar:SetShown(barShown)
        local innerW = w - ((barShown or reserveBar) and (barW + 2) or 0)
        viewport:SetSize(math.max(1, innerW), math.max(1, viewH))
        content:SetSize(math.max(1, innerW), math.max(1, contentH))
        if offset > maxOffset then offset = maxOffset end
        if offset < 0 then offset = 0 end
        offset = floor(offset + 0.5) -- whole-pixel scroll: no shaved edge at the clip line
        if viewport.SetVerticalScroll then viewport:SetVerticalScroll(offset) end
        if barShown then
            local thumbH = math.max(24, viewH * (viewH / contentH))
            thumb:SetHeight(math.min(viewH, thumbH))
            local travel = math.max(0, viewH - thumb:GetHeight())
            local ratio = (maxOffset > 0) and (offset / maxOffset) or 0
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -travel * ratio)
        end
    end

    local function ScrollTo(v)
        offset = math.max(0, math.min(v or 0, maxOffset))
        Layout()
        if opts.onScroll then opts.onScroll(offset, maxOffset) end
    end

    holder:SetScript("OnMouseWheel", function(_, delta)
        if maxOffset <= 0 then return end
        ScrollTo(offset - delta * step)
    end)
    holder:SetScript("OnSizeChanged", Layout)
    holder:SetScript("OnShow", Layout)

    local dragging, dragY, dragOffset
    local UpdateThumb
    local function StopThumbDrag()
        dragging = false
        thumb:SetScript("OnUpdate", nil)
    end
    thumb:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or maxOffset <= 0 then return end
        dragging, dragY, dragOffset = true, select(2, GetCursorPosition()), offset
        thumb:SetScript("OnUpdate", UpdateThumb)
    end)
    UpdateThumb = function()
        if not dragging then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then StopThumbDrag() return end
        local _, cy = GetCursorPosition()
        local scale = thumb:GetEffectiveScale() or 1
        local travel = viewH - (thumb:GetHeight() or 0)
        if travel <= 0 then return end
        ScrollTo(dragOffset + ((dragY - cy) / scale) * (maxOffset / travel))
    end
    thumb:SetScript("OnMouseUp", StopThumbDrag)
    thumb:SetScript("OnHide", StopThumbDrag)

    Layout()
    return {
        frame = holder,
        content = content,
        viewport = viewport,
        scrollBar = bar,
        thumb = thumb,
        ScrollTo = function(_, v) return ScrollTo(v) end,
        GetOffset = function() return offset end,
        GetMaxOffset = function() return maxOffset end,
        SetContentHeight = function(_, h)
            contentH = h or 0
            content:SetHeight(math.max(contentH, viewH))
            Layout()
        end,
        Refresh = Layout,
    }
end

-------------------------------------------------------------------------------
-- Multiline text box (import / export / long text, self-drawn frame)
-------------------------------------------------------------------------------
-- F:MultilineBox(parent, y, cfg) -> frame, height
-- cfg = { label, hint, height = 120, rows, text?, getValue, setValue, readOnly,
-- maxLetters, commitOnEnter, selectAllOnFocus (default true), onCommit }
-- frame:GetText() / frame:SetText(v) / frame:Commit() are provided.
function F:MultilineBox(parent, y, cfg)
    cfg = cfg or {}
    local S = self:Tokens()
    local T = self.Theme
    local boxH = cfg.height or ((cfg.rows and (cfg.rows * 14 + 10)) or 120)
    local hasLabel, hasHint = cfg.label and true or false, cfg.hint and true or false
    local totalH = boxH + (hasLabel and 18 or 0) + (hasHint and 16 or 0) + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local top = 0
    if hasLabel then
        local lbl = Font(frame, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
        lbl:SetPoint("TOPLEFT", frame, "TOPLEFT", T.sidePad, 0)
        lbl:SetText(cfg.label)
        top = -18
    end

    local box = CreateFrame("EditBox", nil, frame)
    box:SetSize(ContentWidth(frame) - T.sidePad * 2, boxH)
    box:SetPoint("TOPLEFT", frame, "TOPLEFT", T.sidePad, top - 2)
    box:SetMultiLine(true)
    box:SetAutoFocus(false)
    if box.SetMaxLetters then box:SetMaxLetters(cfg.maxLetters or 0) end
    if box.SetJustifyV then box:SetJustifyV("TOP") end
    local bg = QfxSurface(box, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(box, box:GetFrameLevel(), S.border, 1, 1)
    box:SetFont(T.font, S.textSize, "")
    box:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4])
    box:SetJustifyH("LEFT")
    box:SetTextInsets(6, 6, 4, 4)

    local function Read()
        local v = cfg.getValue and cfg.getValue() or cfg.text or ""
        return tostring(v or "")
    end
    local function Commit()
        if cfg.readOnly then return end
        local text = box:GetText() or ""
        if cfg.setValue then cfg.setValue(text) end
        if cfg.onCommit then cfg.onCommit(text) end
    end
    box:SetText(Read())
    if cfg.readOnly then
        box:SetScript("OnChar", function() end)
    end
    box:SetScript("OnEnterPressed", function(self2)
        if cfg.commitOnEnter then
            self2:ClearFocus()
        end
    end)
    box:SetScript("OnEscapePressed", function(self2)
        self2:SetText(Read())
        self2._qfxCancelFocusCommit = true
        self2:ClearFocus()
    end)
    box:SetScript("OnEditFocusGained", function(self2)
        brd._setBorder(S.borderHi or S.border)
        if cfg.selectAllOnFocus ~= false and (cfg.readOnly or cfg.selectAllOnFocus) and self2.HighlightText then
            self2:HighlightText()
        end
    end)
    box:SetScript("OnEditFocusLost", function()
        brd._setBorder(S.border)
        if box._qfxCancelFocusCommit then
            box._qfxCancelFocusCommit = nil
        else
            Commit()
        end
        if not cfg.readOnly then box:SetText(Read()) end
    end)

    if hasHint then
        local hint = Font(frame, S.textSize - 1, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        hint:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 2, -3)
        hint:SetText(cfg.hint)
    end

    AttachTooltip(frame, cfg.label or cfg.text, cfg.tooltip)
    frame._box = box
    frame.GetText = function() return box:GetText() end
    frame.SetText = function(_, v) box:SetText(tostring(v or "")) end
    frame.Commit = function() Commit() end
    F:RegisterRefresh(function()
        if not box:HasFocus() then box:SetText(Read()) end
    end)
    return frame, totalH
end

-------------------------------------------------------------------------------
-- Confirmation dialog (self-drawn, Esc / backdrop click cancels)
-------------------------------------------------------------------------------
-- W:Confirm(opts) or W:Confirm("text") -> dialog
-- opts = { title, text, acceptText, cancelText, onAccept, onCancel, width,
-- danger = true (red accept button), reuse = previousDialog }. dialog:Close() hides it.
InstallReusableConfirm(F)

-------------------------------------------------------------------------------
-- SharedMedia helpers (LibSharedMedia-3.0 loaded by any host; all optional)
-------------------------------------------------------------------------------
-- W:LSM() -> media object or nil
-- W:MediaList(kind) -> sorted { { key = name, label = name }, ... }
--   kind: "sound" | "font" | "statusbar" | "background" | "border"
--   Feed MediaList straight into W:SearchableDropdown / values + order.
-- W:MediaValues(kind) -> values, order (for { type = "dropdown" } cfgs)
-- W:FetchMedia(kind, name) -> path | nil (SetFont / SetTexture / PlaySoundFile)
-- W:PreviewSound(name, channel) -> bool (plays a SharedMedia sound)
function F:LSM()
    if type(self._lsm) == "table" then return self._lsm end
    local ok, media = false, nil
    if LibStub then ok, media = pcall(LibStub, "LibSharedMedia-3.0", true) end
    if ok and media then
        self._lsm = media
        return media
    end
    -- Do not negative-cache: another addon may load LibSharedMedia later.
    self._lsm = nil
    return nil
end

function F:MediaList(kind)
    local media = self:LSM()
    local out, seen = {}, {}
    if media and media.HashTable then
        local ok, tbl = pcall(media.HashTable, media, kind)
        if ok and type(tbl) == "table" then
            for name in pairs(tbl) do
                if not seen[name] then
                    seen[name] = true
                    out[#out + 1] = { key = name, label = name }
                end
            end
        end
    end
    if media and media.List then
        local ok, names = pcall(media.List, media, kind)
        if ok and type(names) == "table" then
            for i = 1, #names do
                local name = names[i]
                if name and not seen[name] then
                    seen[name] = true
                    out[#out + 1] = { key = name, label = name }
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

function F:MediaValues(kind)
    local list = self:MediaList(kind)
    local values, order = {}, {}
    for i = 1, #list do
        values[list[i].key] = list[i].label
        order[i] = list[i].key
    end
    return values, order
end

function F:FetchMedia(kind, name)
    local media = self:LSM()
    if not (media and media.Fetch and name and name ~= "") then return nil end
    local ok, path = pcall(media.Fetch, media, kind, name)
    if ok and path and path ~= "" then return path end
    return nil
end

function F:PreviewSound(name, channel)
    local path = self:FetchMedia("sound", name) or (name ~= "" and name or nil)
    if path and PlaySoundFile then
        local ok, played = pcall(PlaySoundFile, path, channel or "Master")
        return ok and played ~= false
    end
    return false
end

-------------------------------------------------------------------------------
-- Icon picker (icon button + searchable dropdown with per-row icons)
-------------------------------------------------------------------------------
-- W:IconPicker(parent, frameLevel, getValue, setValue, opts)
--   -> button, refreshFn. opts = { items = table|function (as SearchableDropdown,
--   each item may carry .icon), width, size, tooltip, placeholder }.
-- W:SpellIconItems(list) -> items from { id | { id, label }, ... } using the
--   spell texture of each id (falls back to the question mark icon).
function F:SpellIconItems(list)
    local out = {}
    for i = 1, #(list or {}) do
        local e = list[i]
        local id = type(e) == "table" and (e.id or e.key) or e
        local label = type(e) == "table" and (e.label or tostring(id)) or tostring(id)
        local icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id))
            or (GetSpellTexture and GetSpellTexture(id))
            or "Interface\\ICONS\\INV_Misc_QuestionMark"
        out[i] = { key = id, label = label, icon = icon }
    end
    return out
end

function F:IconPicker(parent, frameLevel, getValue, setValue, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local dd = self:SearchableDropdown(parent, opts.width or 240, frameLevel, opts.items, getValue, setValue, opts)
    local holder = dd:GetParent()

    local sz = opts.size or 20
    local btn = CreateFrame("Button", nil, holder)
    btn:SetSize(sz, sz)
    btn:SetPoint("RIGHT", holder, "RIGHT", -T.rightPad, 0)
    local bg = QfxSurface(btn, "BACKGROUND", 0, S.controlBg)
    bg:SetAllPoints()
    local brd = QfxBorder(btn, btn:GetFrameLevel(), S.border, 1, 1)
    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:Hide()
    local fallback = Font(btn, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], 1)
    fallback:SetPoint("CENTER", btn, "CENTER", 0, 0)
    fallback:SetText("?")

    local function Update()
        local key = getValue and getValue()
        local src = ResolveList(opts.items)
        local icon
        for i = 1, #src do
            if src[i].key == key then icon = src[i].icon end
        end
        if icon then
            tex:SetTexture(icon)
            tex:Show()
            fallback:Hide()
        else
            tex:Hide()
            fallback:Show()
        end
    end
    Update()

    btn:SetScript("OnClick", function() dd._openMenu() end)
    btn:SetScript("OnEnter", function(self2)
        brd._setBorder(S.borderHi or S.border)
        local tip = ResolveTooltipText(opts.tooltip)
        if tip then
            GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
            GameTooltip:SetText(tip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        brd._setBorder(S.border)
        GameTooltip:Hide()
    end)

    btn._tex, btn._fallback, btn._dropdown = tex, fallback, dd
    dd:Hide() -- the icon button is the opener; the menu still anchors to dd
    F:RegisterRefresh(Update)
    return btn, Update
end

-------------------------------------------------------------------------------
-- Status row (dynamic text, optional label + color)
-------------------------------------------------------------------------------
-- W:StatusRow(parent, y, opts) -> frame, height
-- opts = { label, getText (string|function), color (table|function),
--          wrap, height }. Refreshed by W:Refresh(); frame:Update() forces one.
function F:StatusRow(parent, y, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local h = opts.height or 18
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local x = T.sidePad
    if opts.label then
        local lbl = Font(frame, T.labelSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        lbl:SetPoint("LEFT", frame, "LEFT", x, 0)
        lbl:SetText(opts.label)
        local lw = lbl.GetStringWidth and lbl:GetStringWidth() or nil
        if IsSecret(lw) or not lw then lw = #tostring(opts.label) * 8 end
        x = x + lw + 8
    end
    local val = Font(frame, S.textSize, S.text[1], S.text[2], S.text[3], S.text[4])
    val:SetPoint("LEFT", frame, "LEFT", x, 0)
    val:SetPoint("RIGHT", frame, "RIGHT", -T.rightPad, 0)
    val:SetJustifyH("LEFT")
    if opts.wrap then
        if val.SetWordWrap then val:SetWordWrap(true) end
    else
        if val.SetWordWrap then val:SetWordWrap(false) end
        if val.SetMaxLines then val:SetMaxLines(1) end
    end

    local function Update()
        local text = opts.getText
        if type(text) == "function" then text = text() end
        val:SetText(tostring(text or ""))
        local c = opts.color
        if type(c) == "function" then c = c() end
        if c then
            val:SetTextColor(c[1], c[2], c[3], c[4] or 1)
        else
            val:SetTextColor(S.text[1], S.text[2], S.text[3], S.text[4] or 1)
        end
    end
    Update()
    frame._value = val
    frame._qfx = "statusRow"
    frame._refresh = Update
    frame.Update = function() Update() end
    F:RegisterRefresh(Update)
    return frame, h
end

-------------------------------------------------------------------------------
-- Full-width slider row (label above the track, editable value box right)
-------------------------------------------------------------------------------
-- W:Slider(parent, y, cfg) -> frame, height. Same cfg fields as
-- { type = "slider" } (min, max, step, getValue, setValue, valueSuffix,
-- steppers, tooltip, disabled, disabledTooltip, trackWidth) plus:
--   cfg.label (defaults to cfg.text) and cfg.height.
-- Use it for long labels or full-width fine tuning; DualRow sliders stay
-- available for compact two-column pages.
function F:Slider(parent, y, cfg)
    cfg = cfg or {}
    local S, T = self:Tokens(), self.Theme
    -- inline min/max only need a control-height band; the stacked variant keeps
    -- the taller default
    local h = cfg.height or (cfg.labelsBelow == true and 58 or 46)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    RowBg(frame, parent, self)

    local label = Font(frame, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", T.sidePad, -2)
    label:SetText(cfg.label or cfg.text or "")

    local region = CreateFrame("Frame", nil, frame)
    region:SetSize(ContentWidth(parent), h - 18)
    region:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -18)
    region._label = label
    QfxSlider(region, frame, cfg)
    return frame, h
end

-------------------------------------------------------------------------------
-- Color grid (per-cell color swatches with labels, groups optional)
-------------------------------------------------------------------------------
-- W:ColorGrid(parent, y, columns, entries, opts) -> frame, height, countFn
-- entries = { { label, getValue -> r,g,b[,a], setValue(r,g,b[,a]), tooltip,
--   group, alpha, disabled, disabledTooltip }, ... }. Like CheckGrid but each
-- cell is a color swatch that opens the picker.
function F:ColorGrid(parent, y, columns, entries, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local cols = math.max(1, tonumber(columns) or 2)
    local contentW = ContentWidth(parent)
    local gap = opts.gap or 12
    local cellW = floor((contentW - gap * (cols - 1)) / cols)
    local cellH = opts.rowH or 22
    local groupH = opts.groupH or 20
    entries = entries or {}

    local layout, yOff, col = {}, 0, 0
    local lastGroup
    for i = 1, #entries do
        local e = entries[i]
        if e.group ~= nil and e.group ~= lastGroup then
            lastGroup = e.group
            if col ~= 0 then yOff = yOff + cellH; col = 0 end
            layout[#layout + 1] = { kind = "group", label = e.group, top = yOff }
            yOff = yOff + groupH
        end
        layout[#layout + 1] = { kind = "cell", entry = e, col = col, top = yOff }
        col = col + 1
        if col >= cols then col = 0; yOff = yOff + cellH end
    end
    local totalH = yOff + (col > 0 and cellH or 0) + 4

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(contentW, totalH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)

    local swatches = {}
    for i = 1, #layout do
        local item = layout[i]
        if item.kind == "group" then
            local gl = Font(frame, T.labelSize, S.sectionText[1], S.sectionText[2], S.sectionText[3], 1)
            gl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -item.top - 2)
            gl:SetText(tostring(item.label or ""))
        else
            local e = item.entry
            local cell = CreateFrame("Frame", nil, frame)
            cell:SetSize(cellW, cellH)
            cell:SetPoint("TOPLEFT", frame, "TOPLEFT", item.col * (cellW + gap), -item.top - 2)
            local sw = MakeQfxColorSwatch(cell, 16, e.getValue, e.setValue, { alpha = e.alpha })
            sw:SetPoint("LEFT", cell, "LEFT", 0, 0)
            swatches[#swatches + 1] = sw
            local lbl = Font(cell, T.labelSize, S.text[1], S.text[2], S.text[3], S.text[4])
            lbl:SetPoint("LEFT", sw, "RIGHT", 6, 0)
            lbl:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
            lbl:SetJustifyH("LEFT")
            TruncateToFit(lbl, e.label or e.text or "", cellW - 26)
            if e.tooltip or e.help then AttachTooltip(lbl, e.label, e.tooltip or e.help) end
            if e.disabled or e.disabledTooltip then
                local disabled, tip = e.disabled, e.disabledTooltip
                local block
                local function RefreshDisabled()
                    local off = EvalFlag(disabled)
                    if not block then
                        block = CreateFrame("Frame", nil, cell)
                        block:SetAllPoints()
                        block:SetFrameLevel(cell:GetFrameLevel() + 8)
                        block:EnableMouse(true)
                        block:Hide()
                        if tip then
                            block:SetScript("OnEnter", function(self2)
                                local reason = ResolveTooltipText(tip)
                                if reason then
                                    GameTooltip:SetOwner(self2, "ANCHOR_RIGHT")
                                    GameTooltip:SetText(reason, 1, 1, 1, 1, true)
                                    GameTooltip:Show()
                                end
                            end)
                            block:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        end
                    end
                    sw:SetAlpha(off and 0.35 or 1)
                    lbl:SetAlpha(off and 0.35 or 1)
                    block:SetShown(off)
                end
                self:RegisterRefresh(RefreshDisabled)
                RefreshDisabled()
            end
        end
    end
    F:RegisterRefresh(function()
        for i = 1, #swatches do swatches[i]._update() end
    end)
    return frame, totalH, function() return #swatches end
end

-------------------------------------------------------------------------------
-- Reset row ("Reset this page" style buttons on the right, optional label)
-------------------------------------------------------------------------------
-- W:ResetRow(parent, y, opts) -> frame, height
-- opts = { label, buttons = { { text, onReset, confirm, confirmText, danger }, ... },
--          buttonText, onReset, confirm, confirmText, width }
-- Rightmost button is the last entry. confirm = true asks W:Confirm first.
function F:ResetRow(parent, y, opts)
    opts = opts or {}
    local S, T = self:Tokens(), self.Theme
    local h = (T.wideButtonH or 34) + 6
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ContentWidth(parent), h)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", T.pad, y)
    RowBg(frame, parent, self)

    if opts.label then
        local lbl = Font(frame, S.textSize, S.textMuted[1], S.textMuted[2], S.textMuted[3], S.textMuted[4])
        lbl:SetPoint("LEFT", frame, "LEFT", T.sidePad, 0)
        lbl:SetText(opts.label)
    end

    local specs = opts.buttons or { { text = opts.buttonText or "Reset", onReset = opts.onReset,
        confirm = opts.confirm, confirmText = opts.confirmText, danger = opts.danger } }
    local xOff = -T.rightPad
    local made = {}
    for i = #specs, 1, -1 do
        local spec = specs[i]
        local btn = CreateFrame("Button", nil, frame)
        local bw = spec.width or opts.width or 116
        btn:SetSize(bw, S.buttonH or 20)
        btn:SetPoint("RIGHT", frame, "RIGHT", xOff, 0)
        xOff = xOff - bw - 6
        local base = spec.danger and S.danger or (S.buttonBg or S.controlBg)
        local bg = QfxSurface(btn, "BACKGROUND", 0, base)
        bg:SetAllPoints()
        local brd = QfxBorder(btn, btn:GetFrameLevel(), S.buttonBorder or S.border, 1, 1)
        local lbl = Font(btn, S.textSize, 0.98, 0.99, 1, 1)
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(spec.text or "Reset")
        btn:SetScript("OnEnter", function()
            bg:SetColorTexture(base[1] * 1.25, base[2] * 1.25, base[3] * 1.25, base[4] or 1)
            brd._setBorder(S.borderHi or S.border)
        end)
        btn:SetScript("OnLeave", function()
            bg:SetColorTexture(base[1], base[2], base[3], base[4] or 1)
            brd._setBorder(S.buttonBorder or S.border)
        end)
        btn:SetScript("OnClick", function()
            local function Run()
                if spec.onReset then spec.onReset() end
                self:Refresh()
            end
            if spec.confirm then
                self:Confirm({
                    title = spec.confirmTitle or spec.text or "Reset",
                    text = spec.confirmText or "Are you sure?",
                    acceptText = spec.acceptText, cancelText = spec.cancelText,
                    danger = true, onAccept = Run,
                })
            else
                Run()
            end
        end)
        if spec.tooltip then AttachTooltip(btn, spec.text, spec.tooltip) end
        btn._label = lbl
        made[#made + 1] = btn
    end
    frame._buttons = made
    frame._qfx = "resetRow"
    return frame, h
end

-- Install after all shared drawing, token and refresh helpers are available.
InstallAddonToggle(F)

InstallMotion(F)
InstallSpeechBubble(F)
InstallStatusTicker(F)
InstallBrandImages(F)

InstallDetachedControls(F)

InstallIconButton(F)

InstallCopyDialog(F)

InstallDynamicReorder(F)

InstallContentInput(F)

InstallCloseButton(F)
