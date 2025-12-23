# TattleTotem - Turtle WoW Naxxramas Raid Monitoring Addon

## Claude Code Build Specification

**Skill File:** `C:\Users\Todd\.claude\skills\turtle-wow-lua\SKILL.md`
**Reference Addons:**
- https://github.com/pepopo978/BigWigs (PRIMARY - TWoW BigWigs with all detection patterns)
- https://github.com/Jahfonte/ProcEm (Minimap button ONLY - ignore its config window)
- https://github.com/Jahfonte/GigaHeal (Better UI examples)
- https://github.com/Jahfonte/IsJohnDead

---

## Project Overview

TattleTotem is a "tattle-tale" addon that publicly announces (via /yell, /say, or /rw) when raid members make mistakes during Naxxramas encounters. It monitors:

1. **AoE spell casts** during Kel'Thuzad fight (can break shackles on Guardians)
2. **Shackle Undead breaks** on Guardian of Icecrown (identifies who broke it)
3. **First aggro pulls** on Four Horsemen bosses (who bodypulled)
4. **Debug mode** for testing in any raid/group context

---

## Critical Technical Requirements

### Vanilla 1.12 API ONLY
- NO `COMBAT_LOG_EVENT_UNFILTERED` (that's retail)
- Use `CHAT_MSG_SPELL_*` events with string pattern matching
- Use `CHAT_MSG_COMBAT_*` events for melee/aggro detection

### Combat Log Range CVars (Set on Enable)
```lua
SetCVar("CombatDeathLogRange", 200)
SetCVar("CombatLogRangeParty", 200)
SetCVar("CombatLogRangePartyPet", 200)
SetCVar("CombatLogRangeFriendlyPlayers", 200)
SetCVar("CombatLogRangeFriendlyPlayersPets", 200)
SetCVar("CombatLogRangeHostilePlayers", 200)
SetCVar("CombatLogRangeHostilePlayersPets", 200)
SetCVar("CombatLogRangeCreature", 200)
```

---

## File Structure

```
TattleTotem/
  TattleTotem.toc
  Core.lua
  Config.lua
  MinimapButton.lua   -- Minimap button (copy from ProcEm)
  SpellData.lua
```

---

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

---

## Complete AoE Spell List (SpellData.lua)

Include ALL of these - they can break shackles or cause problems:

```lua
TattleTotem_AoESpells = {
    -- HUNTER
    ["Multi-Shot"] = { class = "HUNTER", type = "ranged_aoe" },
    ["Volley"] = { class = "HUNTER", type = "ranged_aoe" },
    ["Carve"] = { class = "HUNTER", type = "melee_aoe" },  -- TWoW Custom
    ["Explosive Trap"] = { class = "HUNTER", type = "trap_aoe" },
    
    -- MAGE
    ["Arcane Explosion"] = { class = "MAGE", type = "pbaoe" },
    ["Blizzard"] = { class = "MAGE", type = "channeled_aoe" },
    ["Cone of Cold"] = { class = "MAGE", type = "cone_aoe" },
    ["Flamestrike"] = { class = "MAGE", type = "ground_aoe" },
    ["Blast Wave"] = { class = "MAGE", type = "pbaoe" },
    ["Frost Nova"] = { class = "MAGE", type = "pbaoe" },
    ["Icicles"] = { class = "MAGE", type = "channeled_aoe" },  -- TWoW Custom
    
    -- WARLOCK
    ["Rain of Fire"] = { class = "WARLOCK", type = "channeled_aoe" },
    ["Hellfire"] = { class = "WARLOCK", type = "channeled_pbaoe" },
    ["Howl of Terror"] = { class = "WARLOCK", type = "pbaoe_fear" },
    
    -- PALADIN
    ["Holy Wrath"] = { class = "PALADIN", type = "pbaoe" },
    ["Consecration"] = { class = "PALADIN", type = "ground_aoe" },
    
    -- SHAMAN
    ["Chain Lightning"] = { class = "SHAMAN", type = "chain" },
    ["Magma Totem"] = { class = "SHAMAN", type = "totem_aoe" },
    ["Fire Nova Totem"] = { class = "SHAMAN", type = "totem_aoe" },
    
    -- PRIEST
    ["Holy Nova"] = { class = "PRIEST", type = "pbaoe" },
    
    -- DRUID
    ["Hurricane"] = { class = "DRUID", type = "channeled_aoe" },
    ["Swipe"] = { class = "DRUID", type = "melee_aoe" },
    
    -- WARRIOR
    ["Whirlwind"] = { class = "WARRIOR", type = "melee_aoe" },
    ["Cleave"] = { class = "WARRIOR", type = "melee_cleave" },
    ["Thunder Clap"] = { class = "WARRIOR", type = "pbaoe" },
    ["Sweeping Strikes"] = { class = "WARRIOR", type = "buff_cleave" },  -- Buff that causes cleave
    
    -- ROGUE
    ["Blade Flurry"] = { class = "ROGUE", type = "buff_cleave" },  -- Buff that causes cleave
}
```

---

## Boss Data

### Four Horsemen (TWoW Version)
```lua
TattleTotem_FourHorsemen = {
    ["Thane Korth'azz"] = true,
    ["Highlord Mograine"] = true,  -- NOTE: TWoW uses Mograine, NOT Baron Rivendare
    ["Sir Zeliek"] = true,
    ["Lady Blaumeux"] = true,
}
```

### Kel'Thuzad Encounter
```lua
TattleTotem_KTMobs = {
    ["Kel'Thuzad"] = true,
    ["Guardian of Icecrown"] = true,
}
```

---

## Combat Log Event Patterns (from BigWigs)

### Events to Register
```lua
-- Spell cast detection
"CHAT_MSG_SPELL_SELF_DAMAGE"
"CHAT_MSG_SPELL_PARTY_DAMAGE"  
"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE"
"CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE"

-- Aura application/removal
"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"
"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE"
"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE"
"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE"  -- Shackle on Guardian
"CHAT_MSG_SPELL_AURA_GONE_OTHER"           -- Shackle fades

-- Boss buffs
"CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS"   -- Blood Tap stacks

-- Combat/Aggro detection
"CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS"
"CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES"
"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS"
"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES"
"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS"
"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES"

-- Zone detection
"ZONE_CHANGED_NEW_AREA"
"PLAYER_ENTERING_WORLD"

-- Combat state (for 4HM reset)
"PLAYER_REGEN_DISABLED"  -- Entered combat
"PLAYER_REGEN_ENABLED"   -- Left combat (wipe/kill)
```

### String Patterns for Parsing

**AoE Spell Casts:**
```lua
-- Pattern: "PlayerName's SpellName hits/crits TargetName for X damage"
local pattern_spell_damage = "(.+)'s (.+) hits"
local pattern_spell_crit = "(.+)'s (.+) crits"

-- For self: "Your SpellName hits TargetName"
local pattern_self_damage = "Your (.+) hits"
```

**Shackle Detection:**
```lua
-- Shackle applied
local pattern_shackle = "Guardian of Icecrown is afflicted by Shackle Undead"

-- Shackle fades (early = broken)
local pattern_shackle_fade = "Shackle Undead fades from Guardian of Icecrown"
```

**Boss Aggro Detection:**
```lua
-- Boss hits player: "Thane Korth'azz hits PlayerName for X damage"
local pattern_boss_hit = "(.+) hits (.+) for"
local pattern_boss_crit = "(.+) crits (.+) for"
local pattern_boss_miss = "(.+) misses (.+)"
local pattern_boss_attack = "(.+) attacks"
```

---

## Detection Logic

### 1. AoE Cast Detection
```lua
function TattleTotem:OnSpellDamage(msg)
    local caster, spell = self:ParseSpellMessage(msg)
    if caster and spell then
        -- Strip rank from spell name: "Multi-Shot (Rank 4)" -> "Multi-Shot"
        local baseSpell = string.gsub(spell, " %(Rank %d+%)", "")
        
        if TattleTotem_AoESpells[baseSpell] then
            self:ReportAoE(caster, baseSpell)
        end
    end
end
```

### 2. Shackle Break Detection
```lua
-- Track active shackles
TattleTotem.activeShackles = {}  -- { timestamp, caster }

function TattleTotem:OnShackleApplied()
    -- Note: We can't easily get the priest who cast it from combat log
    -- Track timestamp for break detection
    table.insert(self.activeShackles, {
        time = GetTime(),
        expectedDuration = 50,  -- Shackle Undead duration
    })
end

function TattleTotem:OnShackleFade()
    local now = GetTime()
    local shackle = table.remove(self.activeShackles, 1)
    
    if shackle then
        local elapsed = now - shackle.time
        -- If it faded WAY before expected, it was broken
        if elapsed < (shackle.expectedDuration - 5) then
            -- Check recent AoE casts within 0.5 sec window
            self:CheckRecentAoEForShackleBreak()
        end
    end
end
```

### 3. Four Horsemen Aggro Detection

**CRITICAL**: Only detect the FIRST person hit when raid is OUT OF COMBAT.
Once fight starts (inCombat = true), stop tracking. This prevents spam.

```lua
-- State tracking
TattleTotem.horsemenPuller = nil
TattleTotem.inCombat = false  -- Track raid combat state

-- Register for combat state changes
"PLAYER_REGEN_DISABLED"  -- Entered combat
"PLAYER_REGEN_ENABLED"   -- Left combat (wipe/kill)

function TattleTotem:OnCombatStart()
    -- Don't reset puller here - we want to catch the first hit
end

function TattleTotem:OnCombatEnd()
    -- Wipe or kill - reset for next pull
    self.horsemenPuller = nil
    self.inCombat = false
end

function TattleTotem:OnBossAttack(msg)
    -- ONLY track if we haven't recorded a puller yet
    -- Once someone pulls, we're done until combat ends
    if self.horsemenPuller then return end
    
    local boss, target = self:ParseBossAttack(msg)
    
    if boss and TattleTotem_FourHorsemen[boss] then
        -- First hit = the puller
        self.horsemenPuller = target
        self.inCombat = true
        self:ReportPull(target)
    end
end

-- Also reset on zone change
function TattleTotem:Reset4HM()
    self.horsemenPuller = nil
    self.inCombat = false
end
```

---

## UI Specification - Config Frame

### Frame Properties
```lua
-- Main config frame
local frame = CreateFrame("Frame", "TattleTotemConfigFrame", UIParent)
frame:SetWidth(350)
frame:SetHeight(500)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Semi-transparent background
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)  -- 80% opacity black background
```

### UI Layout

```
+------------------------------------------+
|  [X]  RaidTattle Configuration           |
+------------------------------------------+
|                                          |
|  [ ] Enable RaidTattle                   |
|  [ ] Debug Mode (monitor all raids)      |
|                                          |
|  --- Output Method ---                   |
|  ( ) Yell                                |
|  ( ) Raid Warning                        |
|  ( ) Say                                 |
|                                          |
|  --- Four Horsemen Monitoring ---        |
|  [ ] Monitor 4HM First Pull              |
|                                          |
|  --- Kel'Thuzad Monitoring ---           |
|  [ ] Monitor AoE Casts                   |
|  [ ] Monitor Shackle Breaks              |
|                                          |
|  --- AoE Spells to Monitor ---           |
|  +------------------------------------+  |
|  | [ ] Multi-Shot (Hunter)            |  |
|  | [ ] Volley (Hunter)                |  |
|  | [ ] Carve (Hunter)                 |  |
|  | [ ] Arcane Explosion (Mage)        |  |
|  | [ ] Blizzard (Mage)                |  |
|  | [ ] Cone of Cold (Mage)            |  |
|  | ... (scrollable list)              |  |
|  +------------------------------------+  |
|                                          |
|  Anti-Spam Cooldown: [5] seconds         |
|                                          |
+------------------------------------------+
```

---

## Minimap Button

**Reference:** https://github.com/Jahfonte/ProcEm - Copy the minimap button implementation

### Behavior
- Left-click: Toggle config window
- Right-click: Toggle enable/disable
- Tooltip: Show current status (enabled/disabled, debug mode)
- Draggable around minimap edge

### Implementation Pattern (from ProcEm)
```lua
-- Create minimap button frame
local minimapButton = CreateFrame("Button", "TattleTotemMinimapButton", Minimap)
minimapButton:SetWidth(31)
minimapButton:SetHeight(31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Button textures
local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)

local icon = minimapButton:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetTexture("Interface\\Icons\\Spell_Holy_SealOfRighteousness")  -- Or custom icon
icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)

-- Dragging around minimap
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function() this:StartMoving() end)
minimapButton:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

-- Click handlers
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:SetScript("OnClick", function()
    if arg1 == "LeftButton" then
        TattleTotem_ToggleConfig()
    elseif arg1 == "RightButton" then
        TattleTotemDB.enabled = not TattleTotemDB.enabled
        -- Update visual feedback
    end
end)

-- Tooltip
minimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("TattleTotem")
    GameTooltip:AddLine("Left-click: Config", 1, 1, 1)
    GameTooltip:AddLine("Right-click: Toggle", 1, 1, 1)
    GameTooltip:Show()
end)
minimapButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
```

---

### Checkbox Creation Helper
```lua
local function CreateCheckbox(parent, name, label, x, y, tooltipText)
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetWidth(24)
    cb:SetHeight(24)
    
    local text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    text:SetText(label)
    
    if tooltipText then
        cb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipText, 1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return cb
end
```

### Radio Button Group Helper
```lua
local function CreateRadioGroup(parent, name, options, x, y, onChange)
    local buttons = {}
    local yOffset = 0
    
    for i, opt in ipairs(options) do
        local rb = CreateFrame("CheckButton", name..i, parent, "UIRadioButtonTemplate")
        rb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - yOffset)
        rb:SetWidth(20)
        rb:SetHeight(20)
        
        local text = rb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        text:SetPoint("LEFT", rb, "RIGHT", 5, 0)
        text:SetText(opt.label)
        
        rb.value = opt.value
        rb:SetScript("OnClick", function()
            for _, btn in ipairs(buttons) do
                btn:SetChecked(btn == this)
            end
            if onChange then onChange(this.value) end
        end)
        
        table.insert(buttons, rb)
        yOffset = yOffset + 25
    end
    
    return buttons
end
```

### Scrollable Spell List
```lua
local function CreateSpellScrollFrame(parent, x, y, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", "RaidTattleSpellScroll", parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    scrollFrame:SetWidth(width)
    scrollFrame:SetHeight(height)
    
    local scrollChild = CreateFrame("Frame", "RaidTattleSpellScrollChild", scrollFrame)
    scrollChild:SetWidth(width - 20)
    scrollChild:SetHeight(1)  -- Will expand based on content
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Add checkboxes for each spell
    local yOffset = 0
    for spellName, spellData in pairs(RaidTattle_AoESpells) do
        local label = spellName .. " (" .. spellData.class .. ")"
        local cb = CreateCheckbox(scrollChild, "RaidTattleSpell_"..spellName, label, 5, -yOffset)
        cb.spellName = spellName
        cb:SetScript("OnClick", function()
            RaidTattleDB.spells[this.spellName] = this:GetChecked()
        end)
        yOffset = yOffset + 25
    end
    
    scrollChild:SetHeight(yOffset)
    return scrollFrame
end
```

---

## SavedVariables Structure

```lua
TattleTotemDB = {
    enabled = true,
    debugMode = false,         -- DEFAULT OFF, detects AoE everywhere when ON
    outputMethod = "YELL",     -- "YELL", "RAID_WARNING", "SAY"
    antiSpamCooldown = 5,
    minimapAngle = 225,        -- Minimap button position (degrees)
    
    -- Four Horsemen (single toggle - tracks first pull when OUT OF COMBAT)
    monitor4HM = true,
    
    -- KT monitoring
    monitorAoE = true,
    monitorShackle = true,
    
    -- Per-spell toggles
    spells = {
        ["Multi-Shot"] = true,
        ["Volley"] = true,
        ["Arcane Explosion"] = true,
        -- ... all spells default to true
    },
}
```

---

## Output Messages

### Minimal Chat Policy
- **Normal mode**: ONLY output when reporting mistakes (yelling at people)
- **Debug mode**: Shows verbose messages to local chat frame for testing
- **Boss detection**: Brief one-time message to local chat when entering boss area
- **NO spam** on load, zone changes, or status unless explicitly requested

### Boss Area Detection (Local chat only, NOT yelled)
```lua
-- When entering Four Horsemen area:
DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff4HM|r Ready")

-- When entering KT chamber:
DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffKT|r Ready")
```

### Mistake Reports (YELLED to raid)
```lua
-- AoE cast during KT fight
-- Format: "PlayerName AoE: SpellName"
SendChatMessage(playerName .. " AoE: " .. spellName, outputMethod)

-- Shackle break
-- Format: "PlayerName BROKE SHACKLE! (SpellName)"
SendChatMessage(playerName .. " BROKE SHACKLE! (" .. spellName .. ")", outputMethod)

-- Four Horsemen pull - FIRST person hit by ANY horseman
-- Format: "PlayerName pulled 4HM!"
SendChatMessage(playerName .. " pulled 4HM!", outputMethod)
```

---

## Slash Commands

```lua
SLASH_TATTLETOTEM1 = "/tattletotem"
SLASH_TATTLETOTEM2 = "/tt"

SlashCmdList["TATTLETOTEM"] = function(msg)
    local cmd = string.lower(msg or "")
    
    if cmd == "" then
        -- Toggle config frame
        if TattleTotemConfigFrame:IsVisible() then
            TattleTotemConfigFrame:Hide()
        else
            TattleTotemConfigFrame:Show()
        end
    elseif cmd == "debug" then
        TattleTotemDB.debugMode = not TattleTotemDB.debugMode
        DEFAULT_CHAT_FRAME:AddMessage("TattleTotem Debug: " .. (TattleTotemDB.debugMode and "ON" or "OFF"))
    elseif cmd == "enable" then
        TattleTotemDB.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("TattleTotem: Enabled")
    elseif cmd == "disable" then
        TattleTotemDB.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("TattleTotem: Disabled")
    elseif cmd == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("TattleTotem Status:")
        DEFAULT_CHAT_FRAME:AddMessage("  Enabled: " .. (TattleTotemDB.enabled and "Yes" or "No"))
        DEFAULT_CHAT_FRAME:AddMessage("  Debug: " .. (TattleTotemDB.debugMode and "Yes" or "No"))
        DEFAULT_CHAT_FRAME:AddMessage("  Output: " .. TattleTotemDB.outputMethod)
    else
        DEFAULT_CHAT_FRAME:AddMessage("TattleTotem Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt - Toggle config window")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt debug - Toggle debug mode")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt enable - Enable addon")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt disable - Disable addon")
        DEFAULT_CHAT_FRAME:AddMessage("  /tt status - Show current status")
    end
end
```

---

## Anti-Spam System

```lua
TattleTotem.recentReports = {}  -- { "PlayerName_SpellName" = timestamp }

function TattleTotem:CanReport(playerName, spellName)
    local key = playerName .. "_" .. spellName
    local lastReport = self.recentReports[key]
    local now = GetTime()
    
    if lastReport and (now - lastReport) < TattleTotemDB.antiSpamCooldown then
        return false
    end
    
    self.recentReports[key] = now
    return true
end

-- Cleanup old entries periodically
function TattleTotem:CleanupReports()
    local now = GetTime()
    local cutoff = now - 60  -- Remove entries older than 60 seconds
    
    for key, timestamp in pairs(self.recentReports) do
        if timestamp < cutoff then
            self.recentReports[key] = nil
        end
    end
end
```

---

## Zone Detection

```lua
function TattleTotem:IsInNaxxramas()
    local zone = GetRealZoneText()
    return zone == "Naxxramas"
end

function TattleTotem:IsInKTChamber()
    local subzone = GetMinimapZoneText()
    return subzone == "Kel'Thuzad Chamber" or subzone == "The Inner Sanctum"
end

function TattleTotem:ShouldMonitor()
    if TattleTotemDB.debugMode then
        return true  -- Debug mode monitors everywhere
    end
    return self:IsInNaxxramas()
end
```

---

## Debug Mode Behavior

**Default: OFF** - Only enable for testing

When `debugMode = true`:
- Monitor AoE casts EVERYWHERE (not just Naxxramas)
- Detects all AoE spells all the time regardless of zone
- Output to DEFAULT_CHAT_FRAME instead of yell/rw (avoids public spam)
- Useful for testing spell detection patterns before raiding
- Ignore zone checks entirely

When `debugMode = false` (default):
- Only monitor inside Naxxramas
- Only yell when actual mistakes occur
- Silent otherwise

---

## BigWigs Pattern Reference

From pepopo978/BigWigs Kelthuzad.lua:

```lua
-- Shackle detection
trigger_shackle = "Guardian of Icecrown is afflicted by Shackle Undead."
trigger_shackleFade = "Shackle Undead fades from Guardian of Icecrown."

-- Blood Tap (Guardian damage buff)
trigger_bloodTap = "Guardian of Icecrown gains Blood Tap %((.+)%)."

-- Frostbolt interrupt detection (reference for how they parse spells)
trigger_kick1 = "Kick hits Kel'Thuzad"
trigger_pummel1 = "Pummel hits Kel'Thuzad"
trigger_shieldBash1 = "Shield Bash hits Kel'Thuzad"
trigger_earthShock1 = "Earth Shock hits Kel'Thuzad"
```

From Horsemen.lua:
```lua
-- Mark detection (engagement indicator)
marktrigger1 = "afflicted by Mark of Zeliek"
marktrigger2 = "afflicted by Mark of Korth'azz"
marktrigger3 = "afflicted by Mark of Blaumeux"
marktrigger4 = "afflicted by Mark of Mograine"

-- Boss names (TWoW specific)
thane = "Thane Korth'azz"
mograine = "Highlord Mograine"  -- NOT Baron Rivendare
zeliek = "Sir Zeliek"
blaumeux = "Lady Blaumeux"
```

---

## Implementation Notes

1. **Spell Rank Stripping**: Combat log shows "Multi-Shot (Rank 4)" - strip the rank for matching
2. **Self vs Others**: "Your X hits" vs "PlayerName's X hits" - handle both patterns
3. **Buff Cleaves**: Sweeping Strikes and Blade Flurry are buffs, not direct casts - detect when the buff is active AND player does melee damage near shackled target
4. **Timing Window**: For shackle break correlation, use 0.5 second window between AoE cast and shackle fade
5. **4HM Pull Detection**: First combat event from ANY horseman to ANY player = that player pulled (single report per fight)
6. **Minimal Chat**: Only yell when reporting mistakes. Boss area detection goes to local chat only.
7. **Reset Logic**: Clear 4HM puller on zone change or wipe detection

---

## Testing Checklist

- [ ] Minimap button appears and is draggable
- [ ] Minimap button left-click = config, right-click = toggle
- [ ] AoE detection fires for all listed spells
- [ ] Shackle break detection works when Guardian shackle fades early
- [ ] Four Horsemen pull detection tracks FIRST hit by ANY horseman
- [ ] Debug mode (default OFF) detects AoE everywhere when ON
- [ ] Debug mode outputs to local chat (not yelled)
- [ ] Normal mode only monitors Naxxramas
- [ ] Config UI shows/hides with /tt
- [ ] All checkboxes save state properly
- [ ] Radio buttons for output method work
- [ ] Anti-spam cooldown prevents duplicate reports
- [ ] SavedVariables persist between sessions
- [ ] "4HM Ready" message appears when entering horsemen area (local chat)
- [ ] "KT Ready" message appears when entering KT chamber (local chat)
- [ ] NO chat spam on addon load (silent start)
