local _, addon = ...

local Options = {}
addon:RegisterModule("Options", Options)

local function createCheckButton(parent, text, y, getter, setter)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", 18, y)
    check.Text:SetText(text)
    check:SetScript("OnClick", function(current)
        setter(current:GetChecked() and true or false)
    end)
    check.Refresh = function()
        check:SetChecked(getter())
    end
    return check
end

function Options:Initialize()
    local panel = CreateFrame("Frame", "KitarCompanionOptionsPanel")
    panel.name = "Kitar Companion"
    self.panel = panel

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Kitar Companion")

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)
    version:SetText("v" .. addon.version .. " · WoW 9.2.7")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
    description:SetWidth(560)
    description:SetJustifyH("LEFT")
    description:SetText("Ein ruhiger RP-Begleiter für Animationen und die persönliche Finanzverwaltung deines Charakters.")

    local minimap = createCheckButton(panel, "Minimap-Symbol anzeigen", -86,
        function() return not addon.db.minimap.hide end,
        function(value)
            addon.db.minimap.hide = not value
            local module = addon:GetModule("Minimap")
            if module then module:Refresh() end
        end)

    self.checkButtons = { minimap }

    local animationButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    animationButton:SetSize(180, 24)
    animationButton:SetPoint("TOPLEFT", 19, -132)
    animationButton:SetText("Animationsfenster")
    animationButton:SetScript("OnClick", function()
        local module = addon:GetModule("Animations")
        if module then module:Toggle() end
    end)

    local financeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    financeButton:SetSize(180, 24)
    financeButton:SetPoint("LEFT", animationButton, "RIGHT", 12, 0)
    financeButton:SetText("Finanzfenster")
    financeButton:SetScript("OnClick", function()
        local module = addon:GetModule("Finances")
        if module then module:Toggle() end
    end)

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(180, 24)
    resetButton:SetPoint("TOPLEFT", animationButton, "BOTTOMLEFT", 0, -16)
    resetButton:SetText("UI-Einstellungen zurücksetzen")
    resetButton:SetScript("OnClick", function()
        addon:ResetProfile()
        Options:Refresh()
    end)

    local financeResetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    financeResetButton:SetSize(180, 24)
    financeResetButton:SetPoint("LEFT", resetButton, "RIGHT", 12, 0)
    financeResetButton:SetText("Finanzdaten zurücksetzen")
    financeResetButton:SetScript("OnClick", function()
        local module = addon:GetModule("Finances")
        if module then module:ConfirmReset() end
    end)

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 2, -18)
    note:SetWidth(560)
    note:SetJustifyH("LEFT")
    note:SetText("Hinweis: Die erweiterten Animationsbefehle müssen vom verwendeten Server oder dessen RP-System unterstützt werden.")

    panel:SetScript("OnShow", function()
        Options:Refresh()
    end)
    InterfaceOptions_AddCategory(panel)

    function addon:OpenOptions()
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

function Options:Refresh()
    if not self.panel then
        return
    end

    for _, check in ipairs(self.checkButtons) do
        check:Refresh()
    end
end
