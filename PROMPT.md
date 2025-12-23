# RaidTattle - Claude Code Build Prompt

## Quick Start

Read the skill file first:
```
C:\Users\Todd\.claude\skills\turtle-wow-lua\SKILL.md
```

Then read the full spec:
```
CLAUDE-CODE-SPEC.md
```

---

## Build Task

Create a Turtle WoW addon called "RaidTattle" that monitors and announces raid member mistakes in Naxxramas.

### Core Features

1. **AoE Cast Monitor** - Detect when players cast AoE spells during Kel'Thuzad (can break shackled Guardians)

2. **Shackle Break Tracker** - When "Shackle Undead fades from Guardian of Icecrown" appears early, check who cast AoE in the last 0.5 seconds and call them out

3. **Four Horsemen Pull Detector** - Track the FIRST hit from each boss to any player and announce who pulled

4. **Debug Mode** - Toggle that monitors everywhere, not just Naxx (for testing)

### Technical Constraints

- **Vanilla 1.12 API ONLY** - Check the skill file
- Use `CHAT_MSG_SPELL_*` events, NOT `COMBAT_LOG_EVENT_UNFILTERED`
- Parse combat log strings with `string.find()` and patterns
- Semi-transparent config frame (alpha 0.8)
- SavedVariablesPerCharacter for settings

### UI Requirements

- Draggable config window
- Master enable/disable toggle
- Debug mode toggle
- Output method radio buttons (Yell/RW/Say)
- Per-boss toggles for Four Horsemen
- Scrollable spell list with per-spell checkboxes
- Anti-spam cooldown slider

### Output Format

```
-- AoE during KT fight
"Playername cast AoE: Arcane Explosion"

-- Shackle break
"Playername BROKE SHACKLE on Guardian! (Volley)"

-- Four Horsemen pull
"Playername pulled aggro on Thane Korth'azz!"
```

### Reference Code

Look at pepopo978/BigWigs for detection patterns:
- `Raids/Naxxramas/Kelthuzad.lua` - Shackle/Guardian detection
- `Raids/Naxxramas/Horsemen.lua` - Four Horsemen event handling

---

## File Output

Create these files in the addon folder:

```
RaidTattle/
  RaidTattle.toc
  RaidTattle.lua      -- Main addon logic
  Config.lua          -- UI/settings frame
  SpellData.lua       -- AoE spell list
  Localization.lua    -- String constants
```

---

## Critical Details

1. **TWoW Four Horsemen** uses Highlord Mograine, NOT Baron Rivendare

2. **TWoW Custom Spells** to include:
   - Carve (Hunter melee AoE)
   - Icicles (Mage channeled frost AoE)

3. **Sweeping Strikes** is a buff, not a spell - detect the buff active + melee near shackled target

4. **Combat Log Range** - Set CVars to 200 on addon load for full raid coverage

5. **Spell Ranks** - Strip "(Rank X)" from spell names before matching

---

## Testing

Once built, test with:
1. `/rt` - Should open config
2. `/rt debug` - Enable debug mode
3. Cast any AoE spell - Should announce in chat
4. `/rt status` - Should show current settings
