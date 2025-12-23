# BigWigs Reference Code (pepopo978/BigWigs)

Source: https://github.com/pepopo978/BigWigs

These are the actual detection patterns used by the TWoW BigWigs addon.

---

## Kelthuzad.lua - Key Patterns

### Event Registration
```lua
function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS", "Event")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS", "Event")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS", "Event")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES", "Event")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES", "Event")
    self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "Event")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
    
    -- CRITICAL: Set combat log range to max
    SetCVar("CombatDeathLogRange", 200)
    SetCVar("CombatLogRangeParty", 200)
    SetCVar("CombatLogRangePartyPet", 200)
    SetCVar("CombatLogRangeFriendlyPlayers", 200)
    SetCVar("CombatLogRangeFriendlyPlayersPets", 200)
    SetCVar("CombatLogRangeHostilePlayers", 200)
    SetCVar("CombatLogRangeHostilePlayersPets", 200)
    SetCVar("CombatLogRangeCreature", 200)
end
```

### String Trigger Patterns
```lua
L:RegisterTranslations("enUS", function()
    return {
        -- Shackle tracking
        trigger_shackle = "Guardian of Icecrown is afflicted by Shackle Undead.",
        trigger_shackleFade = "Shackle Undead fades from Guardian of Icecrown.",
        
        -- Blood Tap (Guardian damage buff)
        trigger_bloodTap = "Guardian of Icecrown gains Blood Tap %((.+)%).",
        
        -- Boss attack patterns
        trigger_attack1 = "Kel'Thuzad attacks",
        trigger_attack2 = "Kel'Thuzad misses",
        trigger_attack3 = "Kel'Thuzad hits",
        trigger_attack4 = "Kel'Thuzad crits",
        
        -- Interrupt detection
        trigger_kick1 = "Kick hits Kel'Thuzad",
        trigger_kick2 = "Kick crits Kel'Thuzad",
        trigger_kick3 = "Kick was blocked by Kel'Thuzad",
        trigger_pummel1 = "Pummel hits Kel'Thuzad",
        trigger_pummel2 = "Pummel crits Kel'Thuzad",
        trigger_pummel3 = "Pummel was blocked by Kel'Thuzad",
        trigger_shieldBash1 = "Shield Bash hits Kel'Thuzad",
        trigger_shieldBash2 = "Shield Bash crits Kel'Thuzad",
        trigger_shieldBash3 = "Shield Bash was blocked by Kel'Thuzad",
        trigger_earthShock1 = "Earth Shock hits Kel'Thuzad",
        trigger_earthShock2 = "Earth Shock crits Kel'Thuzad",
        
        -- Debuff patterns (with player name capture)
        trigger_mcYou = "You are afflicted by Chains of Kel'Thuzad.",
        trigger_mcOther = "(.+) is afflicted by Chains of Kel'Thuzad",
        trigger_mcOther2 = "(.+) %(.+%) is afflicted by Chains of Kel'Thuzad",
        trigger_mcFade = "Chains of Kel'Thuzad fades from (.+).",
        
        trigger_frostBlastYou = "You are afflicted by Frost Blast.",
        trigger_frostBlastOther = "(.+) is afflicted by Frost Blast.",
        trigger_frostBlastFade = "Frost Blast fades from (.+)",
        
        trigger_detonateYou = "You are afflicted by Detonate Mana.",
        trigger_detonateOther = "(.+) is afflicted by Detonate Mana.",
        trigger_detonateFade = "Detonate Mana fades from (.+).",
        
        -- Frostbolt Volley detection
        trigger_volley = "afflicted by Frostbolt",
    }
end)
```

### Event Handler Pattern
```lua
function module:Event(msg)
    -- Shackle applied
    if string.find(msg, L["trigger_shackle"]) then
        shackleCount = shackleCount + 1
        self:Sync(syncName.shackle .. " " .. shackleCount)
    
    -- Shackle faded
    elseif string.find(msg, L["trigger_shackleFade"]) then
        shackleCount = shackleCount - 1
        self:Sync(syncName.shackle .. " " .. shackleCount)
    
    -- Blood Tap stacks
    elseif string.find(msg, L["trigger_bloodTap"]) then
        local _, _, bloodTapCount, _ = string.find(msg, L["trigger_bloodTap"])
        self:Sync(syncName.bloodTap .. " " .. bloodTapCount)
    
    -- Player debuffs
    elseif msg == L["trigger_frostBlastYou"] then
        self:Sync(syncName.frostBlast .. " " .. UnitName("Player"))
    elseif string.find(msg, L["trigger_frostBlastOther"]) then
        local _, _, frostBlastPlayer, _ = string.find(msg, L["trigger_frostBlastOther"])
        self:Sync(syncName.frostBlast .. " " .. frostBlastPlayer)
    end
end
```

---

## Horsemen.lua - Key Patterns

### Boss Definitions
```lua
local thane = AceLibrary("Babble-Boss-2.2")["Thane Korth'azz"]
local mograine = AceLibrary("Babble-Boss-2.2")["Highlord Mograine"]  -- NOTE: TWoW specific
local zeliek = AceLibrary("Babble-Boss-2.2")["Sir Zeliek"]
local blaumeux = AceLibrary("Babble-Boss-2.2")["Lady Blaumeux"]

module.enabletrigger = { thane, mograine, zeliek, blaumeux }
```

### Mark Detection (Engagement Trigger)
```lua
L:RegisterTranslations("enUS", function()
    return {
        marktrigger1 = "afflicted by Mark of Zeliek",
        marktrigger2 = "afflicted by Mark of Korth'azz",
        marktrigger3 = "afflicted by Mark of Blaumeux",
        marktrigger4 = "afflicted by Mark of Mograine",
        
        -- Boss ability triggers
        meteortrigger = "Thane Korth'azz's Meteor hits ",
        meteortrigger2 = "I like my meat extra crispy!",
        wrathtrigger = "Sir Zeliek's Holy Wrath hits ",
        wrathtrigger2 = "I have no choice but to obey!",
        voidtrigger = "Your life is mine!",
        
        -- Shield Wall
        shieldwalltrigger = "(.*) gains Shield Wall.",
    }
end)
```

### Mark Event Handler
```lua
function module:MarkEvent(msg)
    if string.find(msg, L["marktrigger1"]) or 
       string.find(msg, L["marktrigger2"]) or 
       string.find(msg, L["marktrigger3"]) or 
       string.find(msg, L["marktrigger4"]) then
        self:Sync(syncName.mark)
    end
end
```

### Shield Wall Detection
```lua
function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
    local _, _, mob = string.find(msg, L["shieldwalltrigger"])
    if mob then
        self.shieldWallTimers[mob] = GetTime()
        self:Sync(syncName.shieldwall .. " " .. mob)
    end
end
```

### Boss Death Tracking
```lua
function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
    local thaneDied = string.find(msg, string.format(UNITDIESOTHER, thane))
    local mograineDied = string.find(msg, string.format(UNITDIESOTHER, mograine))
    local zeliekDied = string.find(msg, string.format(UNITDIESOTHER, zeliek))
    local blaumeuxDied = string.find(msg, string.format(UNITDIESOTHER, blaumeux))
    
    if thaneDied then self.thaneDied = true end
    if mograineDied then self.mograineDied = true end
    if zeliekDied then self.zeliekDied = true end
    if blaumeuxDied then self.blaumeuxDied = true end
    
    if thaneDied or mograineDied or zeliekDied or blaumeuxDied then
        self.deaths = self.deaths + 1
        if self.deaths == 4 then
            self:SendBossDeathSync()
        end
    end
end
```

---

## UI Patterns from BigWigs

### Draggable Frame
```lua
self.bossStatusFrame = CreateFrame("Frame", "HorsemenBossStatusFrame", UIParent)
self.bossStatusFrame:SetWidth(150)
self.bossStatusFrame:SetHeight(70)
self.bossStatusFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
self.bossStatusFrame:SetBackdropColor(0, 0, 0, 1)

-- Dragging
self.bossStatusFrame:SetMovable(true)
self.bossStatusFrame:EnableMouse(true)
self.bossStatusFrame:RegisterForDrag("LeftButton")
self.bossStatusFrame:SetScript("OnDragStart", function()
    this:StartMoving()
end)
self.bossStatusFrame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local scale = this:GetEffectiveScale()
    this.module.db.profile.bossframeposx = this:GetLeft() * scale
    this.module.db.profile.bossframeposy = this:GetTop() * scale
end)
```

### FontString Labels
```lua
local font = "Fonts\\FRIZQT__.TTF"
local fontSize = 9

self.bossStatusFrame.thane = self.bossStatusFrame:CreateFontString(nil, "ARTWORK")
self.bossStatusFrame.thane:SetFontObject(GameFontNormal)
self.bossStatusFrame.thane:SetPoint("TOPLEFT", self.bossStatusFrame, "TOPLEFT", 10, -10)
self.bossStatusFrame.thane:SetText("Thane:")
self.bossStatusFrame.thane:SetFont(font, fontSize)
```

---

## Key Takeaways for RaidTattle

1. **Use string.find() with pattern strings** - Combat log messages are plain text
2. **Capture groups with (.+)** - Extract player names from messages
3. **Register multiple events** - Different events for different situations
4. **SetCVar for combat log range** - CRITICAL for seeing events across the raid
5. **Track state with local variables** - shackleCount, deaths, timers
6. **Use this in OnClick scripts** - Vanilla Lua quirk, not self
