# Vanilla 1.12 UI Examples for TattleTotem

Copy-paste ready code patterns for Turtle WoW addon development.

---\n
## Complete Config Frame Example

```lua
-- Config.lua
-- Full configuration window with all UI elements

local ADDON_NAME = "TattleTotem"

-- Create main frame
local ConfigFrame = CreateFrame("Frame", "TattleTotemConfigFrame", UIParent)
ConfigFrame:SetWidth(380)
ConfigFrame:SetHeight(550)
ConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
ConfigFrame:SetFrameStrata("DIALOG")
ConfigFrame:EnableMouse(true)
ConfigFrame:SetMovable(true)
ConfigFrame:RegisterForDrag("LeftButton")
ConfigFrame:SetScript("OnDragStart", function() this:StartMoving() end)
ConfigFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
ConfigFrame:Hide()

-- Semi-transparent background (0.8 alpha = 80% opacity)
ConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
ConfigFrame:SetBackdropColor(0, 0, 0, 0.85)

-- Title bar
local titleBg = ConfigFrame:CreateTexture(nil, "ARTWORK")
titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
titleBg:SetWidth(300)
titleBg:SetHeight(64)
titleBg:SetPoint("TOP", ConfigFrame, "TOP", 0, 12)

local titleText = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", ConfigFrame, "TOP", 0, -4)
titleText:SetText("TattleTotem Configuration")

-- Close button (X)
local closeBtn = CreateFrame("Button", nil, ConfigFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", ConfigFrame, "TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() ConfigFrame:Hide() end)

---------------------------------------------
-- CHECKBOX HELPER FUNCTION
---------------------------------------------
local function CreateCheckbox(parent, name, label, x, y, onClick, tooltip)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetWidth(26)
    cb:SetHeight(26)
    
    -- Label text
    local text = getglobal(name .. "Text")
    if text then
        text:SetText(label)
        text:SetFontObject(GameFontNormal)
    end
    
    -- Click handler
    if onClick then
        cb:SetScript("OnClick", onClick)
    end
    
    -- Tooltip
    if tooltip then
        cb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltip, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return cb
end

---------------------------------------------
-- SECTION HEADER HELPER
---------------------------------------------
local function CreateSectionHeader(parent, text, x, y)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    header:SetText(text)
    header:SetTextColor(1, 0.82, 0)  -- Gold color
    
    -- Underline
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 1, 1, 0.3)
    line:SetWidth(340)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    
    return header
end

---------------------------------------------
-- RADIO BUTTON GROUP HELPER
---------------------------------------------
local function CreateRadioGroup(parent, name, options, x, y, defaultValue, onChange)
    local buttons = {}
    local yOffset = 0
    
    for i, opt in ipairs(options) do
        local rb = CreateFrame("CheckButton", name .. "_" .. i, parent, "UIRadioButtonTemplate")
        rb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - yOffset)
        rb:SetWidth(20)
        rb:SetHeight(20)
        
        local text = getglobal(name .. "_" .. i .. "Text")
        if text then
            text:SetText(opt.label)
            text:SetFontObject(GameFontHighlight)
        end
        
        rb.value = opt.value
        rb.groupButtons = buttons
        
        rb:SetScript("OnClick", function()
            -- Uncheck all others in group
            for _, btn in ipairs(this.groupButtons) do
                btn:SetChecked(btn == this)
            end
            if onChange then
                onChange(this.value)
            end
        end)
        
        -- Set default
        if opt.value == defaultValue then
            rb:SetChecked(true)
        end
        
        table.insert(buttons, rb)
        yOffset = yOffset + 22
    end
    
    return buttons
end

---------------------------------------------
-- MASTER ENABLE TOGGLE (Big and prominent)
---------------------------------------------
local masterEnable = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_MasterEnable",
    "|cff00ff00Enable TattleTotem|r",
    20, -40,
    function()
        TattleTotemDB.enabled = this:GetChecked()
        if TattleTotemDB.enabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TattleTotem:|r Enabled")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TattleTotem:|r Disabled")
        end
    end,
    "Master toggle - enables or disables all TattleTotem functionality"
)

---------------------------------------------
-- DEBUG MODE TOGGLE
---------------------------------------------
local debugMode = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_DebugMode",
    "Debug Mode (monitor everywhere)",
    20, -70,
    function()
        TattleTotemDB.debugMode = this:GetChecked()
        DEFAULT_CHAT_FRAME:AddMessage("TattleTotem Debug: " .. (TattleTotemDB.debugMode and "ON" or "OFF"))
    end,
    "When enabled, monitors AoE casts in any zone (for testing)"
)

---------------------------------------------
-- OUTPUT METHOD SECTION
---------------------------------------------
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

---------------------------------------------
-- FOUR HORSEMEN SECTION
---------------------------------------------
CreateSectionHeader(ConfigFrame, "Four Horsemen Monitoring", 20, -210)

local monitor4HM = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_Monitor4HM",
    "Monitor 4HM First Pull",
    30, -235,
    function()
        TattleTotemDB.monitor4HM = this:GetChecked()
    end,
    "Announce who pulled first (any horseman)"
)
monitor4HM:SetChecked(true)

---------------------------------------------
-- KEL'THUZAD SECTION
---------------------------------------------
CreateSectionHeader(ConfigFrame, "Kel'Thuzad Monitoring", 20, -275)

local ktAoE = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_KT_AoE",
    "Monitor AoE Spell Casts",
    30, -300,
    function()
        TattleTotemDB.ktMonitor.aoe = this:GetChecked()
    end,
    "Announce when players cast AoE spells during KT fight"
)
ktAoE:SetChecked(true)

local ktShackle = CreateCheckbox(
    ConfigFrame,
    "TattleTotem_KT_Shackle",
    "Monitor Shackle Breaks",
    30, -325,
    function()
        TattleTotemDB.ktMonitor.shackle = this:GetChecked()
    end,
    "Announce when a player breaks Shackle Undead on Guardian"
)
ktShackle:SetChecked(true)

---------------------------------------------
-- SCROLLABLE SPELL LIST
---------------------------------------------
CreateSectionHeader(ConfigFrame, "AoE Spells to Monitor", 20, -365)

-- Scroll frame container
local scrollContainer = CreateFrame("Frame", nil, ConfigFrame)
scrollContainer:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -390)
scrollContainer:SetWidth(340)
scrollContainer:SetHeight(120)
scrollContainer:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
scrollContainer:SetBackdropColor(0, 0, 0, 0.5)

-- Scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "TattleTotem_SpellScroll", scrollContainer, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", scrollContainer, "TOPLEFT", 5, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", scrollContainer, "BOTTOMRIGHT", -27, 5)

-- Scroll child (content)
local scrollChild = CreateFrame("Frame", "TattleTotem_SpellScrollChild", scrollFrame)
scrollChild:SetWidth(300)
scrollFrame:SetScrollChild(scrollChild)

-- Add spell checkboxes to scroll child
local spellList = {
    { name = "Multi-Shot", class = "Hunter" },
    { name = "Volley", class = "Hunter" },
    { name = "Carve", class = "Hunter (TWoW)" },
    { name = "Arcane Explosion", class = "Mage" },
    { name = "Blizzard", class = "Mage" },
    { name = "Cone of Cold", class = "Mage" },
    { name = "Flamestrike", class = "Mage" },
    { name = "Blast Wave", class = "Mage" },
    { name = "Frost Nova", class = "Mage" },
    { name = "Icicles", class = "Mage (TWoW)" },
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

local spellOffset = 0
for _, spell in ipairs(spellList) do
    local label = spell.name .. " |cff888888(" .. spell.class .. ")|r"
    local cb = CreateCheckbox(
        scrollChild,
        "TattleTotem_Spell_" .. string.gsub(spell.name, " ", "_"),
        label,
        5, -spellOffset,
        function()
            TattleTotemDB.spells[spell.name] = this:GetChecked()
        end
    )
    cb:SetChecked(true)
    cb.spellName = spell.name
    spellOffset = spellOffset + 22
end

-- Set scroll child height based on content
scrollChild:SetHeight(spellOffset + 10)

---------------------------------------------
-- ANTI-SPAM COOLDOWN SLIDER
---------------------------------------------
local cooldownLabel = ConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cooldownLabel:SetPoint("TOPLEFT", ConfigFrame, "TOPLEFT", 20, -590)
cooldownLabel:SetText("Anti-Spam Cooldown: 5 sec")

-- Note: Vanilla slider is complex, using simple approach
-- For a real slider, use "OptionsSliderTemplate"

---------------------------------------------
-- LOAD SAVED VALUES FUNCTION
---------------------------------------------
function TattleTotem_LoadConfigUI()
    if not TattleTotemDB then return end
    
    masterEnable:SetChecked(TattleTotemDB.enabled)
    debugMode:SetChecked(TattleTotemDB.debugMode)
    
    -- Set radio button
    for _, rb in ipairs(outputRadios) do
        rb:SetChecked(rb.value == TattleTotemDB.outputMethod)
    end
    
    -- Set 4HM checkbox (single toggle now)
    monitor4HM:SetChecked(TattleTotemDB.monitor4HM)
    
    -- Set KT checkboxes
    ktAoE:SetChecked(TattleTotemDB.ktMonitor.aoe)
    ktShackle:SetChecked(TattleTotemDB.ktMonitor.shackle)
    
    -- Set spell checkboxes (iterate scroll child)
    -- This would need to iterate the spell checkboxes
end

---------------------------------------------
-- TOGGLE FUNCTION
---------------------------------------------
function TattleTotem_ToggleConfig()
    if ConfigFrame:IsVisible() then
        ConfigFrame:Hide()
    else
        TattleTotem_LoadConfigUI()
        ConfigFrame:Show()
    end
end
```

---\n

## Slash Command Registration

```lua
-- Slash commands
SLASH_TATTLETOTEM1 = "/tattletotem"
SLASH_TATTLETOTEM2 = "/tt"

SlashCmdList["TATTLETOTEM"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "" or cmd == "config" or cmd == "options" then
        TattleTotem_ToggleConfig()
        
    elseif cmd == "enable" or cmd == "on" then
        TattleTotemDB.enabled = true
        getglobal("TattleTotem_MasterEnable"):SetChecked(true)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TattleTotem:|r Enabled")
        
    elseif cmd == "disable" or cmd == "off" then
        TattleTotemDB.enabled = false
        getglobal("TattleTotem_MasterEnable"):SetChecked(false)
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TattleTotem:|r Disabled")
        
    elseif cmd == "debug" then
        TattleTotemDB.debugMode = not TattleTotemDB.debugMode
        getglobal("TattleTotem_DebugMode"):SetChecked(TattleTotemDB.debugMode)
        if TattleTotemDB.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff00ffTattleTotem:|r Debug mode ON - monitoring all zones")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff00ffTattleTotem:|r Debug mode OFF - Naxxramas only")
        end
        
    elseif cmd == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem Status:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Enabled: " .. (TattleTotemDB.enabled and "|cff00ff00Yes|r" or "|cffff0000No|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Debug Mode: " .. (TattleTotemDB.debugMode and "|cff00ff00On|r" or "|cffaaaaaa Off|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Output: " .. TattleTotemDB.outputMethod)
        DEFAULT_CHAT_FRAME:AddMessage("  Zone: " .. GetRealZoneText())
        
    elseif cmd == "test" then
        -- Send a test message
        local method = TattleTotemDB.outputMethod
        if TattleTotemDB.debugMode then
            DEFAULT_CHAT_FRAME:AddMessage("[TattleTotem TEST] TestPlayer cast AoE: Arcane Explosion")
        else
            SendChatMessage("TestPlayer cast AoE: Arcane Explosion", method)
        end
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/tt|r - Open config window")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/tt enable|r - Enable addon")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/tt disable|r - Disable addon")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/tt debug|r - Toggle debug mode")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/tt status|r - Show current status")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffffff/tt test|r - Send test message")
    end
end
```

---\n

## Event Frame Pattern

```lua
-- Core.lua
-- Main addon logic with event handling

local TattleTotem = CreateFrame("Frame", "TattleTotemFrame", UIParent)

-- State tracking
TattleTotem.recentCasts = {}      -- { playerSpell = timestamp }
TattleTotem.activeShackles = {}   -- { index = { time, caster } }
TattleTotem.horsemenPulled = {}   -- { bossName = pullerName }
TattleTotem.inKTFight = false
TattleTotem.inHorsemenFight = false

-- Register events
local events = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "CHAT_MSG_SPELL_SELF_DAMAGE",
    "CHAT_MSG_SPELL_PARTY_DAMAGE",
    "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
    "CHAT_MSG_SPELL_AURA_GONE_OTHER",
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
}

for _, event in ipairs(events) do
    TattleTotem:RegisterEvent(event)
end

-- Main event handler
TattleTotem:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TattleTotem" then
        TattleTotem:OnLoad()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        TattleTotem:OnZoneChange()
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        TattleTotem:OnSpellDamage(arg1, UnitName("player"))
    elseif event == "CHAT_MSG_SPELL_PARTY_DAMAGE" or event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE" then
        TattleTotem:OnSpellDamage(arg1)
    elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
        TattleTotem:OnCreatureDebuff(arg1)
    elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
        TattleTotem:OnAuraFade(arg1)
    elseif string.find(event, "CHAT_MSG_COMBAT_CREATURE") then
        TattleTotem:OnBossAttack(arg1)
    end
end)

---------------------------------------------
-- INITIALIZATION
---------------------------------------------
function TattleTotem:OnLoad()
    -- Initialize saved variables with defaults
    if not TattleTotemDB then
        TattleTotemDB = {
            enabled = true,
            debugMode = false,
            outputMethod = "YELL",
            cooldown = 5,
            monitor4HM = true,  -- Single toggle for 4HM first pull
            ktMonitor = {
                aoe = true,
                shackle = true,
            },
            spells = {},
        }
        
        -- Default all spells to enabled
        for spellName, _ in pairs(TattleTotem_AoESpells) do
            TattleTotemDB.spells[spellName] = true
        end
    end
    
    -- Set combat log range CVars
    SetCVar("CombatDeathLogRange", 200)
    SetCVar("CombatLogRangeParty", 200)
    SetCVar("CombatLogRangePartyPet", 200)
    SetCVar("CombatLogRangeFriendlyPlayers", 200)
    SetCVar("CombatLogRangeFriendlyPlayersPets", 200)
    SetCVar("CombatLogRangeHostilePlayers", 200)
    SetCVar("CombatLogRangeHostilePlayersPets", 200)
    SetCVar("CombatLogRangeCreature", 200)
    
    -- MINIMAL CHAT: No spam on load, just silently ready
end

---------------------------------------------
-- ZONE DETECTION
---------------------------------------------
function TattleTotem:OnZoneChange()
    local zone = GetRealZoneText()
    local subzone = GetMinimapZoneText()
    
    local wasIn4HM = self.in4HMArea
    local wasInKT = self.inKTChamber
    
    self.inNaxxramas = (zone == "Naxxramas")
    self.inKTChamber = (subzone == "Kel'Thuzad Chamber" or subzone == "The Inner Sanctum")
    self.in4HMArea = (subzone == "The Four Horsemen" or subzone == "Deathknight Wing")
    
    -- Brief "Ready" message when entering boss areas (local chat only)
    if self.in4HMArea and not wasIn4HM then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff4HM|r Ready")
    end
    if self.inKTChamber and not wasInKT then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffKT|r Ready")
    end
    
    -- Reset fight states on zone change
    self.inKTFight = false
    self.horsemenPuller = nil  -- Single puller tracking
    self.activeShackles = {}
end

function TattleTotem:ShouldMonitor()
    if TattleTotemDB.debugMode then
        return true
    end
    return self.inNaxxramas
end

---------------------------------------------
-- SPELL DAMAGE PARSING
---------------------------------------------
function TattleTotem:OnSpellDamage(msg, forcedCaster)
    if not TattleTotemDB.enabled then return end
    if not self:ShouldMonitor() then return end
    if not TattleTotemDB.ktMonitor.aoe then return end
    
    local caster, spell
    
    -- Parse "PlayerName's SpellName hits/crits"
    local _, _, c, s = string.find(msg, "(.+)'s (.+) hits")
    if not c then
        _, _, c, s = string.find(msg, "(.+)'s (.+) crits")
    end
    
    -- Parse "Your SpellName hits/crits"
    if not c and forcedCaster then
        _, _, s = string.find(msg, "Your (.+) hits")
        if not s then
            _, _, s = string.find(msg, "Your (.+) crits")
        end
        c = forcedCaster
    end
    
    if c and s then
        -- Strip rank: "Multi-Shot (Rank 4)" -> "Multi-Shot"
        local baseSpell = string.gsub(s, " %(Rank %d+%) ", "")
        
        -- Check if it's a monitored AoE spell
        if TattleTotem_AoESpells[baseSpell] and TattleTotemDB.spells[baseSpell] then
            self:RecordAoECast(c, baseSpell)
            self:ReportAoE(c, baseSpell)
        end
    end
end

---------------------------------------------
-- AOE TRACKING & REPORTING
---------------------------------------------
function TattleTotem:RecordAoECast(caster, spell)
    local key = caster .. "_" .. spell
    self.recentCasts[key] = GetTime()
end

function TattleTotem:ReportAoE(caster, spell)
    -- Anti-spam check
    local key = caster .. "_" .. spell .. "_reported"
    local now = GetTime()
    local lastReport = self.recentCasts[key]
    
    if lastReport and (now - lastReport) < TattleTotemDB.cooldown then
        return  -- Still on cooldown
    end
    
    self.recentCasts[key] = now
    
    -- Short message: "PlayerName AoE: SpellName"
    local message = caster .. " AoE: " .. spell
    
    -- Send it
    if TattleTotemDB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[TattleTotem]|r " .. message)
    else
        SendChatMessage(message, TattleTotemDB.outputMethod)
    end
end

---------------------------------------------
-- SHACKLE DETECTION
---------------------------------------------
function TattleTotem:OnCreatureDebuff(msg)
    if not TattleTotemDB.enabled then return end
    if not TattleTotemDB.ktMonitor.shackle then return end
    
    -- "Guardian of Icecrown is afflicted by Shackle Undead."
    if string.find(msg, "Guardian of Icecrown is afflicted by Shackle Undead") then
        table.insert(self.activeShackles, {
            time = GetTime(),
            duration = 50,  -- Shackle Undead duration
        })
    end
end

function TattleTotem:OnAuraFade(msg)
    if not TattleTotemDB.enabled then return end
    if not TattleTotemDB.ktMonitor.shackle then return end
    
    -- "Shackle Undead fades from Guardian of Icecrown."
    if string.find(msg, "Shackle Undead fades from Guardian of Icecrown") then
        local now = GetTime()
        local shackle = table.remove(self.activeShackles, 1)
        
        if shackle then
            local elapsed = now - shackle.time
            
            -- If it faded early (more than 5 sec before expected), it was broken
            if elapsed < (shackle.duration - 5) then
                self:CheckShackleBreaker()
            end
        end
    end
end

function TattleTotem:CheckShackleBreaker()
    local now = GetTime()
    local window = 0.5  -- Check casts within last 0.5 seconds
    
    for key, timestamp in pairs(self.recentCasts) do
        if (now - timestamp) < window then
            -- Extract caster and spell from key
            local _, _, caster, spell = string.find(key, "(.+)_(.+)")
            if caster and spell and not string.find(key, "_reported") then
                -- Short message: "PlayerName BROKE SHACKLE! (SpellName)"
                local message = caster .. " BROKE SHACKLE! (" .. spell .. ")"
                
                if TattleTotemDB.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TattleTotem]|r " .. message)
                else
                    SendChatMessage(message, TattleTotemDB.outputMethod)
                end
                return
            end
        end
    end
end

---------------------------------------------
-- FOUR HORSEMEN PULL DETECTION
---------------------------------------------
local HORSEMEN = {
    ["Thane Korth'azz"] = true,
    ["Highlord Mograine"] = true,
    ["Sir Zeliek"] = true,
    ["Lady Blaumeux"] = true,
}

function TattleTotem:OnBossAttack(msg)
    if not TattleTotemDB.enabled then return end
    if not TattleTotemDB.monitor4HM then return end
    if not self:ShouldMonitor() then return end
    
    -- Already reported a puller this fight? Skip.
    if self.horsemenPuller then return end
    
    -- Pattern: "BossName hits/crits/misses PlayerName"
    for bossName, _ in pairs(HORSEMEN) do
        local patterns = {
            bossName .. " hits (.+) for",
            bossName .. " crits (.+) for",
            bossName .. " misses (.+)%. ",
            bossName .. " attacks (.+)%. ",
        }
        
        for _, pattern in ipairs(patterns) do
            local _, _, target = string.find(msg, pattern)
            if target then
                -- FIRST hit by ANY horseman = the puller
                self.horsemenPuller = target
                self:ReportPull(target)
                return
            end
        end
    end
end

function TattleTotem:ReportPull(player)
    -- Short message: "PlayerName pulled 4HM!"
    local message = player .. " pulled 4HM!"
    
    if TattleTotemDB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TattleTotem]|r " .. message)
    else
        SendChatMessage(message, TattleTotemDB.outputMethod)
    end
end

---------------------------------------------
-- CLEANUP TIMER
---------------------------------------------
TattleTotem.cleanupTimer = 0
TattleTotem:SetScript("OnUpdate", function()
    this.cleanupTimer = this.cleanupTimer + arg1
    if this.cleanupTimer > 10 then
        this.cleanupTimer = 0
        
        -- Clean old entries from recentCasts
        local now = GetTime()
        for key, timestamp in pairs(TattleTotem.recentCasts) do
            if (now - timestamp) > 60 then
                TattleTotem.recentCasts[key] = nil
            end
        end
    end
end)
```

---\n

## SpellData.lua

```lua
-- SpellData.lua
-- Complete list of AoE spells to monitor

TattleTotem_AoESpells = {
    -- Hunter
    ["Multi-Shot"] = { class = "HUNTER" },
    ["Volley"] = { class = "HUNTER" },
    ["Carve"] = { class = "HUNTER" },  -- TWoW Custom
    ["Explosive Trap"] = { class = "HUNTER" },
    
    -- Mage
    ["Arcane Explosion"] = { class = "MAGE" },
    ["Blizzard"] = { class = "MAGE" },
    ["Cone of Cold"] = { class = "MAGE" },
    ["Flamestrike"] = { class = "MAGE" },
    ["Blast Wave"] = { class = "MAGE" },
    ["Frost Nova"] = { class = "MAGE" },
    ["Icicles"] = { class = "MAGE" },  -- TWoW Custom
    
    -- Warlock
    ["Rain of Fire"] = { class = "WARLOCK" },
    ["Hellfire"] = { class = "WARLOCK" },
    ["Howl of Terror"] = { class = "WARLOCK" },
    
    -- Paladin
    ["Holy Wrath"] = { class = "PALADIN" },
    ["Consecration"] = { class = "PALADIN" },
    
    -- Shaman
    ["Chain Lightning"] = { class = "SHAMAN" },
    ["Magma Totem"] = { class = "SHAMAN" },
    ["Fire Nova Totem"] = { class = "SHAMAN" },
    
    -- Priest
    ["Holy Nova"] = { class = "PRIEST" },
    
    -- Druid
    ["Hurricane"] = { class = "DRUID" },
    ["Swipe"] = { class = "DRUID" },
    
    -- Warrior
    ["Whirlwind"] = { class = "WARRIOR" },
    ["Cleave"] = { class = "WARRIOR" },
    ["Thunder Clap"] = { class = "WARRIOR" },
    ["Sweeping Strikes"] = { class = "WARRIOR" },
    
    -- Rogue
    ["Blade Flurry"] = { class = "ROGUE" },
}
```

---\n

## TOC File

```toc
## Interface: 11200
## Title: |cff00ffffTattleTotem|r
## Notes: Announces AoE casts, shackle breaks, and bad pulls in Naxxramas
## Author: Todd
## Version: 1.0.0
## SavedVariablesPerCharacter: TattleTotemDB

SpellData.lua
MinimapButton.lua
Config.lua
Core.lua
```

---\n

## MinimapButton.lua (Copy pattern from ProcEm)

**Reference:** https://github.com/Jahfonte/ProcEm

```lua
-- MinimapButton.lua
-- Minimap button for TattleTotem (based on ProcEm pattern)

local minimapShapes = {
    ["ROUND"] = { true, true, true, true },
    ["SQUARE"] = { false, false, false, false },
    ["CORNER-TOPLEFT"] = { false, false, false, true },
    ["CORNER-TOPRIGHT"] = { false, false, true, false },
    ["CORNER-BOTTOMLEFT"] = { false, true, false, false },
    ["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
    ["SIDE-LEFT"] = { false, true, false, true },
    ["SIDE-RIGHT"] = { true, false, true, false },
    ["SIDE-TOP"] = { false, false, true, true },
    ["SIDE-BOTTOM"] = { true, true, false, false },
    ["TRICORNER-TOPLEFT"] = { false, true, true, true },
    ["TRICORNER-TOPRIGHT"] = { true, false, true, true },
    ["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local function GetMinimapShape()
    return GetMinimapShape and GetMinimapShape() or "ROUND"
end

-- Create the minimap button
local button = CreateFrame("Button", "TattleTotemMinimapButton", Minimap)
button:SetWidth(31)
button:SetHeight(31)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button:RegisterForDrag("LeftButton")

-- Overlay border
local overlay = button:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

-- Icon
local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_02")  -- Shackle-like icon
icon:SetPoint("CENTER", button, "CENTER", 0, 0)
button.icon = icon

-- Position update function
local function UpdatePosition()
    local angle = TattleTotemDB and TattleTotemDB.minimapAngle or 225
    local radius = 80
    local rads = math.rad(angle)
    local x = math.cos(rads) * radius
    local y = math.sin(rads) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Dragging
local isDragging = false
button:SetScript("OnDragStart", function()
    isDragging = true
    this:LockHighlight()
end)

button:SetScript("OnDragStop", function()
    isDragging = false
    this:UnlockHighlight()
    -- Calculate angle from center
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx))
    if TattleTotemDB then
        TattleTotemDB.minimapAngle = angle
    end
    UpdatePosition()
end)

button:SetScript("OnUpdate", function()
    if isDragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        local radius = 80
        local x = math.cos(math.rad(angle)) * radius
        local y = math.sin(math.rad(angle)) * radius
        this:ClearAllPoints()
        this:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end)

-- Click handler
button:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        TattleTotem_ToggleConfig()
    elseif arg1 == "RightButton" then
        if TattleTotemDB then
            TattleTotemDB.enabled = not TattleTotemDB.enabled
            if TattleTotemDB.enabled then
                button.icon:SetDesaturated(false)
            else
                button.icon:SetDesaturated(true)
            end
        end
    end
end)

-- Tooltip
button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff00ffffTattleTotem|r")
    if TattleTotemDB then
        if TattleTotemDB.enabled then
            GameTooltip:AddLine("Status: |cff00ff00Enabled|r", 1, 1, 1)
        else
            GameTooltip:AddLine("Status: |cffff0000Disabled|r", 1, 1, 1)
        end
        if TattleTotemDB.debugMode then
            GameTooltip:AddLine("Debug: |cffff00ffON|r", 1, 1, 1)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left-click: Config", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Right-click: Toggle", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("Drag: Move button", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- Initialize position on load
button:SetScript("OnShow", UpdatePosition)

-- Global function to update button state
function TattleTotem_UpdateMinimapButton()
    if TattleTotemDB and TattleTotemDB.enabled then
        button.icon:SetDesaturated(false)
    else
        button.icon:SetDesaturated(true)
    end
    UpdatePosition()
end
```