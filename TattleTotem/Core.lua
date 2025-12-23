local TattleTotem = CreateFrame("Frame", "TattleTotemFrame", UIParent)

TattleTotem.recentCasts = {}
TattleTotem.activeShackles = {}
TattleTotem.guardianDoTs = {}
TattleTotem.horsemenPuller = nil
TattleTotem.inCombat = false
TattleTotem.inNaxxramas = false
TattleTotem.inKTChamber = false
TattleTotem.inKTEncounter = false
TattleTotem.guardiansActive = false
TattleTotem.in4HMArea = false
TattleTotem.in4HMEncounter = false
TattleTotem.cleanupTimer = 0
TattleTotem.ktDetectedAnnounced = false
TattleTotem.ktPullLogged = false
TattleTotem.bigWigsHooked = false
TattleTotem.petCheckTimer = 0
TattleTotem.petWarned = {}

local events = {
    "ADDON_LOADED",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_TARGET_CHANGED",
    "CHAT_MSG_SPELL_SELF_DAMAGE",
    "CHAT_MSG_SPELL_PARTY_DAMAGE",
    "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_AURA_GONE_OTHER",
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
}

for _, ev in ipairs(events) do
    TattleTotem:RegisterEvent(ev)
end

local function InitDefaults()
    if not TattleTotemDB then
        TattleTotemDB = {
            enabled = true,
            debugMode = false,
            outputMethod = "YELL",
            cooldown = 5,
            minimapAngle = 225,
            monitor4HM = true,
            ktMonitor = {
                aoe = true,
                shackle = true,
                pets = true,
            },
            spells = {},
        }

        for spellName, _ in pairs(TattleTotem_AoESpells) do
            TattleTotemDB.spells[spellName] = true
        end
    end

    if not TattleTotemDB.ktMonitor then
        TattleTotemDB.ktMonitor = { aoe = true, shackle = true, pets = true }
    end
    if TattleTotemDB.ktMonitor.pets == nil then
        TattleTotemDB.ktMonitor.pets = true
    end

    if not TattleTotemDB.spells then
        TattleTotemDB.spells = {}
        for spellName, _ in pairs(TattleTotem_AoESpells) do
            TattleTotemDB.spells[spellName] = true
        end
    end
    if not TattleTotemDB.pullLogs then
        TattleTotemDB.pullLogs = {}
    end
end

local function SetCombatLogRange()
    SetCVar("CombatDeathLogRange", 200)
    SetCVar("CombatLogRangeParty", 200)
    SetCVar("CombatLogRangePartyPet", 200)
    SetCVar("CombatLogRangeFriendlyPlayers", 200)
    SetCVar("CombatLogRangeFriendlyPlayersPets", 200)
    SetCVar("CombatLogRangeHostilePlayers", 200)
    SetCVar("CombatLogRangeHostilePlayersPets", 200)
    SetCVar("CombatLogRangeCreature", 200)
end

function TattleTotem:OnLoad()
    InitDefaults()
    SetCombatLogRange()
    TattleTotem_UpdateMinimapButton()
    self:TryHookBigWigs()
end

function TattleTotem:OnZoneChange()
    local zone = GetRealZoneText() or ""
    local subzone = GetMinimapZoneText() or ""
    local zoneLower = string.lower(zone)
    local subzoneLower = string.lower(subzone)

    local wasIn4HM = self.in4HMArea
    local wasInKT = self.inKTChamber

    self.inNaxxramas = (string.find(zoneLower, "naxxramas") ~= nil)
    self.inKTChamber = (string.find(subzoneLower, "kel'thuzad") ~= nil or string.find(subzoneLower, "inner sanctum") ~= nil)
    self.in4HMArea = (string.find(subzoneLower, "four horsemen") ~= nil or string.find(subzoneLower, "deathknight wing") ~= nil)

    if self.in4HMArea and not wasIn4HM and TattleTotemDB.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff4HM|r Ready")
    end
    if self.inKTChamber and not wasInKT and TattleTotemDB.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffKT|r Ready")
        self:AnnounceKTDetected()
    end

    self.horsemenPuller = nil
    self.activeShackles = {}
    self.guardianDoTs = {}
    self.inCombat = false
    self.inKTEncounter = false
    self.guardiansActive = false
    self.ktDetectedAnnounced = false
    self.in4HMEncounter = false
    self.ktPullLogged = false
    self.petWarned = {}
end

function TattleTotem:ShouldMonitor()
    if TattleTotemDB.debugMode then
        return true
    end
    return self.in4HMArea or self.in4HMEncounter or self.inKTEncounter
end

function TattleTotem:UpdateKTEncounterFromLog(msg)
    if self.inKTEncounter then
        return
    end
    for mobName, _ in pairs(TattleTotem_KTMobs) do
        if string.find(msg, mobName) then
            self.inKTEncounter = true
            if mobName == "Guardian of Icecrown" then
                self.guardiansActive = true
            end
            self:AnnounceKTDetected()
            return
        end
    end
end

function TattleTotem:TryHookBigWigs()
    if self.bigWigsHooked then
        return
    end
    if not BigWigs or not BigWigs.BigWigs_RecvSync then
        return
    end
    local original = BigWigs.BigWigs_RecvSync
    BigWigs.BigWigs_RecvSync = function(selfBW, sync, moduleName, nick, ...)
        if TattleTotem and TattleTotem.OnBigWigsSync then
            TattleTotem:OnBigWigsSync(sync, moduleName, nick)
        end
        return original(selfBW, sync, moduleName, nick, ...)
    end
    self.bigWigsHooked = true
end

function TattleTotem:OnBigWigsSync(sync, moduleName, nick)
    if sync == "BossEngaged" then
        if moduleName == "Kel'Thuzad" then
            self.inKTEncounter = true
            self:AnnounceKTDetected()
        elseif moduleName == "The Four Horsemen" then
            self.in4HMEncounter = true
        end
    elseif sync == "BossDeath" then
        if moduleName == "Kel'Thuzad" then
            self.inKTEncounter = false
        elseif moduleName == "The Four Horsemen" then
            self.in4HMEncounter = false
        end
    end
end

function TattleTotem:LogPull(boss, puller, source)
    if not TattleTotemDB then return end
    if not TattleTotemDB.pullLogs then
        TattleTotemDB.pullLogs = {}
    end
    local entry = {
        boss = boss or "Unknown",
        puller = puller or "Unknown",
        source = source or "",
        stamp = date("%Y-%m-%d %H:%M:%S"),
        time = time(),
    }
    table.insert(TattleTotemDB.pullLogs, entry)
    if table.getn(TattleTotemDB.pullLogs) > 200 then
        table.remove(TattleTotemDB.pullLogs, 1)
    end
end

function TattleTotem:Update4HMEncounterFromLog(msg)
    if self.in4HMEncounter then
        return
    end
    for bossName, _ in pairs(TattleTotem_FourHorsemen) do
        if string.find(msg, bossName) then
            self.in4HMEncounter = true
            return
        end
    end
end

function TattleTotem:Update4HMEncounterFromTarget()
    local targetName = UnitName("target")
    if targetName and TattleTotem_FourHorsemen[targetName] then
        self.in4HMEncounter = true
    end
end

function TattleTotem:AnnounceKTDetected()
    if self.ktDetectedAnnounced then
        return
    end
    self.ktDetectedAnnounced = true
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffKT detected|r")
end

function TattleTotem:CanReport(caster, spell)
    local key = caster .. "_" .. spell .. "_reported"
    local now = GetTime()
    local lastReport = self.recentCasts[key]

    if lastReport and (now - lastReport) < TattleTotemDB.cooldown then
        return false
    end

    self.recentCasts[key] = now
    return true
end

function TattleTotem:RecordAoECast(caster, spell)
    local key = caster .. "_" .. spell
    self.recentCasts[key] = GetTime()
end

function TattleTotem:ReportAoE(caster, spell)
    if not self:CanReport(caster, spell) then
        return
    end

    local message = caster .. " AoE: " .. spell

    if TattleTotemDB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6600[TattleTotem]|r " .. message)
    else
        SendChatMessage(message, TattleTotemDB.outputMethod)
    end
end

function TattleTotem:OnSpellDamage(msg, forcedCaster)
    if not TattleTotemDB.enabled then return end
    self:UpdateKTEncounterFromLog(msg)
    if not self:ShouldMonitor() then return end
    if not TattleTotemDB.ktMonitor.aoe then return end
    if not self.guardiansActive then return end

    local caster, spell

    local _, _, c, s = string.find(msg, "(.+)'s (.+) hits")
    if not c then
        _, _, c, s = string.find(msg, "(.+)'s (.+) crits")
    end

    if not c and forcedCaster then
        _, _, s = string.find(msg, "Your (.+) hits")
        if not s then
            _, _, s = string.find(msg, "Your (.+) crits")
        end
        c = forcedCaster
    end

    if c and s then
        local baseSpell = string.gsub(s, " %(Rank %d+%)", "")

        if TattleTotem_AoESpells[baseSpell] and TattleTotemDB.spells[baseSpell] then
            self:RecordAoECast(c, baseSpell)
            self:ReportAoE(c, baseSpell)
        end
    end
end

function TattleTotem:OnCreatureDebuff(msg)
    if not TattleTotemDB.enabled then return end
    self:UpdateKTEncounterFromLog(msg)
    if not TattleTotemDB.ktMonitor.shackle then return end

    if string.find(msg, "Guardian of Icecrown is afflicted by Shackle Undead") then
        table.insert(self.activeShackles, {
            time = GetTime(),
            duration = 50,
        })
    end
end

function TattleTotem:OnPeriodicDamage(msg)
    if not TattleTotemDB.enabled then return end
    self:UpdateKTEncounterFromLog(msg)
    if not TattleTotemDB.ktMonitor.shackle then return end
    if not string.find(msg, "Guardian of Icecrown") then return end

    local caster, spell

    local _, _, c, s = string.find(msg, "(.+)'s (.+) hits Guardian of Icecrown")
    if not c then
        _, _, c, s = string.find(msg, "(.+)'s (.+) crits Guardian of Icecrown")
    end

    if not c then
        _, _, s = string.find(msg, "Your (.+) hits Guardian of Icecrown")
        if not s then
            _, _, s = string.find(msg, "Your (.+) crits Guardian of Icecrown")
        end
        if s then
            c = UnitName("player")
        end
    end

    if c and s then
        local baseSpell = string.gsub(s, " %(Rank %d+%)", "")
        if not self.guardianDoTs[c] then
            self.guardianDoTs[c] = {}
        end
        self.guardianDoTs[c][baseSpell] = GetTime()
    end
end

function TattleTotem:OnAuraFade(msg)
    if not TattleTotemDB.enabled then return end
    self:UpdateKTEncounterFromLog(msg)
    if not TattleTotemDB.ktMonitor.shackle then return end

    if string.find(msg, "Shackle Undead fades from Guardian of Icecrown") then
        local now = GetTime()
        local shackle = table.remove(self.activeShackles, 1)

        if shackle then
            local elapsed = now - shackle.time

            if elapsed < (shackle.duration - 5) then
                self:CheckShackleBreaker()
            end
        end
    end
end

function TattleTotem:CheckShackleBreaker()
    local now = GetTime()
    local window = 0.5
    local reported = {}

    for key, timestamp in pairs(self.recentCasts) do
        if (now - timestamp) < window then
            local _, _, caster, spell = string.find(key, "(.+)_(.+)")
            if caster and spell and not string.find(key, "_reported") then
                local message = caster .. " BROKE SHACKLE! (" .. spell .. ")"
                reported[caster] = true

                if TattleTotemDB.debugMode then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[TattleTotem]|r " .. message)
                else
                    SendChatMessage(message, TattleTotemDB.outputMethod)
                end
            end
        end
    end

    local dotWindow = 10
    for caster, spells in pairs(self.guardianDoTs) do
        if not reported[caster] then
            for spell, timestamp in pairs(spells) do
                if (now - timestamp) < dotWindow then
                    local message = caster .. " had DoT on Guardian! (" .. spell .. ")"

                    if TattleTotemDB.debugMode then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[TattleTotem]|r " .. message)
                    else
                        SendChatMessage(message, TattleTotemDB.outputMethod)
                    end
                    reported[caster] = true
                    break
                end
            end
        end
    end

    self.guardianDoTs = {}
end

function TattleTotem:OnBossAttack(msg)
    self:UpdateKTEncounterFromLog(msg)
    self:Update4HMEncounterFromLog(msg)
    if not TattleTotemDB.enabled then return end
    if not TattleTotemDB.monitor4HM then return end
    if not self:ShouldMonitor() then return end
    if not (self.in4HMArea or self.in4HMEncounter) then return end
    if self.inCombat then return end
    if self.horsemenPuller then return end

    for bossName, _ in pairs(TattleTotem_FourHorsemen) do
        local patterns = {
            bossName .. " hits (.+) for",
            bossName .. " crits (.+) for",
            bossName .. " misses (.+)%.",
            bossName .. " attacks (.+)%.",
        }

        for _, pattern in ipairs(patterns) do
            local _, _, target = string.find(msg, pattern)
            if target then
                self.horsemenPuller = target
                self:LogPull(bossName, target, "combat")
                self:ReportPull(target)
                return
            end
        end
    end

    if not self.ktPullLogged then
        local ktPatterns = {
            "Kel'Thuzad hits (.+) for",
            "Kel'Thuzad crits (.+) for",
            "Kel'Thuzad misses (.+)%.",
            "Kel'Thuzad attacks (.+)%.",
        }
        for _, pattern in ipairs(ktPatterns) do
            local _, _, target = string.find(msg, pattern)
            if target then
                self.ktPullLogged = true
                self:LogPull("Kel'Thuzad", target, "combat")
                return
            end
        end
    end
end

function TattleTotem:CheckHunterPets()
    if not TattleTotemDB.enabled then return end
    if not TattleTotemDB.ktMonitor.pets then return end
    if not self.inKTEncounter then return end

    local num = GetNumRaidMembers()
    for i = 1, num do
        local unit = "raid" .. i
        local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            if class == "HUNTER" then
                local petUnit = unit .. "pet"
                if UnitExists(petUnit) then
                    if not self.petWarned[name] then
                        self.petWarned[name] = true
                        local message = name .. " has pet out (KT)!"
                        if TattleTotemDB.debugMode then
                            DEFAULT_CHAT_FRAME:AddMessage("|cffff3300[TattleTotem]|r " .. message)
                        else
                            SendChatMessage(message, TattleTotemDB.outputMethod)
                        end
                    end
                else
                    self.petWarned[name] = nil
                end
            end
        end
    end
end

function TattleTotem:ReportPull(player)
    local message = player .. " pulled 4HM!"

    if TattleTotemDB.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[TattleTotem]|r " .. message)
    else
        SendChatMessage(message, TattleTotemDB.outputMethod)
    end
end

function TattleTotem:OnCombatStart()
    self.inCombat = true
end

function TattleTotem:OnCombatEnd()
    self.inCombat = false
    self.horsemenPuller = nil
    self.activeShackles = {}
    self.guardianDoTs = {}
    self.inKTEncounter = false
    self.guardiansActive = false
    self.ktDetectedAnnounced = false
    self.in4HMEncounter = false
    self.ktPullLogged = false
    self.petWarned = {}
end

function TattleTotem:CleanupReports()
    local now = GetTime()
    local cutoff = now - 60

    for key, timestamp in pairs(self.recentCasts) do
        if timestamp < cutoff then
            self.recentCasts[key] = nil
        end
    end
end

TattleTotem:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TattleTotem" then
        TattleTotem:OnLoad()
    elseif event == "ADDON_LOADED" and arg1 == "BigWigs" then
        TattleTotem:TryHookBigWigs()

    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        TattleTotem:OnZoneChange()

    elseif event == "PLAYER_REGEN_DISABLED" then
        TattleTotem:OnCombatStart()

    elseif event == "PLAYER_REGEN_ENABLED" then
        TattleTotem:OnCombatEnd()

    elseif event == "PLAYER_TARGET_CHANGED" then
        TattleTotem:Update4HMEncounterFromTarget()

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        TattleTotem:OnSpellDamage(arg1, UnitName("player"))

    elseif event == "CHAT_MSG_SPELL_PARTY_DAMAGE" or event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE" then
        TattleTotem:OnSpellDamage(arg1)

    elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
        TattleTotem:OnCreatureDebuff(arg1)
        TattleTotem:OnPeriodicDamage(arg1)

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" or
           event == "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE" or
           event == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE" then
        TattleTotem:OnPeriodicDamage(arg1)

    elseif event == "CHAT_MSG_SPELL_AURA_GONE_OTHER" then
        TattleTotem:OnAuraFade(arg1)

    elseif string.find(event, "CHAT_MSG_COMBAT_CREATURE") then
        TattleTotem:OnBossAttack(arg1)
    end
end)

TattleTotem:SetScript("OnUpdate", function(self, elapsed)
    local frame = self or this or TattleTotem
    local dt = elapsed or arg1 or 0
    frame.cleanupTimer = frame.cleanupTimer + dt
    if frame.cleanupTimer > 10 then
        frame.cleanupTimer = 0
        frame:CleanupReports()
    end
    frame.petCheckTimer = (frame.petCheckTimer or 0) + dt
    if frame.petCheckTimer > 2 then
        frame.petCheckTimer = 0
        frame:CheckHunterPets()
    end
end)
