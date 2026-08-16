local _, addon = ...

local Animations = {
    sections = {},
    actionButtons = {},
    chromeButtons = {},
    actionLookup = {},
    actionOrder = {},
    favoriteButtons = {},
    favoriteStars = {},
}
addon:RegisterModule("Animations", Animations)

local FRAME_WIDTH = 540
local FRAME_HEIGHT = 360
local HEADER_HEIGHT = 30
local ROW_HEIGHT = 27
-- Der Scrollbereich ist 480 Pixel breit. Der bewusst kleinere Inhalt lässt
-- rechts 12 Pixel Innenabstand und insgesamt 22 Pixel bis zur Scrollleiste.
local CONTENT_WIDTH = 468
local BUTTON_WIDTH = 226
local PANEL_TEXTURE = "Interface\\AddOns\\Kitar_Companion\\Media\\PanelBackgroundModern"
local STAR_EMPTY = "Interface\\AddOns\\Kitar_Companion\\Media\\StarEmpty"
local STAR_FILLED = "Interface\\AddOns\\Kitar_Companion\\Media\\StarFilled"
local ROUND_FILL = "Interface\\AddOns\\Kitar_Companion\\Media\\RoundedCornerFill"
local ROUND_BORDER = "Interface\\AddOns\\Kitar_Companion\\Media\\RoundedCornerBorder"
local ICON_RESET = "Interface\\AddOns\\Kitar_Companion\\Media\\IconReset"
local ICON_MINIMIZE = "Interface\\AddOns\\Kitar_Companion\\Media\\IconMinimize"
local ICON_EXPAND = "Interface\\AddOns\\Kitar_Companion\\Media\\IconExpand"
local ICON_CLOSE = "Interface\\AddOns\\Kitar_Companion\\Media\\IconClose"
local ANIMATION_FLAG_MALE = 0x0001
local ANIMATION_FLAG_FEMALE = 0x0002
local ANIMATION_FLAG_HUMAN_FORM = 0x0004
local ANIMATION_FLAG_WORGEN_FORM = 0x0008
local MIN_SERVER_ANIMATION_COMMANDS = 50

local BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

local EDGE_BACKDROP = {
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

local function createRoundedPanel(frame, radius)
    local rounded = {
        fills = {},
        borders = {},
    }

    local horizontal = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
    horizontal:SetPoint("TOPLEFT", frame, "TOPLEFT", radius, 0)
    horizontal:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -radius, 0)
    horizontal:SetColorTexture(1, 1, 1, 1)
    rounded.fills[#rounded.fills + 1] = horizontal

    local vertical = frame:CreateTexture(nil, "BACKGROUND", nil, -4)
    vertical:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -radius)
    vertical:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, radius)
    vertical:SetColorTexture(1, 1, 1, 1)
    rounded.fills[#rounded.fills + 1] = vertical

    local corners = {
        { "TOPLEFT", 0, 1, 0, 1 },
        { "TOPRIGHT", 1, 0, 0, 1 },
        { "BOTTOMLEFT", 0, 1, 1, 0 },
        { "BOTTOMRIGHT", 1, 0, 1, 0 },
    }
    for _, corner in ipairs(corners) do
        local fill = frame:CreateTexture(nil, "BACKGROUND", nil, -3)
        fill:SetSize(radius, radius)
        fill:SetPoint(corner[1], frame, corner[1], 0, 0)
        fill:SetTexture(ROUND_FILL)
        fill:SetTexCoord(corner[2], corner[3], corner[4], corner[5])
        rounded.fills[#rounded.fills + 1] = fill

        local border = frame:CreateTexture(nil, "BORDER")
        border:SetSize(radius, radius)
        border:SetPoint(corner[1], frame, corner[1], 0, 0)
        border:SetTexture(ROUND_BORDER)
        border:SetTexCoord(corner[2], corner[3], corner[4], corner[5])
        rounded.borders[#rounded.borders + 1] = border
    end

    local top = frame:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT", frame, "TOPLEFT", radius, 0)
    top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -radius, 0)
    top:SetHeight(1)
    top:SetColorTexture(1, 1, 1, 1)
    rounded.borders[#rounded.borders + 1] = top

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", radius, 0)
    bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -radius, 0)
    bottom:SetHeight(1)
    bottom:SetColorTexture(1, 1, 1, 1)
    rounded.borders[#rounded.borders + 1] = bottom

    local left = frame:CreateTexture(nil, "BORDER")
    left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -radius)
    left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, radius)
    left:SetWidth(1)
    left:SetColorTexture(1, 1, 1, 1)
    rounded.borders[#rounded.borders + 1] = left

    local right = frame:CreateTexture(nil, "BORDER")
    right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -radius)
    right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, radius)
    right:SetWidth(1)
    right:SetColorTexture(1, 1, 1, 1)
    rounded.borders[#rounded.borders + 1] = right

    frame.rounded = rounded
end

local function setRoundedPanelColors(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    for _, texture in ipairs(frame.rounded.fills) do
        texture:SetVertexColor(bgR, bgG, bgB, bgA)
    end
    for _, texture in ipairs(frame.rounded.borders) do
        texture:SetVertexColor(borderR, borderG, borderB, borderA)
    end
end

local function canChangeProtectedState()
    if InCombatLockdown and InCombatLockdown() then
        addon:Print("Das Animationsfenster kann im Kampf nicht verändert werden.")
        return false
    end
    return true
end

local function savePosition(frame)
    local point, _, relativePoint, x, y = frame:GetPoint()
    addon.db.animations.position = {
        point = point or "CENTER",
        relativePoint = relativePoint or "CENTER",
        x = math.floor((x or 0) + 0.5),
        y = math.floor((y or 0) + 0.5),
    }
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function normalizeSlashCommand(value)
    if type(value) ~= "string" then
        return nil
    end
    local command = value:match("^%s*/?([^%s;\r\n]+)")
    return command and string.lower(command) or nil
end

local function band(left, right)
    if bit and bit.band then
        return bit.band(left, right)
    end
    if bit32 and bit32.band then
        return bit32.band(left, right)
    end

    local result = 0
    local place = 1
    left = math.max(0, math.floor(tonumber(left) or 0))
    right = math.max(0, math.floor(tonumber(right) or 0))
    while left > 0 and right > 0 do
        local leftBit = left % 2
        local rightBit = right % 2
        if leftBit == 1 and rightBit == 1 then
            result = result + place
        end
        left = math.floor(left / 2)
        right = math.floor(right / 2)
        place = place * 2
    end
    return result
end

local function callBooleanApi(apiTable, functionName)
    if type(apiTable) ~= "table" or type(apiTable[functionName]) ~= "function" then
        return nil
    end

    local ok, result = pcall(apiTable[functionName], apiTable)
    if not ok then
        ok, result = pcall(apiTable[functionName])
    end
    if ok then
        return not not result
    end
    return nil
end

local function isPlayerWorgen()
    local apiResult = callBooleanApi(rawget(_G, "C_CharacterRace"), "IsAWorgen")
    if apiResult ~= nil then
        return apiResult
    end

    if UnitRace then
        local _, raceFile = UnitRace("player")
        return type(raceFile) == "string" and string.lower(raceFile) == "worgen"
    end
    return false
end

local function getPlayerAnimationFlags()
    local sex = UnitSex and UnitSex("player") or 0
    local sexFlag = sex == 2 and ANIMATION_FLAG_MALE
        or sex == 3 and ANIMATION_FLAG_FEMALE
        or 0
    local worgen = isPlayerWorgen()
    if not worgen then
        return sexFlag, false
    end

    local inHumanForm = callBooleanApi(rawget(_G, "C_WorgenRace"), "IsInHumanForm") == true
    local formFlag = inHumanForm and ANIMATION_FLAG_HUMAN_FORM or ANIMATION_FLAG_WORGEN_FORM
    return sexFlag + formFlag, true
end

function Animations:IsActionDisabled(action)
    if type(action) ~= "table" then
        return false
    end

    local command = normalizeSlashCommand(action.macroText or action[2])
    if self.serverAvailabilityKnown
        and action.category ~= "Alltag"
        and command
        and not self.serverAvailableCommands[command] then
        return true
    end

    local disabledFlags = command
        and self.serverDisabledFlags
        and self.serverDisabledFlags[command]
        or tonumber(action.disabledFlags)
    if not disabledFlags or disabledFlags <= 0 then
        return false
    end

    local currentFlags, isWorgen = getPlayerAnimationFlags()
    if not isWorgen or currentFlags == 0 then
        return false
    end
    return band(currentFlags, disabledFlags) == currentFlags
end

function Animations:BuildActionLookup()
    self.actionLookup = {}
    self.actionOrder = {}

    for categoryIndex, category in ipairs(addon.AnimationCategories) do
        for actionIndex, action in ipairs(category.actions) do
            local actionId = categoryIndex .. ":" .. actionIndex
            local entry = {
                id = actionId,
                label = action[1],
                macroText = action[2],
                category = category.name,
                disabledFlags = action.disabledFlags,
            }
            action.id = actionId
            action.category = category.name
            self.actionLookup[actionId] = entry
            self.actionOrder[#self.actionOrder + 1] = entry
        end
    end
end

function Animations:HandleServerAnimationData(animationData)
    local categories = type(animationData) == "table" and animationData.animationsByCategory
    if type(categories) ~= "table" then
        return false
    end

    local availableCommands = {}
    local disabledFlags = {}
    local commandCount = 0
    for _, categoryEntries in pairs(categories) do
        if type(categoryEntries) == "table" then
            for _, serverAction in pairs(categoryEntries) do
                if type(serverAction) == "table" then
                    local command = normalizeSlashCommand(serverAction.slashCommand)
                    if command then
                        if not availableCommands[command] then
                            availableCommands[command] = true
                            commandCount = commandCount + 1
                        end
                        local flags = tonumber(serverAction.disabledFlags)
                        if flags and flags > 0 then
                            disabledFlags[command] = flags
                        end
                    end
                end
            end
        end
    end

    if commandCount < MIN_SERVER_ANIMATION_COMMANDS then
        return false
    end

    self.serverAvailableCommands = availableCommands
    self.serverDisabledFlags = disabledFlags
    self.serverAvailabilityKnown = true
    self.serverCatalogSize = commandCount
    self:RefreshActionAvailability()
    return true
end

function Animations:RegisterServerAvailabilityHandler()
    if self.serverAvailabilityHandlerRegistered then
        return true
    end

    local slops = rawget(_G, "C_Slops")
    local responseCode = rawget(_G, "SLOPS_SMSG_ANIMATIONS_LIST_RESPONSE")
    if type(slops) ~= "table"
        or type(slops.AddMessageHandler) ~= "function"
        or responseCode == nil then
        return false
    end

    local ok = pcall(slops.AddMessageHandler, responseCode, function(animationData)
        Animations:HandleServerAnimationData(animationData)
    end)
    if not ok then
        return false
    end

    self.serverAvailabilityHandlerRegistered = true
    return true
end

function Animations:IsFavorite(actionId)
    return addon.db.animations.favorites[actionId] == true
end

function Animations:UpdateScrollBar()
    if not self.scroll or not self.scrollTrack or not self.scrollThumb then
        return
    end

    local range = self.scroll:GetVerticalScrollRange() or 0
    local trackHeight = self.scrollTrack:GetHeight() or 0
    local viewHeight = self.scroll:GetHeight() or 0
    local contentHeight = viewHeight + range
    self.scrollRange = range

    local thumbHeight = trackHeight
    if range > 0 and contentHeight > 0 then
        thumbHeight = math.max(30, trackHeight * (viewHeight / contentHeight))
    end
    self.scrollThumb:SetHeight(thumbHeight)

    local fraction = range > 0 and clamp((self.scrollOffset or 0) / range, 0, 1) or 0
    local travel = math.max(trackHeight - thumbHeight, 0)
    self.scrollThumb:ClearAllPoints()
    self.scrollThumb:SetPoint("TOP", self.scrollTrack, "TOP", 0, -fraction * travel)
    self.scrollTrack:SetAlpha(range > 0 and 1 or 0.25)
end

function Animations:SetScrollOffset(offset)
    if not self.scroll then
        return
    end

    local range = self.scroll:GetVerticalScrollRange() or 0
    self.scrollOffset = clamp(offset or 0, 0, range)
    self.scroll:SetVerticalScroll(self.scrollOffset)
    self:UpdateScrollBar()
end

function Animations:ScrollFromCursor()
    if not self.scrollTrack or not self.scrollThumb then
        return
    end

    local trackTop = self.scrollTrack:GetTop()
    local trackHeight = self.scrollTrack:GetHeight() or 0
    local thumbHeight = self.scrollThumb:GetHeight() or 0
    local travel = trackHeight - thumbHeight
    if not trackTop or travel <= 0 or (self.scrollRange or 0) <= 0 then
        return
    end

    local _, cursorY = GetCursorPosition()
    cursorY = cursorY / UIParent:GetEffectiveScale()
    local fraction = clamp((trackTop - cursorY - thumbHeight / 2) / travel, 0, 1)
    self:SetScrollOffset(fraction * self.scrollRange)
end

function Animations:Layout()
    local y = -1
    for _, section in ipairs(self.sections) do
        section.header:ClearAllPoints()
        section.header:SetPoint("TOPLEFT", self.container, "TOPLEFT", 0, y)
        section.header:SetPoint("TOPRIGHT", self.container, "TOPRIGHT", 0, y)
        y = y - 27

        if section.body:IsShown() then
            section.body:ClearAllPoints()
            section.body:SetPoint("TOPLEFT", section.header, "BOTTOMLEFT", 0, -3)
            y = y - section.body:GetHeight() - 8
        end
    end

    self.container:SetHeight(math.max(-y, self.scroll:GetHeight()))
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            Animations:SetScrollOffset(Animations.scrollOffset or 0)
        end)
    end
end

function Animations:UpdateSectionLabel(section)
    local expanded = section.body:IsShown()
    local name = section.name
    if section.isFavorites then
        name = name .. " (" .. (section.favoriteCount or 0) .. ")"
    end
    section.header.label:SetText((expanded and "–  " or "+  ") .. name)
end

function Animations:ApplyMinimized()
    local minimized = addon.db.animations.minimized
    self.scroll:SetShown(not minimized)
    self.scrollTrack:SetShown(not minimized)
    self.panelArt:SetShown(not minimized)
    self.frame:SetHeight(minimized and HEADER_HEIGHT + 36 or FRAME_HEIGHT)
    self.minimizeButton.icon:SetTexture(minimized and ICON_EXPAND or ICON_MINIMIZE)
end

function Animations:SetSectionExpanded(section, expanded)
    if not canChangeProtectedState() then
        return
    end

    addon.db.animations.expanded[section.name] = not not expanded
    section.body:SetShown(expanded)
    self:UpdateSectionLabel(section)
    self:Layout()
end

local function applyButtonColors(button, hovered)
    local r, g, b = addon:GetAccentColor()
    local bgR, bgG, bgB, bgA
    local borderR, borderG, borderB, borderA
    local textR, textG, textB
    if hovered then
        bgR, bgG, bgB, bgA = 0.105, 0.085, 0.08, 0.97
        borderR, borderG, borderB, borderA = math.min(r * 1.25, 1), math.min(g * 1.25, 1), math.min(b * 1.25, 1), 0.72
        textR, textG, textB = 0.98, 0.94, 0.84
    else
        bgR, bgG, bgB, bgA = 0.025, 0.023, 0.023, 0.82
        borderR, borderG, borderB, borderA = r, g, b, 0.2
        textR, textG, textB = 0.84, 0.82, 0.78
    end

    if button.usesRoundedPanel then
        setRoundedPanelColors(button, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    else
        button:SetBackdropColor(bgR, bgG, bgB, bgA)
        button:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
    end
    button.label:SetTextColor(textR, textG, textB)
    if button.icon then
        button.icon:SetVertexColor(textR, textG, textB, hovered and 1 or 0.86)
    end
end

local function createChromeButton(parent, width, secure, iconPath)
    local template = secure and "SecureActionButtonTemplate" or nil
    local button = CreateFrame("Button", nil, parent, template)
    button:SetSize(width, 22)
    createRoundedPanel(button, 6)
    button.usesRoundedPanel = true

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", 0, 0)
    label:SetText("")
    button.label = label

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(12, 12)
    icon:SetPoint("CENTER", 0, 0)
    icon:SetTexture(iconPath)
    button.icon = icon

    button:SetScript("OnEnter", function(current)
        applyButtonColors(current, true)
    end)
    button:SetScript("OnLeave", function(current)
        applyButtonColors(current, false)
        GameTooltip_Hide()
    end)
    applyButtonColors(button, false)
    Animations.chromeButtons[#Animations.chromeButtons + 1] = button
    return button
end

function Animations:UpdateFavoriteStar(star)
    local selected = self:IsFavorite(star.actionId)
    star.icon:SetTexture(selected and STAR_FILLED or STAR_EMPTY)
    star.icon:SetVertexColor(selected and 1 or 0.62, selected and 0.82 or 0.58, selected and 0.3 or 0.5, selected and 1 or 0.78)
end

function Animations:RefreshFavoriteStars()
    for _, star in ipairs(self.favoriteStars) do
        self:UpdateFavoriteStar(star)
    end
end

function Animations:ToggleFavorite(actionId)
    if not canChangeProtectedState() then
        return
    end

    local entry = self.actionLookup[actionId]
    if not entry then
        return
    end

    local selected = not self:IsFavorite(actionId)
    addon.db.animations.favorites[actionId] = selected and true or nil
    self:RebuildFavorites()
    addon:Print(entry.label .. (selected and " wurde zu den Favoriten hinzugefügt." or " wurde aus den Favoriten entfernt."))
end

function Animations:CreateActionButton(parent, label, macroText, index, actionId)
    local button = CreateFrame("Button", nil, parent, "SecureActionButtonTemplate,BackdropTemplate")
    button:SetSize(BUTTON_WIDTH, 23)
    button:SetBackdrop(BACKDROP)
    button:RegisterForClicks("AnyUp")
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", macroText)

    local buttonLabel = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    buttonLabel:SetPoint("LEFT", 9, 0)
    buttonLabel:SetPoint("RIGHT", -29, 0)
    buttonLabel:SetJustifyH("LEFT")
    buttonLabel:SetText(label)
    button.label = buttonLabel
    button.actionId = actionId

    local star = CreateFrame("Button", nil, button)
    star:SetSize(17, 17)
    star:SetPoint("RIGHT", -5, 0)
    star:SetFrameLevel(button:GetFrameLevel() + 8)
    star:RegisterForClicks("LeftButtonUp")
    star.actionId = actionId

    local starIcon = star:CreateTexture(nil, "ARTWORK")
    starIcon:SetAllPoints()
    star.icon = starIcon
    star:SetHighlightTexture(STAR_FILLED, "ADD")
    star:SetScript("OnClick", function(current)
        Animations:ToggleFavorite(current.actionId)
    end)
    star:SetScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_RIGHT")
        GameTooltip:SetText(Animations:IsFavorite(current.actionId) and "Aus Favoriten entfernen" or "Zu Favoriten hinzufügen")
        GameTooltip:Show()
    end)
    star:SetScript("OnLeave", GameTooltip_Hide)
    self.favoriteStars[#self.favoriteStars + 1] = star
    self:UpdateFavoriteStar(star)

    local row = math.floor((index - 1) / 2)
    if index % 2 == 1 then
        button:SetPoint("TOPLEFT", 0, -row * ROW_HEIGHT)
    else
        button:SetPoint("TOPRIGHT", 0, -row * ROW_HEIGHT)
    end

    button:SetScript("OnEnter", function(current)
        applyButtonColors(current, true)
    end)
    button:SetScript("OnLeave", function(current)
        applyButtonColors(current, false)
    end)
    applyButtonColors(button, false)
    self.actionButtons[#self.actionButtons + 1] = button

    return button
end

function Animations:RefreshActionAvailability()
    if InCombatLockdown and InCombatLockdown() then
        self.pendingAvailabilityRefresh = true
        return
    end

    self.pendingAvailabilityRefresh = nil
    for _, section in ipairs(self.sections) do
        if not section.isFavorites and section.category and section.actionButtons then
            local visibleCount = 0
            for index, action in ipairs(section.category.actions) do
                local button = section.actionButtons[index]
                local available = not self:IsActionDisabled(action)
                if button then
                    button:ClearAllPoints()
                    if available then
                        visibleCount = visibleCount + 1
                        local row = math.floor((visibleCount - 1) / 2)
                        if visibleCount % 2 == 1 then
                            button:SetPoint("TOPLEFT", 0, -row * ROW_HEIGHT)
                        else
                            button:SetPoint("TOPRIGHT", 0, -row * ROW_HEIGHT)
                        end
                    end
                    button:SetShown(available)
                end
            end
            section.body:SetHeight(math.max(1, math.ceil(visibleCount / 2) * ROW_HEIGHT))
        end
    end

    self:RebuildFavorites()
end

function Animations:RegisterAvailabilityEvents()
    if self.availabilityEventFrame then
        return
    end

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    frame:RegisterEvent("UNIT_MODEL_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(_, event, unit)
        if event == "ADDON_LOADED" or event == "PLAYER_ENTERING_WORLD" then
            Animations:RegisterServerAvailabilityHandler()
        end
        if event == "ADDON_LOADED" then
            return
        end
        if event == "UNIT_MODEL_CHANGED" and unit ~= "player" then
            return
        end
        if event == "PLAYER_REGEN_ENABLED" and not Animations.pendingAvailabilityRefresh then
            return
        end
        Animations:RefreshActionAvailability()
    end)
    self.availabilityEventFrame = frame
end

function Animations:RebuildFavorites()
    local section = self.favoritesSection
    if not section or not addon.db or not addon.db.animations then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        return
    end

    for _, button in pairs(self.favoriteButtons) do
        button:Hide()
    end

    local count = 0
    for _, entry in ipairs(self.actionOrder) do
        if self:IsFavorite(entry.id) and not self:IsActionDisabled(entry) then
            count = count + 1
            local button = self.favoriteButtons[entry.id]
            if not button then
                button = self:CreateActionButton(section.body, entry.label, entry.macroText, count, entry.id)
                self.favoriteButtons[entry.id] = button
            end

            button:ClearAllPoints()
            local row = math.floor((count - 1) / 2)
            if count % 2 == 1 then
                button:SetPoint("TOPLEFT", 0, -row * ROW_HEIGHT)
            else
                button:SetPoint("TOPRIGHT", 0, -row * ROW_HEIGHT)
            end
            button:Show()
        end
    end

    section.favoriteCount = count
    section.emptyText:SetShown(count == 0)
    section.body:SetHeight(count == 0 and 30 or math.ceil(count / 2) * ROW_HEIGHT)
    self:UpdateSectionLabel(section)
    self:RefreshFavoriteStars()
    self:Layout()
end

function Animations:CreateWindow()
    local frame = CreateFrame("Frame", "KitarCompanionAnimationFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetBackdrop(EDGE_BACKDROP)

    local underlay = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    underlay:SetAllPoints()
    underlay:SetColorTexture(0.015, 0.012, 0.012, 0.98)

    local panelArt = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    panelArt:SetAllPoints()
    panelArt:SetTexture(PANEL_TEXTURE)
    panelArt:SetTexCoord(0, 1, 0, 683 / 1024)
    panelArt:SetVertexColor(0.9, 0.9, 0.9, 0.97)
    self.panelArt = panelArt

    local position = addon.db.animations.position
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    self.frame = frame

    local function startWindowDrag()
        if canChangeProtectedState() then
            frame:StartMoving()
        end
    end

    local function stopWindowDrag()
        frame:StopMovingOrSizing()
        savePosition(frame)
    end

    local function enableWindowDrag(region)
        region:EnableMouse(true)
        region:RegisterForDrag("LeftButton")
        region:SetScript("OnDragStart", startWindowDrag)
        region:SetScript("OnDragStop", stopWindowDrag)
    end

    enableWindowDrag(frame)

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", 18, -14)
    header:SetPoint("TOPRIGHT", -18, -14)
    header:SetHeight(HEADER_HEIGHT)
    enableWindowDrag(header)
    self.header = header

    local brandPanel = CreateFrame("Frame", nil, header)
    brandPanel:SetSize(132, 24)
    brandPanel:SetPoint("CENTER", header, "CENTER", 0, 0)
    createRoundedPanel(brandPanel, 7)
    local brandR, brandG, brandB = addon:GetAccentColor()
    setRoundedPanelColors(brandPanel, 0.018, 0.018, 0.018, 0.78, brandR, brandG, brandB, 0.26)
    self.brandPanel = brandPanel

    local title = brandPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("CENTER", 0, 0)
    title:SetText("Kitar Companion")
    self.title = title

    local closeButton = createChromeButton(header, 24, false, ICON_CLOSE)
    closeButton:SetPoint("RIGHT", -5, 0)
    closeButton:HookScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_TOP")
        GameTooltip:SetText("Fenster schließen")
        GameTooltip:Show()
    end)
    closeButton:SetScript("OnClick", function()
        if canChangeProtectedState() then
            frame:Hide()
            addon.db.animations.shown = false
        end
    end)

    local minimizeButton = createChromeButton(header, 24, false, ICON_MINIMIZE)
    minimizeButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
    minimizeButton:HookScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_TOP")
        GameTooltip:SetText(addon.db.animations.minimized and "Fenster erweitern" or "Fenster minimieren")
        GameTooltip:Show()
    end)
    minimizeButton:SetScript("OnClick", function()
        if canChangeProtectedState() then
            addon.db.animations.minimized = not addon.db.animations.minimized
            Animations:ApplyMinimized()
        end
    end)
    self.minimizeButton = minimizeButton

    local resetButton = createChromeButton(header, 26, true, ICON_RESET)
    resetButton:SetPoint("RIGHT", minimizeButton, "LEFT", -5, 0)
    resetButton:RegisterForClicks("AnyUp")
    resetButton:SetAttribute("type", "macro")
    resetButton:SetAttribute("macrotext", "/zuruecksetzen")
    resetButton:HookScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_TOP")
        GameTooltip:SetText("Animation zurücksetzen")
        GameTooltip:Show()
    end)

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", 27, -HEADER_HEIGHT - 27)
    scroll:SetPoint("BOTTOMRIGHT", -33, 20)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        Animations:SetScrollOffset((Animations.scrollOffset or 0) - delta * 54)
    end)
    scroll:SetScript("OnSizeChanged", function()
        Animations:UpdateScrollBar()
    end)
    enableWindowDrag(scroll)
    self.scroll = scroll

    local scrollTrack = CreateFrame("Button", nil, frame)
    scrollTrack:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -20, -HEADER_HEIGHT - 27)
    scrollTrack:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    scrollTrack:SetWidth(6)
    local trackTexture = scrollTrack:CreateTexture(nil, "BACKGROUND")
    trackTexture:SetPoint("TOP", 0, 0)
    trackTexture:SetPoint("BOTTOM", 0, 0)
    trackTexture:SetWidth(2)
    trackTexture:SetColorTexture(0.32, 0.3, 0.28, 0.22)
    scrollTrack:SetScript("OnMouseDown", function()
        Animations:ScrollFromCursor()
    end)
    self.scrollTrack = scrollTrack

    local scrollThumb = CreateFrame("Button", nil, scrollTrack)
    scrollThumb:SetWidth(5)
    scrollThumb:SetHeight(30)
    scrollThumb:RegisterForDrag("LeftButton")
    local thumbTexture = scrollThumb:CreateTexture(nil, "ARTWORK")
    thumbTexture:SetAllPoints()
    scrollThumb.texture = thumbTexture
    scrollThumb:SetScript("OnDragStart", function(current)
        current:SetScript("OnUpdate", function()
            Animations:ScrollFromCursor()
        end)
    end)
    scrollThumb:SetScript("OnDragStop", function(current)
        current:SetScript("OnUpdate", nil)
        Animations:ScrollFromCursor()
    end)
    self.scrollThumb = scrollThumb

    local container = CreateFrame("Frame", nil, scroll)
    container:SetWidth(CONTENT_WIDTH)
    container:SetHeight(1)
    scroll:SetScrollChild(container)
    self.container = container

    local favoritesSection = {
        name = "Favoriten",
        isFavorites = true,
        favoriteCount = 0,
    }
    local favoritesHeader = CreateFrame("Button", nil, container)
    favoritesHeader:SetHeight(24)
    createRoundedPanel(favoritesHeader, 7)
    local favoriteR, favoriteG, favoriteB = addon:GetAccentColor()
    setRoundedPanelColors(favoritesHeader, 0.04, 0.034, 0.028, 0.94, favoriteR, favoriteG, favoriteB, 0.3)
    favoritesSection.header = favoritesHeader

    local favoritesLabel = favoritesHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    favoritesLabel:SetPoint("LEFT", 7, 0)
    favoritesLabel:SetTextColor(0.91, 0.8, 0.55)
    favoritesHeader.label = favoritesLabel

    local favoritesBody = CreateFrame("Frame", nil, container)
    favoritesBody:SetWidth(CONTENT_WIDTH)
    favoritesBody:SetHeight(30)
    favoritesSection.body = favoritesBody

    local emptyText = favoritesBody:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emptyText:SetPoint("TOPLEFT", 9, -8)
    emptyText:SetText("Noch keine Favoriten – klicke auf einen Stern.")
    favoritesSection.emptyText = emptyText

    local favoritesExpanded = addon.db.animations.expanded["Favoriten"] ~= false
    favoritesBody:SetShown(favoritesExpanded)
    favoritesHeader:SetScript("OnClick", function()
        Animations:SetSectionExpanded(favoritesSection, not favoritesBody:IsShown())
    end)
    favoritesHeader:SetScript("OnEnter", function(current)
        local r, g, b = addon:GetAccentColor()
        setRoundedPanelColors(current, 0.09, 0.07, 0.05, 0.96, r, g, b, 0.62)
        current.label:SetTextColor(1, 0.9, 0.62)
    end)
    favoritesHeader:SetScript("OnLeave", function(current)
        local r, g, b = addon:GetAccentColor()
        setRoundedPanelColors(current, 0.04, 0.034, 0.028, 0.94, r, g, b, 0.3)
        current.label:SetTextColor(0.91, 0.8, 0.55)
    end)
    self.favoritesSection = favoritesSection
    self.sections[#self.sections + 1] = favoritesSection
    self:UpdateSectionLabel(favoritesSection)

    for _, category in ipairs(addon.AnimationCategories) do
        local section = {
            name = category.name,
            category = category,
            actionButtons = {},
        }
        local categoryHeader = CreateFrame("Button", nil, container)
        categoryHeader:SetHeight(24)
        createRoundedPanel(categoryHeader, 7)
        local categoryR, categoryG, categoryB = addon:GetAccentColor()
        setRoundedPanelColors(categoryHeader, 0.028, 0.026, 0.026, 0.9, categoryR, categoryG, categoryB, 0.24)
        section.header = categoryHeader

        local label = categoryHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", 7, 0)
        label:SetTextColor(0.8, 0.78, 0.73)
        categoryHeader.label = label

        local body = CreateFrame("Frame", nil, container)
        body:SetWidth(CONTENT_WIDTH)
        body:SetHeight(math.ceil(#category.actions / 2) * ROW_HEIGHT)
        section.body = body

        for index, action in ipairs(category.actions) do
            section.actionButtons[index] = self:CreateActionButton(body, action[1], action[2], index, action.id)
        end

        local expanded = not not addon.db.animations.expanded[category.name]
        body:SetShown(expanded)
        self:UpdateSectionLabel(section)
        categoryHeader:SetScript("OnClick", function()
            Animations:SetSectionExpanded(section, not section.body:IsShown())
        end)
        categoryHeader:SetScript("OnEnter", function(current)
            local r, g, b = addon:GetAccentColor()
            setRoundedPanelColors(current, 0.07, 0.06, 0.058, 0.95, r, g, b, 0.58)
            current.label:SetTextColor(0.96, 0.91, 0.82)
        end)
        categoryHeader:SetScript("OnLeave", function(current)
            local r, g, b = addon:GetAccentColor()
            setRoundedPanelColors(current, 0.028, 0.026, 0.026, 0.9, r, g, b, 0.24)
            current.label:SetTextColor(0.8, 0.78, 0.73)
        end)

        self.sections[#self.sections + 1] = section
    end

    self:RefreshActionAvailability()

    frame:SetScript("OnShow", function()
        addon.db.animations.shown = true
        Animations:SetScrollOffset(Animations.scrollOffset or 0)
    end)
    frame:SetScript("OnHide", function()
        addon.db.animations.shown = false
    end)

    self:Layout()
    self:SetScrollOffset(0)
    self:ApplyMinimized()
    self:Refresh()
    frame:SetShown(addon.db.animations.shown)
end

function Animations:Toggle()
    if not canChangeProtectedState() then
        return
    end

    self.frame:SetShown(not self.frame:IsShown())
end

function Animations:ResetPosition()
    if not self.frame then
        return
    end

    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    savePosition(self.frame)
end

function Animations:ApplyProfileSettings()
    if not self.frame then
        return
    end

    self:ResetPosition()
    for _, section in ipairs(self.sections) do
        local expanded = addon.db.animations.expanded[section.name] == true
        section.body:SetShown(expanded)
        self:UpdateSectionLabel(section)
    end
    self:RebuildFavorites()
    self:SetScrollOffset(0)
    self:ApplyMinimized()
    self:Layout()
    self.frame:SetShown(addon.db.animations.shown == true)
end

function Animations:Refresh()
    if not self.frame then
        return
    end

    local r, g, b = addon:GetAccentColor()
    self.frame:SetBackdropBorderColor(r, g, b, 0.55)
    setRoundedPanelColors(self.brandPanel, 0.018, 0.018, 0.018, 0.78, r, g, b, 0.26)
    self.title:SetTextColor(0.9, 0.86, 0.78)
    self.scrollThumb.texture:SetColorTexture(r, g, b, 0.72)
    for _, section in ipairs(self.sections) do
        if section.isFavorites then
            setRoundedPanelColors(section.header, 0.04, 0.034, 0.028, 0.94, r, g, b, 0.3)
        else
            setRoundedPanelColors(section.header, 0.028, 0.026, 0.026, 0.9, r, g, b, 0.24)
        end
    end
    for _, button in ipairs(self.actionButtons) do
        applyButtonColors(button, false)
    end
    for _, button in ipairs(self.chromeButtons) do
        applyButtonColors(button, false)
    end
    self:RefreshFavoriteStars()
    self:UpdateScrollBar()
end

function Animations:Initialize()
    self:BuildActionLookup()
    self:CreateWindow()
    self:RegisterServerAvailabilityHandler()
    self:RegisterAvailabilityEvents()
end
