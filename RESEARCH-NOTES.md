# RaidTattle Research Notes

## Turtle WoW Specific Details

### Four Horsemen Roster
TWoW uses **Highlord Mograine**, NOT Baron Rivendare (who is in the retail/classic version).

Boss Names:
- Thane Korth'azz (Front-left, Meteor)
- Highlord Mograine (Front-right, Righteous Fire)
- Sir Zeliek (Back-right, Holy Wrath - chains, no melee allowed)
- Lady Blaumeux (Back-left, Void Zones, Shadow Bolt)

### TWoW Custom AoE Spells

**Carve (Hunter)**
- Melee AoE ability
- 10yd cone in front of hunter
- 60% weapon damage
- Hits up to 5 targets
- Could easily break a nearby shackle if hunter is meleeing

**Icicles (Mage)**
- Frost channeled spell
- AoE damage around the mage
- Freezes the caster in place while channeling
- TWoW custom frost ability

### Guardian of Icecrown Mechanics

- Spawns in Phase 3 at 40% KT HP
- 5 Guardians spawn total
- Blood Tap buff: +15% damage, +10% size per stack (every 15 sec)
- Strategy: Shackle 3, tank 2
- Shackle Undead duration: ~50 seconds
- ANY damage to shackled Guardian breaks the shackle

### Shackle Break Detection Logic

1. Track when "Guardian of Icecrown is afflicted by Shackle Undead" appears
2. Store timestamp
3. When "Shackle Undead fades from Guardian of Icecrown" appears:
   - Check if elapsed time < expected duration (50 sec minus buffer)
   - If early fade, check recentAoECasts table for casts in last 0.5 seconds
   - Report the player whose AoE likely broke it

### Combat Log Message Formats

**Spell Damage (others):**
```
"PlayerName's SpellName hits TargetName for X damage."
"PlayerName's SpellName crits TargetName for X damage."
```

**Spell Damage (self):**
```
"Your SpellName hits TargetName for X damage."
"Your SpellName crits TargetName for X damage."
```

**Debuff Applied:**
```
"TargetName is afflicted by DebuffName."
"You are afflicted by DebuffName."
```

**Debuff Faded:**
```
"DebuffName fades from TargetName."
```

**Buff Gained:**
```
"TargetName gains BuffName."
"TargetName gains BuffName (X)."  -- With stack count
```

**Melee Attack:**
```
"AttackerName hits TargetName for X damage."
"AttackerName crits TargetName for X damage."
"AttackerName misses TargetName."
"AttackerName attacks TargetName."
```

---

## AoE Spell Categories

### Direct AoE (Obvious)
- Arcane Explosion, Blizzard, Flamestrike, Cone of Cold, Blast Wave, Frost Nova
- Rain of Fire, Hellfire
- Holy Wrath, Consecration
- Chain Lightning
- Hurricane, Swipe
- Whirlwind, Thunder Clap, Cleave
- Multi-Shot, Volley
- Holy Nova

### Totem AoE
- Magma Totem (pulses fire damage)
- Fire Nova Totem (explodes)

### Trap AoE
- Explosive Trap

### Buff-Based Cleave (Tricky to Detect)
- **Sweeping Strikes** (Warrior) - Next 5 melee attacks hit additional target
- **Blade Flurry** (Rogue) - Melee attacks hit additional target for 15 sec

For buff-based cleaves, we need to:
1. Track when player gains the buff
2. Track when player does melee damage
3. If buff active + melee near shackled target = potential break

This is harder to implement reliably. Consider:
- Just warning when buff is applied near a Guardian
- Or simplifying to just track the buff application itself

---

## Event Priority

Most critical events for RaidTattle:

1. `CHAT_MSG_SPELL_PARTY_DAMAGE` - Raid member spell damage
2. `CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE` - Friendly player spell damage
3. `CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE` - Debuffs on mobs (Shackle)
4. `CHAT_MSG_SPELL_AURA_GONE_OTHER` - Debuff fades (Shackle break)
5. `CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS` - Boss attacks raid member

Less critical but useful:
- `CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS` - Boss/mob buffs (Blood Tap)
- `CHAT_MSG_MONSTER_YELL` - Boss emotes/phase changes

---

## Anti-Spam Considerations

Default 5 second cooldown per player+spell combo.

Edge cases:
- Same player casts same AoE twice in 5 sec = only report once
- Same player casts different AoE = report both
- Different players cast same AoE = report both
- Shackle break = always report (different category)
- Boss pull = only report first pull per boss per encounter

---

## Testing Without Naxx

Debug mode should allow testing in:
- Any dungeon with undead mobs (for shackle testing)
- Any raid environment (for AoE detection)
- Target dummies (for spell detection)

Output in debug mode should go to DEFAULT_CHAT_FRAME, not /yell, to avoid spam in public areas.

---

## Potential Future Features

1. **Per-encounter reset** - Reset horsemen pull tracking on wipe
2. **Statistics** - Track who breaks the most shackles over time
3. **Sound alerts** - Play sound when shackle breaks
4. **Whisper option** - Whisper the offender instead of public shame
5. **Ignore list** - Don't report certain players (tanks, etc.)
6. **MC detection** - Don't report players who are mind controlled
