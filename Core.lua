local addonName, addon = ...

KitarCompanion = addon
addon.name = addonName
addon.version = GetAddOnMetadata(addonName, "Version") or "1.4.0"
addon.modules = {}

local DEFAULTS = {
    profileVersion = 7,
    animations = {
        shown = false,
        minimized = false,
        position = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = 0,
        },
        expanded = {
            ["Favoriten"] = true,
        },
        favorites = {},
    },
    minimap = {
        hide = false,
        minimapPos = 220,
        radius = 80,
    },
}

local VALID_FRAME_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local function sanitizeNumber(value, fallback, minimum, maximum)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    if minimum then
        value = math.max(minimum, value)
    end
    if maximum then
        value = math.min(maximum, value)
    end
    return value
end

local function sanitizeFramePoint(value, fallback)
    return type(value) == "string" and VALID_FRAME_POINTS[value] and value or fallback
end

local function copyDefaults(source, target)
    if type(target) ~= "table" then
        target = {}
    end

    for key, value in pairs(source) do
        if type(value) == "table" then
            target[key] = copyDefaults(value, target[key])
        elseif target[key] == nil then
            target[key] = value
        end
    end

    return target
end

local function sanitizeProfile()
    local animations = KitarCompanionDB.animations
    local position = animations.position
    position.point = sanitizeFramePoint(position.point, "CENTER")
    position.relativePoint = sanitizeFramePoint(position.relativePoint, "CENTER")
    position.x = sanitizeNumber(position.x, 0, -10000, 10000)
    position.y = sanitizeNumber(position.y, 0, -10000, 10000)
    animations.shown = animations.shown == true
    animations.minimized = animations.minimized == true

    local minimap = KitarCompanionDB.minimap
    minimap.hide = minimap.hide == true
    minimap.minimapPos = sanitizeNumber(minimap.minimapPos, 220) % 360
    minimap.radius = sanitizeNumber(minimap.radius, 80, 40, 160)
end

function addon:RegisterModule(name, module)
    module.name = name
    self.modules[name] = module
end

function addon:GetModule(name)
    return self.modules[name]
end

function addon:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff8f2838Kitar|r |cffe4d6b8Companion:|r " .. tostring(message))
end

function addon:GetAccentColor()
    return 0.56, 0.10, 0.16
end

function addon:RefreshModules()
    for _, module in pairs(self.modules) do
        if module.Refresh then
            module:Refresh()
        end
    end
end

function addon:ResetProfile()
    if InCombatLockdown and InCombatLockdown() then
        self:Print("Die Einstellungen können im Kampf nicht zurückgesetzt werden.")
        return
    end

    local storedFavorites = KitarCompanionDB.animations and KitarCompanionDB.animations.favorites
    local favorites = type(storedFavorites) == "table" and storedFavorites or {}
    local migratedAnimations = KitarCompanionDB.migratedAnimations
    local migratedFromSHRoleplay = KitarCompanionDB.migratedFromSHRoleplay

    for key in pairs(KitarCompanionDB) do
        KitarCompanionDB[key] = nil
    end
    copyDefaults(DEFAULTS, KitarCompanionDB)
    KitarCompanionDB.animations.favorites = favorites
    KitarCompanionDB.migratedAnimations = migratedAnimations
    KitarCompanionDB.migratedFromSHRoleplay = migratedFromSHRoleplay
    self.db = KitarCompanionDB

    local animations = self:GetModule("Animations")
    if animations and animations.ApplyProfileSettings then
        animations:ApplyProfileSettings()
    end

    local finances = self:GetModule("Finances")
    if finances and finances.ResetPosition then
        finances:ResetPosition()
    end

    self:RefreshModules()
    self:Print("UI-Einstellungen und Fensterpositionen wurden zurückgesetzt. Favoriten bleiben erhalten.")
end

local function migrateAnimationSettings()
    if type(SHAnimationDB) ~= "table" or KitarCompanionDB.migratedAnimations then
        return
    end

    if type(SHAnimationDB.pos) == "table" then
        local old = SHAnimationDB.pos
        KitarCompanionDB.animations.position = {
            point = old.point or "CENTER",
            relativePoint = old.relPoint or "CENTER",
            x = old.x or 0,
            y = old.y or 0,
        }
    end

    if SHAnimationDB.minimized ~= nil then
        KitarCompanionDB.animations.minimized = not not SHAnimationDB.minimized
    end

    if type(SHAnimationDB.minimap) == "table" then
        local oldMinimap = SHAnimationDB.minimap
        if oldMinimap.hide ~= nil then
            KitarCompanionDB.minimap.hide = not not oldMinimap.hide
        end
        KitarCompanionDB.minimap.minimapPos = oldMinimap.minimapPos or KitarCompanionDB.minimap.minimapPos
        KitarCompanionDB.minimap.radius = oldMinimap.radius or KitarCompanionDB.minimap.radius
    end

    KitarCompanionDB.migratedAnimations = true
end

local function showHelp()
    addon:Print("Befehle:")
    addon:Print("/kitar – Einstellungen öffnen")
    addon:Print("/kitar ani oder /kani – Animationsfenster ein-/ausblenden")
    addon:Print("/kitar finanzen oder /kfin – Finanzfenster ein-/ausblenden")
    addon:Print("/kitar ratentest JJJJ-MM-TT – Raten für ein Datum simulieren")
    addon:Print("/kitar nachbuchen – offene automatische Raten jetzt nachbuchen")
    addon:Print("/kitar minimap – Minimap-Symbol ein-/ausblenden")
    addon:Print("/kitar reset – UI-Einstellungen zurücksetzen")
end

local function hideLegacyFrames()
    local legacyFrames = {
        SHRoleplayAnimationFrame,
        SHRoleplayFinanceFrame,
        SHRoleplayStartCapitalFrame,
        SHRoleplayMinimapButton,
        SHAnimationFrame,
    }
    for _, frame in pairs(legacyFrames) do
        if frame and frame.Hide then
            frame:Hide()
        end
    end

    local legacyMinimap = LibStub and LibStub("LibDBIcon-1.0", true)
    if legacyMinimap and legacyMinimap.Hide then
        legacyMinimap:Hide("SH_Animations_Minimap")
    end
end

local function slashHandler(message)
    local command, argument = string.match(message or "", "^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    argument = string.lower(argument or "")

    if command == "" or command == "config" or command == "optionen" then
        if addon.OpenOptions then
            addon:OpenOptions()
        else
            showHelp()
        end
    elseif command == "ani" or command == "animation" or command == "animationen" or command == "toggle" then
        local animations = addon:GetModule("Animations")
        if animations then
            animations:Toggle()
        end
    elseif command == "fin" or command == "finanz" or command == "finanzen" or command == "geld" then
        local finances = addon:GetModule("Finances")
        if finances then
            finances:Toggle()
        end
    elseif command == "ratentest" then
        local finances = addon:GetModule("Finances")
        if finances and finances.TestRateSchedule then
            finances:TestRateSchedule(argument)
        end
    elseif command == "nachbuchen" then
        local finances = addon:GetModule("Finances")
        if finances and finances.RunManualCatchup then
            finances:RunManualCatchup()
        end
    elseif command == "minimap" then
        addon.db.minimap.hide = not addon.db.minimap.hide
        local minimap = addon:GetModule("Minimap")
        if minimap then
            minimap:Refresh()
        end
        addon:Print(addon.db.minimap.hide and "Minimap-Symbol ausgeblendet." or "Minimap-Symbol eingeblendet.")
    elseif command == "reset" or command == "zuruecksetzen" then
        addon:ResetProfile()
    elseif command == "help" or command == "hilfe" then
        showHelp()
    else
        showHelp()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        local importedLegacyProfile = false
        if type(KitarCompanionDB) ~= "table" then
            if type(SHRoleplayDB) == "table" then
                KitarCompanionDB = copyDefaults(SHRoleplayDB, {})
                importedLegacyProfile = true
            else
                KitarCompanionDB = {}
            end
        end

        KitarCompanionDB = copyDefaults(DEFAULTS, KitarCompanionDB)
        KitarCompanionDB.actionBars = nil
        KitarCompanionDB.theme = nil
        KitarCompanionDB.profileVersion = DEFAULTS.profileVersion
        if importedLegacyProfile then
            KitarCompanionDB.migratedFromSHRoleplay = true
        end
        addon.db = KitarCompanionDB
        migrateAnimationSettings()
        sanitizeProfile()

        for _, module in pairs(addon.modules) do
            if module.Initialize then
                module:Initialize()
            end
        end

        SLASH_KITARCOMPANION1 = "/kitar"
        SLASH_KITARCOMPANION2 = "/kcompanion"
        SlashCmdList.KITARCOMPANION = slashHandler

        SLASH_KITARANIMATIONS1 = "/kani"
        SlashCmdList.KITARANIMATIONS = function()
            local animations = addon:GetModule("Animations")
            if animations then
                animations:Toggle()
            end
        end

        if importedLegacyProfile then
            addon:Print("Einstellungen aus SH Roleplay wurden übernommen. Nach dem Ausloggen kann das alte Addon deaktiviert werden.")
        end
    elseif event == "PLAYER_LOGIN" then
        for _, module in pairs(addon.modules) do
            if module.Enable then
                module:Enable()
            end
        end
        if IsAddOnLoaded and (IsAddOnLoaded("SH_Roleplay") or IsAddOnLoaded("SH_Animations")) then
            C_Timer.After(0.5, hideLegacyFrames)
        end
    end
end)
