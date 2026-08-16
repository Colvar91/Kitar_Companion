local _, addon = ...

local MinimapModule = {}
addon:RegisterModule("Minimap", MinimapModule)

local function updatePosition(button)
    local angle = math.rad(addon.db.minimap.minimapPos or 220)
    local radius = addon.db.minimap.radius or 80
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function updateAngleFromCursor(button)
    local scale = UIParent:GetEffectiveScale()
    local cursorX, cursorY = GetCursorPosition()
    local centerX, centerY = Minimap:GetCenter()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local atan2 = math.atan2 or _G.atan2
    if not centerX or not centerY or not atan2 then
        return
    end

    addon.db.minimap.minimapPos = math.deg(atan2(cursorY - centerY, cursorX - centerX))
    updatePosition(button)
end

function MinimapModule:Initialize()
    local button = CreateFrame("Button", "KitarCompanionMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            local finances = addon:GetModule("Finances")
            if finances then
                finances:Toggle()
            end
        elseif mouseButton == "RightButton" then
            local animations = addon:GetModule("Animations")
            if animations then
                animations:Toggle()
            end
        elseif mouseButton == "MiddleButton" and addon.OpenOptions then
            addon:OpenOptions()
        end
    end)
    button:SetScript("OnDragStart", function(current)
        current:SetScript("OnUpdate", updateAngleFromCursor)
    end)
    button:SetScript("OnDragStop", function(current)
        current:SetScript("OnUpdate", nil)
        updateAngleFromCursor(current)
    end)
    button:SetScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff8f2838Kitar|r Companion")
        GameTooltip:AddLine("Linksklick: Finanzen", 0.82, 0.74, 0.60)
        GameTooltip:AddLine("Rechtsklick: Animationen", 0.82, 0.74, 0.60)
        GameTooltip:AddLine("Mittlere Maustaste: Einstellungen", 0.82, 0.74, 0.60)
        GameTooltip:AddLine("Ziehen: Symbol verschieben", 0.66, 0.60, 0.52)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)

    self.button = button
    updatePosition(button)
    self:Refresh()
end

function MinimapModule:Refresh()
    if not self.button then
        return
    end

    updatePosition(self.button)
    self.button:SetShown(not addon.db.minimap.hide)
end
