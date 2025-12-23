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

local overlay = button:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetTexture("Interface\\Icons\\Ability_Creature_Cursed_02")
icon:SetPoint("CENTER", button, "CENTER", 0, 0)
button.icon = icon

local isDragging = false

local function UpdatePosition()
    local angle = TattleTotemDB and TattleTotemDB.minimapAngle or 225
    local radius = 80
    local rads = math.rad(angle)
    local x = math.cos(rads) * radius
    local y = math.sin(rads) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

button:SetScript("OnDragStart", function(self)
    local btn = self or this
    if not btn then return end
    isDragging = true
    btn:LockHighlight()
end)

button:SetScript("OnDragStop", function(self)
    local btn = self or this
    if not btn then return end
    isDragging = false
    btn:UnlockHighlight()
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

button:SetScript("OnUpdate", function(self)
    local btn = self or this
    if not btn then return end
    if isDragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        local radius = 80
        local x = math.cos(math.rad(angle)) * radius
        local y = math.sin(math.rad(angle)) * radius
        btn:ClearAllPoints()
        btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end)

button:SetScript("OnClick", function(self, mouseButton)
    local btn = self or this
    local click = mouseButton or arg1
    if click == "LeftButton" then
        TattleTotem_ToggleConfig()
    elseif click == "RightButton" then
        if TattleTotemDB then
            TattleTotemDB.enabled = not TattleTotemDB.enabled
            if TattleTotemDB.enabled then
                button.icon:SetDesaturated(nil)
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Enabled")
            else
                button.icon:SetDesaturated(1)
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ffffTattleTotem:|r Disabled")
            end
        end
    end
end)

button:SetScript("OnEnter", function(self)
    local btn = self or this
    if not btn then return end
    GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
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

button:SetScript("OnShow", UpdatePosition)

function TattleTotem_UpdateMinimapButton()
    if TattleTotemDB and TattleTotemDB.enabled then
        button.icon:SetDesaturated(nil)
    else
        button.icon:SetDesaturated(1)
    end
    UpdatePosition()
end
