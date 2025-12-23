local ConfigFrame = CreateFrame("Frame", "TattleTotemConfigFrame", UIParent)
ConfigFrame:SetWidth(380)
ConfigFrame:SetHeight(520)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ConfigFrame:SetFrameStrata("DIALOG")
ConfigFrame:EnableMouse(true)
ConfigFrame:SetMovable(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", function(self)
    local frame = self or this
    if frame then frame:StartMoving() end
end)
ConfigFrame:SetScript("OnDragStop", function(self)
    local frame = self or this
    if frame then frame:StopMovingOrSizing() end
end)
ConfigFrame:Hide()

ConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
ConfigFrame:SetBackdropColor(0, 0, 0, 0.85)

local titleBg = ConfigFrame:CreateTexture(nil, "ARTWORK")
titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
titleBg:SetWidth(300)
titleBg:SetHeight(64)
titleBg:SetPoint("TOP", ConfigFrame, "TOP", 0, 12)

local titleText = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", ConfigFrame, "TOP", 0, -4)
titleText:SetText("TattleTotem Configuration")

local closeBtn = CreateFrame("Button", nil, ConfigFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() ConfigFrame:Hide() end)

local function CreateCheckbox(parent, name, label, x, y, onClick, tooltip)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetWidth(26)
    cb:SetHeight(26)

    local text = getglobal(name .. "Text")
    if text then
        text:SetText(label)
        text:SetFontObject(GameFontNormal)
    end

    if onClick then
        cb:SetScript("OnClick", onClick)
    end

    if tooltip then
        cb:SetScript("OnEnter", function(self)
            local owner = self or this
            if not owner then return end
            GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    return cb
end

local function CreateSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(text)
    header:SetTextColor(1, 0.82, 0)

    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, 0.3)
    line:SetWidth(340)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)

    return header
end

local function CreateRadioGroup(parent, name, options, x, y, defaultValue, onChange)
    local buttons = {}
    local yOffset = 0

    for i, opt in ipairs(options) do
        local rb = CreateFrame("CheckButton", name .. "_" .. tostring(i), parent, "UIRadioButtonTemplate")
        rb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - yOffset)
        rb:SetWidth(20)
        rb:SetHeight(20)

        local text = getglobal(name .. "_" .. tostring(i) .. "Text")
        if text then
            text:SetText(opt.label)
            text:SetFontObject(GameFontHighlight)
        end

        rb.value = opt.value
        rb.groupButtons = buttons

        rb:SetScript("OnClick", function(self)
            local btnSelf = self or this
            if not btnSelf then return end
            for _, btn in ipairs(btnSelf.groupButtons) do
                btn:SetChecked(btn == btnSelf)
            end
            if onChange then
                onChange(btnSelf.value)
            end
        end)

        if opt.value == defaultValue then
            rb:SetChecked(true)
        end

        table.insert(buttons, rb)
        yOffset = yOffset + 22
    end

    return buttons
end

local masterEnable = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_MasterEnable",
    "|cff00ff00Enable TattleTotem|r",
    20, -40,
    function(self)
        local cb = self or this
        if not cb then return end
        TattleTotemDB.enabled = cb:GetChecked()
        TattleTotem_UpdateMinimapButton()
    end,
    "Master toggle - enables or disables all TattleTotem functionality"
)

local debugMode = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_DebugMode",
    "Debug Mode (monitor everywhere)",
    20, -70,
    function(self)
        local cb = self or this
        if not cb then return end
        TattleTotemDB.debugMode = cb:GetChecked()
        if TattleTotemDB.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Debug ON - monitoring all zones")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Debug OFF - Naxxramas only")
        end
    end,
    "When enabled, monitors AoE casts in any zone and outputs to local chat (for testing)"
)

CreateSectionHeader(ConfigFrame, "Output Method", 20, -110)

local outputOptions = {
    { label = "Yell (/yell)", value = "YELL" },
    { label = "Raid Warning (/rw)", value = "RAID_WARNING" },
    { label = "Say (/say)", value = "SAY" },
}

local outputRadios = CreateRadioGroup(
    ConfigFrame,
    "TattleTotem_Output",
    outputOptions,
    30, -135,
    "YELL",
    function(value)
        TattleTotemDB.outputMethod = value
    end
)

CreateSectionHeader(ConfigFrame, "Four Horsemen Monitoring", 20, -210)

local monitor4HM = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_Monitor4HM",
    "Monitor 4HM First Pull",
    30, -235,
    function(self)
        local cb = self or this
        if not cb then return end
        TattleTotemDB.monitor4HM = cb:GetChecked()
    end,
    "Announce who pulled first (tracks first boss hit when out of combat)"
)

CreateSectionHeader(ConfigFrame, "Kel'Thuzad Monitoring", 20, -275)

local ktAoE = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_KT_AoE",
    "Monitor AoE Spell Casts",
    30, -300,
    function(self)
        local cb = self or this
        if not cb then return end
        TattleTotemDB.ktMonitor.aoe = cb:GetChecked()
    end,
    "Announce when players cast AoE spells during KT fight"
)

local ktShackle = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_KT_Shackle",
    "Monitor Shackle Breaks",
    30, -325,
    function(self)
        local cb = self or this
        if not cb then return end
        TattleTotemDB.ktMonitor.shackle = cb:GetChecked()
    end,
    "Announce when a player breaks Shackle Undead on Guardian"
)

local ktPets = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_KT_Pets",
    "Warn Hunters With Pets Out",
    30, -350,
    function(self)
        local cb = self or this
        if not cb then return end
        TattleTotemDB.ktMonitor.pets = cb:GetChecked()
    end,
    "Announce hunters who have pets out during KT fight"
)

CreateSectionHeader(ConfigFrame, "AoE Spells to Monitor", 20, -390)

local scrollContainer = CreateFrame("Frame", nil, ConfigFrame)
scrollContainer:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -415)
scrollContainer:SetWidth(340)
scrollContainer:SetHeight(100)
scrollContainer:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
scrollContainer:SetBackdropColor(0, 0, 0, 0.5)

local scrollFrame = CreateFrame("ScrollFrame", "TattleTotem_SpellScroll", scrollContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", scrollContainer, "TOPLEFT", 5, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", scrollContainer, "BOTTOMRIGHT", -27, 5)

local scrollChild = CreateFrame("Frame", "TattleTotem_SpellScrollChild", scrollFrame)
scrollChild:SetWidth(300)
scrollFrame:SetScrollChild(scrollChild)

local spellList = {
    { name = "Multi-Shot", class = "Hunter" },
    { name = "Volley", class = "Hunter" },
    { name = "Carve", class = "Hunter" },
    { name = "Arcane Explosion", class = "Mage" },
    { name = "Blizzard", class = "Mage" },
    { name = "Cone of Cold", class = "Mage" },
    { name = "Flamestrike", class = "Mage" },
    { name = "Blast Wave", class = "Mage" },
    { name = "Frost Nova", class = "Mage" },
    { name = "Icicles", class = "Mage" },
    { name = "Rain of Fire", class = "Warlock" },
    { name = "Hellfire", class = "Warlock" },
    { name = "Howl of Terror", class = "Warlock" },
    { name = "Holy Wrath", class = "Paladin" },
    { name = "Consecration", class = "Paladin" },
    { name = "Chain Lightning", class = "Shaman" },
    { name = "Magma Totem", class = "Shaman" },
    { name = "Fire Nova Totem", class = "Shaman" },
    { name = "Holy Nova", class = "Priest" },
    { name = "Hurricane", class = "Druid" },
    { name = "Swipe", class = "Druid" },
    { name = "Whirlwind", class = "Warrior" },
    { name = "Cleave", class = "Warrior" },
    { name = "Thunder Clap", class = "Warrior" },
    { name = "Sweeping Strikes", class = "Warrior" },
    { name = "Blade Flurry", class = "Rogue" },
}

local spellCheckboxes = {}
local spellOffset = 0

for _, spell in ipairs(spellList) do
    local safeName = string.gsub(spell.name, " ", "_")
    local label = spell.name .. " |cff888888(" .. spell.class .. ")|r"
    local cb = CreateCheckbox(
        scrollChild,
        "TattleTotem_Spell_" .. safeName,
        label,
        5, -spellOffset,
        function(self)
            local cb = self or this
            if not cb then return end
            if TattleTotemDB and TattleTotemDB.spells then
                TattleTotemDB.spells[spell.name] = cb:GetChecked()
            end
        end
    )
    cb.spellName = spell.name
    table.insert(spellCheckboxes, cb)
    spellOffset = spellOffset + 22
end

scrollChild:SetHeight(spellOffset + 10)

function TattleTotem_LoadConfigUI()
    if not TattleTotemDB then return end

    masterEnable:SetChecked(TattleTotemDB.enabled)
    debugMode:SetChecked(TattleTotemDB.debugMode)

    for _, rb in ipairs(outputRadios) do
        rb:SetChecked(rb.value == TattleTotemDB.outputMethod)
    end

    monitor4HM:SetChecked(TattleTotemDB.monitor4HM)

    if TattleTotemDB.ktMonitor then
        ktAoE:SetChecked(TattleTotemDB.ktMonitor.aoe)
        ktShackle:SetChecked(TattleTotemDB.ktMonitor.shackle)
        if TattleTotemDB.ktMonitor.pets ~= nil then
            ktPets:SetChecked(TattleTotemDB.ktMonitor.pets)
        end
    end

    for _, cb in ipairs(spellCheckboxes) do
        if TattleTotemDB.spells and cb.spellName then
            cb:SetChecked(TattleTotemDB.spells[cb.spellName])
        end
    end
end

function TattleTotem_ToggleConfig()
    if ConfigFrame:IsVisible() then
        ConfigFrame:Hide()
    else
        TattleTotem_LoadConfigUI()
        ConfigFrame:Show()
    end
end

SLASH_TATTLETOTEM1 = "/tattletotem"
SLASH_TATTLETOTEM2 = "/tt"

SlashCmdList["TATTLETOTEM"] = function(msg)
    local cmd = string.lower(msg or "")

    if cmd == "" or cmd == "config" or cmd == "options" then
        TattleTotem_ToggleConfig()

    elseif cmd == "enable" or cmd == "on" then
        TattleTotemDB.enabled = true
        getglobal("TattleTotem_MasterEnable"):SetChecked(true)
        TattleTotem_UpdateMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TattleTotem:|r Enabled")

    elseif cmd == "disable" or cmd == "off" then
        TattleTotemDB.enabled = false
        getglobal("TattleTotem_MasterEnable"):SetChecked(false)
        TattleTotem_UpdateMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TattleTotem:|r Disabled")

    elseif cmd == "debug" then
        TattleTotemDB.debugMode = not TattleTotemDB.debugMode
        getglobal("TattleTotem_DebugMode"):SetChecked(TattleTotemDB.debugMode)
        if TattleTotemDB.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Debug ON - monitoring all zones")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Debug OFF - Naxxramas only")
        end

    elseif cmd == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem Status:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Enabled: " .. (TattleTotemDB.enabled and "|cff00ff00Yes|r" or "|cffff0000No|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Debug: " .. (TattleTotemDB.debugMode and "|cff00ff00On|r" or "|cffaaaaaa Off|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Output: " .. tostring(TattleTotemDB.outputMethod))
        DEFAULT_CHAT_FRAME:AddMessage("  Zone: " .. tostring(GetRealZoneText()))

    elseif cmd == "test" then
        local method = TattleTotemDB.outputMethod
        if TattleTotemDB.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[TattleTotem]|r TestPlayer AoE: Arcane Explosion")
        else
            SendChatMessage("TestPlayer AoE: Arcane Explosion", method)
        end
    elseif string.find(cmd, "^logs") then
        local _, _, arg = string.find(cmd, "^logs%s*(.*)$")
        local logs = TattleTotemDB.pullLogs or {}
        local total = table.getn(logs)
        if total == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r No pull logs recorded.")
            return
        end

        local count
        if arg == "all" then
            count = total
        else
            count = tonumber(arg)
            if not count or count <= 0 then
                count = 10
            end
        end

        local start = total - count + 1
        if start < 1 then start = 1 end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Showing " .. (total - start + 1) .. " of " .. total .. " logs")
        for i = start, total do
            local e = logs[i] or {}
            local stamp = e.stamp or "?"
            local puller = e.puller or "Unknown"
            local boss = e.boss or "Unknown"
            local source = e.source or ""
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem|r " .. stamp .. " - " .. puller .. " pulled " .. boss .. (source ~= "" and (" (" .. source .. ")") or ""))
        end

    elseif cmd == "clearlogs" then
        TattleTotemDB.pullLogs = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Pull logs cleared.")

    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt - Open config window")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt enable - Enable addon")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt disable - Disable addon")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt debug - Toggle debug mode")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt status - Show current status")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt test - Send test message")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt logs [N|all] - Show last N pull logs (default 10)")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt clearlogs - Clear pull logs")
    end
end
