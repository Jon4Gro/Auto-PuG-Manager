local addonName, addon = ...

local f = CreateFrame("Frame", "APM_MainUI", UIParent)
f:SetSize(470, 790)
f:SetPoint("CENTER")
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:Hide()
tinsert(UISpecialFrames, "APM_MainUI")
addon.MainUI = f

local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", 0, -15)
title:SetText("Auto PuG Manager Configuration")

local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

local function CreateEditBox(parent, name, width, height, x, y, labelText, maxLetters, isNumeric)
    local eb = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    eb:SetSize(width, height)
    eb:SetPoint("TOPLEFT", x, y)
    eb:SetAutoFocus(false)
    if maxLetters then eb:SetMaxLetters(maxLetters) end
    if isNumeric then eb:SetNumeric(true) end
    
    local label = eb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", eb, "TOPLEFT", 0, 2)
    label:SetText(labelText)
    eb.label = label
    return eb
end

local toggleBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
toggleBtn:SetSize(120, 30)
toggleBtn:SetPoint("BOTTOM", 0, 20)
toggleBtn:SetText("Start APM")

local resetRoleBtn = CreateFrame("Button", "APM_Btn_ResetRole", f, "UIPanelButtonTemplate")
resetRoleBtn:SetSize(120, 30)
resetRoleBtn:SetPoint("BOTTOMLEFT", 20, 20)
resetRoleBtn:SetText("Reset My Role")

local isUpdating = false
local uiElements = {}

-- SECTION: Limits
local limitTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
limitTitle:SetPoint("TOPLEFT", 20, -45)
limitTitle:SetText("Role Limits")

uiElements.limT = CreateEditBox(f, "APM_EB_LimT", 30, 20, 25, -75, "Tank", 2, true)
uiElements.limH = CreateEditBox(f, "APM_EB_LimH", 30, 20, 75, -75, "Heal", 2, true)

local dpsBox = CreateFrame("Frame", nil, f)
dpsBox:SetSize(110, 50)
dpsBox:SetPoint("TOPLEFT", 115, -55)
dpsBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
dpsBox:SetBackdropColor(0, 0, 0, 0.4)

uiElements.limMD = CreateEditBox(dpsBox, "APM_EB_LimMD", 30, 20, 15, -20, "mDPS", 2, true)
uiElements.limRD = CreateEditBox(dpsBox, "APM_EB_LimRD", 30, 20, 65, -20, "rDPS", 2, true)

uiElements.limD = CreateEditBox(f, "APM_EB_LimD", 30, 20, 245, -75, "Any DPS", 2, true)
uiElements.limF1 = CreateEditBox(f, "APM_EB_LimF1", 30, 20, 315, -75, "1st Flag", 2, true)

-- SECTION: Tracker Config
local trackTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
trackTitle:SetPoint("TOPLEFT", 20, -115)
trackTitle:SetText("Tracker Options")

local cbShowTracker = CreateFrame("CheckButton", "APM_CB_ShowTracker", f, "UICheckButtonTemplate")
cbShowTracker:SetPoint("TOPLEFT", 15, -135)
_G["APM_CB_ShowTrackerText"]:SetText("Show Tracker")
uiElements.showTracker = cbShowTracker

local cbTrackF1 = CreateFrame("CheckButton", "APM_CB_TrackF1", f, "UICheckButtonTemplate")
cbTrackF1:SetPoint("TOPLEFT", 140, -135)
_G["APM_CB_TrackF1Text"]:SetText("Track 1st Flag")
uiElements.trackF1 = cbTrackF1

uiElements.f1Name = CreateEditBox(f, "APM_EB_F1Name", 100, 20, 300, -136, "1st Flag Name")

local cbShowF1Names = CreateFrame("CheckButton", "APM_CB_ShowF1Names", f, "UICheckButtonTemplate")
cbShowF1Names:SetPoint("TOPLEFT", 15, -165)
_G["APM_CB_ShowF1NamesText"]:SetText("List 1st Flag Names")
uiElements.showF1Names = cbShowF1Names

local cbShowLevelNames = CreateFrame("CheckButton", "APM_CB_ShowLevelNames", f, "UICheckButtonTemplate")
cbShowLevelNames:SetPoint("TOPLEFT", 170, -165)
_G["APM_CB_ShowLevelNamesText"]:SetText("List Lvl Names")
uiElements.showLevelNames = cbShowLevelNames

uiElements.levelCond = CreateEditBox(f, "APM_EB_LevelCond", 100, 20, 300, -184, "Lvl Cond (e.g. >50)")

-- SECTION: Keywords
local kwTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
kwTitle:SetPoint("TOPLEFT", 20, -215)
kwTitle:SetText("Keywords (comma separated)")

uiElements.kwT = CreateEditBox(f, "APM_EB_KwT", 180, 20, 25, -245, "Tank")
uiElements.kwH = CreateEditBox(f, "APM_EB_KwH", 180, 20, 235, -245, "Healer")
uiElements.kwMD = CreateEditBox(f, "APM_EB_KwMD", 180, 20, 25, -295, "Melee DPS")
uiElements.kwRD = CreateEditBox(f, "APM_EB_KwRD", 180, 20, 235, -295, "Ranged DPS")
uiElements.kwD = CreateEditBox(f, "APM_EB_KwD", 180, 20, 25, -345, "Any DPS")

local flagBox = CreateFrame("Frame", nil, f)
flagBox:SetSize(420, 60)
flagBox:SetPoint("TOPLEFT", 20, -380)
flagBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
flagBox:SetBackdropColor(0, 0, 0, 0.4)

uiElements.kwF1 = CreateEditBox(flagBox, "APM_EB_KwF1", 130, 20, 15, -25, "1st Flag")
local cbF1 = CreateFrame("CheckButton", "APM_CB_F1", flagBox, "UICheckButtonTemplate")
cbF1:SetPoint("LEFT", uiElements.kwF1, "RIGHT", 5, 0)
cbF1:SetSize(24, 24)
local cbF1Label = cbF1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
cbF1Label:SetPoint("BOTTOM", cbF1, "TOP", 0, 2)
cbF1Label:SetText("Need")
uiElements.reqF1 = cbF1

uiElements.kwF2 = CreateEditBox(flagBox, "APM_EB_KwF2", 130, 20, 215, -25, "2nd Flag")
local cbF2 = CreateFrame("CheckButton", "APM_CB_F2", flagBox, "UICheckButtonTemplate")
cbF2:SetPoint("LEFT", uiElements.kwF2, "RIGHT", 5, 0)
cbF2:SetSize(24, 24)
local cbF2Label = cbF2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
cbF2Label:SetPoint("BOTTOM", cbF2, "TOP", 0, 2)
cbF2Label:SetText("Need")
uiElements.reqF2 = cbF2

-- SECTION: Spam config
local spamTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
spamTitle:SetPoint("TOPLEFT", 20, -455)
spamTitle:SetText("Chat Spam Configuration (Use %STATS% for dynamic counts)")

uiElements.spamText = CreateEditBox(f, "APM_EB_SpamText", 390, 20, 25, -485, "Spam Text")
uiElements.spamChan = CreateEditBox(f, "APM_EB_SpamChan", 180, 20, 25, -535, "Channel (e.g. world or 5)")
uiElements.spamInt = CreateEditBox(f, "APM_EB_SpamInt", 100, 20, 235, -535, "Interval (Secs, 0=Off)", 4, true)

-- SECTION: Invite config
local invTitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
invTitle:SetPoint("TOPLEFT", 20, -575)
invTitle:SetText("Whisper / Invite Options")

uiElements.invPhrase = CreateEditBox(f, "APM_EB_InvPhrase", 390, 20, 25, -605, "Manual Invite Whisper Phrase")
uiElements.autoResp = CreateEditBox(f, "APM_EB_AutoResp", 390, 20, 25, -655, "Role Full/Queued Auto-Response")
uiElements.ofExpire = CreateEditBox(f, "APM_EB_OfExpire", 50, 20, 25, -705, "Queue Expire (Mins)", 3, true)

-- OPAQUE TOGGLE
local cbOpaque = CreateFrame("CheckButton", "APM_CB_Opaque", f, "UICheckButtonTemplate")
cbOpaque:SetPoint("BOTTOMRIGHT", -145, 20)
_G["APM_CB_OpaqueText"]:SetText("Black UI Background")
uiElements.opaqueToggle = cbOpaque

-- Functions
local function SaveFromUI()
    if isUpdating then return end
    APM_DB.limits.T = tonumber(uiElements.limT:GetText()) or 0
    APM_DB.limits.H = tonumber(uiElements.limH:GetText()) or 0
    APM_DB.limits.mD = tonumber(uiElements.limMD:GetText()) or 0
    APM_DB.limits.rD = tonumber(uiElements.limRD:GetText()) or 0
    APM_DB.limits.D = tonumber(uiElements.limD:GetText()) or 0
    APM_DB.limits.F1 = tonumber(uiElements.limF1:GetText()) or 0
    
    APM_DB.requireF1 = uiElements.reqF1:GetChecked() and true or false
    APM_DB.requireF2 = uiElements.reqF2:GetChecked() and true or false
    
    APM_DB.tracker.show = uiElements.showTracker:GetChecked() and true or false
    APM_DB.tracker.trackF1 = uiElements.trackF1:GetChecked() and true or false
    APM_DB.tracker.f1Name = uiElements.f1Name:GetText()
    APM_DB.tracker.showF1Names = uiElements.showF1Names:GetChecked() and true or false
    APM_DB.tracker.showLevelNames = uiElements.showLevelNames:GetChecked() and true or false
    APM_DB.tracker.levelCond = uiElements.levelCond:GetText()
    
    APM_DB.opaqueStyle = uiElements.opaqueToggle:GetChecked() and true or false
    
    APM_DB.keywords.T = uiElements.kwT:GetText()
    APM_DB.keywords.H = uiElements.kwH:GetText()
    APM_DB.keywords.mD = uiElements.kwMD:GetText()
    APM_DB.keywords.rD = uiElements.kwRD:GetText()
    APM_DB.keywords.D = uiElements.kwD:GetText()
    APM_DB.keywords.F1 = uiElements.kwF1:GetText()
    APM_DB.keywords.F2 = uiElements.kwF2:GetText()
    
    APM_DB.spam.text = uiElements.spamText:GetText()
    APM_DB.spam.channel = uiElements.spamChan:GetText()
    APM_DB.spam.intervalSecs = tonumber(uiElements.spamInt:GetText()) or 0
    
    APM_DB.invitePhrase = uiElements.invPhrase:GetText()
    APM_DB.autoResponse = uiElements.autoResp:GetText()
    APM_DB.overflowExpireMins = tonumber(uiElements.ofExpire:GetText()) or 5

    addon.ApplyStyle(addon.MainUI)
    addon.ApplyStyle(addon.overflowFrame)
    addon.ApplyStyle(addon.trackerFrame)
    addon.ApplyStyle(addon.assignFrame)
    addon.ApplyStyle(addon.resumeFrame)
    addon.UpdateTracker()
end

local function UpdateDPSExclusion(eb)
    if isUpdating then return end
    isUpdating = true
    
    local name = eb:GetName()
    local txt = eb:GetText()
    
    if name == "APM_EB_LimD" and txt ~= "" then
        uiElements.limMD:SetText("")
        uiElements.limRD:SetText("")
    elseif (name == "APM_EB_LimMD" or name == "APM_EB_LimRD") and txt ~= "" then
        uiElements.limD:SetText("")
    end
    
    isUpdating = false
    SaveFromUI()
end

local function LoadToUI()
    isUpdating = true
    
    uiElements.limT:SetText((APM_DB.limits.T == nil or APM_DB.limits.T == 0) and "" or APM_DB.limits.T)
    uiElements.limH:SetText((APM_DB.limits.H == nil or APM_DB.limits.H == 0) and "" or APM_DB.limits.H)
    uiElements.limMD:SetText((APM_DB.limits.mD == nil or APM_DB.limits.mD == 0) and "" or APM_DB.limits.mD)
    uiElements.limRD:SetText((APM_DB.limits.rD == nil or APM_DB.limits.rD == 0) and "" or APM_DB.limits.rD)
    uiElements.limD:SetText((APM_DB.limits.D == nil or APM_DB.limits.D == 0) and "" or APM_DB.limits.D)
    uiElements.limF1:SetText((APM_DB.limits.F1 == nil or APM_DB.limits.F1 == 0) and "" or APM_DB.limits.F1)
    
    uiElements.reqF1:SetChecked(APM_DB.requireF1)
    uiElements.reqF2:SetChecked(APM_DB.requireF2)
    
    uiElements.showTracker:SetChecked(APM_DB.tracker and APM_DB.tracker.show or false)
    uiElements.trackF1:SetChecked(APM_DB.tracker and APM_DB.tracker.trackF1 or false)
    uiElements.f1Name:SetText(APM_DB.tracker and APM_DB.tracker.f1Name or "Aura")
    uiElements.showF1Names:SetChecked(APM_DB.tracker and APM_DB.tracker.showF1Names or false)
    uiElements.showLevelNames:SetChecked(APM_DB.tracker and APM_DB.tracker.showLevelNames or false)
    uiElements.levelCond:SetText(APM_DB.tracker and APM_DB.tracker.levelCond or ">50")
    
    uiElements.opaqueToggle:SetChecked(APM_DB.opaqueStyle)
    
    uiElements.kwT:SetText(APM_DB.keywords.T)
    uiElements.kwH:SetText(APM_DB.keywords.H)
    uiElements.kwMD:SetText(APM_DB.keywords.mD)
    uiElements.kwRD:SetText(APM_DB.keywords.rD)
    uiElements.kwD:SetText(APM_DB.keywords.D)
    uiElements.kwF1:SetText(APM_DB.keywords.F1)
    uiElements.kwF2:SetText(APM_DB.keywords.F2)
    
    uiElements.spamText:SetText(APM_DB.spam.text)
    uiElements.spamChan:SetText(APM_DB.spam.channel)
    uiElements.spamInt:SetText(APM_DB.spam.intervalSecs or 300)
    
    uiElements.invPhrase:SetText(APM_DB.invitePhrase)
    uiElements.autoResp:SetText(APM_DB.autoResponse)
    uiElements.ofExpire:SetText(APM_DB.overflowExpireMins)
    
    isUpdating = false
    addon.ApplyStyle(addon.MainUI)
end

for _, element in pairs(uiElements) do
    if element:GetObjectType() == "EditBox" then
        if element:GetName() == "APM_EB_LimMD" or element:GetName() == "APM_EB_LimRD" or element:GetName() == "APM_EB_LimD" then
            element:SetScript("OnTextChanged", UpdateDPSExclusion)
        else
            element:SetScript("OnTextChanged", SaveFromUI)
        end
    elseif element:GetObjectType() == "CheckButton" then
        element:SetScript("OnClick", SaveFromUI)
    end
end

f:SetScript("OnShow", LoadToUI)

addon.ToggleAPM = function()
    addon.isActive = not addon.isActive
    if addon.isActive then
        toggleBtn:SetText("Stop APM")
        print("|cff00ff00Auto PuG Manager Started!|r")
        addon.UpdateOverflow()
        addon.UpdateTracker()
    else
        toggleBtn:SetText("Start APM")
        print("|cffff0000Auto PuG Manager Stopped!|r")
        if addon.overflowFrame then addon.overflowFrame:Hide() end
        if addon.assignFrame then addon.assignFrame:Hide() end
        if addon.resumeFrame then addon.resumeFrame:Hide() end
        addon.spamPaused = false
        addon.unassignedQueueList = {}
        addon.unassignedQueueMap = {}
        addon.UpdateTracker()
    end
end
toggleBtn:SetScript("OnClick", addon.ToggleAPM)

resetRoleBtn:SetScript("OnClick", function()
    addon.ResetMyRole()
end)
