---------------------------------------------------------
-- SAVED VARIABLES
---------------------------------------------------------
UAHealDB = UAHealDB or {}

---------------------------------------------------------
-- DRAG HANDLE
---------------------------------------------------------

local dragHandle = CreateFrame("Frame", "UAHealDragHandle", UIParent)
dragHandle:SetFrameStrata("LOW")
dragHandle:SetWidth(100)
dragHandle:SetHeight(16)
dragHandle:SetPoint("TOP", UIParent, "TOP", 0, -200)
dragHandle:EnableMouse(true)

local ToggleActionBarNumbers
local ApplyScale
local PositionPartyFrames
local actionBarNumbersShown

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

-- Small button that hides all the health/mana frames (player, party,
-- raid) while keeping just the drag bar itself visible -- useful for
-- clearing the UI out of the way temporarily, e.g. while digging through
-- bags. The drag bar stays visible/clickable so you can un-minimize.
local isMinimized = false

local minimizeButton = CreateFrame("Frame", "UAHealMinimizeButton", UIParent)
minimizeButton:SetFrameStrata("LOW")
minimizeButton:SetWidth(16)
minimizeButton:SetHeight(16)
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
local lastDragX, lastDragY = nil, nil

local function StopDrag()
    dragging = false
    dragCatcher:Hide()

    if lastDragX and lastDragY then
        UAHealDB.position = { x = lastDragX, y = lastDragY }
    end
end

---------------------------------------------------------
-- MACRO WINDOW
---------------------------------------------------------

local macroWindow = CreateFrame("Frame", "UAHealMacroWindow", UIParent)
macroWindow:SetWidth(230)
macroWindow:SetHeight(461)
-- FIX: repositioning alone didn't solve the raid-grid overlap -- the
-- raid frames (created later in the file) were rendering ON TOP of the
-- settings window's own text/content, a frame strata/layering issue,
-- not a position issue. Explicit "TOOLTIP" strata (the highest
-- priority, same one already proven reliable for the hover tooltip and
-- drag catcher elsewhere in this addon) guarantees this always renders
-- on top, regardless of creation order.
macroWindow:SetFrameStrata("TOOLTIP")
-- Anchored to the center of the screen rather than near the drag bar --
-- the raid grid (8 columns wide) is much wider than the party frames it
-- replaces, and the settings window used to open right into that space
-- whenever raid frames were showing. A fixed, predictable screen
-- position avoids that regardless of where the drag bar has been moved
-- to or which mode (party/raid) is currently active.
macroWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
macroWindow:EnableMouse(true)
macroWindow:Hide()

local macroBorder = macroWindow:CreateTexture(nil, "BACKGROUND")
macroBorder:SetAllPoints()
macroBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
macroBorder:SetVertexColor(0.03, 0.03, 0.03, 0.95)

local macroFill = macroWindow:CreateTexture(nil, "BACKGROUND")
macroFill:SetPoint("TOPLEFT", macroWindow, "TOPLEFT", 1, -1)
macroFill:SetPoint("BOTTOMRIGHT", macroWindow, "BOTTOMRIGHT", -1, 1)
macroFill:SetTexture("Interface\\Buttons\\WHITE8x8")
macroFill:SetVertexColor(0.10, 0.10, 0.10, 0.97)

local macroTitle = macroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
macroTitle:SetPoint("TOP", macroWindow, "TOP", 0, -10)
macroTitle:SetText("Settings")

---------------------------------------------------------
-- TABS
---------------------------------------------------------
-- Three tabs: "Macros" (the click-heal setup, shown by default),
-- "Frame Scale" (resizing the whole addon), and "About" (always last --
-- credits/version). Everything belonging to a tab is tracked in that
-- tab's table, so switching tabs is just showing one group and hiding
-- the others.

local macrosTabElements = {}
local scaleTabElements = {}

local macrosTabButton = CreateFrame("Frame", nil, macroWindow)
macrosTabButton:SetWidth(70)
macrosTabButton:SetHeight(20)
macrosTabButton:SetPoint("TOP", macroTitle, "BOTTOM", -37, -8)
macrosTabButton:EnableMouse(true)
ApplyButtonBevel(macrosTabButton)

local macrosTabText = macrosTabButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
macrosTabText:SetPoint("CENTER", macrosTabButton, "CENTER", 0, 0)
macrosTabText:SetText("Macros")

local scaleTabButton = CreateFrame("Frame", nil, macroWindow)
scaleTabButton:SetWidth(70)
scaleTabButton:SetHeight(20)
scaleTabButton:SetPoint("LEFT", macrosTabButton, "RIGHT", 4, 0)
scaleTabButton:EnableMouse(true)
ApplyButtonBevel(scaleTabButton)

local scaleTabText = scaleTabButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
scaleTabText:SetPoint("CENTER", scaleTabButton, "CENTER", 0, 0)
scaleTabText:SetText("Frames")

local function ShowTab(tab)
    for _, el in ipairs(macrosTabElements) do
        if tab == "macros" then el:Show() else el:Hide() end
    end
    for _, el in ipairs(scaleTabElements) do
        if tab == "scale" then el:Show() else el:Hide() end
    end
end

macrosTabButton:SetScript("OnMouseDown", function() ShowTab("macros") end)
scaleTabButton:SetScript("OnMouseDown", function() ShowTab("scale") end)

-- Only relevant to the Macros tab, so it's grouped with everything else
-- there rather than showing on every tab regardless.
local macroHint = macroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
macroHint:SetPoint("TOP", macroTitle, "BOTTOM", 0, -38)
macroHint:SetWidth(190)
macroHint:SetJustifyH("CENTER")
macroHint:SetText("Not sure what Action Bar ID to use? Click the button below to reveal it on your action bar, then put that number in the ID box below.")
table.insert(macrosTabElements, macroHint)

---------------------------------------------------------
-- SCALE TAB
---------------------------------------------------------
-- Quick -/+ buttons with a live percentage between them, adjusting in
-- fixed 10% steps -- simpler and more reliable than a Slider widget
-- (untested on this client, and the extra complexity wasn't buying us
-- much over two plain buttons).

local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.8, 2.0, 0.1
local currentScale = 1.0

-- Value text anchored to macroWindow's own true center (via the tab
-- buttons, which are always visible regardless of which tab is
-- selected, unlike macroHint), with the two buttons placed symmetrically
-- to its left and right -- this guarantees genuine centering regardless
-- of how wide the percentage text happens to render, unlike the
-- previous chain-of-relative-anchors approach.
local scaleValueText = macroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
scaleValueText:SetPoint("TOP", macroTitle, "BOTTOM", 0, -68)
scaleValueText:SetText("100%")

local scaleMinusButton = CreateFrame("Frame", nil, macroWindow)
scaleMinusButton:SetWidth(28)
scaleMinusButton:SetHeight(24)
scaleMinusButton:SetPoint("RIGHT", scaleValueText, "LEFT", -20, 0)
scaleMinusButton:EnableMouse(true)
ApplyButtonBevel(scaleMinusButton)

local scaleMinusText = scaleMinusButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
scaleMinusText:SetPoint("CENTER", scaleMinusButton, "CENTER", 0, 0)
scaleMinusText:SetText("-")

local scalePlusButton = CreateFrame("Frame", nil, macroWindow)
scalePlusButton:SetWidth(28)
scalePlusButton:SetHeight(24)
scalePlusButton:SetPoint("LEFT", scaleValueText, "RIGHT", 20, 0)
scalePlusButton:EnableMouse(true)
ApplyButtonBevel(scalePlusButton)

local scalePlusText = scalePlusButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
scalePlusText:SetPoint("CENTER", scalePlusButton, "CENTER", 0, 0)
scalePlusText:SetText("+")

local function SetScaleValue(value)
    if value < SCALE_MIN then value = SCALE_MIN end
    if value > SCALE_MAX then value = SCALE_MAX end
    value = math.floor(value * 10 + 0.5) / 10
    currentScale = value
    scaleValueText:SetText(math.floor(value * 100) .. "%")
    ApplyScale(value)
    UAHealDB.scale = value
end

scaleMinusButton:SetScript("OnMouseDown", function()
    SetScaleValue(currentScale - SCALE_STEP)
end)

scalePlusButton:SetScript("OnMouseDown", function()
    SetScaleValue(currentScale + SCALE_STEP)
end)

table.insert(scaleTabElements, scaleMinusButton)
table.insert(scaleTabElements, scaleMinusText)
table.insert(scaleTabElements, scaleValueText)
table.insert(scaleTabElements, scalePlusButton)
table.insert(scaleTabElements, scalePlusText)

-- Growth direction: party frames stack downward (default, matching
-- real vanilla raid-frame convention) or sideways. Repositions live via
-- PositionPartyFrames (defined later, once the party frames actually
-- exist -- forward-declared at the top of the file for that reason).
local layoutButton = CreateFrame("Frame", nil, macroWindow)
layoutButton:SetWidth(160)
layoutButton:SetHeight(20)
layoutButton:SetPoint("TOP", scaleValueText, "BOTTOM", 0, -30)
layoutButton:EnableMouse(true)
ApplyButtonBevel(layoutButton)

local layoutButtonText = layoutButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
layoutButtonText:SetPoint("CENTER", layoutButton, "CENTER", 0, 0)
layoutButtonText:SetText("Layout: Vertical")

layoutButton:SetScript("OnMouseDown", function()
    layoutHorizontal = not layoutHorizontal
    if layoutHorizontal then
        layoutButtonText:SetText("Layout: Horizontal")
    else
        layoutButtonText:SetText("Layout: Vertical")
    end
    PositionPartyFrames()
    UAHealDB.layoutHorizontal = layoutHorizontal
end)

table.insert(scaleTabElements, layoutButton)

local showNumbersButton = CreateFrame("Frame", nil, macroWindow)
showNumbersButton:SetWidth(190)
showNumbersButton:SetHeight(20)
showNumbersButton:SetPoint("TOP", macroTitle, "BOTTOM", 0, -70)
showNumbersButton:EnableMouse(true)
ApplyButtonBevel(showNumbersButton)

local showNumbersText = showNumbersButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
showNumbersText:SetPoint("CENTER", showNumbersButton, "CENTER", 0, 0)
showNumbersText:SetText("Show Action Bar ID Numbers")

showNumbersButton:SetScript("OnMouseDown", function()
    ToggleActionBarNumbers()
    if actionBarNumbersShown then
        showNumbersText:SetText("Hide Action Bar ID Numbers")
    else
        showNumbersText:SetText("Show Action Bar ID Numbers")
    end
end)

local macroSectionHeader = macroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
macroSectionHeader:SetPoint("TOPLEFT", macroWindow, "TOPLEFT", 14, -135)
macroSectionHeader:SetFont("Fonts\\FRIZQT__.TTF", 13, "THICKOUTLINE")
macroSectionHeader:SetText("Macro")

local slotColHeader = macroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
slotColHeader:SetPoint("TOP", macroWindow, "TOPLEFT", 162, -135)
slotColHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "THICKOUTLINE")
slotColHeader:SetText("Action Bar ID")

local spellColHeader = macroWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
spellColHeader:SetPoint("TOP", macroWindow, "TOPLEFT", 210, -135)
spellColHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "THICKOUTLINE")
spellColHeader:SetText("Spell")

for _, el in ipairs({ macroSectionHeader, slotColHeader, spellColHeader }) do
    table.insert(macrosTabElements, el)
end

local function CreateMacroRow(parent, labelText, yOffset)
    -- Wraps everything in one container frame per row, so the whole row
    -- can be shown/hidden as a single unit (needed for tab-switching)
    -- instead of tracking 5 separate pieces individually.
    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(230)
    container:SetHeight(20)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)

    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", container, "TOPLEFT", 14, 0)
    label:SetText(labelText)

    local editBG = container:CreateTexture(nil, "BACKGROUND")
    editBG:SetWidth(36)
    editBG:SetHeight(16)
    editBG:SetPoint("TOPRIGHT", container, "TOPRIGHT", -50, 0)
    editBG:SetTexture("Interface\\Buttons\\WHITE8x8")
    editBG:SetVertexColor(0, 0, 0, 0.6)

    local edit = CreateFrame("EditBox", nil, container)
    edit:SetWidth(32)
    edit:SetHeight(14)
    edit:SetPoint("CENTER", editBG, "CENTER", 0, 0)
    edit:SetNumeric(true)
    edit:SetMaxLetters(3)
    edit:SetPassword(false)
    edit:EnableMouse(true)
    edit:EnableKeyboard(true)
    edit:SetFontObject(GameFontNormal)
    edit:SetFont("Fonts\\FRIZQT__.TTF", 12, 0)
    edit:SetScript("OnMouseDown", function() edit:SetFocus() end)
    edit:SetScript("OnEnterPressed", function() edit:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function() edit:ClearFocus() end)

    local valueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueLabel:SetPoint("LEFT", editBG, "RIGHT", 6, 0)

    local slotIcon = container:CreateTexture(nil, "OVERLAY")
    slotIcon:SetWidth(16)
    slotIcon:SetHeight(16)
    slotIcon:SetPoint("LEFT", valueLabel, "RIGHT", 6, 0)

    return edit, valueLabel, slotIcon, container
end

local macroEdits = {}
local macroValueLabels = {}
local macroSlotIcons = {}
local macroRowContainers = {}

local function AddRow(key, labelText, yOffset)
    local edit, valueLabel, slotIcon, container = CreateMacroRow(macroWindow, labelText, yOffset)
    macroEdits[key] = edit
    macroValueLabels[key] = valueLabel
    macroSlotIcons[key] = slotIcon
    table.insert(macroRowContainers, container)
    table.insert(macrosTabElements, container)
end

AddRow("plain",     "Click:",                 -171)
AddRow("shift",     "Shift+Click:",           -197)
AddRow("ctrl",      "Ctrl+Click:",            -223)
AddRow("alt",       "Alt+Click:",             -249)
AddRow("shiftCtrl", "Shift+Ctrl+Click:",      -275)
AddRow("shiftAlt",  "Shift+Alt+Click:",       -301)
AddRow("ctrlAlt",   "Ctrl+Alt+Click:",        -327)
AddRow("allMods",   "Shift+Ctrl+Alt+Click:",  -353)

local resetButton = CreateFrame("Frame", nil, macroWindow)
resetButton:SetWidth(80)
resetButton:SetHeight(20)
resetButton:SetPoint("BOTTOM", macroWindow, "BOTTOM", 0, 30)
resetButton:EnableMouse(true)
ApplyButtonBevel(resetButton)

local resetText = resetButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
resetText:SetPoint("CENTER", resetButton, "CENTER", 0, 0)
resetText:SetText("Reset")

resetButton:SetScript("OnMouseDown", function()
    for _, edit in pairs(macroEdits) do
        edit:SetNumber(0)
    end
end)

local saveButton = CreateFrame("Frame", nil, macroWindow)
saveButton:SetWidth(120)
saveButton:SetHeight(20)
saveButton:SetPoint("BOTTOM", resetButton, "TOP", 0, 8)
saveButton:EnableMouse(true)
ApplyButtonBevel(saveButton)

local saveText = saveButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
saveText:SetPoint("CENTER", saveButton, "CENTER", 0, 0)
saveText:SetText("Save Preferences")

for _, el in ipairs({ showNumbersButton, resetButton, saveButton }) do
    table.insert(macrosTabElements, el)
end

ShowTab("macros")

local savedFlashUntil = 0

saveButton:SetScript("OnMouseDown", function()
    for key, edit in pairs(macroEdits) do
        UAHealDB[key] = edit:GetNumber()
    end
    savedFlashUntil = GetTime() + 1.5
end)

local savedConfirmText = saveButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
savedConfirmText:SetPoint("TOP", saveButton, "BOTTOM", 0, -2)
savedConfirmText:SetTextColor(0.2, 1, 0.2)

local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("ADDON_LOADED")
loadFrame:SetScript("OnEvent", function()
    for key, edit in pairs(macroEdits) do
        if UAHealDB[key] and UAHealDB[key] > 0 then
            edit:SetNumber(UAHealDB[key])
        end
    end

    -- Restores wherever the drag bar was last left, so the whole addon
    -- doesn't reset to its default spot every reload/relog. Uses the
    -- exact same "CENTER"/"BOTTOMLEFT" anchor style already proven to
    -- work throughout dragging itself, rather than GetPoint() (untested
    -- anywhere else in this addon, and a likely culprit if this wasn't
    -- restoring correctly before).
    -- Only restores a saved position if it's a real, sane on-screen
    -- coordinate -- both a real number AND non-negative (a genuine live
    -- cursor position, measured from the bottom-left of the screen, can
    -- never be negative). This specifically guards against leftover bad
    -- data from the old GetPoint()-based version, which stored numbers
    -- in an incompatible format and could send the whole addon off the
    -- bottom of the screen.
    local pos = UAHealDB.position
    if pos and type(pos.x) == "number" and type(pos.y) == "number" and pos.x >= 0 and pos.y >= 0 then
        dragHandle:ClearAllPoints()
        dragHandle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x, pos.y)
    end

    -- Restores the saved scale. Sets the slider's value AND explicitly
    -- updates the label/applies the scale directly, rather than relying
    -- on SetValue() alone to trigger OnValueChanged -- untested whether
    -- that cascades automatically on this client, so this covers it
    -- either way.
    -- Restores the saved scale using the -/+ control's own setter, which
    -- handles clamping, the label, and applying the scale all in one.
    if UAHealDB.scale then
        SetScaleValue(UAHealDB.scale)
    end

    -- Restores the saved layout direction and applies it once the party
    -- frames actually exist (ADDON_LOADED fires after the whole file has
    -- finished executing, so PositionPartyFrames is guaranteed to be
    -- properly assigned by this point).
    if UAHealDB.layoutHorizontal then
        layoutHorizontal = true
        layoutButtonText:SetText("Layout: Horizontal")
        PositionPartyFrames()
    end
end)

macroWindow:SetScript("OnUpdate", function()
    if GetTime() < savedFlashUntil then
        savedConfirmText:SetText("Saved!")
    else
        savedConfirmText:SetText("")
    end

    for key, edit in pairs(macroEdits) do
        local slot = edit:GetNumber()
        macroValueLabels[key]:SetText(slot)

        local icon = macroSlotIcons[key]
        if slot and slot > 0 then
            local texture = GetActionTexture(slot)
            if texture then
                icon:SetTexture(texture)
                icon:Show()
            else
                icon:Hide()
            end
        else
            icon:Hide()
        end
    end
end)



local ACTION_DELAY = 0.05
local pendingActionSlot = nil
local pendingActionUnit = nil
local pendingActionTime = 0
local pendingPreviousTarget = nil

local function FireMacroSlot(unit, key)
    if not unit then return end
    local edit = macroEdits[key]
    if not edit then return end
    local slot = edit:GetNumber()
    if not slot or slot == 0 then return end

    -- Remembers whether you had a target before switching to the person
    -- being healed, so it can be restored right after the heal fires --
    -- your actual target shouldn't visibly change from your perspective.
    -- FIX: originally tried restoring by name via TargetUnit(name), but
    -- confirmed via testing that TargetUnit doesn't work with a plain
    -- name string on this client (only real unit IDs like "party1").
    -- TargetLastTarget() -- a real vanilla function that just says "go
    -- back to whatever I was targeting before this" -- works correctly
    -- instead, confirmed via testing.
    pendingPreviousTarget = UnitExists("target") and UnitName("target") or nil

    TargetUnit(unit)
    pendingActionSlot = slot
    pendingActionUnit = unit
    pendingActionTime = GetTime() + ACTION_DELAY
end

local actionTicker = CreateFrame("Frame")
actionTicker:SetScript("OnUpdate", function()
    if pendingActionSlot and GetTime() >= pendingActionTime then
        if UnitIsUnit("target", pendingActionUnit) then
            UseAction(pendingActionSlot)
        end

        if pendingPreviousTarget then
            TargetLastTarget()
        end

        pendingActionSlot = nil
        pendingActionUnit = nil
        pendingPreviousTarget = nil
    end
end)

local function AttachClickCast(frame, getUnit)
    frame:EnableMouse(true)

    frame:SetScript("OnMouseDown", function()
        local shift = IsShiftKeyDown()
        local ctrl = IsControlKeyDown()
        local alt = IsAltKeyDown()

        local key
        if shift and ctrl and alt then key = "allMods"
        elseif shift and ctrl then key = "shiftCtrl"
        elseif shift and alt then key = "shiftAlt"
        elseif ctrl and alt then key = "ctrlAlt"
        elseif shift then key = "shift"
        elseif ctrl then key = "ctrl"
        elseif alt then key = "alt"
        else key = "plain" end

        FireMacroSlot(getUnit(), key)
    end)
end

---------------------------------------------------------
-- HOVER TOOLTIP
---------------------------------------------------------

local HOVER_TOOLTIP_DELAY = 0.6

local GESTURE_LABELS = {
    { key = "plain",     label = "Click" },
    { key = "shift",     label = "Shift+Click" },
    { key = "ctrl",      label = "Ctrl+Click" },
    { key = "alt",       label = "Alt+Click" },
    { key = "shiftCtrl", label = "Shift+Ctrl+Click" },
    { key = "shiftAlt",  label = "Shift+Alt+Click" },
    { key = "ctrlAlt",   label = "Ctrl+Alt+Click" },
    { key = "allMods",   label = "Shift+Ctrl+Alt+Click" },
}

local hoverTooltip = CreateFrame("Frame", "UAHealHoverTooltip", UIParent)
hoverTooltip:SetWidth(120)
hoverTooltip:SetFrameStrata("TOOLTIP")
hoverTooltip:Hide()

local hoverTooltipFill = hoverTooltip:CreateTexture(nil, "BACKGROUND")
hoverTooltipFill:SetAllPoints()
hoverTooltipFill:SetTexture("Interface\\Buttons\\WHITE8x8")
hoverTooltipFill:SetVertexColor(0.05, 0.05, 0.05, 0.35)

local hoverTooltipRows = {}
local hoverTooltipDividers = {}
local ROW_HEIGHT = 18
local MAX_ROWS = #GESTURE_LABELS

for i, gesture in ipairs(GESTURE_LABELS) do
    local rowIcon = hoverTooltip:CreateTexture(nil, "OVERLAY")
    rowIcon:SetWidth(14)
    rowIcon:SetHeight(14)
    rowIcon:SetPoint("TOPLEFT", hoverTooltip, "TOPLEFT", 8, -8 - (i - 1) * ROW_HEIGHT)

    local rowText = hoverTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rowText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
    rowText:SetShadowOffset(1, -1)
    rowText:SetShadowColor(0, 0, 0, 0.9)

    hoverTooltipRows[gesture.key] = { icon = rowIcon, text = rowText }
end

for i = 1, MAX_ROWS + 1 do
    local divider = hoverTooltip:CreateTexture(nil, "BORDER")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", hoverTooltip, "TOPLEFT", 4, -6 - (i - 1) * ROW_HEIGHT)
    divider:SetPoint("TOPRIGHT", hoverTooltip, "TOPRIGHT", -4, -6 - (i - 1) * ROW_HEIGHT)
    divider:SetTexture("Interface\\Buttons\\WHITE8x8")
    divider:SetVertexColor(1, 1, 1, 0.25)
    hoverTooltipDividers[i] = divider
end

local hoverFrame, hoverStartTime = nil, 0

local function ShowHoverTooltip(atFrame)
    local rowsShown = 0
    for _, gesture in ipairs(GESTURE_LABELS) do
        local edit = macroEdits[gesture.key]
        local row = hoverTooltipRows[gesture.key]
        local slot = edit and edit:GetNumber()

        if slot and slot > 0 then
            rowsShown = rowsShown + 1
            row.icon:SetPoint("TOPLEFT", hoverTooltip, "TOPLEFT", 8, -8 - (rowsShown - 1) * ROW_HEIGHT)
            row.text:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)

            local texture = GetActionTexture(slot)
            if texture then
                row.icon:SetTexture(texture)
                row.icon:Show()
            else
                row.icon:Hide()
            end
            row.text:SetText(gesture.label)
            row.text:Show()
        else
            row.icon:Hide()
            row.text:Hide()
        end
    end

    if rowsShown == 0 then
        hoverTooltip:Hide()
        return
    end

    for i = 1, MAX_ROWS + 1 do
        if i <= rowsShown + 1 then
            hoverTooltipDividers[i]:Show()
        else
            hoverTooltipDividers[i]:Hide()
        end
    end

    hoverTooltip:SetHeight(16 + rowsShown * ROW_HEIGHT)
    hoverTooltip:ClearAllPoints()

    local screenHalf = UIParent:GetWidth() / 2
    local cursorX = GetCursorPosition()
    if cursorX < screenHalf then
        hoverTooltip:SetPoint("TOPLEFT", atFrame, "TOPRIGHT", 4, 0)
    else
        hoverTooltip:SetPoint("TOPRIGHT", atFrame, "TOPLEFT", -4, 0)
    end

    hoverTooltip:Show()
end

local hoverTicker = CreateFrame("Frame")
hoverTicker:SetScript("OnUpdate", function()
    if hoverFrame and (GetTime() - hoverStartTime) >= HOVER_TOOLTIP_DELAY and not hoverTooltip:IsShown() then
        ShowHoverTooltip(hoverFrame)
    end
end)

local function AttachHoverTooltip(frame)
    frame:SetScript("OnEnter", function()
        hoverFrame = frame
        hoverStartTime = GetTime()
    end)

    frame:SetScript("OnLeave", function()
        if hoverFrame == frame then
            hoverFrame = nil
            hoverTooltip:Hide()
        end
    end)
end

local lastClickTime = 0
local DOUBLE_CLICK_WINDOW = 1.0

dragHandle:SetScript("OnMouseDown", function()
    local now = GetTime()

    if now - lastClickTime < DOUBLE_CLICK_WINDOW then
        if macroWindow:IsShown() then
            macroWindow:Hide()
        else
            macroWindow:Show()
        end
        lastClickTime = 0
        return
    end

    lastClickTime = now
    dragging = true
    dragCatcher:Show()
end)

dragHandle:SetScript("OnMouseUp", StopDrag)
dragCatcher:SetScript("OnMouseUp", StopDrag)

dragHandle:SetScript("OnUpdate", function()
    if dragging then
        local x, y = GetCursorPosition()
        lastDragX, lastDragY = x, y
        dragHandle:ClearAllPoints()
        dragHandle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end)

---------------------------------------------------------
-- LOW HEALTH THRESHOLD
---------------------------------------------------------

local LOW_HEALTH_THRESHOLD = 0.30

-- Keeps a health/mana percentage within a sane 0-1 range no matter what
-- the underlying API returns. A disconnected or otherwise stale unit can
-- occasionally return garbage values (e.g. a huge leftover mana number),
-- which without this clamp caused a bar to render at an enormous width
-- instead of failing safely.
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
-- CLASS COLORS
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

---------------------------------------------------------
-- CLASS ICONS
---------------------------------------------------------

local CLASS_ICON_TEXTURE = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

local CLASS_ICON_TCOORDS = {
    WARRIOR = { 0,          0.25,       0,    0.25 },
    MAGE    = { 0.25,       0.49609375, 0,    0.25 },
    ROGUE   = { 0.49609375, 0.7421875,  0,    0.25 },
    DRUID   = { 0.7421875,  0.98828125, 0,    0.25 },
    HUNTER  = { 0,          0.25,       0.25, 0.5  },
    SHAMAN  = { 0.25,       0.49609375, 0.25, 0.5  },
    PRIEST  = { 0.49609375, 0.7421875,  0.25, 0.5  },
    WARLOCK = { 0.7421875,  0.98828125, 0.25, 0.5  },
    PALADIN = { 0,          0.25,       0.5,  0.75 },
}

local function CreateClassIcon(parentBar, anchorTo)
    local icon = parentBar:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(14)
    icon:SetHeight(14)
    icon:SetPoint("RIGHT", anchorTo, "LEFT", -2, 0)
    return icon
end

local function UpdateClassIcon(icon, unit)
    local _, classToken = UnitClass(unit)
    local coords = classToken and CLASS_ICON_TCOORDS[classToken]
    if coords then
        icon:SetTexture(CLASS_ICON_TEXTURE)
        icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        icon:Show()
    else
        icon:Hide()
    end
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
-- BUFF ICONS
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
            icon:SetPoint("TOPLEFT", parentBar, "TOPLEFT", 2, -2)
        else
            icon:SetPoint("LEFT", icons[i - 1], "RIGHT", 1, 0)
        end
        icon:Hide()
        icons[i] = icon
    end
    return icons
end

local function UpdateBuffIcons(icons, unit)
    for i = 1, BUFF_ICON_COUNT do
        local texture = UnitBuff(unit, i)
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
-- DEBUFF ICONS
---------------------------------------------------------
-- Same pattern as buffs above, using UnitDebuff instead of UnitBuff --
-- anchored to the top-right corner so they don't overlap the buff icons
-- in the top-left.

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
    -- REDESIGNED: the "peek through a 2px gap" approach (grey fill inset
    -- inside a black outer texture) proved unreliable across multiple
    -- rounds of testing -- the border kept disappearing or only
    -- partially showing. Switched to the same proven technique already
    -- used successfully elsewhere in this addon (ApplyButtonBevel's edge
    -- strips, hoverTooltip's guaranteed-top-strata): 4 explicit black
    -- edge textures, on a frame level high enough to guarantee they
    -- render ON TOP of the health/mana bars, rather than relying on a
    -- gap for the border to show through.
    local BORDER_THICKNESS = 2

    local border = CreateFrame("Frame", nil, parent)
    border:SetPoint("TOP", parent, "TOP", 0, topOffset + 1)
    border:SetWidth(122)
    border:SetHeight(blockHeight + 2)
    border:SetFrameLevel(10)

    -- FIX: making fill a child of "border" (to fix its visibility not
    -- toggling correctly) meant it also inherited border's very high
    -- frame level (needed to keep the black edges on top) -- which then
    -- rendered the grey fill ABOVE the health/mana bars too, completely
    -- covering them. Back to being a child of "parent" (rendering behind
    -- everything, at normal depth), but with an explicit reference
    -- stored on border so its visibility can still be toggled alongside
    -- the border wherever that happens.
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
    sheen:SetHeight(barHeight * 0.4)
    sheen:SetTexture("Interface\\Buttons\\WHITE8x8")
    sheen:SetVertexColor(1, 1, 1, 0.25)
    sheen:SetBlendMode("ADD")
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

---------------------------------------------------------
-- TITLE
---------------------------------------------------------

local title = dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("CENTER", dragHandle, "CENTER", 0, 0)
title:SetText("UAHeal")

---------------------------------------------------------
-- HEALTH BAR (PLAYER)
---------------------------------------------------------

local cardBorder = CreateCardBorder(f, -35, 59)
f.cardBorder = cardBorder

AttachClickCast(cardBorder, function() return "player" end)
AttachHoverTooltip(cardBorder)

local hpBar = CreateFrame("Frame", "UAHealHPBar", f)
hpBar:SetPoint("TOP", f, "TOP", 0, -36)
hpBar:SetFrameLevel(2)
hpBar:SetWidth(118)
hpBar:SetHeight(52)
hpBar:EnableMouse(false)

local hpBG = hpBar:CreateTexture(nil, "BACKGROUND")
hpBG:SetAllPoints()
hpBG:SetTexture("Interface\\Buttons\\WHITE8x8")
hpBG:SetVertexColor(0.2, 0, 0, 0.8)

local hpFill = hpBar:CreateTexture(nil, "ARTWORK")
hpFill:SetPoint("LEFT", hpBar, "LEFT")
hpFill:SetHeight(52)
hpFill:SetTexture("Interface\\Buttons\\WHITE8x8")
hpFill:SetVertexColor(1, 0, 0, 1)

AddBarSheen(hpBar, 52)

local hpText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
hpText:SetPoint("TOP", hpBar, "TOP", 0, -18)
hpText:SetShadowOffset(1, -1)
hpText:SetShadowColor(0, 0, 0, 0.8)

local hpValueText = hpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hpValueText:SetPoint("TOP", hpText, "BOTTOM", 0, -2)
hpValueText:SetShadowOffset(1, -1)
hpValueText:SetShadowColor(0, 0, 0, 0.8)

local buffIcons = CreateBuffIcons(hpBar)
local debuffIcons = CreateDebuffIcons(hpBar)

---------------------------------------------------------
-- MANA BAR (PLAYER)
---------------------------------------------------------

local mpBar = CreateFrame("Frame", "UAHealMPBar", f)
mpBar:SetPoint("TOP", hpBar, "BOTTOM", 0, 0)
mpBar:SetFrameLevel(2)
mpBar:SetWidth(118)
mpBar:SetHeight(5)
mpBar:EnableMouse(false)

local mpBG = mpBar:CreateTexture(nil, "BACKGROUND")
mpBG:SetAllPoints()
mpBG:SetTexture("Interface\\Buttons\\WHITE8x8")
mpBG:SetVertexColor(0, 0, 0.2, 0.8)

local mpFill = mpBar:CreateTexture(nil, "ARTWORK")
mpFill:SetPoint("LEFT", mpBar, "LEFT")
mpFill:SetHeight(5)
mpFill:SetTexture("Interface\\Buttons\\WHITE8x8")
mpFill:SetVertexColor(0, 0, 1, 1)

f.mpBar = mpBar

---------------------------------------------------------
-- UPDATE LOOP (PLAYER)
---------------------------------------------------------

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

    local hp = UnitHealth(unit) or 0
    local hpMax = UnitHealthMax(unit) or 1
    local hpPercent = ClampPercent(hpMax > 0 and (hp / hpMax) or 0)
    hpFill:SetWidth(118 * hpPercent * currentScale)
    if hpPercent <= LOW_HEALTH_THRESHOLD then
        hpFill:SetVertexColor(1, 0, 0)
    else
        hpFill:SetVertexColor(GetClassColor(unit))
    end

    local name = UnitName(unit) or "Unknown"
    hpText:SetText(name)
    hpValueText:SetText(math.floor(hpPercent * 100) .. "%      " .. hp .. "/" .. hpMax)

    local mp = UnitMana(unit) or 0
    local mpMax = UnitManaMax(unit) or 1
    local mpPercent = ClampPercent(mpMax > 0 and (mp / mpMax) or 0)
    mpFill:SetWidth(118 * mpPercent * currentScale)
    mpFill:SetVertexColor(GetPowerColor(unit))

    UpdateBuffIcons(buffIcons, unit)
    UpdateDebuffIcons(debuffIcons, unit)
end)

---------------------------------------------------------
-- PARTY FRAMES (party1-party4)
---------------------------------------------------------

local units = { "party1", "party2", "party3", "party4" }

local partyFrames = {}
layoutHorizontal = false

-- Positions every party frame relative to the previous one (starting
-- from the player frame), either stacking downward (default) or
-- sideways, depending on the current layout setting. Called once after
-- all party frames exist, and again whenever the layout is toggled.
PositionPartyFrames = function()
    local anchor = f
    for _, frame in ipairs(partyFrames) do
        frame:ClearAllPoints()
        if layoutHorizontal then
            -- FIX: anchoring via "LEFT"/"RIGHT" matches each frame's own
            -- vertical CENTER -- but the outer 200x120 box's center and
            -- the 122x61 card's center inside it aren't quite the same
            -- reference point, causing a small vertical mismatch between
            -- cards. Using TOPLEFT/TOPRIGHT instead aligns the outer
            -- boxes' TOP edges directly -- since every frame is the same
            -- height with its card positioned identically inside, this
            -- guarantees the cards themselves end up aligned too. The
            -- -78 offset accounts for both frames' 39px of left/right
            -- padding around their cards, keeping them touching with no
            -- gap.
            frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", -78, 0)
        else
            -- A small explicit gap (not relying on each card's own
            -- border rendering correctly at the exact seam) so there's
            -- always a clear visual break between stacked frames,
            -- regardless of party size.
            -- Butted flush together (no gap) -- the new border redesign
            -- above means each card draws its own explicit black edge,
            -- so two touching cards should naturally show a clean black
            -- seam between them without needing an artificial gap.
            -- FIX: same category of issue just fixed for the drag bar --
            -- anchoring at offset 0 makes the NEXT frame's invisible
            -- outer box touch the previous card's mana bar, but that
            -- next frame's own actual card sits inset ~34px inside its
            -- box, leaving a real gap between the two visible cards. +34
            -- pulls the next card's true top up to meet the previous
            -- one directly.
            frame:SetPoint("TOP", anchor.mpBar or anchor, "BOTTOM", 0, 34)
        end
        anchor = frame

        -- FIX: this used to recalculate the card's internal position
        -- per layout mode, but that used a slightly different baseline
        -- than each card's creation-time position, causing a small
        -- visible gap between the border and the mana bar specifically
        -- in vertical mode. Now that the border draws its own explicit
        -- edges (rather than relying on internal offset tricks for the
        -- stacking gap), this recalculation isn't needed at all -- every
        -- card just keeps its original creation-time alignment,
        -- matching the player's own frame exactly in both modes.

        -- Party members' pet cards also need repositioning per layout
        -- mode: to the right in vertical mode (frames stack downward,
        -- so the right side is free), but ABOVE the owner's frame in
        -- horizontal mode -- since frames already extend rightward one
        -- after another there, putting the pet card also to the right
        -- would collide with the next party member's frame.
        if frame.petOwnerFrame then
            frame.petOwnerFrame:ClearAllPoints()
            if layoutHorizontal then
                -- Positions the pet card's own visible card flush
                -- against the TOP of the owner's own card, calculated
                -- the same way the drag-bar-to-first-card gap was
                -- closed earlier: the owner's card sits 61px tall,
                -- inset 34px from frame's own top, so offsetting by
                -- +61 (TOP-to-TOP) lands the pet card's card exactly
                -- flush above it.
                frame.petOwnerFrame:SetPoint("TOP", frame, "TOP", 0, 61)
            else
                frame.petOwnerFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -78, 0)
            end
        end
    end
end

for index, unit in ipairs(units) do
    local thisUnit = unit
    local partyPetUnit = "partypet" .. index

    local frame = CreateFrame("Frame", "UAHeal_"..thisUnit, UIParent)
    frame:SetFrameStrata("LOW")
    frame:SetWidth(200)
    frame:SetHeight(120)
    table.insert(partyFrames, frame)

    local cardBorder2 = CreateCardBorder(frame, -35, 59)
    frame.cardBorder = cardBorder2

    AttachClickCast(cardBorder2, function() return thisUnit end)
    AttachHoverTooltip(cardBorder2)

    -- Compact indicator for this party member's pet (real vanilla unit
    -- ID "partypetN", one per party slot). Attached directly to their
    -- card rather than a full separate panel -- much less UI clutter
    -- for a supplementary display than 4 more standalone draggable
    -- panels would be.
    -- Full matching card for this party member's pet (same
    -- border/health/mana structure as every other frame in this addon,
    -- via the same reusable CreateCardBorder building block), positioned
    -- directly to the right of the owner's own card.
    local petOwnerFrame = CreateFrame("Frame", nil, frame)
    petOwnerFrame:SetWidth(200)
    petOwnerFrame:SetHeight(120)
    -- petOwnerFrame is a 200px invisible container (like every other
    -- frame in this addon) with its own visible card inset ~39px
    -- inside it. Anchoring at 0 would only make the invisible outer
    -- boxes touch, not the actual cards -- -39 pulls it in so the
    -- visible pet card lands flush against the owner's card directly.
    -- FIX: same category of issue already solved for horizontal party-
    -- frame stacking -- anchoring by LEFT/RIGHT matches each frame's
    -- CENTER point, but petOwnerFrame's outer box and cardBorder2 (the
    -- owner's actual card, not an outer box) don't share the same
    -- vertical center, causing a height mismatch. Anchoring by
    -- TOPLEFT/TOPRIGHT using the full outer boxes (frame, not
    -- cardBorder2) instead -- since both are identically-structured
    -- 200x120 containers with the same internal card inset, their tops
    -- lining up correctly aligns the visible cards too. -78 accounts
    -- for both frames' 39px of padding on each side, same formula
    -- already proven for horizontal party stacking.
    petOwnerFrame:SetPoint("TOPLEFT", frame, "TOPRIGHT", -78, 0)
    petOwnerFrame:SetFrameStrata("LOW")
    petOwnerFrame:Hide()
    frame.petOwnerFrame = petOwnerFrame

    local petIndicator = CreateCardBorder(petOwnerFrame, -35, 59)
    AttachClickCast(petIndicator, function() return partyPetUnit end)
    AttachHoverTooltip(petIndicator)

    local petIndicatorHPBar = CreateFrame("Frame", nil, petOwnerFrame)
    petIndicatorHPBar:SetPoint("TOP", petOwnerFrame, "TOP", 0, -36)
    petIndicatorHPBar:SetFrameLevel(2)
    petIndicatorHPBar:SetWidth(118)
    petIndicatorHPBar:SetHeight(52)

    local petIndicatorFill = petIndicatorHPBar:CreateTexture(nil, "ARTWORK")
    petIndicatorFill:SetPoint("LEFT", petIndicatorHPBar, "LEFT")
    petIndicatorFill:SetHeight(52)
    petIndicatorFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    petIndicatorFill:SetVertexColor(0.1, 0.7, 0.5, 1)

    AddBarSheen(petIndicatorHPBar, 52)

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
    petIndicatorMPBar:SetWidth(118)
    petIndicatorMPBar:SetHeight(5)

    local petIndicatorMPFill = petIndicatorMPBar:CreateTexture(nil, "ARTWORK")
    petIndicatorMPFill:SetPoint("LEFT", petIndicatorMPBar, "LEFT")
    petIndicatorMPFill:SetHeight(5)
    petIndicatorMPFill:SetTexture("Interface\\Buttons\\WHITE8x8")
    petIndicatorMPFill:SetVertexColor(0, 0, 1, 1)

    local hpBar2 = CreateFrame("Frame", nil, frame)
    frame.hpBar = hpBar2
    hpBar2:SetPoint("TOP", frame, "TOP", 0, -36)
    hpBar2:SetFrameLevel(2)
    hpBar2:SetWidth(118)
    hpBar2:SetHeight(52)

    local hpFill2 = hpBar2:CreateTexture(nil, "ARTWORK")
    hpFill2:SetPoint("LEFT", hpBar2, "LEFT")
    hpFill2:SetHeight(52)
    hpFill2:SetTexture("Interface\\Buttons\\WHITE8x8")
    hpFill2:SetVertexColor(1, 0, 0, 1)

    AddBarSheen(hpBar2, 52)

    local hpText2 = hpBar2:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hpText2:SetPoint("TOP", hpBar2, "TOP", 0, -18)
    hpText2:SetShadowOffset(1, -1)
    hpText2:SetShadowColor(0, 0, 0, 0.8)

    local hpValueText2 = hpBar2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hpValueText2:SetPoint("TOP", hpText2, "BOTTOM", 0, -2)
    hpValueText2:SetShadowOffset(1, -1)
    hpValueText2:SetShadowColor(0, 0, 0, 0.8)

    local buffIcons2 = CreateBuffIcons(hpBar2)
    local debuffIcons2 = CreateDebuffIcons(hpBar2)

    local mpBar2 = CreateFrame("Frame", nil, frame)
    frame.mpBar = mpBar2
    mpBar2:SetPoint("TOP", hpBar2, "BOTTOM", 0, 0)
    mpBar2:SetFrameLevel(2)
    mpBar2:SetWidth(118)
    mpBar2:SetHeight(5)

    local mpFill2 = mpBar2:CreateTexture(nil, "ARTWORK")
    mpFill2:SetPoint("LEFT", mpBar2, "LEFT")
    mpFill2:SetHeight(5)
    mpFill2:SetTexture("Interface\\Buttons\\WHITE8x8")
    mpFill2:SetVertexColor(0, 0, 1, 1)

    frame:SetScript("OnUpdate", function()
        if not InRaidMode() and not isMinimized and UnitExists(thisUnit) then
            cardBorder2:Show()
            cardBorder2.fillTexture:Show()
            hpBar2:Show()

            if UnitExists(partyPetUnit) then
                petOwnerFrame:Show()
                petIndicator:Show()
                petIndicator.fillTexture:Show()
                petIndicatorHPBar:Show()
                petIndicatorMPBar:Show()

                local petHP = UnitHealth(partyPetUnit) or 0
                local petHPMax = UnitHealthMax(partyPetUnit) or 1
                local petHPPercent = ClampPercent(petHPMax > 0 and (petHP / petHPMax) or 0)
                petIndicatorFill:SetWidth(118 * petHPPercent * currentScale)
                if petHPPercent <= LOW_HEALTH_THRESHOLD then
                    petIndicatorFill:SetVertexColor(1, 0, 0)
                else
                    petIndicatorFill:SetVertexColor(0.1, 0.7, 0.5)
                end

                -- FIX: UnitName("partypetN") confirmed via testing to
                -- return the PET OWNER's name, not the pet's own actual
                -- name -- a genuine client bug (UnitExists/UnitHealth
                -- correctly reference the real pet, just not this name
                -- lookup specifically). Uses the owner's own name
                -- instead (via thisUnit, e.g. "party1" -- confirmed
                -- working correctly, since it's what the main card
                -- itself already displays), labeled as "[Owner]'s Pet"
                -- rather than showing the pet's real name (unavailable)
                -- or a generic "Pet" (less informative).
                local ownerName = UnitName(thisUnit) or "Unknown"
                petIndicatorText:SetText(ownerName .. "'s Pet")
                petIndicatorValueText:SetText(math.floor(petHPPercent * 100) .. "%      " .. petHP .. "/" .. petHPMax)

                local petMP = UnitMana(partyPetUnit) or 0
                local petMPMax = UnitManaMax(partyPetUnit) or 1
                local petMPPercent = ClampPercent(petMPMax > 0 and (petMP / petMPMax) or 0)
                petIndicatorMPFill:SetWidth(118 * petMPPercent * currentScale)
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
            hpFill2:SetWidth(118 * hpPercent * currentScale)

            local name = UnitName(thisUnit) or "Unknown"

            if UnitIsConnected(thisUnit) then
                mpBar2:Show()
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
                mpFill2:SetWidth(118 * mpPercent * currentScale)
                mpFill2:SetVertexColor(GetPowerColor(thisUnit))

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
-- SLASH COMMANDS
---------------------------------------------------------

SLASH_UAHEAL1 = "/uaheal"
SLASH_UAHEAL2 = "/uah"
SlashCmdList["UAHEAL"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "settings" then
        macroWindow:Show()

    elseif msg == "reload" then
        -- Resets the panel back to its default spot, in case it ever
        -- ends up lost off-screen -- also clears the saved position so
        -- the next real /reload doesn't just put it right back.
        UAHealDB.position = nil
        dragHandle:ClearAllPoints()
        dragHandle:SetPoint("TOP", UIParent, "TOP", 0, -200)

    else
        DEFAULT_CHAT_FRAME:AddMessage("UAHeal commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/uaheal settings (or /uah settings) - opens the Settings/Click Macros window")
        DEFAULT_CHAT_FRAME:AddMessage("/uaheal reload (or /uah reload) - resets the panel back to the default position")
        DEFAULT_CHAT_FRAME:AddMessage("/uaheal (or /uah) - shows this list")
    end
end

---------------------------------------------------------
-- RAID FRAMES (raid1-40)
---------------------------------------------------------

local RAID_FRAME_WIDTH = 80
local RAID_FRAME_HEIGHT = 24
local RAID_COLS = 8
local RAID_GAP = 2

local raidContainer = CreateFrame("Frame", "UAHealRaidContainer", UIParent)
raidContainer:SetFrameStrata("LOW")
raidContainer:SetWidth(RAID_COLS * (RAID_FRAME_WIDTH + RAID_GAP))
raidContainer:SetHeight(5 * (RAID_FRAME_HEIGHT + RAID_GAP))
raidContainer:SetPoint("TOP", dragHandle, "BOTTOM", 8, -10)

-- Uniform scale for the whole visible addon, like VuhDo's own scale
-- slider (0.6x-2x). Each of these is a top-level frame whose children
-- (health/mana bars, buffs, buttons, etc.) are properly parented to it,
-- so scaling just this handful of frames scales everything they contain
-- automatically -- standard WoW frame behavior.
ApplyScale = function(value)
    -- FIX: scaling dragHandle/minimizeButton/the old settings button
    -- alongside the health frames caused a cascade of real bugs -- the
    -- hiding behind other elements, centering drifting off at low scale,
    -- and the drag bar/tab buttons disappearing entirely. Reverted back
    -- to the simpler, stable version: only the actual health/party/raid
    -- frames scale. The drag bar and its buttons stay a fixed size
    -- always, which is what was working reliably before this was added.
    f:SetScale(value)
    for _, pf in ipairs(partyFrames) do
        pf:SetScale(value)
    end
    raidContainer:SetScale(value)

    -- FIX: with the drag bar staying a genuinely fixed size while the
    -- card beneath it shrinks, the bar started hanging over the now-
    -- narrower card at low scale. Just narrowing dragHandle's WIDTH
    -- (not a full SetScale) fixes the visual overhang without touching
    -- scale at all -- avoiding that whole category of bug entirely. The
    -- minimize button is anchored to dragHandle's right edge, so it
    -- automatically follows along; no separate change needed there.
    dragHandle:SetWidth(100 * value)
end

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

    AttachClickCast(rFrame, function()
        if InRaidMode() and not isMinimized then
            return raidUnit
        end
        return nil
    end)
    AttachHoverTooltip(rFrame)

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
-- PET FRAME
---------------------------------------------------------
-- A separate, independently movable and minimizable mini-panel for
-- your pet (hunter pet, warlock demon, mage water elemental, etc -- the
-- "pet" unit ID covers all of these generically). Built from the exact
-- same reusable helpers as everything else in this addon.

local petDragHandle = CreateFrame("Frame", "UAHealPetDragHandle", UIParent)
petDragHandle:SetFrameStrata("LOW")
petDragHandle:SetWidth(100)
petDragHandle:SetHeight(16)
petDragHandle:SetPoint("TOP", UIParent, "TOP", 150, -200)
petDragHandle:EnableMouse(true)
ApplyButtonBevel(petDragHandle)

local petTitle = petDragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
petTitle:SetPoint("CENTER", petDragHandle, "CENTER", 0, 0)
petTitle:SetText("Pet")

local petIsMinimized = false

local petMinimizeButton = CreateFrame("Frame", "UAHealPetMinimizeButton", UIParent)
petMinimizeButton:SetFrameStrata("LOW")
petMinimizeButton:SetWidth(16)
petMinimizeButton:SetHeight(16)
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

-- Its own drag catcher, kept entirely separate from the main panel's
-- dragging system so the two never interfere with each other.
local petDragCatcher = CreateFrame("Frame", "UAHealPetDragCatcher", UIParent)
petDragCatcher:SetAllPoints(UIParent)
petDragCatcher:SetFrameStrata("TOOLTIP")
petDragCatcher:EnableMouse(true)
petDragCatcher:Hide()

local petDragging = false
local petLastDragX, petLastDragY = nil, nil

local function StopPetDrag()
    petDragging = false
    petDragCatcher:Hide()

    if petLastDragX and petLastDragY then
        UAHealDB.petPosition = { x = petLastDragX, y = petLastDragY }
    end
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
        petLastDragX, petLastDragY = x, y
        petDragHandle:ClearAllPoints()
        petDragHandle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end)

-- Pet card: reuses the same card/bar building blocks as the player and
-- party frames. Pets don't have a "class" the way players do, so their
-- health uses a fixed teal color instead of class-color, to keep it
-- visually distinct from player/party cards at a glance.
local petFrame = CreateFrame("Frame", "UAHealPetFrame", UIParent)
petFrame:SetFrameStrata("LOW")
petFrame:SetWidth(200)
petFrame:SetHeight(120)
petFrame:SetPoint("TOP", petDragHandle, "BOTTOM", 8, 35)
petFrame:EnableMouse(false)

local petCardBorder = CreateCardBorder(petFrame, -35, 59)

AttachClickCast(petCardBorder, function() return "pet" end)
AttachHoverTooltip(petCardBorder)

local petHPBar = CreateFrame("Frame", "UAHealPetHPBar", petFrame)
petHPBar:SetPoint("TOP", petFrame, "TOP", 0, -36)
petHPBar:SetFrameLevel(2)
petHPBar:SetWidth(118)
petHPBar:SetHeight(52)
petHPBar:EnableMouse(false)

local petHPBG = petHPBar:CreateTexture(nil, "BACKGROUND")
petHPBG:SetAllPoints()
petHPBG:SetTexture("Interface\\Buttons\\WHITE8x8")
petHPBG:SetVertexColor(0, 0.15, 0.1, 0.8)

local petHPFill = petHPBar:CreateTexture(nil, "ARTWORK")
petHPFill:SetPoint("LEFT", petHPBar, "LEFT")
petHPFill:SetHeight(52)
petHPFill:SetTexture("Interface\\Buttons\\WHITE8x8")
petHPFill:SetVertexColor(0.1, 0.7, 0.5, 1)

AddBarSheen(petHPBar, 52)

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
petMPBar:SetWidth(118)
petMPBar:SetHeight(5)
petMPBar:EnableMouse(false)

local petMPBG = petMPBar:CreateTexture(nil, "BACKGROUND")
petMPBG:SetAllPoints()
petMPBG:SetTexture("Interface\\Buttons\\WHITE8x8")
petMPBG:SetVertexColor(0, 0, 0.2, 0.8)

local petMPFill = petMPBar:CreateTexture(nil, "ARTWORK")
petMPFill:SetPoint("LEFT", petMPBar, "LEFT")
petMPFill:SetHeight(5)
petMPFill:SetTexture("Interface\\Buttons\\WHITE8x8")
petMPFill:SetVertexColor(0, 0, 1, 1)

petFrame:SetScript("OnUpdate", function()
    -- Drag bar and minimize button only show at all once a pet actually
    -- exists -- regardless of minimize state, since minimizing should
    -- only affect the card itself, not whether the controls to un-
    -- minimize it are visible.
    if UnitExists("pet") then
        petDragHandle:Show()
        petMinimizeButton:Show()
    else
        petDragHandle:Hide()
        petMinimizeButton:Hide()
    end

    if petIsMinimized or not UnitExists("pet") then
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
    petHPFill:SetWidth(118 * hpPercent * currentScale)
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
    petMPFill:SetWidth(118 * mpPercent * currentScale)
    petMPFill:SetVertexColor(GetPowerColor(unit))

    UpdateBuffIcons(petBuffIcons, unit)
end)

petFrame:SetScale(currentScale)

-- Extends the existing ApplyScale (defined earlier, before petFrame
-- existed) rather than editing its body directly -- petFrame wasn't in
-- scope at that point in the file, so wrapping the original function is
-- the safe way to add pet-frame scaling without a forward-reference
-- issue.
local baseApplyScale = ApplyScale
ApplyScale = function(value)
    baseApplyScale(value)
    petFrame:SetScale(value)
end

-- Restores the pet panel's saved position, same safe non-negative-only
-- check as the main panel uses. A separate ADDON_LOADED handler since
-- petDragHandle doesn't exist yet at the point the main loadFrame
-- handler was defined earlier in the file.
local petLoadFrame = CreateFrame("Frame")
petLoadFrame:RegisterEvent("ADDON_LOADED")
petLoadFrame:SetScript("OnEvent", function()
    local petPos = UAHealDB.petPosition
    if petPos and type(petPos.x) == "number" and type(petPos.y) == "number" and petPos.x >= 0 and petPos.y >= 0 then
        petDragHandle:ClearAllPoints()
        petDragHandle:SetPoint("CENTER", UIParent, "BOTTOMLEFT", petPos.x, petPos.y)
    end
end)


local ACTION_BAR_OFFSETS = {
    MultiBarLeftButton         = 36,
    MultiBarRightButton        = 24,
    MultiBarBottomRightButton  = 48,
    MultiBarBottomLeftButton   = 60,

    -- UnrealUI (a popular full UI replacement for this client) names its
    -- buttons differently and doesn't use the standard names above at all
    -- -- these entries let this feature keep working for anyone using it,
    -- without touching UnrealUI's own files. Confirmed directly from
    -- UnrealUI's own source (modules/actionbar.lua) -- these offsets
    -- independently match the ones already confirmed above, which is a
    -- good sign both are accurate for this client.
    UnrealUIActionBar2Button  = 24,
    UnrealUIActionBar3Button  = 36,
    UnrealUIActionBar4Button  = 48,
    UnrealUIActionBar5Button  = 60,
    UnrealUIActionBar6Button  = 12,
    UnrealUIActionBar7Button  = 72,
    UnrealUIActionBar8Button  = 84,
    UnrealUIActionBar9Button  = 96,
    UnrealUIActionBar10Button = 108,
}

local actionBarLabels = {}
local mainBarLabels = {}
actionBarNumbersShown = false

local function CreateActionNumberLabel(button)
    local shadowOffsets = {
        {1, 0}, {-1, 0}, {0, 1}, {0, -1},
        {1, 1}, {1, -1}, {-1, 1}, {-1, -1},
    }
    local shadows = {}
    for _, off in ipairs(shadowOffsets) do
        local shadow = button:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        shadow:SetPoint("CENTER", button, "CENTER", off[1], off[2])
        shadow:SetTextColor(0, 0, 0)
        table.insert(shadows, shadow)
    end

    local mainText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainText:SetPoint("CENTER", button, "CENTER", 0, 0)
    mainText:SetTextColor(1, 1, 1)

    local label = {}

    function label:SetText(text)
        mainText:SetText(text)
        for _, s in ipairs(shadows) do
            s:SetText(text)
        end
    end

    function label:Show()
        mainText:Show()
        for _, s in ipairs(shadows) do
            s:Show()
        end
    end

    function label:Hide()
        mainText:Hide()
        for _, s in ipairs(shadows) do
            s:Hide()
        end
    end

    label:Hide()
    return label
end

local function BuildActionBarLabels()
    if next(actionBarLabels) or next(mainBarLabels) then return end

    for i = 1, 12 do
        local button = _G["ActionButton" .. i]
        if button then
            local label = CreateActionNumberLabel(button)
            table.insert(mainBarLabels, { label = label, index = i, button = button })
        end
    end

    -- UnrealUI's bar 1 is the same "paged" main bar as above, just under a
    -- different name -- feeds into the same live-updating list rather than
    -- the fixed-offset one below.
    for i = 1, 12 do
        local button = _G["UnrealUIActionBar1Button" .. i]
        if button then
            local label = CreateActionNumberLabel(button)
            table.insert(mainBarLabels, { label = label, index = i, button = button })
        end
    end

    for prefix, offset in pairs(ACTION_BAR_OFFSETS) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button then
                local label = CreateActionNumberLabel(button)
                label:SetText(tostring(offset + i))
                table.insert(actionBarLabels, { label = label, button = button })
            end
        end
    end
end

local mainBarPageTicker = CreateFrame("Frame")
mainBarPageTicker:SetScript("OnUpdate", function()
    if actionBarNumbersShown then
        local page = CURRENT_ACTIONBAR_PAGE or 1
        for _, entry in ipairs(mainBarLabels) do
            entry.label:SetText(tostring((page - 1) * 12 + entry.index))
        end
    end
end)

ToggleActionBarNumbers = function()
    BuildActionBarLabels()
    actionBarNumbersShown = not actionBarNumbersShown

    for _, entry in ipairs(mainBarLabels) do
        if actionBarNumbersShown then
            entry.label:Show()
        else
            entry.label:Hide()
        end
    end

    for _, entry in ipairs(actionBarLabels) do
        if actionBarNumbersShown then
            entry.label:Show()
        else
            entry.label:Hide()
        end
    end
end