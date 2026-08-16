local _, addon = ...

local Finances = {
    tabs = {},
    pages = {},
    buttons = {},
    accentLabels = {},
    historyRows = {},
    rateRows = {},
}
addon:RegisterModule("Finances", Finances)

local FRAME_WIDTH = 610
local FRAME_HEIGHT = 430
local HEADER_HEIGHT = 30
local MAX_CATCHUP_YEARS = 5
local BALANCE_HISTORY_VERSION = 1
local PANEL_TEXTURE = "Interface\\AddOns\\Kitar_Companion\\Media\\PanelBackgroundModern"
local ROUND_FILL = "Interface\\AddOns\\Kitar_Companion\\Media\\RoundedCornerFill"
local ROUND_BORDER = "Interface\\AddOns\\Kitar_Companion\\Media\\RoundedCornerBorder"
local ICON_CLOSE = "Interface\\AddOns\\Kitar_Companion\\Media\\IconClose"

local EDGE_BACKDROP = {
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

local INPUT_BACKDROP = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
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

    frame.roundedPanel = rounded
end

local function setRoundedPanelColors(frame, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    if not frame or not frame.roundedPanel then
        return
    end
    for _, texture in ipairs(frame.roundedPanel.fills) do
        texture:SetVertexColor(bgR, bgG, bgB, bgA)
    end
    for _, texture in ipairs(frame.roundedPanel.borders) do
        texture:SetVertexColor(borderR, borderG, borderB, borderA)
    end
end

local function trim(text)
    return (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function sanitizeFramePoint(value, fallback)
    return type(value) == "string" and VALID_FRAME_POINTS[value] and value or fallback
end

local function getOrderedTableRecords(records)
    if type(records) ~= "table" then
        return {}
    end

    local indexed = {}
    for index, record in pairs(records) do
        if type(index) == "number" and index >= 1 and index == math.floor(index)
            and type(record) == "table" then
            indexed[#indexed + 1] = {
                index = index,
                record = record,
            }
        end
    end
    table.sort(indexed, function(left, right)
        return left.index < right.index
    end)

    local ordered = {}
    for _, entry in ipairs(indexed) do
        ordered[#ordered + 1] = entry.record
    end
    return ordered
end

local function splitMoney(copper)
    local amount = math.abs(math.floor(tonumber(copper) or 0))
    local gold = math.floor(amount / 10000)
    local silver = math.floor((amount % 10000) / 100)
    local coins = amount % 100
    return gold, silver, coins
end

local function moneyText(copper, icons, showSign)
    local value = tonumber(copper) or 0
    local gold, silver, coins = splitMoney(value)
    local sign = ""
    if showSign then
        sign = value >= 0 and "+" or "−"
    elseif value < 0 then
        sign = "−"
    end

    if icons then
        return string.format(
            "%s%d |TInterface\\MONEYFRAME\\UI-GoldIcon:13:13|t  %d |TInterface\\MONEYFRAME\\UI-SilverIcon:13:13|t  %d |TInterface\\MONEYFRAME\\UI-CopperIcon:13:13|t",
            sign, gold, silver, coins
        )
    end
    return string.format("%s%dg %ds %dk", sign, gold, silver, coins)
end

local function compactMoneyText(copper, showSign)
    local value = tonumber(copper) or 0
    local gold, silver, coins = splitMoney(value)
    local parts = {}
    if gold > 0 then
        parts[#parts + 1] = gold .. "g"
    end
    if silver > 0 then
        parts[#parts + 1] = silver .. "s"
    end
    if coins > 0 or #parts == 0 then
        parts[#parts + 1] = coins .. "k"
    end

    local sign = ""
    if showSign then
        sign = value >= 0 and "+" or "−"
    elseif value < 0 then
        sign = "−"
    end
    return sign .. table.concat(parts, " ")
end

local function formatHistoryDate(value)
    value = tostring(value or "")
    local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if year then
        return string.format("%d.%d.%d", tonumber(day), tonumber(month), tonumber(year))
    end

    day, month, year = value:match("^(%d%d?)%.(%d%d?)%.(%d%d%d%d)")
    if day then
        return string.format("%d.%d.%d", tonumber(day), tonumber(month), tonumber(year))
    end
    return string.sub(value, 1, 10)
end

local function getCalendarDate()
    local current = C_DateAndTime.GetCurrentCalendarTime()
    return current.monthDay or current.day, current.month, current.year
end

local function getDateStamp()
    local day, month, year = getCalendarDate()
    return string.format("%04d-%02d-%02d", year, month, day)
end

local function getStoredCalendarDate()
    local day, month, year = getCalendarDate()
    return string.format("%02d.%02d.%04d", day, month, year)
end

local function getCalendarTimestamp()
    local current = C_DateAndTime.GetCurrentCalendarTime()
    local day = current.monthDay or current.day
    return string.format(
        "%04d-%02d-%02d %02d:%02d",
        current.year,
        current.month,
        day,
        tonumber(current.hour) or 0,
        tonumber(current.minute) or 0
    )
end

local function getTransactionDateStamp(transaction)
    local value = tostring(transaction and transaction.time or "")
    local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)")
    if year then
        return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
    end

    day, month, year = value:match("^(%d%d?)%.(%d%d?)%.(%d%d%d%d)")
    if day then
        return string.format("%04d-%02d-%02d", tonumber(year), tonumber(month), tonumber(day))
    end
end

local WEEKDAY_LABELS = { "Mo", "Di", "Mi", "Do", "Fr", "Sa", "So" }
local WEEKDAY_NAMES = { "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag" }

local function getCalendarTime(day, month, year)
    return time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = 12,
        min = 0,
        sec = 0,
    })
end

local function getDaysInMonth(month, year)
    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    month = clamp(math.floor(tonumber(month) or 1), 1, 12)
    year = math.floor(tonumber(year) or 2000)
    if month == 2 and (year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)) then
        return 29
    end
    return days[month]
end

local function getDateKey(day, month, year)
    return (tonumber(year) or 0) * 10000 + (tonumber(month) or 0) * 100 + (tonumber(day) or 0)
end

local function getNextCalendarDate(day, month, year)
    day = tonumber(day) + 1
    month = tonumber(month)
    year = tonumber(year)
    if day > getDaysInMonth(month, year) then
        day = 1
        month = month + 1
        if month > 12 then
            month = 1
            year = year + 1
        end
    end
    return day, month, year
end

local function getWeekdayIndex(day, month, year)
    local key = string.format("%04d-%02d-%02d", year, month, day)
    local storedWeekday = addon.CalendarDays and tonumber(addon.CalendarDays[key])
    if addon.CalendarDataValid ~= false and storedWeekday and storedWeekday >= 1 and storedWeekday <= 7 then
        return storedWeekday
    end

    local weekday = tonumber(date("%w", getCalendarTime(day, month, year))) or 1
    return weekday == 0 and 7 or weekday
end

local function parseStoredDate(value, fallbackDay, fallbackMonth, fallbackYear)
    if type(value) == "string" then
        local day, month, year = value:match("^(%d+)%.(%d+)%.(%d+)$")
        if not day then
            year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        end
        day, month, year = tonumber(day), tonumber(month), tonumber(year)
        if day and month and year and month >= 1 and month <= 12
            and day >= 1 and day <= getDaysInMonth(month, year) then
            return day, month, year
        end
    end
    return fallbackDay, fallbackMonth, fallbackYear
end

local function normalizeWeekdays(weekdays)
    local normalized = {}
    local hasStoredSchedule = type(weekdays) == "table"
    for index = 1, 7 do
        normalized[index] = not hasStoredSchedule or weekdays[index] ~= false
    end
    return normalized
end

local function normalizeInterval(value)
    if value == "Monatlich" then
        return "Monatlich"
    end
    return "Täglich"
end

local function isRateDueOnDate(rate, day, month, year)
    if rate.paused then
        return false
    end
    if rate.intervall == "Monatlich" then
        local bookingDay = clamp(math.floor(tonumber(rate.bookingDay) or 1), 1, 31)
        return day == math.min(bookingDay, getDaysInMonth(month, year))
    end

    local weekday = getWeekdayIndex(day, month, year)
    return type(rate.weekdays) ~= "table" or rate.weekdays[weekday] ~= false
end

local function markRateChecked(rate, day, month, year)
    rate.lastRunDay = day
    rate.lastRunMonth = month
    rate.lastRunYear = year
end

local function allocateRateId(database)
    local nextId = math.max(1, math.floor(tonumber(database.nextRateId) or 1))
    while true do
        local candidate = "rate-" .. nextId
        local exists = false
        for _, existingRate in ipairs(database.raten or {}) do
            if existingRate.id == candidate then
                exists = true
                break
            end
        end
        nextId = nextId + 1
        if not exists then
            database.nextRateId = nextId
            return candidate
        end
    end
end

local function getSignedRateAmount(rate)
    local amount = math.floor(tonumber(rate.wert) or 0)
    return rate.typ == "Ausgabe" and -amount or amount
end

local function getTransactionTotal(transactions)
    local total = 0
    for _, transaction in ipairs(transactions or {}) do
        total = total + math.floor(tonumber(transaction.copperValue) or 0)
    end
    return total
end

local function findRateById(rateId)
    if type(rateId) ~= "string" or type(SHFinanzenDB) ~= "table" then
        return nil
    end
    for index, rate in ipairs(SHFinanzenDB.raten or {}) do
        if rate.id == rateId then
            return rate, index
        end
    end
end

local function getRatePaymentKey(rate)
    return "[Rate] " .. (rate.name or "Unbenannt") .. "\031" .. getSignedRateAmount(rate)
end

local function getRateScheduleText(rate)
    if rate.intervall == "Monatlich" then
        return string.format("Monatl. am %d.", clamp(math.floor(tonumber(rate.bookingDay) or 1), 1, 31))
    end

    local weekdays = normalizeWeekdays(rate.weekdays)
    local allDays = true
    for index = 1, 7 do
        if not weekdays[index] then
            allDays = false
            break
        end
    end
    if allDays then
        return "Täglich"
    end

    local mondayToFriday = true
    for index = 1, 5 do
        mondayToFriday = mondayToFriday and weekdays[index]
    end
    if mondayToFriday and not weekdays[6] and not weekdays[7] then
        return "Mo–Fr"
    end
    if not weekdays[1] and not weekdays[2] and not weekdays[3] and not weekdays[4] and not weekdays[5]
        and weekdays[6] and weekdays[7] then
        return "Sa–So"
    end

    local selected = {}
    for index, label in ipairs(WEEKDAY_LABELS) do
        if weekdays[index] then
            selected[#selected + 1] = label
        end
    end
    return #selected > 0 and table.concat(selected, " ") or "Keine Tage"
end

local function getNextRateDateText(rate)
    if rate.paused then
        return "Pausiert"
    end

    local day, month, year = getCalendarDate()
    local todayKey = getDateKey(day, month, year)
    local lastRunKey = rate.lastRunDay and rate.lastRunMonth and rate.lastRunYear
        and getDateKey(rate.lastRunDay, rate.lastRunMonth, rate.lastRunYear)
    if lastRunKey and lastRunKey >= todayKey then
        day, month, year = getNextCalendarDate(day, month, year)
    end

    local startDay, startMonth, startYear = parseStoredDate(rate.start, nil, nil, nil)
    local startKey = startDay and getDateKey(startDay, startMonth, startYear)
    for _ = 1, 370 do
        local currentKey = getDateKey(day, month, year)
        if (not startKey or currentKey >= startKey) and isRateDueOnDate(rate, day, month, year) then
            return string.format("%d.%d.%d", day, month, year)
        end
        day, month, year = getNextCalendarDate(day, month, year)
    end
    return "–"
end

local function parseTestDate(value)
    value = string.lower(trim(value))
    if value == "" or value == "heute" then
        return getCalendarDate()
    end

    local year, month, day = value:match("^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$")
    if not year then
        day, month, year = value:match("^(%d%d?)%.(%d%d?)%.(%d%d%d%d)$")
    end
    day, month, year = tonumber(day), tonumber(month), tonumber(year)
    if not day or not month or not year or year < 1970 or month < 1 or month > 12 then
        return nil
    end
    if day < 1 or day > getDaysInMonth(month, year) then
        return nil
    end
    return day, month, year
end

function Finances:SanitizeDB()
    if type(SHFinanzenDB) ~= "table" then
        SHFinanzenDB = {}
    end

    local database = SHFinanzenDB
    database.transactions = getOrderedTableRecords(database.transactions)
    database.raten = getOrderedTableRecords(database.raten)
    database.balance = math.floor(tonumber(database.balance) or 0)
    database.initialSet = database.initialSet == true
    database.windowOpen = database.windowOpen == true
    local payoutDay, payoutMonth, payoutYear = parseStoredDate(database.lastPayout, nil, nil, nil)
    if not payoutDay then
        payoutDay, payoutMonth, payoutYear = parseStoredDate(database.lastRateCatchup, nil, nil, nil)
    end
    database.lastPayout = payoutDay
        and string.format("%04d-%02d-%02d", payoutYear, payoutMonth, payoutDay)
        or ""
    database.lastRateCatchup = nil
    database.selectedTab = clamp(math.floor(tonumber(database.selectedTab) or 1), 1, 4)
    database.nextRateId = math.max(1, math.floor(tonumber(database.nextRateId) or 1))

    if type(database.position) ~= "table" then
        database.position = {
            point = database.point or "CENTER",
            relativePoint = database.relativePoint or "CENTER",
            x = tonumber(database.xOfs) or 0,
            y = tonumber(database.yOfs) or 0,
        }
    end
    database.position.point = sanitizeFramePoint(database.position.point, "CENTER")
    database.position.relativePoint = sanitizeFramePoint(database.position.relativePoint, "CENTER")
    database.position.x = clamp(tonumber(database.position.x) or 0, -10000, 10000)
    database.position.y = clamp(tonumber(database.position.y) or 0, -10000, 10000)

    -- SH Finanzen 1.0 speicherte Raten teilweise noch in Silber.
    if not database.rateUnit then
        for _, rate in ipairs(database.raten) do
            rate.wert = (tonumber(rate.wert) or 0) * 100
        end
        database.rateUnit = "copper"
    end

    for _, transaction in ipairs(database.transactions) do
        local copperValue = tonumber(transaction.copperValue)
        if not copperValue then
            copperValue = math.max(0, math.floor(tonumber(transaction.gold) or 0)) * 10000
                + math.max(0, math.floor(tonumber(transaction.silver) or 0)) * 100
                + math.max(0, math.floor(tonumber(transaction.copper) or 0))
            if transaction.type == "expense" then
                copperValue = -copperValue
            end
        end
        copperValue = math.floor(copperValue)
        transaction.copperValue = copperValue
        transaction.type = copperValue < 0 and "expense" or "income"
        transaction.time = type(transaction.time) == "string" and transaction.time or ""
        transaction.desc = type(transaction.desc) == "string" and transaction.desc or "Keine Beschreibung"
        if trim(transaction.desc) == "" then
            transaction.desc = "Keine Beschreibung"
        end
        transaction.gold, transaction.silver, transaction.copper = splitMoney(copperValue)
        if type(transaction.rateId) ~= "string" then
            transaction.rateId = nil
        end
        if type(transaction.rateDate) ~= "string" then
            transaction.rateDate = nil
        end
        if type(transaction.source) ~= "string" then
            transaction.source = nil
        end
    end

    if tonumber(database.kitarBalanceHistoryVersion) ~= BALANCE_HISTORY_VERSION then
        local difference = database.balance - getTransactionTotal(database.transactions)
        if difference ~= 0 then
            local gold, silver, copper = splitMoney(difference)
            database.transactions[#database.transactions + 1] = {
                time = getCalendarTimestamp(),
                type = difference < 0 and "expense" or "income",
                gold = gold,
                silver = silver,
                copper = copper,
                copperValue = difference,
                desc = "Bestandsübertrag",
                source = "balance-migration",
            }
        end
        database.kitarBalanceHistoryVersion = BALANCE_HISTORY_VERSION
    end
    database.balance = getTransactionTotal(database.transactions)

    local todayDay, todayMonth, todayYear = getCalendarDate()
    local todayKey = getDateKey(todayDay, todayMonth, todayYear)
    local usedRateIds = {}
    for _, rate in ipairs(database.raten) do
        if type(rate.id) ~= "string" or rate.id == "" or usedRateIds[rate.id] then
            rate.id = allocateRateId(database)
        end
        usedRateIds[rate.id] = true
        local rateName = type(rate.name) == "string" and trim(rate.name) or ""
        rate.name = rateName ~= "" and rateName or "Unbenannt"
        rate.wert = math.max(0, math.floor(tonumber(rate.wert) or 0))
        rate.typ = rate.typ == "Ausgabe" and "Ausgabe" or "Einnahme"
        rate.intervall = normalizeInterval(rate.intervall)
        rate.paused = rate.paused == true
        if not parseStoredDate(rate.start, nil, nil, nil) then
            rate.start = getStoredCalendarDate()
        end
        if rate.intervall == "Täglich" then
            rate.weekdays = normalizeWeekdays(rate.weekdays)
        else
            rate.bookingDay = clamp(math.floor(tonumber(rate.bookingDay) or 1), 1, 31)
            if rate.lastRunMonth and rate.lastRunYear and not rate.lastRunDay then
                local lastMonth = tonumber(rate.lastRunMonth)
                local lastYear = tonumber(rate.lastRunYear)
                if lastMonth == todayMonth and lastYear == todayYear then
                    rate.lastRunDay = todayDay
                elseif lastMonth and lastYear then
                    rate.lastRunDay = getDaysInMonth(lastMonth, lastYear)
                end
            end
        end

        local lastDay = tonumber(rate.lastRunDay)
        local lastMonth = tonumber(rate.lastRunMonth)
        local lastYear = tonumber(rate.lastRunYear)
        if lastDay and lastMonth and lastYear then
            lastDay = math.floor(lastDay)
            lastMonth = math.floor(lastMonth)
            lastYear = math.floor(lastYear)
        end
        local validLastRun = lastDay and lastMonth and lastYear
            and lastYear >= 1970
            and lastMonth >= 1 and lastMonth <= 12
            and lastDay >= 1 and lastDay <= getDaysInMonth(lastMonth, lastYear)
            and getDateKey(lastDay, lastMonth, lastYear) <= todayKey
        if validLastRun then
            rate.lastRunDay = lastDay
            rate.lastRunMonth = lastMonth
            rate.lastRunYear = lastYear
        else
            rate.lastRunDay = nil
            rate.lastRunMonth = nil
            rate.lastRunYear = nil
        end
    end

    database.daily = nil
    database.dailyExpense = nil
    database.rent = nil
    database.lease = nil
    database.lastMonth = nil
end

function Finances:ValidateCalendarData()
    local calendar = addon.CalendarDays
    local meta = addon.CalendarMeta
    local firstDate = type(meta) == "table" and meta.firstDate
    local lastDate = type(meta) == "table" and meta.lastDate
    local expectedCount = type(meta) == "table" and tonumber(meta.dayCount)
    local valid = type(calendar) == "table"
        and type(firstDate) == "string"
        and type(lastDate) == "string"
        and expectedCount and expectedCount > 0
    local count = 0

    if valid then
        for key, storedWeekday in pairs(calendar) do
            count = count + 1
            local year, month, day = key:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
            year, month, day = tonumber(year), tonumber(month), tonumber(day)
            storedWeekday = tonumber(storedWeekday)
            if not year or not month or not day or month < 1 or month > 12
                or day < 1 or day > getDaysInMonth(month, year)
                or not storedWeekday or storedWeekday < 1 or storedWeekday > 7
                or key < firstDate or key > lastDate then
                valid = false
                break
            end

            local calculated = tonumber(date("%w", getCalendarTime(day, month, year))) or 1
            calculated = calculated == 0 and 7 or calculated
            if calculated ~= storedWeekday then
                valid = false
                break
            end
        end
    end

    if not valid or count ~= expectedCount
        or not calendar[firstDate]
        or not calendar[lastDate] then
        valid = false
    end

    addon.CalendarDataValid = valid
    if not valid then
        addon:Print("Die Sicherheits-Kalenderdatei ist unvollständig. Wochentage werden dynamisch berechnet.")
    end
end

local function getRPNameColored()
    local defaultName = UnitName("player") or "Abenteurer"
    if not TRP3_API or not TRP3_API.profile or not TRP3_API.profile.getData then
        return defaultName
    end

    local profile = TRP3_API.profile.getData("player")
    if not profile or not profile.characteristics then
        return defaultName
    end

    local characteristics = profile.characteristics
    local name = trim((characteristics.FN or ""):gsub("%s+", " "))
    if name == "" then
        name = defaultName
    end
    if characteristics.CH and characteristics.CH ~= "" then
        return "|cff" .. characteristics.CH .. name .. "|r"
    end
    return name
end

local function applyButtonColors(button, hovered)
    local r, g, b = addon:GetAccentColor()
    local selected = button.selected == true
    local danger = button.danger == true
    local bgR, bgG, bgB, bgA = 0.025, 0.023, 0.023, 0.88
    local borderR, borderG, borderB, borderA = r, g, b, 0.24
    local textR, textG, textB = 0.84, 0.82, 0.78

    if button.semanticColor == "income" then
        bgR, bgG, bgB, bgA = 0.018, 0.045, 0.027, 0.9
        borderR, borderG, borderB, borderA = 0.18, 0.52, 0.29, 0.55
        textR, textG, textB = 0.56, 0.86, 0.64
        if selected then
            bgR, bgG, bgB, bgA = 0.035, 0.13, 0.065, 0.98
            borderR, borderG, borderB, borderA = 0.3, 0.82, 0.45, 0.92
            textR, textG, textB = 0.72, 1, 0.8
        elseif hovered then
            bgR, bgG, bgB, bgA = 0.03, 0.09, 0.048, 0.96
            borderR, borderG, borderB, borderA = 0.24, 0.7, 0.38, 0.82
            textR, textG, textB = 0.68, 0.96, 0.75
        end
    elseif button.semanticColor == "expense" then
        bgR, bgG, bgB, bgA = 0.05, 0.018, 0.021, 0.9
        borderR, borderG, borderB, borderA = 0.62, 0.15, 0.2, 0.58
        textR, textG, textB = 0.9, 0.56, 0.58
        if selected then
            bgR, bgG, bgB, bgA = 0.15, 0.025, 0.035, 0.98
            borderR, borderG, borderB, borderA = 0.92, 0.22, 0.28, 0.94
            textR, textG, textB = 1, 0.72, 0.72
        elseif hovered then
            bgR, bgG, bgB, bgA = 0.1, 0.025, 0.031, 0.96
            borderR, borderG, borderB, borderA = 0.8, 0.19, 0.24, 0.84
            textR, textG, textB = 0.98, 0.66, 0.67
        end
    elseif danger then
        borderR, borderG, borderB = 0.65, 0.12, 0.14
        textR, textG, textB = 0.9, 0.58, 0.55
    elseif selected then
        bgR, bgG, bgB, bgA = r * 0.24, g * 0.24, b * 0.24, 0.96
        borderR, borderG, borderB, borderA = r, g, b, 0.8
        textR, textG, textB = 1, 0.91, 0.72
    elseif hovered then
        bgR, bgG, bgB, bgA = 0.105, 0.085, 0.08, 0.98
        borderR, borderG, borderB, borderA = math.min(borderR * 1.25, 1), math.min(borderG * 1.25, 1), math.min(borderB * 1.25, 1), 0.7
        textR, textG, textB = 0.98, 0.94, 0.84
    end

    setRoundedPanelColors(button, bgR, bgG, bgB, bgA, borderR, borderG, borderB, borderA)
    if button.label then
        button.label:SetTextColor(textR, textG, textB)
    end
    if button.icon then
        button.icon:SetVertexColor(textR, textG, textB, 0.92)
    end
end

local function createButton(parent, text, width, height)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, height)
    createRoundedPanel(button, math.min(7, math.floor(height / 2)))

    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text or "")
    button.label = label

    button:SetScript("OnEnter", function(current)
        applyButtonColors(current, true)
    end)
    button:SetScript("OnLeave", function(current)
        applyButtonColors(current, false)
        GameTooltip_Hide()
    end)
    applyButtonColors(button, false)
    Finances.buttons[#Finances.buttons + 1] = button
    return button
end

local function createIconButton(parent, iconPath, width)
    local button = createButton(parent, "", width or 24, 22)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(12, 12)
    icon:SetPoint("CENTER")
    icon:SetTexture(iconPath)
    button.icon = icon
    applyButtonColors(button, false)
    return button
end

local function createInput(parent, width, numeric, maxLetters)
    local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    input:SetSize(width, 25)
    input:SetBackdrop(INPUT_BACKDROP)
    input:SetBackdropColor(0.018, 0.017, 0.017, 0.95)
    input:SetBackdropBorderColor(0.32, 0.28, 0.25, 0.42)
    input:SetTextInsets(7, 7, 0, 0)
    input:SetFontObject(GameFontHighlightSmall)
    input:SetAutoFocus(false)
    input:SetNumeric(numeric == true)
    if maxLetters then
        input:SetMaxLetters(maxLetters)
    end
    input:SetScript("OnEscapePressed", input.ClearFocus)
    input:SetScript("OnEnterPressed", input.ClearFocus)
    input:HookScript("OnEditFocusGained", function(current)
        local r, g, b = addon:GetAccentColor()
        current:SetBackdropBorderColor(r, g, b, 0.78)
    end)
    input:HookScript("OnEditFocusLost", function(current)
        current:SetBackdropBorderColor(0.32, 0.28, 0.25, 0.42)
    end)
    return input
end

local function limitTo99(input)
    local value = tonumber(input:GetText()) or 0
    if value > 99 then
        input:SetText("99")
    end
end

local function createCard(parent)
    local card = CreateFrame("Frame", nil, parent)
    createRoundedPanel(card, 8)
    return card
end

local function createScrollArea(parent, contentWidth)
    local area = {}
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:EnableMouseWheel(true)
    area.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(contentWidth, 1)
    scroll:SetScrollChild(content)
    area.content = content

    local track = CreateFrame("Button", nil, parent)
    track:SetWidth(6)
    area.track = track

    local trackTexture = track:CreateTexture(nil, "BACKGROUND")
    trackTexture:SetPoint("TOP", 0, 0)
    trackTexture:SetPoint("BOTTOM", 0, 0)
    trackTexture:SetWidth(2)
    trackTexture:SetColorTexture(0.32, 0.3, 0.28, 0.22)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetSize(5, 30)
    thumb:RegisterForDrag("LeftButton")
    local thumbTexture = thumb:CreateTexture(nil, "ARTWORK")
    thumbTexture:SetAllPoints()
    thumb.texture = thumbTexture
    area.thumb = thumb
    area.offset = 0
    area.range = 0

    function area:Update()
        local range = self.scroll:GetVerticalScrollRange() or 0
        local trackHeight = self.track:GetHeight() or 0
        local viewHeight = self.scroll:GetHeight() or 0
        local contentHeight = viewHeight + range
        self.range = range
        self.offset = clamp(self.offset or 0, 0, range)
        self.scroll:SetVerticalScroll(self.offset)

        local thumbHeight = trackHeight
        if range > 0 and contentHeight > 0 then
            thumbHeight = math.max(28, trackHeight * (viewHeight / contentHeight))
        end
        self.thumb:SetHeight(thumbHeight)
        local fraction = range > 0 and self.offset / range or 0
        local travel = math.max(trackHeight - thumbHeight, 0)
        self.thumb:ClearAllPoints()
        self.thumb:SetPoint("TOP", self.track, "TOP", 0, -fraction * travel)
        self.track:SetAlpha(range > 0 and 1 or 0.2)
    end

    function area:SetOffset(offset)
        self.offset = clamp(offset or 0, 0, self.scroll:GetVerticalScrollRange() or 0)
        self:Update()
    end

    function area:FromCursor()
        local trackTop = self.track:GetTop()
        local trackHeight = self.track:GetHeight() or 0
        local thumbHeight = self.thumb:GetHeight() or 0
        local travel = trackHeight - thumbHeight
        if not trackTop or travel <= 0 or self.range <= 0 then
            return
        end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local fraction = clamp((trackTop - cursorY - thumbHeight / 2) / travel, 0, 1)
        self:SetOffset(fraction * self.range)
    end

    scroll:SetScript("OnMouseWheel", function(_, delta)
        area:SetOffset((area.offset or 0) - delta * 45)
    end)
    scroll:SetScript("OnSizeChanged", function()
        area:Update()
    end)
    track:SetScript("OnMouseDown", function()
        area:FromCursor()
    end)
    thumb:SetScript("OnDragStart", function(current)
        current:SetScript("OnUpdate", function()
            area:FromCursor()
        end)
    end)
    thumb:SetScript("OnDragStop", function(current)
        current:SetScript("OnUpdate", nil)
        area:FromCursor()
    end)
    return area
end

function Finances:AddTransaction(copper, description, metadata)
    local amount = math.floor(tonumber(copper) or 0)
    if amount == 0 then
        return false
    end
    local gold, silver, coins = splitMoney(amount)
    local transaction = {
        time = getCalendarTimestamp(),
        type = amount >= 0 and "income" or "expense",
        gold = gold,
        silver = silver,
        copper = coins,
        copperValue = amount,
        desc = trim(description) ~= "" and trim(description) or "Keine Beschreibung",
    }
    if type(metadata) == "table" then
        transaction.rateId = metadata.rateId
        transaction.rateDate = metadata.rateDate
        transaction.source = metadata.source
    end
    table.insert(SHFinanzenDB.transactions, transaction)
    SHFinanzenDB.balance = (SHFinanzenDB.balance or 0) + amount
    return true
end

function Finances:RecalculateBalance()
    if type(SHFinanzenDB) ~= "table" then
        return 0
    end
    SHFinanzenDB.balance = getTransactionTotal(SHFinanzenDB.transactions)
    return SHFinanzenDB.balance
end

function Finances:ApplyRate(rate)
    self:AddTransaction(getSignedRateAmount(rate), "[Rate] " .. (rate.name or "Unbenannt"), {
        rateId = rate.id,
        rateDate = getDateStamp(),
        source = "rate",
    })
end

function Finances:ProcessCreationDayRates()
    if not SHFinanzenDB.initialSet then
        return 0
    end

    local todayDay, todayMonth, todayYear = getCalendarDate()
    local todayStamp = getDateStamp()
    local applied = 0
    local paymentsByRateId = {}
    local consumedByRateId = {}
    local legacyPayments = {}
    local consumedLegacyPayments = {}
    for _, transaction in ipairs(SHFinanzenDB.transactions or {}) do
        if getTransactionDateStamp(transaction) == todayStamp then
            local description = tostring(transaction.desc or "")
            if description:match("^%[Rate%] ") then
                if type(transaction.rateId) == "string" and transaction.rateId ~= "" then
                    paymentsByRateId[transaction.rateId] = (paymentsByRateId[transaction.rateId] or 0) + 1
                else
                    local key = description .. "\031" .. math.floor(tonumber(transaction.copperValue) or 0)
                    legacyPayments[key] = legacyPayments[key] or {}
                    legacyPayments[key][#legacyPayments[key] + 1] = transaction
                end
            end
        end
    end

    local function consumeExistingPayment(rate)
        local rateId = rate.id
        local exactConsumed = consumedByRateId[rateId] or 0
        if exactConsumed < (paymentsByRateId[rateId] or 0) then
            consumedByRateId[rateId] = exactConsumed + 1
            return true
        end

        if rate.identityVersion == 1 then
            return false
        end

        local key = getRatePaymentKey(rate)
        local legacyConsumed = consumedLegacyPayments[key] or 0
        local transaction = legacyPayments[key] and legacyPayments[key][legacyConsumed + 1]
        if transaction then
            consumedLegacyPayments[key] = legacyConsumed + 1
            transaction.rateId = rateId
            transaction.rateDate = todayStamp
            transaction.source = transaction.source or "rate"
            return true
        end
        return false
    end

    for _, rate in ipairs(SHFinanzenDB.raten or {}) do
        local startDay, startMonth, startYear = parseStoredDate(rate.start, 0, 0, 0)
        local createdToday = startDay == todayDay and startMonth == todayMonth and startYear == todayYear
        if createdToday then
            local dueToday = not rate.paused and isRateDueOnDate(rate, todayDay, todayMonth, todayYear)
            local alreadyPaid = dueToday and consumeExistingPayment(rate)
            if rate.creationDayHandled ~= todayStamp then
                if dueToday then
                    if not alreadyPaid then
                        self:ApplyRate(rate)
                        applied = applied + 1
                    end
                end
                markRateChecked(rate, todayDay, todayMonth, todayYear)
                rate.creationDayHandled = todayStamp
            end
            rate.identityVersion = 1
        end
    end
    return applied
end

function Finances:TestRateSchedule(value)
    local day, month, year = parseTestDate(value)
    if not day then
        addon:Print("Ungültiges Testdatum. Beispiel: /kitar ratentest 2026-07-25")
        return
    end

    local weekday = getWeekdayIndex(day, month, year)
    addon:Print(string.format(
        "Ratentest: %s, %02d.%02d.%04d",
        WEEKDAY_NAMES[weekday], day, month, year
    ))

    local rates = SHFinanzenDB and SHFinanzenDB.raten or {}
    if #rates == 0 then
        addon:Print("Keine automatischen Raten vorhanden.")
        addon:Print("Simulation beendet – Vermögen und Historie wurden nicht verändert.")
        return
    end

    local dueCount = 0
    for _, rate in ipairs(rates) do
        local due = not rate.paused and isRateDueOnDate(rate, day, month, year)
        if due then
            dueCount = dueCount + 1
        end
        local status
        if rate.paused then
            status = "|cff827b73Pausiert|r"
        else
            status = due and "|cff69d58aFällig|r" or "|cff827b73Nicht fällig|r"
        end
        local income = rate.typ ~= "Ausgabe"
        local moneyColor = income and "|cff69d58a" or "|cffff6969"
        local amount = moneyColor .. (income and "+" or "−") .. compactMoneyText(rate.wert, false) .. "|r"
        addon:Print(string.format(
            "%s: %s – %s – %s",
            status, rate.name or "Unbenannt", amount, getRateScheduleText(rate)
        ))
    end

    addon:Print(string.format(
        "Ergebnis: %d von %d Raten fällig. Simulation – keine Daten verändert.",
        dueCount, #rates
    ))
end

function Finances:RunRatesForToday()
    if not SHFinanzenDB.initialSet then
        return
    end
    local day, month, year = getCalendarDate()
    local todayKey = getDateKey(day, month, year)
    for _, rate in ipairs(SHFinanzenDB.raten) do
        local lastDay = tonumber(rate.lastRunDay)
        local lastMonth = tonumber(rate.lastRunMonth)
        local lastYear = tonumber(rate.lastRunYear)
        local wasCheckedToday = lastDay == day and lastMonth == month and lastYear == year
        local lastKey = lastDay and lastMonth and lastYear and getDateKey(lastDay, lastMonth, lastYear)
        if not wasCheckedToday and (not lastKey or lastKey < todayKey) then
            if not rate.paused and isRateDueOnDate(rate, day, month, year) then
                self:ApplyRate(rate)
            end
            markRateChecked(rate, day, month, year)
        end
    end
end

function Finances:RunOfflineCatchup(force)
    if not SHFinanzenDB.initialSet or not SHFinanzenDB.raten then
        return
    end

    local todayDay, todayMonth, todayYear = getCalendarDate()
    local stamp = getDateStamp()
    if not force and SHFinanzenDB.lastPayout == stamp then
        return
    end

    local total = 0
    local incomeTotal = 0
    local expenseTotal = 0
    local dailyMissed = 0
    local monthlyMissed = 0
    local currentKey = getDateKey(todayDay, todayMonth, todayYear)
    local payoutDay, payoutMonth, payoutYear = parseStoredDate(
        SHFinanzenDB.lastPayout,
        todayDay,
        todayMonth,
        todayYear
    )
    if getDateKey(payoutDay, payoutMonth, payoutYear) > currentKey then
        payoutDay, payoutMonth, payoutYear = todayDay, todayMonth, todayYear
    end

    local earliestYear = math.max(1970, todayYear - MAX_CATCHUP_YEARS)
    local earliestDay = math.min(todayDay, getDaysInMonth(todayMonth, earliestYear))
    local earliestKey = getDateKey(earliestDay, todayMonth, earliestYear)
    local payoutKey = getDateKey(payoutDay, payoutMonth, payoutYear)
    if payoutKey < earliestKey then
        payoutDay, payoutMonth, payoutYear = earliestDay, todayMonth, earliestYear
        payoutKey = earliestKey
        addon:Print("Die Offline-Nachbuchung wurde aus Sicherheitsgründen auf die letzten fünf Jahre begrenzt.")
    end
    local catchupAdvancesDate = payoutKey < currentKey

    for _, rate in ipairs(SHFinanzenDB.raten) do
        local amount = tonumber(rate.wert) or 0
        if rate.typ == "Ausgabe" then
            amount = -amount
        end
        local wasCheckedToday = tonumber(rate.lastRunDay) == todayDay
            and tonumber(rate.lastRunMonth) == todayMonth
            and tonumber(rate.lastRunYear) == todayYear
        local cursorDay, cursorMonth, cursorYear = payoutDay, payoutMonth, payoutYear
        local rateOccurrences = 0

        while getDateKey(cursorDay, cursorMonth, cursorYear) < currentKey do
            cursorDay, cursorMonth, cursorYear = getNextCalendarDate(cursorDay, cursorMonth, cursorYear)
            local cursorKey = getDateKey(cursorDay, cursorMonth, cursorYear)
            local mayProcessDay = cursorKey < currentKey or not wasCheckedToday
            if not rate.paused and mayProcessDay and isRateDueOnDate(rate, cursorDay, cursorMonth, cursorYear) then
                total = total + amount
                if amount >= 0 then
                    incomeTotal = incomeTotal + amount
                else
                    expenseTotal = expenseTotal + amount
                end
                rateOccurrences = rateOccurrences + 1
            end
        end

        if rate.intervall == "Monatlich" then
            monthlyMissed = math.max(monthlyMissed, rateOccurrences)
        else
            dailyMissed = math.max(dailyMissed, rateOccurrences)
        end
        if catchupAdvancesDate then
            markRateChecked(rate, todayDay, todayMonth, todayYear)
        end
    end

    if incomeTotal ~= 0 or expenseTotal ~= 0 then
        local description
        if dailyMissed <= 1 and monthlyMissed <= 0 then
            description = "Autom. Rate"
        elseif dailyMissed <= 1 and monthlyMissed == 1 then
            description = "Autom. Rate (M)"
        elseif dailyMissed <= 1 then
            description = string.format("Autom. Rate (%dM)", monthlyMissed)
        elseif monthlyMissed == 0 then
            description = string.format("Autom. Rate (%dT)", dailyMissed)
        else
            description = string.format("Autom. Rate (%dT/%dM)", dailyMissed, monthlyMissed)
        end
        if incomeTotal > 0 and expenseTotal < 0 then
            self:AddTransaction(incomeTotal, description .. " – Einnahmen", { source = "rate-catchup" })
            self:AddTransaction(expenseTotal, description .. " – Ausgaben", { source = "rate-catchup" })
        else
            self:AddTransaction(total, description, { source = "rate-catchup" })
        end
    end

    SHFinanzenDB.lastPayout = stamp
end

function Finances:RunManualCatchup()
    self:SanitizeDB()
    if not SHFinanzenDB.initialSet then
        addon:Print("Lege zuerst unter Finanzen ein Startvermögen fest.")
        return
    end

    local transactionsBefore = #SHFinanzenDB.transactions
    local balanceBefore = SHFinanzenDB.balance or 0
    self:ProcessCreationDayRates()
    self:RunOfflineCatchup(true)
    self:RunRatesForToday()
    self:RefreshAll()

    local addedTransactions = #SHFinanzenDB.transactions - transactionsBefore
    local balanceChange = (SHFinanzenDB.balance or 0) - balanceBefore
    if addedTransactions > 0 then
        local bookingLabel = addedTransactions == 1 and "Buchung" or "Buchungen"
        addon:Print(string.format(
            "Nachbuchung abgeschlossen: %d %s, Vermögensänderung %s.",
            addedTransactions,
            bookingLabel,
            moneyText(balanceChange, false, true)
        ))
    else
        addon:Print("Keine offenen automatischen Raten gefunden.")
    end
end

local function setRowBackground(row, index)
    if not row.background then
        row.background = row:CreateTexture(nil, "BACKGROUND")
        row.background:SetAllPoints()
    end
    if index % 2 == 0 then
        row.background:SetColorTexture(0.08, 0.065, 0.06, 0.4)
    else
        row.background:SetColorTexture(0.025, 0.023, 0.023, 0.38)
    end
end

function Finances:RefreshOverview()
    if not self.balanceText then
        return
    end
    self.helloText:SetText("Hallo " .. getRPNameColored() .. "!")
    self.balanceText:SetText(moneyText(SHFinanzenDB.balance or 0, true, false))
    local positive = (SHFinanzenDB.balance or 0) >= 0
    self.balanceText:SetTextColor(positive and 0.94 or 0.96, positive and 0.82 or 0.4, positive and 0.52 or 0.38)

    local daily = {}
    local monthly = {}
    for _, rate in ipairs(SHFinanzenDB.raten or {}) do
        local sign = rate.typ == "Ausgabe" and "−" or "+"
        local color = rate.typ == "Ausgabe" and "|cffff6969" or "|cff69d58a"
        local line
        if rate.paused then
            line = string.format(
                "|cff827b73[Pausiert] %s|r  |cff9d9489%s|r",
                rate.name or "Unbenannt",
                compactMoneyText(rate.wert, false)
            )
        else
            line = string.format(
                "%s%s %s|r  |cff9d9489%s|r",
                color,
                sign,
                rate.name or "Unbenannt",
                compactMoneyText(rate.wert, false)
            )
        end
        local target = rate.intervall == "Monatlich" and monthly or daily
        if #target < 6 then
            target[#target + 1] = line
        end
    end
    self.dailyRates:SetText(#daily > 0 and table.concat(daily, "\n") or "|cff746e68Keine täglichen Raten|r")
    self.monthlyRates:SetText(#monthly > 0 and table.concat(monthly, "\n") or "|cff746e68Keine monatlichen Raten|r")
    self.startCapitalButton:SetShown(not SHFinanzenDB.initialSet)
end

function Finances:RefreshHistory()
    if not self.historyArea then
        return
    end
    for _, row in ipairs(self.historyRows) do
        row:Hide()
    end

    local rowHeight = 29
    local count = 0
    for index = #SHFinanzenDB.transactions, 1, -1 do
        count = count + 1
        local entry = SHFinanzenDB.transactions[index]
        local row = self.historyRows[count]
        if not row then
            row = CreateFrame("Frame", nil, self.historyArea.content)
            row:SetSize(532, rowHeight - 1)
            setRowBackground(row, count)

            row.date = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.date:SetPoint("LEFT", 8, 0)
            row.date:SetWidth(91)
            row.date:SetJustifyH("LEFT")

            row.kind = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.kind:SetPoint("LEFT", 103, 0)
            row.kind:SetWidth(70)
            row.kind:SetJustifyH("LEFT")

            row.amount = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.amount:SetPoint("LEFT", 177, 0)
            row.amount:SetWidth(112)
            row.amount:SetJustifyH("LEFT")

            row.description = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.description:SetPoint("LEFT", 293, 0)
            row.description:SetWidth(200)
            row.description:SetJustifyH("LEFT")
            row.description:SetWordWrap(false)

            row.delete = createIconButton(row, ICON_CLOSE, 24)
            row.delete:SetPoint("RIGHT", -5, 0)
            row.delete.danger = true
            applyButtonColors(row.delete, false)
            row.delete:HookScript("OnEnter", function(current)
                GameTooltip:SetOwner(current, "ANCHOR_TOP")
                GameTooltip:SetText("Buchung löschen")
                GameTooltip:Show()
            end)
            self.historyRows[count] = row
        end

        setRowBackground(row, count)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(count - 1) * rowHeight)
        row.date:SetText(formatHistoryDate(entry.time))
        row.kind:SetText(entry.type == "expense" and "Ausgabe" or "Einnahme")
        local value = tonumber(entry.copperValue) or 0
        row.amount:SetText((value < 0 and "|cffff6969" or "|cff69d58a") .. compactMoneyText(value, true) .. "|r")
        row.description:SetText(entry.desc or "")
        row.delete:SetScript("OnClick", function()
            Finances:ConfirmDeleteTransaction(entry)
        end)
        row:Show()
    end

    self.historyEmpty:SetShown(count == 0)
    self.historyArea.content:SetHeight(math.max(1, count * rowHeight))
    C_Timer.After(0, function()
        if Finances.historyArea then
            Finances.historyArea:Update()
        end
    end)
end

function Finances:RefreshRates()
    if not self.rateArea then
        return
    end
    for _, row in ipairs(self.rateRows) do
        row:Hide()
    end

    local rowHeight = 32
    for index, rate in ipairs(SHFinanzenDB.raten) do
        local row = self.rateRows[index]
        if not row then
            row = CreateFrame("Frame", nil, self.rateArea.content)
            row:SetSize(532, rowHeight - 1)

            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.name:SetPoint("LEFT", 8, 0)
            row.name:SetWidth(78)
            row.name:SetJustifyH("LEFT")
            row.name:SetWordWrap(false)

            row.amount = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.amount:SetPoint("LEFT", 90, 0)
            row.amount:SetWidth(80)
            row.amount:SetJustifyH("LEFT")

            row.interval = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.interval:SetPoint("LEFT", 174, 0)
            row.interval:SetWidth(78)
            row.interval:SetJustifyH("LEFT")

            row.nextDate = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.nextDate:SetPoint("LEFT", 256, 0)
            row.nextDate:SetWidth(86)
            row.nextDate:SetJustifyH("LEFT")

            row.kind = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.kind:SetPoint("LEFT", 346, 0)
            row.kind:SetWidth(56)
            row.kind:SetJustifyH("LEFT")

            row.delete = createIconButton(row, ICON_CLOSE, 24)
            row.delete:SetPoint("RIGHT", -4, 0)
            row.delete.danger = true
            applyButtonColors(row.delete, false)
            row.delete:HookScript("OnEnter", function(current)
                GameTooltip:SetOwner(current, "ANCHOR_TOP")
                GameTooltip:SetText("Rate löschen")
                GameTooltip:Show()
            end)

            row.toggle = createButton(row, "Pause", 44, 22)
            row.toggle:SetPoint("RIGHT", row.delete, "LEFT", -4, 0)
            row.toggle:HookScript("OnEnter", function(current)
                GameTooltip:SetOwner(current, "ANCHOR_TOP")
                GameTooltip:SetText(current.tooltipText or "Rate pausieren")
                GameTooltip:Show()
            end)

            row.edit = createButton(row, "Ändern", 46, 22)
            row.edit:SetPoint("RIGHT", row.toggle, "LEFT", -4, 0)
            row.edit:HookScript("OnEnter", function(current)
                GameTooltip:SetOwner(current, "ANCHOR_TOP")
                GameTooltip:SetText("Rate bearbeiten")
                GameTooltip:Show()
            end)
            self.rateRows[index] = row
        end

        setRowBackground(row, index)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(index - 1) * rowHeight)
        row.name:SetText(rate.name or "Unbenannt")
        local income = rate.typ ~= "Ausgabe"
        local color = income and "|cff69d58a" or "|cffff6969"
        row.amount:SetText(color .. (income and "+" or "−") .. compactMoneyText(rate.wert, false) .. "|r")
        row.interval:SetText(getRateScheduleText(rate))
        row.nextDate:SetText(getNextRateDateText(rate))
        row.kind:SetText(color .. (rate.typ or "Einnahme") .. "|r")
        row:SetAlpha(rate.paused and 0.62 or 1)
        row.toggle.label:SetText(rate.paused and "Start" or "Pause")
        row.toggle.tooltipText = rate.paused and "Rate fortsetzen" or "Rate pausieren"
        applyButtonColors(row.toggle, false)
        local rateId = rate.id
        local pauseOnClick = not rate.paused
        row.edit:SetScript("OnClick", function()
            Finances:BeginEditRate(rateId)
        end)
        row.toggle:SetScript("OnClick", function()
            Finances:SetRatePaused(rateId, pauseOnClick)
        end)
        row.delete:SetScript("OnClick", function()
            Finances:ConfirmDeleteRate(rateId)
        end)
        row:Show()
    end

    self.rateEmpty:SetShown(#SHFinanzenDB.raten == 0)
    self.rateArea.content:SetHeight(math.max(1, #SHFinanzenDB.raten * rowHeight))
    C_Timer.After(0, function()
        if Finances.rateArea then
            Finances.rateArea:Update()
        end
    end)
end

function Finances:RefreshAll()
    self:RecalculateBalance()
    self:RefreshOverview()
    self:RefreshHistory()
    self:RefreshRates()
end

function Finances:SelectTab(index)
    index = clamp(math.floor(tonumber(index) or 1), 1, #self.tabs)
    SHFinanzenDB.selectedTab = index
    for tabIndex, button in ipairs(self.tabs) do
        button.selected = tabIndex == index
        applyButtonColors(button, false)
        self.pages[tabIndex]:SetShown(tabIndex == index)
    end
    if index == 3 then
        self:RefreshHistory()
    elseif index == 4 then
        self:RefreshRates()
    end
end

function Finances:CreateOverviewPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local hello = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hello:SetPoint("TOP", 0, -4)
    hello:SetFont(hello:GetFont(), 15, "OUTLINE")
    self.helloText = hello

    local balanceCard = createCard(page)
    balanceCard:SetPoint("TOPLEFT", 0, -34)
    balanceCard:SetPoint("TOPRIGHT", 0, -34)
    balanceCard:SetHeight(77)
    self.balanceCard = balanceCard

    local balanceLabel = balanceCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    balanceLabel:SetPoint("TOP", 0, -13)
    balanceLabel:SetText("Vermögen")
    self.balanceLabel = balanceLabel
    self.accentLabels[#self.accentLabels + 1] = balanceLabel

    local balance = balanceCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    balance:SetPoint("TOP", balanceLabel, "BOTTOM", 0, -11)
    balance:SetFont(balance:GetFont(), 17, "OUTLINE")
    self.balanceText = balance

    local dailyCard = createCard(page)
    dailyCard:SetPoint("TOPLEFT", balanceCard, "BOTTOMLEFT", 0, -12)
    dailyCard:SetPoint("BOTTOM", page, "BOTTOM", -6, 0)
    dailyCard:SetWidth(266)
    self.dailyCard = dailyCard

    local dailyHeader = dailyCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dailyHeader:SetPoint("TOPLEFT", 14, -13)
    dailyHeader:SetText("Tägliche Raten")
    self.dailyHeader = dailyHeader
    self.accentLabels[#self.accentLabels + 1] = dailyHeader

    local dailyRates = dailyCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dailyRates:SetPoint("TOPLEFT", dailyHeader, "BOTTOMLEFT", 0, -12)
    dailyRates:SetPoint("RIGHT", -12, 0)
    dailyRates:SetJustifyH("LEFT")
    dailyRates:SetJustifyV("TOP")
    dailyRates:SetSpacing(5)
    self.dailyRates = dailyRates

    local monthlyCard = createCard(page)
    monthlyCard:SetPoint("TOPRIGHT", balanceCard, "BOTTOMRIGHT", 0, -12)
    monthlyCard:SetPoint("BOTTOM", page, "BOTTOM", 6, 0)
    monthlyCard:SetWidth(266)
    self.monthlyCard = monthlyCard

    local monthlyHeader = monthlyCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    monthlyHeader:SetPoint("TOPLEFT", 14, -13)
    monthlyHeader:SetText("Monatliche Raten")
    self.monthlyHeader = monthlyHeader
    self.accentLabels[#self.accentLabels + 1] = monthlyHeader

    local monthlyRates = monthlyCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    monthlyRates:SetPoint("TOPLEFT", monthlyHeader, "BOTTOMLEFT", 0, -12)
    monthlyRates:SetPoint("RIGHT", -12, 0)
    monthlyRates:SetJustifyH("LEFT")
    monthlyRates:SetJustifyV("TOP")
    monthlyRates:SetSpacing(5)
    self.monthlyRates = monthlyRates

    local startButton = createButton(balanceCard, "Startvermögen festlegen", 170, 24)
    startButton:SetPoint("RIGHT", -12, 0)
    startButton:SetScript("OnClick", function()
        Finances.startWindow:ClearAllPoints()
        Finances.startWindow:SetPoint("LEFT", Finances.frame, "RIGHT", 8, 0)
        Finances.startWindow:Show()
    end)
    self.startCapitalButton = startButton
    return page
end

function Finances:CreateTransactionPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 2, -5)
    heading:SetText("Neue Buchung")
    self.transactionHeading = heading
    self.accentLabels[#self.accentLabels + 1] = heading

    local hint = page:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -6)
    hint:SetText("Trage hier Einnahmen und Ausgaben deines RP-Charakters ein.")

    local form = createCard(page)
    form:SetPoint("TOPLEFT", 0, -56)
    form:SetPoint("TOPRIGHT", 0, -56)
    form:SetHeight(190)
    self.transactionCard = form

    local income = createButton(form, "Einnahme", 118, 27)
    income:SetPoint("TOPLEFT", 16, -16)
    income.semanticColor = "income"
    income.selected = true
    applyButtonColors(income, false)
    local expense = createButton(form, "Ausgabe", 118, 27)
    expense:SetPoint("LEFT", income, "RIGHT", 8, 0)
    expense.semanticColor = "expense"
    applyButtonColors(expense, false)
    self.transactionType = "income"
    income:SetScript("OnClick", function()
        Finances.transactionType = "income"
        income.selected = true
        expense.selected = false
        applyButtonColors(income, false)
        applyButtonColors(expense, false)
    end)
    expense:SetScript("OnClick", function()
        Finances.transactionType = "expense"
        expense.selected = true
        income.selected = false
        applyButtonColors(expense, false)
        applyButtonColors(income, false)
    end)
    self.incomeButton = income
    self.expenseButton = expense

    local amountLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    amountLabel:SetPoint("TOPLEFT", income, "BOTTOMLEFT", 1, -17)
    amountLabel:SetText("Betrag")
    self.accentLabels[#self.accentLabels + 1] = amountLabel

    local gold = createInput(form, 66, true, 8)
    gold:SetPoint("TOPLEFT", amountLabel, "BOTTOMLEFT", 0, -6)
    local goldLabel = form:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldLabel:SetPoint("LEFT", gold, "RIGHT", 5, 0)
    goldLabel:SetText("Gold")

    local silver = createInput(form, 54, true, 2)
    silver:SetPoint("LEFT", goldLabel, "RIGHT", 14, 0)
    silver:SetScript("OnTextChanged", limitTo99)
    local silverLabel = form:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    silverLabel:SetPoint("LEFT", silver, "RIGHT", 5, 0)
    silverLabel:SetText("Silber")

    local copper = createInput(form, 54, true, 2)
    copper:SetPoint("LEFT", silverLabel, "RIGHT", 14, 0)
    copper:SetScript("OnTextChanged", limitTo99)
    local copperLabel = form:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copperLabel:SetPoint("LEFT", copper, "RIGHT", 5, 0)
    copperLabel:SetText("Kupfer")

    local descriptionLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descriptionLabel:SetPoint("TOPLEFT", gold, "BOTTOMLEFT", 0, -17)
    descriptionLabel:SetText("Beschreibung")
    self.accentLabels[#self.accentLabels + 1] = descriptionLabel

    local description = createInput(form, 350, false, 80)
    description:SetPoint("TOPLEFT", descriptionLabel, "BOTTOMLEFT", 0, -6)

    local add = createButton(form, "Buchung hinzufügen", 154, 28)
    add:SetPoint("LEFT", description, "RIGHT", 12, 0)
    add:SetScript("OnClick", function()
        local amount = (tonumber(gold:GetText()) or 0) * 10000
            + (tonumber(silver:GetText()) or 0) * 100
            + (tonumber(copper:GetText()) or 0)
        if amount <= 0 then
            addon:Print("Bitte gib einen Betrag für die Buchung ein.")
            return
        end
        if Finances.transactionType == "expense" then
            amount = -amount
        end
        Finances:AddTransaction(amount, description:GetText())
        gold:SetText("")
        silver:SetText("")
        copper:SetText("")
        description:SetText("")
        Finances:RefreshAll()
        addon:Print("Buchung gespeichert: " .. moneyText(amount, false, true))
    end)

    self.transactionGold = gold
    self.transactionSilver = silver
    self.transactionCopper = copper
    self.transactionDescription = description
    return page
end

local function createTableHeader(parent, labels)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(23)
    local background = header:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.07, 0.058, 0.052, 0.72)
    for _, column in ipairs(labels) do
        local label = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("LEFT", column[2], 0)
        label:SetWidth(column[3])
        label:SetJustifyH("LEFT")
        label:SetText(column[1])
        Finances.accentLabels[#Finances.accentLabels + 1] = label
    end
    return header
end

function Finances:CreateHistoryPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 2, -5)
    heading:SetText("Buchungsverlauf")
    self.accentLabels[#self.accentLabels + 1] = heading

    local header = createTableHeader(page, {
        { "Datum", 8, 91 },
        { "Art", 103, 70 },
        { "Betrag", 177, 112 },
        { "Beschreibung", 293, 200 },
    })
    header:SetPoint("TOPLEFT", 0, -38)
    header:SetPoint("TOPRIGHT", -14, -38)

    local area = createScrollArea(page, 532)
    area.scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    area.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -14, 0)
    area.track:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 12, -3)
    area.track:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    self.historyArea = area

    local empty = page:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", area.scroll, "CENTER", 0, 8)
    empty:SetText("Noch keine Buchungen vorhanden.")
    self.historyEmpty = empty
    return page
end

function Finances:SetRateInterval(value)
    self.newRateInterval = value
    self.dailyButton.selected = value == "Täglich"
    self.monthlyButton.selected = value == "Monatlich"
    applyButtonColors(self.dailyButton, false)
    applyButtonColors(self.monthlyButton, false)
    if self.dailySchedule then
        self.dailySchedule:SetShown(value == "Täglich")
    end
    if self.monthlySchedule then
        self.monthlySchedule:SetShown(value == "Monatlich")
    end
end

function Finances:SetRateType(value)
    self.newRateType = value
    self.rateIncomeButton.selected = value == "Einnahme"
    self.rateExpenseButton.selected = value == "Ausgabe"
    applyButtonColors(self.rateIncomeButton, false)
    applyButtonColors(self.rateExpenseButton, false)
end

function Finances:ResetRateForm()
    self.editingRateId = nil
    self.rateName:SetText("")
    self.rateGold:SetText("")
    self.rateSilver:SetText("")
    self.rateCopper:SetText("")
    self.rateBookingDay:SetText("1")
    for index = 1, 7 do
        self.newRateWeekdays[index] = true
        self.weekdayButtons[index].selected = true
        applyButtonColors(self.weekdayButtons[index], false)
    end
    self:SetRateInterval("Täglich")
    self:SetRateType("Einnahme")
    self.rateSubmitButton.label:SetText("Rate hinzufügen")
    self.rateCancelButton:Hide()
end

function Finances:BeginEditRate(rateId)
    local rate = findRateById(rateId)
    if not rate then
        addon:Print("Die ausgewählte Rate wurde nicht gefunden.")
        self:RefreshRates()
        return
    end

    self.editingRateId = rate.id
    self.rateName:SetText(rate.name or "")
    local gold, silver, copper = splitMoney(rate.wert)
    self.rateGold:SetText(gold > 0 and tostring(gold) or "")
    self.rateSilver:SetText(silver > 0 and tostring(silver) or "")
    self.rateCopper:SetText(copper > 0 and tostring(copper) or "")
    self:SetRateType(rate.typ)
    self:SetRateInterval(rate.intervall)
    local weekdays = normalizeWeekdays(rate.weekdays)
    for index = 1, 7 do
        self.newRateWeekdays[index] = weekdays[index]
        self.weekdayButtons[index].selected = weekdays[index]
        applyButtonColors(self.weekdayButtons[index], false)
    end
    self.rateBookingDay:SetText(tostring(clamp(math.floor(tonumber(rate.bookingDay) or 1), 1, 31)))
    self.rateSubmitButton.label:SetText("Änderung speichern")
    self.rateCancelButton:Show()
end

local function weekdaySchedulesMatch(left, right)
    left = normalizeWeekdays(left)
    right = normalizeWeekdays(right)
    for index = 1, 7 do
        if left[index] ~= right[index] then
            return false
        end
    end
    return true
end

function Finances:SaveRateForm()
    local amount = (tonumber(self.rateGold:GetText()) or 0) * 10000
        + (tonumber(self.rateSilver:GetText()) or 0) * 100
        + (tonumber(self.rateCopper:GetText()) or 0)
    if amount <= 0 then
        addon:Print("Bitte gib einen Betrag für die Rate ein.")
        return
    end

    local interval = self.newRateInterval or "Täglich"
    local weekdays
    local bookingDay
    if interval == "Täglich" then
        weekdays = {}
        local hasWorkday = false
        for index = 1, 7 do
            weekdays[index] = self.newRateWeekdays[index] == true
            hasWorkday = hasWorkday or weekdays[index]
        end
        if not hasWorkday then
            addon:Print("Bitte wähle mindestens einen Arbeitstag aus.")
            return
        end
    else
        bookingDay = tonumber(self.rateBookingDay:GetText())
        if not bookingDay or bookingDay < 1 or bookingDay > 31 then
            addon:Print("Bitte wähle einen Buchungstag zwischen 1 und 31.")
            return
        end
        bookingDay = math.floor(bookingDay)
    end

    local rateName = trim(self.rateName:GetText())
    rateName = rateName ~= "" and rateName or "Unbenannt"
    local editingRate = self.editingRateId and findRateById(self.editingRateId)
    local paidToday = 0
    if editingRate then
        local scheduleChanged = editingRate.intervall ~= interval
            or (interval == "Täglich" and not weekdaySchedulesMatch(editingRate.weekdays, weekdays))
            or (interval == "Monatlich"
                and math.floor(tonumber(editingRate.bookingDay) or 1) ~= bookingDay)
        editingRate.name = rateName
        editingRate.wert = amount
        editingRate.typ = self.newRateType or "Einnahme"
        editingRate.intervall = interval
        editingRate.weekdays = weekdays
        editingRate.bookingDay = bookingDay
        if scheduleChanged then
            local day, month, year = getCalendarDate()
            markRateChecked(editingRate, day, month, year)
            editingRate.creationDayHandled = getDateStamp()
        end
        addon:Print("Automatische Rate aktualisiert.")
    else
        SHFinanzenDB.raten[#SHFinanzenDB.raten + 1] = {
            id = allocateRateId(SHFinanzenDB),
            identityVersion = 1,
            name = rateName,
            wert = amount,
            typ = self.newRateType or "Einnahme",
            intervall = interval,
            start = getStoredCalendarDate(),
            weekdays = weekdays,
            bookingDay = bookingDay,
            paused = false,
        }
        paidToday = self:ProcessCreationDayRates()
        addon:Print("Automatische Rate hinzugefügt.")
    end

    self:ResetRateForm()
    self:RefreshAll()
    if paidToday > 0 then
        addon:Print("Die heute fällige Rate wurde direkt gebucht.")
    end
end

function Finances:SetRatePaused(rateId, paused)
    local rate = findRateById(rateId)
    if not rate then
        self:RefreshRates()
        return
    end
    rate.paused = paused == true
    local day, month, year = getCalendarDate()
    markRateChecked(rate, day, month, year)
    rate.creationDayHandled = getDateStamp()
    self:RefreshAll()
    addon:Print(rate.paused and "Automatische Rate pausiert." or "Automatische Rate fortgesetzt.")
end

function Finances:DeleteTransaction(transaction)
    for index, current in ipairs(SHFinanzenDB.transactions or {}) do
        if current == transaction then
            table.remove(SHFinanzenDB.transactions, index)
            self:RecalculateBalance()
            self:RefreshAll()
            addon:Print("Buchung gelöscht.")
            return
        end
    end
    self:RefreshHistory()
end

function Finances:DeleteRate(rateId)
    local rate, index = findRateById(rateId)
    if not rate then
        self:RefreshRates()
        return
    end
    table.remove(SHFinanzenDB.raten, index)
    if self.editingRateId == rateId then
        self:ResetRateForm()
    end
    self:RefreshAll()
    addon:Print("Automatische Rate gelöscht.")
end

function Finances:ConfirmDeleteTransaction(transaction)
    StaticPopup_Show(
        "KITARCOMPANION_DELETE_TRANSACTION",
        transaction.desc or "Keine Beschreibung",
        nil,
        transaction
    )
end

function Finances:ConfirmDeleteRate(rateId)
    local rate = findRateById(rateId)
    if rate then
        StaticPopup_Show("KITARCOMPANION_DELETE_RATE", rate.name or "Unbenannt", nil, rate.id)
    end
end

function Finances:CreateRatesPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()

    local heading = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 2, -5)
    heading:SetText("Automatische Raten")
    self.accentLabels[#self.accentLabels + 1] = heading

    local form = createCard(page)
    form:SetPoint("TOPLEFT", 0, -37)
    form:SetPoint("TOPRIGHT", 0, -37)
    form:SetHeight(138)
    self.rateFormCard = form

    local nameLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", 13, -11)
    nameLabel:SetText("Bezeichnung")
    self.accentLabels[#self.accentLabels + 1] = nameLabel
    local name = createInput(form, 160, false, 50)
    name:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -5)

    local amountLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    amountLabel:SetPoint("TOPLEFT", 190, -11)
    amountLabel:SetText("Gold / Silber / Kupfer")
    self.accentLabels[#self.accentLabels + 1] = amountLabel
    local gold = createInput(form, 48, true, 8)
    gold:SetPoint("TOPLEFT", amountLabel, "BOTTOMLEFT", 0, -5)
    local silver = createInput(form, 40, true, 2)
    silver:SetPoint("LEFT", gold, "RIGHT", 5, 0)
    silver:SetScript("OnTextChanged", limitTo99)
    local copper = createInput(form, 40, true, 2)
    copper:SetPoint("LEFT", silver, "RIGHT", 5, 0)
    copper:SetScript("OnTextChanged", limitTo99)

    local intervalLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    intervalLabel:SetPoint("TOPLEFT", 339, -11)
    intervalLabel:SetText("Intervall")
    self.accentLabels[#self.accentLabels + 1] = intervalLabel
    local daily = createButton(form, "Täglich", 75, 25)
    daily:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", 0, -5)
    local monthly = createButton(form, "Monatlich", 75, 25)
    monthly:SetPoint("LEFT", daily, "RIGHT", 5, 0)
    daily:SetScript("OnClick", function() Finances:SetRateInterval("Täglich") end)
    monthly:SetScript("OnClick", function() Finances:SetRateInterval("Monatlich") end)
    self.dailyButton = daily
    self.monthlyButton = monthly

    local typeLabel = form:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeLabel:SetPoint("TOPLEFT", 13, -64)
    typeLabel:SetText("Art")
    self.accentLabels[#self.accentLabels + 1] = typeLabel
    local income = createButton(form, "Einnahme", 88, 25)
    income:SetPoint("LEFT", typeLabel, "RIGHT", 8, 0)
    income.semanticColor = "income"
    local expense = createButton(form, "Ausgabe", 88, 25)
    expense:SetPoint("LEFT", income, "RIGHT", 5, 0)
    expense.semanticColor = "expense"
    income:SetScript("OnClick", function() Finances:SetRateType("Einnahme") end)
    expense:SetScript("OnClick", function() Finances:SetRateType("Ausgabe") end)
    self.rateIncomeButton = income
    self.rateExpenseButton = expense

    local dailySchedule = CreateFrame("Frame", nil, form)
    dailySchedule:SetPoint("TOPLEFT", 13, -101)
    dailySchedule:SetSize(390, 24)
    self.dailySchedule = dailySchedule

    local workdayLabel = dailySchedule:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    workdayLabel:SetPoint("LEFT", 0, 0)
    workdayLabel:SetWidth(76)
    workdayLabel:SetJustifyH("LEFT")
    workdayLabel:SetText("Arbeitstage")
    self.accentLabels[#self.accentLabels + 1] = workdayLabel

    self.newRateWeekdays = {}
    self.weekdayButtons = {}
    for index, label in ipairs(WEEKDAY_LABELS) do
        local weekdayIndex = index
        self.newRateWeekdays[weekdayIndex] = true
        local weekdayButton = createButton(dailySchedule, label, 31, 23)
        if weekdayIndex == 1 then
            weekdayButton:SetPoint("LEFT", workdayLabel, "RIGHT", 4, 0)
        else
            weekdayButton:SetPoint("LEFT", self.weekdayButtons[weekdayIndex - 1], "RIGHT", 3, 0)
        end
        weekdayButton.selected = true
        applyButtonColors(weekdayButton, false)
        weekdayButton:SetScript("OnClick", function(current)
            Finances.newRateWeekdays[weekdayIndex] = not Finances.newRateWeekdays[weekdayIndex]
            current.selected = Finances.newRateWeekdays[weekdayIndex]
            applyButtonColors(current, false)
        end)
        self.weekdayButtons[weekdayIndex] = weekdayButton
    end

    local monthlySchedule = CreateFrame("Frame", nil, form)
    monthlySchedule:SetPoint("TOPLEFT", 13, -101)
    monthlySchedule:SetSize(390, 24)
    self.monthlySchedule = monthlySchedule

    local bookingDayLabel = monthlySchedule:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bookingDayLabel:SetPoint("LEFT", 0, 0)
    bookingDayLabel:SetText("Buchungstag")
    self.accentLabels[#self.accentLabels + 1] = bookingDayLabel

    local bookingDay = createInput(monthlySchedule, 43, true, 2)
    bookingDay:SetPoint("LEFT", bookingDayLabel, "RIGHT", 9, 0)
    bookingDay:SetText("1")
    bookingDay:SetScript("OnTextChanged", function(current)
        local value = tonumber(current:GetText())
        if value and value > 31 then
            current:SetText("31")
        end
    end)
    self.rateBookingDay = bookingDay

    local bookingDayHint = monthlySchedule:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    bookingDayHint:SetPoint("LEFT", bookingDay, "RIGHT", 8, 0)
    bookingDayHint:SetText("Tag im Monat (1–31)")

    local add = createButton(form, "Rate hinzufügen", 130, 27)
    add:SetPoint("TOPRIGHT", -13, -61)
    add:SetScript("OnClick", function()
        Finances:SaveRateForm()
    end)
    self.rateSubmitButton = add

    local cancel = createButton(form, "Abbrechen", 78, 27)
    cancel:SetPoint("RIGHT", add, "LEFT", -6, 0)
    cancel:SetScript("OnClick", function()
        Finances:ResetRateForm()
    end)
    cancel:Hide()
    self.rateCancelButton = cancel

    local header = createTableHeader(page, {
        { "Name", 8, 78 },
        { "Betrag", 90, 80 },
        { "Zeitplan", 174, 78 },
        { "Nächste", 256, 86 },
        { "Art", 346, 56 },
    })
    header:SetPoint("TOPLEFT", form, "BOTTOMLEFT", 0, -9)
    header:SetPoint("TOPRIGHT", form, "BOTTOMRIGHT", -14, -9)

    local area = createScrollArea(page, 532)
    area.scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    area.scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -14, 0)
    area.track:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 12, -3)
    area.track:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    self.rateArea = area

    local empty = page:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("CENTER", area.scroll, "CENTER", 0, 5)
    empty:SetText("Noch keine automatischen Raten vorhanden.")
    self.rateEmpty = empty

    self.rateName = name
    self.rateGold = gold
    self.rateSilver = silver
    self.rateCopper = copper
    self:ResetRateForm()
    return page
end

function Finances:CreateStartWindow()
    local window = CreateFrame("Frame", "KitarCompanionStartCapitalFrame", UIParent, "BackdropTemplate")
    window:SetSize(310, 178)
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetBackdrop(EDGE_BACKDROP)
    window:SetBackdropBorderColor(addon:GetAccentColor())
    window:Hide()

    local underlay = window:CreateTexture(nil, "BACKGROUND", nil, -8)
    underlay:SetAllPoints()
    underlay:SetColorTexture(0.015, 0.012, 0.012, 0.99)

    local art = window:CreateTexture(nil, "BACKGROUND", nil, -7)
    art:SetAllPoints()
    art:SetTexture(PANEL_TEXTURE)
    art:SetTexCoord(0, 1, 0, 683 / 1024)
    art:SetVertexColor(0.82, 0.82, 0.82, 0.9)

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 17, -17)
    title:SetText("Startvermögen")
    self.accentLabels[#self.accentLabels + 1] = title

    local close = createIconButton(window, ICON_CLOSE, 24)
    close:SetPoint("TOPRIGHT", -13, -13)
    close:SetScript("OnClick", function() window:Hide() end)

    local label = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    label:SetText("Wie viel besitzt dein Charakter zu Beginn?")

    local gold = createInput(window, 72, true, 8)
    gold:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -16)
    local goldLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    goldLabel:SetPoint("LEFT", gold, "RIGHT", 5, 0)
    goldLabel:SetText("G")

    local silver = createInput(window, 54, true, 2)
    silver:SetPoint("LEFT", goldLabel, "RIGHT", 12, 0)
    silver:SetScript("OnTextChanged", limitTo99)
    local silverLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    silverLabel:SetPoint("LEFT", silver, "RIGHT", 5, 0)
    silverLabel:SetText("S")

    local copper = createInput(window, 54, true, 2)
    copper:SetPoint("LEFT", silverLabel, "RIGHT", 12, 0)
    copper:SetScript("OnTextChanged", limitTo99)
    local copperLabel = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copperLabel:SetPoint("LEFT", copper, "RIGHT", 5, 0)
    copperLabel:SetText("K")

    local cancel = createButton(window, "Abbrechen", 110, 27)
    cancel:SetPoint("BOTTOMLEFT", 17, 15)
    cancel:SetScript("OnClick", function() window:Hide() end)

    local save = createButton(window, "Übernehmen", 110, 27)
    save:SetPoint("BOTTOMRIGHT", -17, 15)
    save:SetScript("OnClick", function()
        local amount = (tonumber(gold:GetText()) or 0) * 10000
            + (tonumber(silver:GetText()) or 0) * 100
            + (tonumber(copper:GetText()) or 0)
        if amount <= 0 then
            addon:Print("Bitte gib ein Startvermögen ein.")
            return
        end
        Finances:AddTransaction(amount, "Startkapital")
        SHFinanzenDB.initialSet = true
        SHFinanzenDB.lastPayout = getDateStamp()
        local paidToday = Finances:ProcessCreationDayRates()
        Finances:RunRatesForToday()
        gold:SetText("")
        silver:SetText("")
        copper:SetText("")
        window:Hide()
        Finances:RefreshAll()
        addon:Print("Startvermögen gespeichert: " .. moneyText(amount, false, false))
        if paidToday > 0 then
            addon:Print("Heute fällige Raten wurden direkt gebucht.")
        end
    end)

    self.startWindow = window
end

function Finances:CreateWindow()
    local frame = CreateFrame("Frame", "KitarCompanionFinanceFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetBackdrop(EDGE_BACKDROP)

    local r, g, b = addon:GetAccentColor()
    frame:SetBackdropBorderColor(r, g, b, 0.72)

    local underlay = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    underlay:SetAllPoints()
    underlay:SetColorTexture(0.015, 0.012, 0.012, 0.98)

    local panelArt = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    panelArt:SetAllPoints()
    panelArt:SetTexture(PANEL_TEXTURE)
    panelArt:SetTexCoord(0, 1, 0, 683 / 1024)
    panelArt:SetVertexColor(0.86, 0.86, 0.86, 0.96)
    self.panelArt = panelArt

    local position = SHFinanzenDB.position
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
    self.frame = frame

    local function startWindowDrag()
        frame:StartMoving()
    end

    local function stopWindowDrag()
        frame:StopMovingOrSizing()
        local point, _, relativePoint, x, y = frame:GetPoint()
        SHFinanzenDB.position = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = math.floor((x or 0) + 0.5),
            y = math.floor((y or 0) + 0.5),
        }
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

    local brand = CreateFrame("Frame", nil, header)
    brand:SetSize(132, 24)
    brand:SetPoint("CENTER", header, "CENTER", 0, 0)
    createRoundedPanel(brand, 7)
    setRoundedPanelColors(brand, 0.018, 0.018, 0.018, 0.78, r, g, b, 0.26)
    self.brandPanel = brand

    local brandTitle = brand:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    brandTitle:SetPoint("CENTER")
    brandTitle:SetText("Kitar Companion")
    self.brandTitle = brandTitle

    local close = createIconButton(header, ICON_CLOSE, 24)
    close:SetPoint("RIGHT", -5, 0)
    close:SetScript("OnClick", function()
        frame:Hide()
        SHFinanzenDB.windowOpen = false
    end)
    close:HookScript("OnEnter", function(current)
        GameTooltip:SetOwner(current, "ANCHOR_TOP")
        GameTooltip:SetText("Fenster schließen")
        GameTooltip:Show()
    end)

    local tabHolder = CreateFrame("Frame", nil, frame)
    tabHolder:SetPoint("TOPLEFT", 28, -55)
    tabHolder:SetPoint("TOPRIGHT", -28, -55)
    tabHolder:SetHeight(28)

    local tabNames = { "Übersicht", "Buchung", "Historie", "Raten" }
    for index, tabName in ipairs(tabNames) do
        local tab = createButton(tabHolder, tabName, 130, 27)
        if index == 1 then
            tab:SetPoint("LEFT", 0, 0)
        else
            tab:SetPoint("LEFT", self.tabs[index - 1], "RIGHT", 8, 0)
        end
        tab:SetScript("OnClick", function()
            Finances:SelectTab(index)
        end)
        self.tabs[index] = tab
    end

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 28, -94)
    content:SetPoint("BOTTOMRIGHT", -28, 22)
    self.content = content

    self.pages[1] = self:CreateOverviewPage(content)
    self.pages[2] = self:CreateTransactionPage(content)
    self.pages[3] = self:CreateHistoryPage(content)
    self.pages[4] = self:CreateRatesPage(content)
    enableWindowDrag(content)
    enableWindowDrag(self.historyArea.scroll)
    enableWindowDrag(self.rateArea.scroll)
    self:CreateStartWindow()

    frame:SetScript("OnShow", function()
        SHFinanzenDB.windowOpen = true
        Finances:RefreshAll()
        Finances:SelectTab(SHFinanzenDB.selectedTab or 1)
    end)
    frame:SetScript("OnHide", function()
        if Finances.startWindow then
            Finances.startWindow:Hide()
        end
    end)
    frame:Hide()
end

function Finances:Toggle()
    if not self.frame then
        return
    end
    if self.frame:IsShown() then
        self.frame:Hide()
        SHFinanzenDB.windowOpen = false
    else
        self.frame:Show()
        SHFinanzenDB.windowOpen = true
    end
end

function Finances:ResetPosition()
    SHFinanzenDB.position = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
    }
    if self.frame then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

function Finances:HideLegacyFrames()
    if SHFinanzenFrame and SHFinanzenFrame ~= self.frame then
        SHFinanzenFrame:Hide()
    end
    if SHFinanzen_MinimapButton then
        SHFinanzen_MinimapButton:Hide()
    end
end

function Finances:DisableLegacyRateProcessing()
    local legacyAddons = {
        rawget(_G, "SHRoleplay"),
        rawget(_G, "SH_Roleplay"),
    }
    for _, legacyAddon in pairs(legacyAddons) do
        local legacyFinances = type(legacyAddon) == "table"
            and type(legacyAddon.modules) == "table"
            and legacyAddon.modules.Finances
        if type(legacyFinances) == "table" and legacyFinances ~= self then
            legacyFinances.Enable = function() end
        end
    end

    local standaloneFunctions = {
        "SH_ApplyRate",
        "SH_RunRates_WoWCalendar",
        "SH_OfflineRateCatchup",
    }
    for _, functionName in ipairs(standaloneFunctions) do
        if type(rawget(_G, functionName)) == "function" then
            rawset(_G, functionName, function() end)
        end
    end
end

function Finances:ResetData()
    SHFinanzenDB.transactions = {}
    SHFinanzenDB.raten = {}
    SHFinanzenDB.balance = 0
    SHFinanzenDB.initialSet = false
    SHFinanzenDB.lastPayout = ""
    SHFinanzenDB.lastRateCatchup = nil
    SHFinanzenDB.rateUnit = "copper"
    SHFinanzenDB.kitarBalanceHistoryVersion = BALANCE_HISTORY_VERSION
    SHFinanzenDB.nextRateId = 1
    SHFinanzenDB.selectedTab = 1

    if self.startWindow then
        self.startWindow:Hide()
    end
    self:RefreshAll()
    self:SelectTab(1)
    addon:Print("Die Finanzdaten dieses Charakters wurden zurückgesetzt.")
end

function Finances:ConfirmReset()
    StaticPopup_Show("KITARCOMPANION_RESET_FINANCES")
end

function Finances:Refresh()
    if not self.frame then
        return
    end
    local r, g, b = addon:GetAccentColor()
    self.frame:SetBackdropBorderColor(r, g, b, 0.72)
    setRoundedPanelColors(self.brandPanel, 0.018, 0.018, 0.018, 0.78, r, g, b, 0.26)
    self.brandTitle:SetTextColor(0.93, 0.88, 0.78)
    setRoundedPanelColors(self.balanceCard, 0.024, 0.021, 0.02, 0.9, r, g, b, 0.28)
    setRoundedPanelColors(self.dailyCard, 0.021, 0.019, 0.019, 0.88, r, g, b, 0.18)
    setRoundedPanelColors(self.monthlyCard, 0.021, 0.019, 0.019, 0.88, r, g, b, 0.18)
    setRoundedPanelColors(self.transactionCard, 0.021, 0.019, 0.019, 0.9, r, g, b, 0.22)
    setRoundedPanelColors(self.rateFormCard, 0.021, 0.019, 0.019, 0.9, r, g, b, 0.22)
    for _, label in ipairs(self.accentLabels) do
        label:SetTextColor(r, g, b)
    end
    self.historyArea.thumb.texture:SetColorTexture(r, g, b, 0.92)
    self.rateArea.thumb.texture:SetColorTexture(r, g, b, 0.92)
    if self.startWindow then
        self.startWindow:SetBackdropBorderColor(r, g, b, 0.72)
    end
    for _, button in ipairs(self.buttons) do
        applyButtonColors(button, false)
    end
end

function Finances:Initialize()
    self:DisableLegacyRateProcessing()
    self:ValidateCalendarData()
    self:SanitizeDB()
    local importsLegacyData = IsAddOnLoaded and (IsAddOnLoaded("SHFinanzen") or IsAddOnLoaded("SH_Roleplay"))
    local firstImport = importsLegacyData and not SHFinanzenDB.importedIntoKitarCompanion
    if importsLegacyData then
        SHFinanzenDB.importedIntoKitarCompanion = true
    end
    self:CreateWindow()
    self:SelectTab(SHFinanzenDB.selectedTab or 1)
    self:Refresh()
    self:RefreshAll()

    SLASH_KITARFINANCES1 = "/kfin"
    SlashCmdList.KITARFINANCES = function(message)
        local command, argument = string.match(message or "", "^%s*(%S*)%s*(.-)%s*$")
        command = string.lower(command or "")
        if command == "test" or command == "ratentest" then
            Finances:TestRateSchedule(argument)
        elseif command == "nachbuchen" then
            Finances:RunManualCatchup()
        else
            Finances:Toggle()
        end
    end

    StaticPopupDialogs.KITARCOMPANION_RESET_FINANCES = {
        text = "Alle Buchungen, Raten und das Startvermögen dieses Charakters wirklich löschen?",
        button1 = "Zurücksetzen",
        button2 = CANCEL,
        OnAccept = function()
            Finances:ResetData()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs.KITARCOMPANION_DELETE_TRANSACTION = {
        text = "Buchung „%s“ wirklich löschen?\nDer Kontostand wird automatisch angepasst.",
        button1 = "Löschen",
        button2 = CANCEL,
        OnAccept = function(_, transaction)
            Finances:DeleteTransaction(transaction)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs.KITARCOMPANION_DELETE_RATE = {
        text = "Automatische Rate „%s“ wirklich löschen?\nBereits gebuchte Einträge bleiben erhalten.",
        button1 = "Löschen",
        button2 = CANCEL,
        OnAccept = function(_, rateId)
            Finances:DeleteRate(rateId)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    if importsLegacyData then
        C_Timer.After(0.3, function()
            Finances:HideLegacyFrames()
        end)
        if firstImport then
            addon:Print("Vorhandene Finanzdaten wurden in Kitar Companion übernommen. Nach dem Ausloggen können die alten Addons deaktiviert werden.")
        end
    end
end

function Finances:Enable()
    self:SanitizeDB()
    if SHFinanzenDB.initialSet then
        local repairedRates = self:ProcessCreationDayRates()
        self:RunOfflineCatchup(false)
        self:RunRatesForToday()
        if repairedRates > 0 then
            addon:Print("Eine heute fällige Rate wurde automatisch nachgetragen.")
        end
    end
    self.lastObservedRateDate = getDateStamp()
    if not self.rateTicker then
        self.rateTicker = C_Timer.NewTicker(60, function()
            local currentStamp = getDateStamp()
            if currentStamp ~= Finances.lastObservedRateDate then
                Finances.lastObservedRateDate = currentStamp
                if SHFinanzenDB.initialSet then
                    Finances:RunOfflineCatchup(false)
                    Finances:RunRatesForToday()
                    Finances:RefreshAll()
                end
            end
        end)
    end
    self:RefreshAll()
    if SHFinanzenDB.windowOpen then
        self.frame:Show()
    else
        self.frame:Hide()
    end
    self:HideLegacyFrames()
end
