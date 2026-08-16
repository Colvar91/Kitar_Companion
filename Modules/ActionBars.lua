local _, addon = ...

local ActionBars = {
    buttons = {},
}
addon:RegisterModule("ActionBars", ActionBars)

local BUTTON_GROUPS = {
    { prefix = "ActionButton", count = 12 },
    { prefix = "MultiBarBottomLeftButton", count = 12 },
    { prefix = "MultiBarBottomRightButton", count = 12 },
    { prefix = "MultiBarRightButton", count = 12 },
    { prefix = "MultiBarLeftButton", count = 12 },
    { prefix = "PetActionButton", count = 10 },
    { prefix = "StanceButton", count = 10 },
    { prefix = "PossessButton", count = 2 },
    { prefix = "OverrideActionBarButton", count = 6 },
}

local ART_GLOBALS = {
    "MainMenuBarArtFrameBackground",
    "MainMenuBarTexture0",
    "MainMenuBarTexture1",
    "MainMenuBarTexture2",
    "MainMenuBarTexture3",
    "MainMenuBarLeftEndCap",
    "MainMenuBarRightEndCap",
    "SlidingActionBarTexture0",
    "SlidingActionBarTexture1",
}

local function setRegionAlpha(region, alpha)
    if region and region.SetAlpha then
        region:SetAlpha(alpha)
    end
end

local function findRegion(button, field, suffix)
    if button[field] then
        return button[field]
    end

    local name = button:GetName()
    return name and _G[name .. suffix]
end

function ActionBars:SetBorderColor(button, bright)
    if not button.__shrpBorder then
        return
    end

    local r, g, b = addon:GetAccentColor()
    local factor = bright and 1.35 or 1
    for _, texture in ipairs(button.__shrpBorder) do
        texture:SetColorTexture(math.min(r * factor, 1), math.min(g * factor, 1), math.min(b * factor, 1), bright and 1 or 0.9)
    end
end

function ActionBars:SkinButton(button)
    if not button or button.__shrpSkinned then
        return
    end

    button.__shrpSkinned = true
    self.buttons[#self.buttons + 1] = button

    local background = button:CreateTexture(nil, "BACKGROUND", nil, -7)
    background:SetPoint("TOPLEFT", -2, 2)
    background:SetPoint("BOTTOMRIGHT", 2, -2)
    background:SetColorTexture(0.025, 0.02, 0.02, 0.94)
    button.__shrpBackground = background

    local border = {}
    border[1] = button:CreateTexture(nil, "OVERLAY", nil, 6)
    border[1]:SetPoint("TOPLEFT", -2, 2)
    border[1]:SetPoint("TOPRIGHT", 2, 2)
    border[1]:SetHeight(2)
    border[2] = button:CreateTexture(nil, "OVERLAY", nil, 6)
    border[2]:SetPoint("BOTTOMLEFT", -2, -2)
    border[2]:SetPoint("BOTTOMRIGHT", 2, -2)
    border[2]:SetHeight(2)
    border[3] = button:CreateTexture(nil, "OVERLAY", nil, 6)
    border[3]:SetPoint("TOPLEFT", -2, 2)
    border[3]:SetPoint("BOTTOMLEFT", -2, -2)
    border[3]:SetWidth(2)
    border[4] = button:CreateTexture(nil, "OVERLAY", nil, 6)
    border[4]:SetPoint("TOPRIGHT", 2, 2)
    border[4]:SetPoint("BOTTOMRIGHT", 2, -2)
    border[4]:SetWidth(2)
    button.__shrpBorder = border

    local icon = findRegion(button, "icon", "Icon") or findRegion(button, "Icon", "Icon")
    if icon and icon.SetTexCoord then
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", -2, 2)
    end

    local normal = button.GetNormalTexture and button:GetNormalTexture()
    setRegionAlpha(normal, 0)

    local pushed = button.GetPushedTexture and button:GetPushedTexture()
    if pushed then
        pushed:SetVertexColor(1, 0.82, 0.45, 0.35)
    end

    local checked = button.GetCheckedTexture and button:GetCheckedTexture()
    if checked then
        checked:SetVertexColor(1, 0.72, 0.25, 0.55)
    end

    local hotkey = findRegion(button, "HotKey", "HotKey")
    if hotkey then
        hotkey:SetTextColor(0.92, 0.84, 0.68)
        hotkey:SetShadowColor(0, 0, 0, 1)
        hotkey:SetShadowOffset(1, -1)
    end

    local count = findRegion(button, "Count", "Count")
    if count then
        count:SetTextColor(1, 0.92, 0.72)
        count:SetShadowColor(0, 0, 0, 1)
    end

    local name = findRegion(button, "Name", "Name")
    if name then
        name:SetTextColor(0.95, 0.88, 0.74)
        name:SetShadowColor(0, 0, 0, 1)
    end

    local cooldown = findRegion(button, "cooldown", "Cooldown") or findRegion(button, "Cooldown", "Cooldown")
    if cooldown and cooldown.SetSwipeColor then
        cooldown:SetSwipeColor(0.02, 0.015, 0.01, 0.82)
    end

    button:HookScript("OnEnter", function(current)
        ActionBars:SetBorderColor(current, true)
        current:SetAlpha(1)
    end)
    button:HookScript("OnLeave", function(current)
        ActionBars:SetBorderColor(current, false)
        current:SetAlpha(addon.db.actionBars.fade and addon.db.actionBars.idleAlpha or 1)
    end)

    self:SetBorderColor(button, false)
end

function ActionBars:SkinAll()
    if not addon.db.actionBars.enabled then
        return
    end

    if InCombatLockdown and InCombatLockdown() then
        self.pendingSkin = true
        return
    end

    self.pendingSkin = false

    for _, group in ipairs(BUTTON_GROUPS) do
        for index = 1, group.count do
            self:SkinButton(_G[group.prefix .. index])
        end
    end

    self:SkinButton(_G.ExtraActionButton1)
    if _G.ZoneAbilityFrame then
        self:SkinButton(_G.ZoneAbilityFrame.SpellButton)
    end

    self:Refresh()
end

function ActionBars:ApplyArt()
    local alpha = addon.db.actionBars.hideArt and 0 or 1
    for _, name in ipairs(ART_GLOBALS) do
        setRegionAlpha(_G[name], alpha)
    end

    local artFrame = _G.MainMenuBarArtFrame
    if artFrame then
        setRegionAlpha(artFrame.Background, alpha)
        setRegionAlpha(artFrame.LeftEndCap, alpha)
        setRegionAlpha(artFrame.RightEndCap, alpha)
    end
end

function ActionBars:Refresh()
    if not addon.db or not addon.db.actionBars.enabled then
        return
    end

    local alpha = addon.db.actionBars.fade and addon.db.actionBars.idleAlpha or 1
    for _, button in ipairs(self.buttons) do
        self:SetBorderColor(button, false)
        button:SetAlpha(alpha)
        local normal = button.GetNormalTexture and button:GetNormalTexture()
        setRegionAlpha(normal, 0)
    end

    self:ApplyArt()
end

function ActionBars:Initialize()
    self.eventFrame = CreateFrame("Frame")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    self.eventFrame:RegisterEvent("UPDATE_BINDINGS")
    self.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    self.eventFrame:SetScript("OnEvent", function()
        ActionBars:SkinAll()
    end)

    if hooksecurefunc and ActionButton_Update then
        hooksecurefunc("ActionButton_Update", function(button)
            if addon.db and addon.db.actionBars.enabled then
                if button and (button.__shrpSkinned or not (InCombatLockdown and InCombatLockdown())) then
                    ActionBars:SkinButton(button)
                    local normal = button.GetNormalTexture and button:GetNormalTexture()
                    setRegionAlpha(normal, 0)
                else
                    ActionBars.pendingSkin = true
                end
            end
        end)
    end
end

function ActionBars:Enable()
    self:SkinAll()
end
