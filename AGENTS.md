# TattleTotem - Turtle WoW Naxxramas Raid Monitor

## Project Overview

Build a "tattle-tale" addon for Turtle WoW that publicly announces raid member mistakes in Naxxramas via /yell, /say, or /rw.

**Read these files in order:**
1. `CLAUDE-CODE-SPEC.md` - Full technical specification
2. `UI-EXAMPLES.md` - Copy-paste ready UI code for vanilla 1.12
3. `BIGWIGS-REFERENCE.md` - Detection patterns from TWoW BigWigs
4. `RESEARCH-NOTES.md` - TWoW-specific mechanics details

**Skill File:** `C:\Users\Todd\.claude\skills\turtle-wow-lua\SKILL.md`

**Reference Addons:**
- https://github.com/pepopo978/BigWigs (Detection patterns)
- https://github.com/Jahfonte/ProcEm (Minimap button ONLY - ignore its config window)
- https://github.com/Jahfonte/GigaHeal (Better UI examples)

---

## Quick Summary

### What It Does
1. **AoE Monitor** - Detects AoE spell casts during Kel'Thuzad fight
2. **Shackle Break Tracker** - Identifies who broke Shackle Undead on Guardians
3. **Pull Detector** - Announces first person to pull Four Horsemen (out of combat -> first hit only)
4. **Debug Mode** - Test anywhere, not just Naxxramas

### Output Examples
```
-- Boss area detection (local chat only)
|cff00ffff4HM|r Ready
|cff00ffffKT|r Ready

-- Mistake reports (YELLED)
Huntard AoE: Multi-Shot
Noobmage BROKE SHACKLE! (Arcane Explosion)
Leeroyjnkns pulled 4HM!
```

### Minimal Chat Policy
- NO spam on addon load
- Boss area detection = local chat only ("4HM Ready", "KT Ready")
- Only YELL when reporting actual mistakes

---

## File Structure to Create

```
TattleTotem/
  TattleTotem.toc
  Core.lua           -- Main addon frame, event handling, detection logic
  Config.lua         -- UI configuration frame (use GigaHeal as reference, NOT ProcEm)
  MinimapButton.lua  -- Minimap button (copy from ProcEm)
  SpellData.lua      -- AoE spell list table
```

---

## Critical Requirements

### 1. Vanilla 1.12 API Only
- NO `COMBAT_LOG_EVENT_UNFILTERED` 
- Use `CHAT_MSG_SPELL_*` events
- Use `string.find()` for pattern matching
- Use `this` not `self` in OnClick/OnEvent scripts

### 2. Combat Log Range (MUST SET)
```lua
SetCVar("CombatDeathLogRange", 200)
SetCVar("CombatLogRangeParty", 200)
SetCVar("CombatLogRangeFriendlyPlayers", 200)
SetCVar("CombatLogRangeCreature", 200)
```

### 3. TWoW Boss Names
```lua
-- Four Horsemen (TWoW uses Mograine, NOT Baron Rivendare)
"Thane Korth'azz"
"Highlord Mograine"  
"Sir Zeliek"
"Lady Blaumeux"

-- KT Fight
"Kel'Thuzad"
"Guardian of Icecrown"
```

### 4. TWoW Custom Spells (Include These)
```lua
["Carve"] = true,    -- Hunter melee AoE
["Icicles"] = true,  -- Mage channeled frost AoE
```

---

## UI Requirements

### Minimap Button (REQUIRED - copy from ProcEm)
- Left-click: Toggle config window
- Right-click: Toggle enable/disable
- Draggable around minimap edge
- Tooltip shows status

### Config Frame (use GigaHeal as UI reference, NOT ProcEm)
- [x] Semi-transparent background (alpha 0.8)
- [x] Draggable window
- [x] Close button (X)
- [x] **Master Enable/Disable toggle** (top, prominent)
- [x] **Debug Mode toggle** (DEFAULT OFF - detects AoE everywhere when ON)
- [x] Output method radio buttons (Yell / Raid Warning / Say)
- [x] 4HM monitoring toggle (single checkbox)
- [x] KT monitoring toggles (AoE / Shackle)
- [x] Scrollable spell list with per-spell checkboxes
- [x] Anti-spam cooldown setting

### Debug Mode Behavior
- **Default: OFF**
- When ON: Detects ALL AoE casts EVERYWHERE (for testing)
- When ON: Output goes to local chat frame (not yelled)
- When OFF: Only monitors inside Naxxramas, only yells mistakes

### 4HM Pull Detection (CRITICAL)
- ONLY triggers on out of combat -> first aggro
- Once puller is recorded, STOP tracking until combat ends
- Reset on PLAYER_REGEN_ENABLED (wipe/kill)
- Single report per fight, no spam

### Slash Commands
```
/tt or /tattletotem    -- Toggle config window
/tt enable             -- Enable addon
/tt disable            -- Disable addon  
/tt debug              -- Toggle debug mode
/tt status             -- Show current settings
```

---

## SavedVariables Structure

```lua
TattleTotemDB = {
    enabled = true,
    debugMode = false,      -- DEFAULT OFF, detects AoE everywhere when ON
    outputMethod = "YELL",  -- "YELL", "RAID_WARNING", "SAY"
    cooldown = 5,
    minimapAngle = 225,     -- Minimap button position
    
    -- Single toggle for 4HM (tracks first pull when OUT OF COMBAT only)
    monitor4HM = true,
    
    ktMonitor = {
        aoe = true,
        shackle = true,
    },
    
    spells = {
        -- All default to true, user can disable specific ones
        ["Multi-Shot"] = true,
        ["Volley"] = true,
        ["Arcane Explosion"] = true,
        -- ... etc
    },
}
```

---

## Detection Patterns (from BigWigs)

### Shackle Tracking
```lua
-- Applied
"Guardian of Icecrown is afflicted by Shackle Undead."

-- Broken/Faded
"Shackle Undead fades from Guardian of Icecrown."
```

### Spell Damage Parsing
```lua
-- Other player's spell
"(.+)'s (.+) hits"   -- Captures: playerName, spellName
"(.+)'s (.+) crits"

-- Your spell  
"Your (.+) hits"     -- Captures: spellName
```

### Boss Attack (Pull Detection)
```lua
"Thane Korth'azz hits (.+) for"
"Highlord Mograine crits (.+) for"
-- etc
```

---

## Event Registration

```lua
local events = {
    "CHAT_MSG_SPELL_SELF_DAMAGE",
    "CHAT_MSG_SPELL_PARTY_DAMAGE",
    "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
    "CHAT_MSG_SPELL_AURA_GONE_OTHER",
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_DISABLED",  -- Entered combat
    "PLAYER_REGEN_ENABLED",   -- Left combat (reset 4HM tracker)
    "ADDON_LOADED",
}
```

---

## Testing Checklist

After building, verify:
- [ ] Minimap button appears and is draggable
- [ ] Minimap button left-click opens config
- [ ] Minimap button right-click toggles enable
- [ ] `/tt` opens config window
- [ ] Config window is draggable
- [ ] Master enable toggle works
- [ ] Debug mode toggle works (default OFF)
- [ ] Debug mode ON = detects AoE everywhere, outputs to local chat
- [ ] Debug mode OFF = only Naxx, only yells mistakes
- [ ] Settings persist after /reload
- [ ] All checkboxes save their state
- [ ] Radio buttons switch output method
- [ ] Spell list scrolls properly
- [ ] "4HM Ready" appears when entering horsemen area (local chat only)
- [ ] "KT Ready" appears when entering KT chamber (local chat only)
- [ ] NO chat spam on addon load
- [ ] 4HM reports FIRST hit only (out of combat -> in combat transition)
- [ ] 4HM tracker resets on wipe/kill (PLAYER_REGEN_ENABLED)
