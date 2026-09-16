---------------------------------------------------------
-- GLOBAL UI CONFIGURATION
---------------------------------------------------------
local UI_CONFIG = {
    -- 玩家与小队血条尺寸
    UNIT_WIDTH  = 70, -- 框架/血条宽度
    HP_HEIGHT   = 45,  -- 血条高度
    MP_HEIGHT   = 5,   -- 蓝条/能量条高度
    BAR_GAP     = 0,   -- 间隙

    -- 团队框架尺寸 (40人面板)
    RAID_WIDTH  = 80,  -- 团队单格宽度
    RAID_HEIGHT = 24,  -- 团队单格高度

    -- 顶部拖拽条尺寸
    DRAG_WIDTH  = 60, -- 拖拽条宽度
    DRAG_HEIGHT = 16,  -- 拖拽条高度
}

local TOTAL_BORDER_HEIGHT = UI_CONFIG.HP_HEIGHT + UI_CONFIG.MP_HEIGHT + UI_CONFIG.BAR_GAP

---------------------------------------------------------
-- RUNTIME DATA (NO PERSISTENCE)
---------------------------------------------------------
local runtimeRoles = {}
local ROLE_CYCLE = { "Tank", "Healer", "DPS" }
local ROLE_COLORS = {
    Tank = { 0.3, 0.5, 1 },
    Healer = { 0.3, 1, 0.4 },
    DPS = { 1, 0.3, 0.3 },
}

local currentScale = 1.0
local layoutHorizontal = false

local function CycleRole(name)
    if not name then return end
    local current = runtimeRoles[name]

    if not current then
        runtimeRoles[name] = ROLE_CYCLE[1]
        return
    end

    local currentIndex = nil
    for i, role in ipairs(ROLE_CYCLE) do
        if role == current then
            currentIndex = i
            break
        end
    end

    if not currentIndex or currentIndex >= #ROLE_CYCLE then
        runtimeRoles[name] = nil
    else
        runtimeRoles[name] = ROLE_CYCLE[currentIndex + 1]
    end
end

local function CreateRoleBadge(parentBar)
    local badge = CreateFrame("Frame", nil, parentBar)
    badge:SetWidth(20)
    badge:SetHeight(20)
    badge:SetPoint("TOPRIGHT", parentBar, "TOPRIGHT", 0, 0)
    badge:EnableMouse(true)
    badge:SetFrameLevel(15)

    local badgeBG = badge:CreateTexture(nil, "BACKGROUND")
    badgeBG:SetAllPoints()
    badgeBG:SetTexture("Interface\\Buttons\\WHITE8x8")
    badgeBG:SetVertexColor(0, 0, 0, 0)

    local EMPTY_OUTLINE_THICKNESS = 0
    local emptyOutlineTop = badge:CreateTexture(nil, "OVERLAY")
    emptyOutlineTop:SetPoint("TOPLEFT", badge, "TOPLEFT", 5, -5)
    emptyOutlineTop:SetPoint("TOPRIGHT", badge, "TOPRIGHT", -5, -5)
    emptyOutlineTop:SetHeight(EMPTY_OUTLINE_THICKNESS)
    emptyOutlineTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    emptyOutlineTop:SetVertexColor(0, 0, 0, 1)

    local emptyOutlineBottom = badge:CreateTexture(nil, "OVERLAY")
    emptyOutlineBottom:SetPoint("BOTTOMLEFT", badge, "BOTTOMLEFT", 5, 5)
    emptyOutlineBottom:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -5, 5)
    emptyOutlineBottom:SetHeight(EMPTY_OUTLINE_THICKNESS)
    emptyOutlineBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    emptyOutlineBottom:SetVertexColor(0, 0, 0, 1)

    local emptyOutlineLeft = badge:CreateTexture(nil, "OVERLAY")
    emptyOutlineLeft:SetPoint("TOPLEFT", badge, "TOPLEFT", 5, -5)
    emptyOutlineLeft:SetPoint("BOTTOMLEFT", badge, "BOTTOMLEFT", 5, 5)
    emptyOutlineLeft:SetWidth(EMPTY_OUTLINE_THICKNESS)
    emptyOutlineLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    emptyOutlineLeft:SetVertexColor(0, 0, 0, 1)

    local emptyOutlineRight = badge:CreateTexture(nil, "OVERLAY")
    emptyOutlineRight:SetPoint("TOPRIGHT", badge, "TOPRIGHT", -5, -5)
    emptyOutlineRight:SetPoint("BOTTOMRIGHT", badge, "BOTTOMRIGHT", -5, 5)
    emptyOutlineRight:SetWidth(EMPTY_OUTLINE_THICKNESS)
    emptyOutlineRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    emptyOutlineRight:SetVertexColor(0, 0, 0, 1)

    local emptyOutline = { emptyOutlineTop, emptyOutlineBottom, emptyOutlineLeft, emptyOutlineRight }

    local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    badgeText:SetPoint("CENTER", badge, "CENTER", 0, 0)

    local badgeIcon = badge:CreateTexture(nil, "OVERLAY")
    badgeIcon:SetWidth(20)
    badgeIcon:SetHeight(20)
    badgeIcon:SetPoint("CENTER", badge, "CENTER", 0, 0)
    badgeIcon:Hide()

    local clickCatcher = CreateFrame("Frame", nil, parentBar)
    clickCatcher:SetAllPoints(badge)
    clickCatcher:EnableMouse(true)
    clickCatcher:SetFrameLevel(20)
    clickCatcher:SetFrameStrata("TOOLTIP")

    return badge, badgeText, badgeIcon, clickCatcher, emptyOutline
end

local function UpdateRoleBadge(badge, badgeText, badgeIcon, emptyOutline, name)
    local role = name and runtimeRoles[name]

    local ROLE_BUILTIN_ICONS = {
        Tank = "Interface\\AddOns\\UAHeal\\icons\\tank",
        Healer = "Interface\\AddOns\\UAHeal\\icons\\healer",
        DPS = "Interface\\AddOns\\UAHeal\\icons\\dps",
    }

    if role then
        for _, edge in ipairs(emptyOutline) do
            edge:Hide()
        end

        local iconPath = ROLE_BUILTIN_ICONS[role]

        if iconPath then
            badgeText:SetText("")
            badgeIcon:SetTexture(iconPath)
            badgeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            badgeIcon:Show()
        else
            badgeIcon:Hide()
            local color = ROLE_COLORS[role] or { 1, 1, 1 }
            badgeText:SetTextColor(color[1], color[2], color[3])
            badgeText:SetText(role:sub(1, 1))
        end
    else
        badgeIcon:Hide()
        badgeText:SetText("")
        for _, edge in ipairs(emptyOutline) do
            edge:Show()
        end
    end
end

---------------------------------------------------------
-- DRAG HANDLE (CENTER POSITIONED)
---------------------------------------------------------

local dragHandle = CreateFrame("Frame", "UAHealDragHandle", UIParent)
dragHandle:SetFrameStrata("LOW")
dragHandle:SetWidth(UI_CONFIG.DRAG_WIDTH)
dragHandle:SetHeight(UI_CONFIG.DRAG_HEIGHT)
dragHandle:SetPoint("CENTER", UIParent, "CENTER", -300, 100)
dragHandle:EnableMouse(true)

local PositionPartyFrames

local function ApplyButtonBevel(frame)
    local fill = frame:CreateTexture(nil, "BACKGROUND")
    fill:SetAllPoints()
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetVertexColor(0.25, 0.25, 0.25, 0.9)

    local edgeTop = frame:CreateTexture(nil, "BORDER")
    edgeTop:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edgeTop:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edgeTop:SetHeight(1)
    edgeTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeTop:SetVertexColor(0.55, 0.55, 0.55, 0.9)

    local edgeLeft = frame:CreateTexture(nil, "BORDER")
    edgeLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    edgeLeft:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edgeLeft:SetWidth(1)
    edgeLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeLeft:SetVertexColor(0.55, 0.55, 0.55, 0.9)

    local edgeBottom = frame:CreateTexture(nil, "BORDER")
    edgeBottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    edgeBottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edgeBottom:SetHeight(1)
    edgeBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeBottom:SetVertexColor(0.02, 0.02, 0.02, 0.9)

    local edgeRight = frame:CreateTexture(nil, "BORDER")
    edgeRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    edgeRight:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    edgeRight:SetWidth(1)
    edgeRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeRight:SetVertexColor(0.02, 0.02, 0.02, 0.9)
end

ApplyButtonBevel(dragHandle)

local isMinimized = false

local minimizeButton = CreateFrame("Frame", "UAHealMinimizeButton", UIParent)
minimizeButton:SetFrameStrata("LOW")
minimizeButton:SetWidth(UI_CONFIG.DRAG_HEIGHT)
minimizeButton:SetHeight(UI_CONFIG.DRAG_HEIGHT)
minimizeButton:SetPoint("LEFT", dragHandle, "RIGHT", 0, 0)
minimizeButton:EnableMouse(true)
ApplyButtonBevel(minimizeButton)

local minimizeText = minimizeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
minimizeText:SetPoint("CENTER", minimizeButton, "CENTER", 0, 0)
minimizeText:SetText("-")

minimizeButton:SetScript("OnMouseDown", function()
    isMinimized = not isMinimized
    if isMinimized then
        minimizeText:SetText("+")
    else
        minimizeText:SetText("-")
    end
end)

local dragCatcher = CreateFrame("Frame", "UAHealDragCatcher", UIParent)
dragCatcher:SetAllPoints(UIParent)
dragCatcher:SetFrameStrata("TOOLTIP")
dragCatcher:EnableMouse(true)
dragCatcher:Hide()

local dragging = false

local function StopDrag()
    dragging = false
    dragCatcher:Hide()
end

---------------------------------------------------------
-- TARGET ON CLICK ATTACHMENT
---------------------------------------------------------

local function AttachTargetOnClick(frame, getUnit)
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function()
        local unit = getUnit()
        if unit and UnitExists(unit) then
            TargetUnit(unit)
        end
    end)
end

dragHandle:SetScript("OnMouseDown", function()
    dragging = true
    dragCatcher:Show()
end)

dragHandle:SetScript("OnMouseUp", StopDrag)
dragCatcher:SetScript("OnMouseUp", StopDrag)

dragHandle:SetScript("OnUpdate", function()
    if dragging then
        local x, y = GetCursorPosition()
        dragHandle:ClearAllPoints()
        dragHandle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end)

---------------------------------------------------------
-- LOW HEALTH THRESHOLD
---------------------------------------------------------

local LOW_HEALTH_THRESHOLD = 0.30

local function ClampPercent(value)
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

---------------------------------------------------------
-- RAID MODE DETECTION
---------------------------------------------------------

local function InRaidMode()
    return (GetNumRaidMembers() or 0) > 0
end

---------------------------------------------------------
-- CLASS COLORS & ICONS
---------------------------------------------------------

local CLASS_COLORS = {
    WARRIOR = { r = 0.780, g = 0.612, b = 0.431 },
    PALADIN = { r = 0.961, g = 0.549, b = 0.729 },
    HUNTER  = { r = 0.671, g = 0.831, b = 0.451 },
    ROGUE   = { r = 1.000, g = 0.961, b = 0.412 },
    PRIEST  = { r = 1.000, g = 1.000, b = 1.000 },
    SHAMAN  = { r = 0.000, g = 0.439, b = 0.871 },
    MAGE    = { r = 0.412, g = 0.800, b = 0.941 },
    WARLOCK = { r = 0.580, g = 0.510, b = 0.788 },
    DRUID   = { r = 1.000, g = 0.490, b = 0.039 },
}

local function GetClassColor(unit)
    local _, classToken = UnitClass(unit)
    local color = classToken and CLASS_COLORS[classToken]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 0, 0
end

local POWER_COLORS = {
    [0] = { r = 0.000, g = 0.000, b = 1.000 },
    [1] = { r = 1.000, g = 0.000, b = 0.000 },
    [2] = { r = 1.000, g = 0.500, b = 0.250 },
    [3] = { r = 1.000, g = 1.000, b = 0.000 },
    [4] = { r = 0.000, g = 1.000, b = 0.000 },
}

local function GetPowerColor(unit)
    local powerType = UnitPowerType(unit)
    local color = POWER_COLORS[powerType]
    if color then
        return color.r, color.g, color.b
    end
    return 0, 0, 1
end

---------------------------------------------------------
-- BUFF / DEBUFF ICONS
---------------------------------------------------------

local BUFF_ICON_SIZE = 12
local BUFF_ICON_COUNT = 6

local function CreateBuffIcons(parentBar)
    local icons = {}
    for i = 1, BUFF_ICON_COUNT do
        local icon = parentBar:CreateTexture(nil, "OVERLAY")
        icon:SetWidth(BUFF_ICON_SIZE)
        icon:SetHeight(BUFF_ICON_SIZE)
        if i == 1 then
            icon:SetPoint("TOPLEFT", parentBar, "TOPLEFT", 0, 0)
        else
            icon:SetPoint("LEFT", icons[i - 1], "RIGHT", 0, 0)
        end
        icon:Hide()
        icons[i] = icon
    end
    return icons
end

local BUFF_PRIORITY = {
    ["/Game/Interface/Icons/Spell_Holy_WordFortitude_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_PrayerOfFortitude_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_PowerWordShield_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_Renew_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_Renew02_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_DivineSpirit_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_PrayerofSpirit_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_InnerFire_TEX"] = 1,
    ["/Game/Interface/Icons/Spell_Holy_FistOfJustice_TEX"] = 2,
    ["/Game/Interface/Icons/Spell_Holy_GreaterBlessingofKings_TEX"] = 2,
    ["/Game/Interface/Icons/Spell_Holy_SealOfWisdom_TEX"] = 2,
    ["/Game/Interface/Icons/Spell_Holy_SealOfSalvation_TEX"] = 2,
    ["/Game/Interface/Icons/Spell_Holy_BlessingOfProtection_TEX"] = 2,
    ["/Game/Interface/Icons/Spell_Nature_Regeneration_TEX"] = 3,
    ["/Game/Interface/Icons/Spell_Nature_Thorns_TEX"] = 3,
    ["/Game/Interface/Icons/Spell_Holy_MagicalSentry_TEX"] = 4,
    ["/Game/Interface/Icons/Spell_Frost_FrostArmor02_TEX"] = 4,
    ["/Game/Interface/Icons/Spell_Nature_StrengthOfEarthTotem_TEX"] = 5,
    ["/Game/Interface/Icons/Spell_Nature_ManaRegenTotem_TEX"] = 5,
    ["/Game/Interface/Icons/Spell_Nature_Windfury_TEX"] = 5,
    ["/Game/Interface/Icons/Ability_Warrior_BattleShout_TEX"] = 6,
    ["/Game/Interface/Icons/Ability_Warrior_RallyingCry_TEX"] = 6,
}

local function UpdateBuffIcons(icons, unit)
    local buffTextures = {}
    for i = 1, BUFF_ICON_COUNT do
        local texture = UnitBuff(unit, i)
        if texture then
            table.insert(buffTextures, texture)
        end
    end

    table.sort(buffTextures, function(a, b)
        local aTier = BUFF_PRIORITY[a] or 999
        local bTier = BUFF_PRIORITY[b] or 999
        return aTier < bTier
    end)

    for i = 1, BUFF_ICON_COUNT do
        local icon = icons[i]
        local texture = buffTextures[i]
        if texture then
            icon:SetTexture(texture)
            icon:Show()
        else
            icon:Hide()
        end
    end
end

local DEBUFF_ICON_SIZE = 12
local DEBUFF_ICON_COUNT = 6

local function CreateDebuffIcons(parentBar)
    local icons = {}
    for i = 1, DEBUFF_ICON_COUNT do
        local icon = parentBar:CreateTexture(nil, "OVERLAY")
        icon:SetWidth(DEBUFF_ICON_SIZE)
        icon:SetHeight(DEBUFF_ICON_SIZE)
        if i == 1 then
            icon:SetPoint("BOTTOMLEFT", parentBar, "BOTTOMLEFT", 2, 2)
        else
            icon:SetPoint("LEFT", icons[i - 1], "RIGHT", 1, 0)
        end
        icon:Hide()
        icons[i] = icon
    end
    return icons
end

local function UpdateDebuffIcons(icons, unit)
    for i = 1, DEBUFF_ICON_COUNT do
        local texture = UnitDebuff(unit, i)
        local icon = icons[i]
        if texture then
            icon:SetTexture(texture)
            icon:Show()
        else
            icon:Hide()
        end
    end
end

---------------------------------------------------------
-- CARD STYLING
---------------------------------------------------------

local function CreateCardBorder(parent, topOffset, blockHeight)
    local BORDER_THICKNESS = 1

    local border = CreateFrame("Frame", nil, parent)
    border:SetPoint("TOP", parent, "TOP", 0, topOffset + 1)
    border:SetWidth(UI_CONFIG.UNIT_WIDTH + 4)
    border:SetHeight(blockHeight + 2)
    border:SetFrameLevel(10)

    local fill = parent:CreateTexture(nil, "BACKGROUND")
    fill:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetVertexColor(0.3, 0.3, 0.3, 1)
    border.fillTexture = fill

    local edgeTop = border:CreateTexture(nil, "OVERLAY")
    edgeTop:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    edgeTop:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    edgeTop:SetHeight(BORDER_THICKNESS)
    edgeTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeTop:SetVertexColor(0, 0, 0, 1)

    local edgeBottom = border:CreateTexture(nil, "OVERLAY")
    edgeBottom:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    edgeBottom:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    edgeBottom:SetHeight(BORDER_THICKNESS)
    edgeBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeBottom:SetVertexColor(0, 0, 0, 1)

    local edgeLeft = border:CreateTexture(nil, "OVERLAY")
    edgeLeft:SetPoint("TOPLEFT", border, "TOPLEFT", 0, 0)
    edgeLeft:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 0, 0)
    edgeLeft:SetWidth(BORDER_THICKNESS)
    edgeLeft:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeLeft:SetVertexColor(0, 0, 0, 1)

    local edgeRight = border:CreateTexture(nil, "OVERLAY")
    edgeRight:SetPoint("TOPRIGHT", border, "TOPRIGHT", 0, 0)
    edgeRight:SetPoint("BOTTOMRIGHT", border, "BOTTOMRIGHT", 0, 0)
    edgeRight:SetWidth(BORDER_THICKNESS)
    edgeRight:SetTexture("Interface\\Buttons\\WHITE8x8")
    edgeRight:SetVertexColor(0, 0, 0, 1)

    return border
end

local function AddBarSheen(bar, barHeight)
    local sheen = bar:CreateTexture(nil, "OVERLAY")
    sheen:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
    sheen:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
    sheen:SetHeight(barHeight * 0)
    sheen:SetTexture("Interface\\Buttons\\WHITE8x8")
    sheen:SetVertexColor(1, 1, 1, 0.25)
    sheen:SetBlendMode("ADD")
end

local function CreateOutlinedText(parent, fontSize)
    local mainText = parent:CreateFontString(nil, "OVERLAY")
    mainText:SetFont("Fonts\\FRIZQT__.TTF", fontSize, "THICKOUTLINE")
    mainText:SetTextColor(1, 0.82, 0)

    local label = {}

    function label:SetPoint(...)
        mainText:SetPoint(...)
    end

    function label:SetText(text)
        mainText:SetText(text)
    end

    function label:Show()
        mainText:Show()
    end

    function label:Hide()
        mainText:Hide()
    end

    return label
end

---------------------------------------------------------
-- MAIN FRAME (PLAYER)
---------------------------------------------------------

local f = CreateFrame("Frame", "UAHealFrame", UIParent)
f:SetFrameStrata("LOW")
f:SetWidth(200)
f:SetHeight(120)
f:SetPoint("TOP", dragHandle, "BOTTOM", 8, 34)
f:EnableMouse(false)

local title = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("CENTER", dragHandle, "CENTER", 0, 0)
title:SetText("UAHeal")

local cardBorder = CreateCardBorder(f, -35, TOTAL_BORDER_HEIGHT)
f.cardBorder = cardBorder

AttachTargetOnClick(cardBorder, function() return "player" end)
cardBorder.unit = "player"

local hpBar = CreateFrame("Frame", "UAHealHPBar", f)
hpBar:SetPoint("TOP", f, "TOP", 0, -36)
hpBar:SetFrameLevel(2)
hpBar:SetWidth(UI_CONFIG.UNIT_WIDTH)
hpBar:SetHeight(UI_CONFIG.HP_HEIGHT)
hpBar:EnableMouse(false)

local hpBG = hpBar:CreateTexture(nil, "BACKGROUND")
hpBG:SetAllPoints()
hpBG:SetTexture("Interface\\Buttons\\WHITE8x8")
hpBG:SetVertexColor(0.2, 0.2, 0.2, 0.8)

local hpFill = hpBar:CreateTexture(nil, "ARTWORK")
hpFill:SetPoint("LEFT", hpBar, "LEFT")
hpFill:SetHeight(UI_CONFIG.HP_HEIGHT)
hpFill:SetTexture("Interface\\Buttons\\WHITE8x8")
hpFill:SetVertexColor(1, 0, 0, 1)

AddBarSheen(hpBar, UI_CONFIG.HP_HEIGHT)

local textBacking = hpBar:CreateTexture(nil, "BACKGROUND")
textBacking:SetPoint("TOP", hpBar, "TOP", 0, -10)
textBacking:SetWidth(UI_CONFIG.UNIT_WIDTH)
textBacking:SetHeight(32)
textBacking:SetTexture("Interface\\Buttons\\WHITE8x8")
textBacking:SetVertexColor(0, 0, 0, 0.85)

local hpText = CreateOutlinedText(hpBar, 14)
hpText:SetPoint("TOP", hpBar, "TOP", 0, -18)

local hpValueText = CreateOutlinedText(hpBar, 12)
hpValueText:SetPoint("TOP", hpBar, "TOP", 0, -32)

local buffIcons = CreateBuffIcons(hpBar)

local roleBadge, roleBadgeText, roleBadgeIcon, roleBadgeClickCatcher, roleBadgeEmptyOutline = CreateRoleBadge(hpBar)
roleBadgeClickCatcher:SetScript("OnMouseDown", function()
    CycleRole(UnitName("player"))
end)
local debuffIcons = CreateDebuffIcons(hpBar)

local mpBar = CreateFrame("Frame", "UAHealMPBar", f)
mpBar:SetPoint("TOP", hpBar, "BOTTOM", 0, 0)
mpBar:SetFrameLevel(2)
mpBar:SetWidth(UI_CONFIG.UNIT_WIDTH)
mpBar:SetHeight(UI_CONFIG.MP_HEIGHT)
mpBar:EnableMouse(false)

local mpBG = mpBar:CreateTexture(nil, "BACKGROUND")
mpBG:SetAllPoints()
mpBG:SetTexture("Interface\\Buttons\\WHITE8x8")
mpBG:SetVertexColor(0.2, 0.2, 0.2, 0.8)

local mpFill = mpBar:CreateTexture(nil, "ARTWORK")
mpFill:SetPoint("LEFT", mpBar, "LEFT")
mpFill:SetHeight(UI_CONFIG.MP_HEIGHT)
mpFill:SetTexture("Interface\\Buttons\\WHITE8x8")
mpFill:SetVertexColor(0, 0, 1, 1)

f.mpBar = mpBar

f:SetScript("OnUpdate", function()
    if InRaidMode() or isMinimized then
        cardBorder:Hide()
        cardBorder.fillTexture:Hide()
        hpBar:Hide()
        mpBar:Hide()
        return
    end
    cardBorder:Show()
    cardBorder.fillTexture:Show()
    hpBar:Show()
    mpBar:Show()

    local unit = "player"
    local name = UnitName(unit) or "Unknown"

    if UnitIsDeadOrGhost(unit) then
        hpFill:SetWidth(0)
        hpFill:SetVertexColor(0.5, 0.5, 0.5)
        hpText:SetText(name)
        hpValueText:SetText("Dead")
        mpFill:SetWidth(0)
        UpdateBuffIcons(buffIcons, unit)
        UpdateDebuffIcons(debuffIcons, unit)
        UpdateRoleBadge(roleBadge, roleBadgeText, roleBadgeIcon, roleBadgeEmptyOutline, name)
        return
    end

    local hp = UnitHealth(unit) or 0
    local hpMax = UnitHealthMax(unit) or 1
    local hpPercent = ClampPercent(hpMax > 0 and (hp / hpMax) or 0)
    hpFill:SetWidth(UI_CONFIG.UNIT_WIDTH * hpPercent * currentScale)
    if hpPercent <= LOW_HEALTH_THRESHOLD then
        hpFill:SetVertexColor(1, 0, 0)
    else
        hpFill:SetVertexColor(GetClassColor(unit))
    end

    hpText:SetText(name)
    hpValueText:SetText("-"..(hpMax-hp) .. "/" .. hpMax)
--    hpValueText:SetText(math.floor(hpPercent * 100) .. "%      " .. hp .. "/" .. hpMax)

    local mp = UnitMana(unit) or 0
    local mpMax = UnitManaMax(unit) or 1
    local mpPercent = ClampPercent(mpMax > 0 and (mp / mpMax) or 0)
    mpFill:SetWidth(UI_CONFIG.UNIT_WIDTH * mpPercent * currentScale)
    mpFill:SetVertexColor(GetPowerColor(unit))

    UpdateBuffIcons(buffIcons, unit)
    UpdateDebuffIcons(debuffIcons, unit)
    UpdateRoleBadge(roleBadge, roleBadgeText, roleBadgeIcon, roleBadgeEmptyOutline, name)
end)

---------------------------------------------------------
-- PARTY FRAMES (party1-party4)
---------------------------------------------------------

local units = { "party1", "party2", "party3", "party4" }
local partyFrames = {}

PositionPartyFrames = function()
    local anchor = f
    for index, frame in ipairs(partyFrames) do
        if UnitExists(units[index]) then
            frame:ClearAllPoints()
            if layoutHorizontal then
                frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", -78, 0)
            else
                frame:SetPoint("TOP", anchor.mpBar or anchor, "BOTTOM", 0, 34)
            end
            anchor = frame

            if frame.petOwnerFrame then
                frame.petOwnerFrame:ClearAllPoints()
                if layoutHorizontal then
                    frame.petOwnerFrame:SetPoint("TOP", frame, "TOP", 0, 61)
                else
                    frame.petOwnerFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -78, 0)
                end
            end
        end
    end
end

local partyCollapseFrame = CreateFrame("Frame")
partyCollapseFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
partyCollapseFrame:SetScript("OnEvent", function()
    if not InRaidMode() and not isMinimized then
        PositionPartyFrames()
    end
end)

for index, unit in ipairs(units) do
    local thisUnit = unit
    local partyPetUnit = "partypet" .. index

    local frame = CreateFrame("Frame", "UAHeal_"..thisUnit, UIParent)
    frame:SetFrameStrata("LOW")
    frame:SetWidth(200)
    frame:SetHeight(120)
    table.insert(partyFrames, frame)

    local cardBorder2 = CreateCardBorder(frame, -35, TOTAL_BORDER_HEIGHT)
    frame.cardBorder = cardBorder2

    AttachTargetOnClick(cardBorder2, function() return thisUnit end)
    cardBorder2.unit = thisUnit

    local petOwnerFrame = CreateFrame("Frame", nil, frame)
    petOwnerFrame:SetWidth(200)
    petOwnerFrame:SetHeight(120)
    petOwnerFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -78, 0)
    petOwnerFrame:SetFrameStrata("LOW")
    petOwnerFrame:Hide()
    frame.petOwnerFrame = petOwnerFrame

    local petIndicator = CreateCardBorder(petOwnerFrame, -35, TOTAL_BORDER_HEIGHT)
    AttachTargetOnClick(petIndicator, function() return partyPetUnit end)
    petIndicator.unit = partyPetUnit

    local petIndicatorHPBar = CreateFrame("Frame", nil, petOwnerFrame)
    petIndicatorHPBar:SetPoint("TOP", petOwnerFrame, "TOP", 0, -36)
    petIndicatorHPBar:SetFrameLevel(2)
    petIndicatorHPBar:SetWidth(UI_CONFIG.UNIT_WIDTH)
    petIndicatorHPBar:SetHeight(UI_CONFIG.HP_HEIGHT)

    local petIndicatorFill = petIndicatorHPBar:CreateTexture(nil, "ARTWORK")
    petIndicatorFill:SetPoint("LEFT", petIndicatorHPBar, "LEFT")
    petIndicatorFill:SetHeight(UI_CONFIG.HP_HEIGHT)
    petIndicatorFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    petIndicatorFill:SetVertexColor(0.1, 0.7, 0.5, 1)

    AddBarSheen(petIndicatorHPBar, UI_CONFIG.HP_HEIGHT)

    local petIndicatorText = petIndicatorHPBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petIndicatorText:SetPoint("TOP", petIndicatorHPBar, "TOP", 0, -18)
    petIndicatorText:SetShadowOffset(1, -1)
    petIndicatorText:SetShadowColor(0, 0, 0, 0.8)

    local petIndicatorValueText = petIndicatorHPBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    petIndicatorValueText:SetPoint("TOP", petIndicatorText, "BOTTOM", 0, -2)
    petIndicatorValueText:SetShadowOffset(1, -1)
    petIndicatorValueText:SetShadowColor(0, 0, 0, 0.8)

    local petIndicatorMPBar = CreateFrame("Frame", nil, petOwnerFrame)
    petIndicatorMPBar:SetPoint("TOP", petIndicatorHPBar, "BOTTOM", 0, 0)
    petIndicatorMPBar:SetFrameLevel(2)
    petIndicatorMPBar:SetWidth(UI_CONFIG.UNIT_WIDTH)
    petIndicatorMPBar:SetHeight(UI_CONFIG.MP_HEIGHT)

    local petIndicatorMPFill = petIndicatorMPBar:CreateTexture(nil, "ARTWORK")
    petIndicatorMPFill:SetPoint("LEFT", petIndicatorMPBar, "LEFT")
    petIndicatorMPFill:SetHeight(UI_CONFIG.MP_HEIGHT)
    petIndicatorMPFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    petIndicatorMPFill:SetVertexColor(0, 0, 1, 1)

    local hpBar2 = CreateFrame("Frame", nil, frame)
    frame.hpBar = hpBar2
    hpBar2:SetPoint("TOP", frame, "TOP", 0, -36)
    hpBar2:SetFrameLevel(2)
    hpBar2:SetWidth(UI_CONFIG.UNIT_WIDTH)
    hpBar2:SetHeight(UI_CONFIG.HP_HEIGHT)

    local hpBG2 = hpBar2:CreateTexture(nil, "BACKGROUND")
    hpBG2:SetAllPoints()
    hpBG2:SetTexture("Interface\\Buttons\\WHITE8x8")
    hpBG2:SetVertexColor(0.2, 0.2, 0.2, 0.8)

    local hpFill2 = hpBar2:CreateTexture(nil, "ARTWORK")
    hpFill2:SetPoint("LEFT", hpBar2, "LEFT")
    hpFill2:SetHeight(UI_CONFIG.HP_HEIGHT)
    hpFill2:SetTexture("Interface\\Buttons\\WHITE8x8")
    hpFill2:SetVertexColor(1, 0, 0, 1)

    AddBarSheen(hpBar2, UI_CONFIG.HP_HEIGHT)

    local hpText2 = hpBar2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hpText2:SetPoint("TOP", hpBar2, "TOP", 0, -18)
    hpText2:SetShadowOffset(1, -1)
    hpText2:SetShadowColor(0, 0, 0, 0.8)

    local hpValueText2 = hpBar2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpValueText2:SetPoint("TOP", hpText2, "BOTTOM", 0, -2)
    hpValueText2:SetShadowOffset(1, -1)
    hpValueText2:SetShadowColor(0, 0, 0, 0.8)

    local buffIcons2 = CreateBuffIcons(hpBar2)

    local roleBadge2, roleBadgeText2, roleBadgeIcon2, roleBadgeClickCatcher2, roleBadgeEmptyOutline2 = CreateRoleBadge(hpBar2)
    roleBadgeClickCatcher2:SetScript("OnMouseDown", function()
        CycleRole(UnitName(thisUnit))
    end)
    local debuffIcons2 = CreateDebuffIcons(hpBar2)

    local mpBar2 = CreateFrame("Frame", nil, frame)
    frame.mpBar = mpBar2
    mpBar2:SetPoint("TOP", hpBar2, "BOTTOM", 0, 0)
    mpBar2:SetFrameLevel(2)
    mpBar2:SetWidth(UI_CONFIG.UNIT_WIDTH)
    mpBar2:SetHeight(UI_CONFIG.MP_HEIGHT)

    local mpBG2 = mpBar2:CreateTexture(nil, "BACKGROUND")
    mpBG2:SetAllPoints()
    mpBG2:SetTexture("Interface\\Buttons\\WHITE8x8")
    mpBG2:SetVertexColor(0.2, 0.2, 0.2, 0.8)

    local mpFill2 = mpBar2:CreateTexture(nil, "ARTWORK")
    mpFill2:SetPoint("LEFT", mpBar2, "LEFT")
    mpFill2:SetHeight(UI_CONFIG.MP_HEIGHT)
    mpFill2:SetTexture("Interface\\Buttons\\WHITE8x8")
    mpFill2:SetVertexColor(0, 0, 1, 1)

    frame:SetScript("OnUpdate", function()
        if not InRaidMode() and not isMinimized and UnitExists(thisUnit) then
            cardBorder2:Show()
            cardBorder2.fillTexture:Show()
            hpBar2:Show()

            local _, ownerClass = UnitClass(thisUnit)
            local ownerCanHavePet = ownerClass == "HUNTER" or ownerClass == "WARLOCK"

            if ownerCanHavePet and UnitExists(partyPetUnit) then
                petOwnerFrame:Show()
                petIndicator:Show()
                petIndicator.fillTexture:Show()
                petIndicatorHPBar:Show()
                petIndicatorMPBar:Show()

                local petHP = UnitHealth(partyPetUnit) or 0
                local petHPMax = UnitHealthMax(partyPetUnit) or 1
                local petHPPercent = ClampPercent(petHPMax > 0 and (petHP / petHPMax) or 0)
                petIndicatorFill:SetWidth(UI_CONFIG.UNIT_WIDTH * petHPPercent * currentScale)
                if petHPPercent <= LOW_HEALTH_THRESHOLD then
                    petIndicatorFill:SetVertexColor(1, 0, 0)
                else
                    petIndicatorFill:SetVertexColor(0.1, 0.7, 0.5)
                end

                local ownerName = UnitName(thisUnit) or "Unknown"
                petIndicatorText:SetText(ownerName .. "'s Pet")
                petIndicatorValueText:SetText(math.floor(petHPPercent * 100) .. "%      " .. petHP .. "/" .. petHPMax)

                local petMP = UnitMana(partyPetUnit) or 0
                local petMPMax = UnitManaMax(partyPetUnit) or 1
                local petMPPercent = ClampPercent(petMPMax > 0 and (petMP / petMPMax) or 0)
                petIndicatorMPFill:SetWidth(UI_CONFIG.UNIT_WIDTH * petMPPercent * currentScale)
                petIndicatorMPFill:SetVertexColor(GetPowerColor(partyPetUnit))
            else
                petOwnerFrame:Hide()
                petIndicator:Hide()
                petIndicator.fillTexture:Hide()
                petIndicatorHPBar:Hide()
                petIndicatorMPBar:Hide()
            end

            local hp = UnitHealth(thisUnit) or 0
            local hpMax = UnitHealthMax(thisUnit) or 1
            local hpPercent = ClampPercent(hpMax > 0 and (hp / hpMax) or 0)
            hpFill2:SetWidth(UI_CONFIG.UNIT_WIDTH * hpPercent * currentScale)

            local name = UnitName(thisUnit) or "Unknown"

            if UnitIsConnected(thisUnit) then
                mpBar2:Show()
                if UnitIsDeadOrGhost(thisUnit) then
                    hpFill2:SetWidth(0)
                    hpFill2:SetVertexColor(0.5, 0.5, 0.5)
                    hpText2:SetText(name)
                    hpValueText2:SetText("Dead")
                    mpFill2:SetWidth(0)
                else
                    if hpPercent <= LOW_HEALTH_THRESHOLD then
                        hpFill2:SetVertexColor(1, 0, 0)
                    else
                        hpFill2:SetVertexColor(GetClassColor(thisUnit))
                    end
                    hpText2:SetText(name)
                    hpValueText2:SetText(math.floor(hpPercent * 100) .. "%      " .. hp .. "/" .. hpMax)

                    local mp = UnitMana(thisUnit) or 0
                    local mpMax = UnitManaMax(thisUnit) or 1
                    local mpPercent = ClampPercent(mpMax > 0 and (mp / mpMax) or 0)
                    mpFill2:SetWidth(UI_CONFIG.UNIT_WIDTH * mpPercent * currentScale)
                    mpFill2:SetVertexColor(GetPowerColor(thisUnit))
                end

                UpdateBuffIcons(buffIcons2, thisUnit)
                UpdateDebuffIcons(debuffIcons2, thisUnit)
            else
                mpBar2:Hide()
                hpFill2:SetVertexColor(0.5, 0.5, 0.5)
                hpText2:SetText(name)
                hpValueText2:SetText("Disconnected")

                for i = 1, BUFF_ICON_COUNT do
                    buffIcons2[i]:Hide()
                end
                for i = 1, DEBUFF_ICON_COUNT do
                    debuffIcons2[i]:Hide()
                end
            end

            UpdateRoleBadge(roleBadge2, roleBadgeText2, roleBadgeIcon2, roleBadgeEmptyOutline2, name)
        else
            cardBorder2:Hide()
            cardBorder2.fillTexture:Hide()
            hpBar2:Hide()
            mpBar2:Hide()
            petOwnerFrame:Hide()
            petIndicator:Hide()
            petIndicator.fillTexture:Hide()
            petIndicatorHPBar:Hide()
            petIndicatorMPBar:Hide()
        end
    end)
end

PositionPartyFrames()

---------------------------------------------------------
-- RAID FRAMES (raid1-40)
---------------------------------------------------------

local RAID_FRAME_WIDTH = UI_CONFIG.RAID_WIDTH
local RAID_FRAME_HEIGHT = UI_CONFIG.RAID_HEIGHT
local RAID_COLS = 8
local RAID_GAP = 2

local raidContainer = CreateFrame("Frame", "UAHealRaidContainer", UIParent)
raidContainer:SetFrameStrata("LOW")
raidContainer:SetWidth(RAID_COLS * (RAID_FRAME_WIDTH + RAID_GAP))
raidContainer:SetHeight(5 * (RAID_FRAME_HEIGHT + RAID_GAP))
raidContainer:SetPoint("TOP", dragHandle, "BOTTOM", 8, -10)

for i = 1, 40 do
    local raidUnit = "raid" .. i
    local col = (i - 1) % RAID_COLS
    local row = math.floor((i - 1) / RAID_COLS)

    local rFrame = CreateFrame("Frame", "UAHealRaid_"..i, raidContainer)
    rFrame:SetFrameStrata("LOW")
    rFrame:SetWidth(RAID_FRAME_WIDTH)
    rFrame:SetHeight(RAID_FRAME_HEIGHT)
    rFrame:SetPoint("TOPLEFT", raidContainer, "TOPLEFT",
        col * (RAID_FRAME_WIDTH + RAID_GAP),
        -row * (RAID_FRAME_HEIGHT + RAID_GAP))

    local rBorder = CreateFrame("Frame", nil, rFrame)
    rBorder:SetAllPoints()
    ApplyButtonBevel(rBorder)

    local rFill = rFrame:CreateTexture(nil, "ARTWORK")
    rFill:SetPoint("TOPLEFT", rFrame, "TOPLEFT", 1, -1)
    rFill:SetPoint("BOTTOMLEFT", rFrame, "BOTTOMLEFT", 1, 1)
    rFill:SetWidth(RAID_FRAME_WIDTH - 2)
    rFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    rFill:SetVertexColor(1, 0, 0, 1)

    local rText = rFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rText:SetPoint("CENTER", rFrame, "CENTER", 0, 0)
    rText:SetShadowOffset(1, -1)
    rText:SetShadowColor(0, 0, 0, 0.8)

    AttachTargetOnClick(rFrame, function()
        if InRaidMode() and not isMinimized then
            return raidUnit
        end
        return nil
    end)
    rFrame.unit = raidUnit

    rFrame:SetScript("OnUpdate", function()
        if InRaidMode() and not isMinimized and UnitExists(raidUnit) then
            rFrame:EnableMouse(true)
            rBorder:Show()
            rFill:Show()
            rText:Show()

            local hp = UnitHealth(raidUnit) or 0
            local hpMax = UnitHealthMax(raidUnit) or 1
            local hpPercent = ClampPercent(hpMax > 0 and (hp / hpMax) or 0)
            rFill:SetWidth((RAID_FRAME_WIDTH - 2) * hpPercent)

            local name = UnitName(raidUnit) or "Unknown"

            if UnitIsConnected(raidUnit) then
                if hpPercent <= LOW_HEALTH_THRESHOLD then
                    rFill:SetVertexColor(1, 0, 0)
                else
                    rFill:SetVertexColor(GetClassColor(raidUnit))
                end
                rText:SetText(name)
            else
                rFill:SetVertexColor(0.5, 0.5, 0.5)
                rText:SetText(name .. " (DC)")
            end
        else
            rFrame:EnableMouse(false)
            rBorder:Hide()
            rFill:Hide()
            rText:Hide()
        end
    end)
end

---------------------------------------------------------
-- PET FRAME (CENTER POSITIONED)
---------------------------------------------------------

local petDragHandle = CreateFrame("Frame", "UAHealPetDragHandle", UIParent)
petDragHandle:SetFrameStrata("LOW")
petDragHandle:SetWidth(UI_CONFIG.DRAG_WIDTH)
petDragHandle:SetHeight(UI_CONFIG.DRAG_HEIGHT)
petDragHandle:SetPoint("CENTER", UIParent, "CENTER", 150, 0)
petDragHandle:EnableMouse(true)
ApplyButtonBevel(petDragHandle)

local petTitle = petDragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
petTitle:SetPoint("CENTER", petDragHandle, "CENTER", 0, 0)
petTitle:SetText("Pet")

local petIsMinimized = false

local petMinimizeButton = CreateFrame("Frame", "UAHealPetMinimizeButton", UIParent)
petMinimizeButton:SetFrameStrata("LOW")
petMinimizeButton:SetWidth(UI_CONFIG.DRAG_HEIGHT)
petMinimizeButton:SetHeight(UI_CONFIG.DRAG_HEIGHT)
petMinimizeButton:SetPoint("LEFT", petDragHandle, "RIGHT", 0, 0)
petMinimizeButton:EnableMouse(true)
ApplyButtonBevel(petMinimizeButton)

local petMinimizeText = petMinimizeButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
petMinimizeText:SetPoint("CENTER", petMinimizeButton, "CENTER", 0, 0)
petMinimizeText:SetText("-")

petMinimizeButton:SetScript("OnMouseDown", function()
    petIsMinimized = not petIsMinimized
    if petIsMinimized then
        petMinimizeText:SetText("+")
    else
        petMinimizeText:SetText("-")
    end
end)

local petDragCatcher = CreateFrame("Frame", "UAHealPetDragCatcher", UIParent)
petDragCatcher:SetAllPoints(UIParent)
petDragCatcher:SetFrameStrata("TOOLTIP")
petDragCatcher:EnableMouse(true)
petDragCatcher:Hide()

local petDragging = false

local function StopPetDrag()
    petDragging = false
    petDragCatcher:Hide()
end

petDragHandle:SetScript("OnMouseDown", function()
    petDragging = true
    petDragCatcher:Show()
end)

petDragHandle:SetScript("OnMouseUp", StopPetDrag)
petDragCatcher:SetScript("OnMouseUp", StopPetDrag)

petDragHandle:SetScript("OnUpdate", function()
    if petDragging then
        local x, y = GetCursorPosition()
        petDragHandle:ClearAllPoints()
        petDragHandle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end)

local petFrame = CreateFrame("Frame", "UAHealPetFrame", UIParent)
petFrame:SetFrameStrata("LOW")
petFrame:SetWidth(200)
petFrame:SetHeight(120)
petFrame:SetPoint("TOP", petDragHandle, "BOTTOM", 8, 35)
petFrame:EnableMouse(false)

local petCardBorder = CreateCardBorder(petFrame, -35, TOTAL_BORDER_HEIGHT)

AttachTargetOnClick(petCardBorder, function() return "pet" end)
petCardBorder.unit = "pet"

local petHPBar = CreateFrame("Frame", "UAHealPetHPBar", petFrame)
petHPBar:SetPoint("TOP", petFrame, "TOP", 0, -36)
petHPBar:SetFrameLevel(2)
petHPBar:SetWidth(UI_CONFIG.UNIT_WIDTH)
petHPBar:SetHeight(UI_CONFIG.HP_HEIGHT)
petHPBar:EnableMouse(false)

local petHPBG = petHPBar:CreateTexture(nil, "BACKGROUND")
petHPBG:SetAllPoints()
petHPBG:SetTexture("Interface\\Buttons\\WHITE8x8")
petHPBG:SetVertexColor(0.2, 0.2, 0.2, 0.8)

local petHPFill = petHPBar:CreateTexture(nil, "ARTWORK")
petHPFill:SetPoint("LEFT", petHPBar, "LEFT")
petHPFill:SetHeight(UI_CONFIG.HP_HEIGHT)
petHPFill:SetTexture("Interface\\Buttons\\WHITE8x8")
petHPFill:SetVertexColor(0.1, 0.7, 0.5, 1)

AddBarSheen(petHPBar, UI_CONFIG.HP_HEIGHT)

local petHPText = petHPBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
petHPText:SetPoint("TOP", petHPBar, "TOP", 0, -18)
petHPText:SetShadowOffset(1, -1)
petHPText:SetShadowColor(0, 0, 0, 0.8)

local petHPValueText = petHPBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
petHPValueText:SetPoint("TOP", petHPText, "BOTTOM", 0, -2)
petHPValueText:SetShadowOffset(1, -1)
petHPValueText:SetShadowColor(0, 0, 0, 0.8)

local petBuffIcons = CreateBuffIcons(petHPBar)

local petMPBar = CreateFrame("Frame", "UAHealPetMPBar", petFrame)
petMPBar:SetPoint("TOP", petHPBar, "BOTTOM", 0, 0)
petMPBar:SetFrameLevel(2)
petMPBar:SetWidth(UI_CONFIG.UNIT_WIDTH)
petMPBar:SetHeight(UI_CONFIG.MP_HEIGHT)
petMPBar:EnableMouse(false)

local petMPBG = petMPBar:CreateTexture(nil, "BACKGROUND")
petMPBG:SetAllPoints()
petMPBG:SetTexture("Interface\\Buttons\\WHITE8x8")
petMPBG:SetVertexColor(0.2, 0.2, 0.2, 0.8)

local petMPFill = petMPBar:CreateTexture(nil, "ARTWORK")
petMPFill:SetPoint("LEFT", petMPBar, "LEFT")
petMPFill:SetHeight(UI_CONFIG.MP_HEIGHT)
petMPFill:SetTexture("Interface\\Buttons\\WHITE8x8")
petMPFill:SetVertexColor(0, 0, 1, 1)

petFrame:SetScript("OnUpdate", function()
    local _, playerClass = UnitClass("player")
    local canHavePet = playerClass == "HUNTER" or playerClass == "WARLOCK"

    if canHavePet and UnitExists("pet") then
        petDragHandle:Show()
        petMinimizeButton:Show()
    else
        petDragHandle:Hide()
        petMinimizeButton:Hide()
    end

    if not canHavePet or petIsMinimized or not UnitExists("pet") then
        petCardBorder:Hide()
        petCardBorder.fillTexture:Hide()
        petHPBar:Hide()
        petMPBar:Hide()
        return
    end
    petCardBorder:Show()
    petCardBorder.fillTexture:Show()
    petHPBar:Show()
    petMPBar:Show()

    local unit = "pet"

    local hp = UnitHealth(unit) or 0
    local hpMax = UnitHealthMax(unit) or 1
    local hpPercent = ClampPercent(hpMax > 0 and (hp / hpMax) or 0)
    petHPFill:SetWidth(UI_CONFIG.UNIT_WIDTH * hpPercent * currentScale)
    if hpPercent <= LOW_HEALTH_THRESHOLD then
        petHPFill:SetVertexColor(1, 0, 0)
    else
        petHPFill:SetVertexColor(0.1, 0.7, 0.5)
    end

    local name = UnitName(unit) or "Pet"
    petHPText:SetText(name)
    petHPValueText:SetText(math.floor(hpPercent * 100) .. "%      " .. hp .. "/" .. hpMax)

    local mp = UnitMana(unit) or 0
    local mpMax = UnitManaMax(unit) or 1
    local mpPercent = ClampPercent(mpMax > 0 and (mp / mpMax) or 0)
    petMPFill:SetWidth(UI_CONFIG.UNIT_WIDTH * mpPercent * currentScale)
    petMPFill:SetVertexColor(GetPowerColor(unit))

    UpdateBuffIcons(petBuffIcons, unit)
end)
