local addonName, addon = ...
_G[addonName] = addon

-- Default Database
local defaultDB = {
    opaqueStyle = false,
    limits = { T = 2, mD = 2, rD = 2, D = 0, H = 2, F1 = 4 },
    requireF1 = false,
    requireF2 = false,
    tracker = { show = true, trackF1 = true, f1Name = "Aura", showF1Names = false, showLevelNames = false, levelCond = ">50" },
    keywords = {
        T = "tank,prot,bear,blood",
        mD = "melee,ret,rogue,feral,enh",
        rD = "ranged,hunter,mage,lock,ele,boom",
        D = "dps,damage",
        H = "heal,resto,holy,disc,tree",
        F1 = "loom,heirloom",
        F2 = "aura,aoe,exp"
    },
    spam = { text = "LFM Raid! %STATS% whisper role, looms, aura.", channel = "world", intervalSecs = 300 },
    overflowExpireMins = 5,
    invitePhrase = "Inviting you now, please have your Aura active!",
    autoResponse = "Role full or missing requirements, you have been added to the queue!",
    minimap = { hide = false, angle = 45 }
}

addon.isActive = false
addon.spamPaused = false
addon.overflowQueue = {}
addon.roster = {} -- { ["cleanname"] = { displayName = "Name", role = "T", F1 = true, level = 80 } }
addon.pendingInvites = {} -- { ["cleanname"] = { displayName = "Name", role = "T", F1 = true, time = GetTime() } }
addon.unassignedQueueList = {}
addon.unassignedQueueMap = {}

local lastSpamTime = 0
local timerAccumulator = 0
local levelUpdateTimer = 0 -- Timer for 5s level polling

local coreFrame = CreateFrame("Frame")
coreFrame:RegisterEvent("ADDON_LOADED")
coreFrame:RegisterEvent("CHAT_MSG_WHISPER")
coreFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
coreFrame:RegisterEvent("RAID_ROSTER_UPDATE")

-------------------------------------------------
-- MINIMAP BUTTON
-------------------------------------------------
local minimapBtn = CreateFrame("Button", "APM_MinimapButton", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)

local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore")
icon:SetSize(21, 21)
icon:SetPoint("CENTER", minimapBtn, "CENTER", -1, 1)

local border = minimapBtn:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT", minimapBtn, "TOPLEFT", -11, 11)

minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function(self)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        APM_DB.minimap.angle = angle
        addon.UpdateMinimapButton()
    end)
end)
minimapBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Auto PuG Manager")
    GameTooltip:AddLine("Left-Click to open options.", 1, 1, 1)
    GameTooltip:AddLine("Right-Click to Start/Stop APM.", 1, 1, 1)
    GameTooltip:AddLine("Drag to move.", 1, 1, 1)
    GameTooltip:Show()
end)
minimapBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

minimapBtn:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if addon.MainUI then
            if addon.MainUI:IsShown() then
                addon.MainUI:Hide()
            else
                addon.ApplyStyle(addon.MainUI)
                addon.MainUI:Show()
            end
        end
    elseif button == "RightButton" then
        if addon.ToggleAPM then addon.ToggleAPM() end
    end
end)

function addon.UpdateMinimapButton()
    if not APM_DB.minimap then APM_DB.minimap = { hide = false, angle = 45 } end
    if APM_DB.minimap.hide then
        minimapBtn:Hide()
    else
        minimapBtn:Show()
        local angle = math.rad(APM_DB.minimap.angle or 45)
        local radius = 80
        local x = math.cos(angle) * radius
        local y = math.sin(angle) * radius
        minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end
end


-------------------------------------------------
-- STYLING ENGINE
-------------------------------------------------
function addon.ApplyStyle(frame)
    if not frame then return end
    if APM_DB.opaqueStyle then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = false, tileSize = 0, edgeSize = 16,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.95)
    else
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 8, right = 8, top = 8, bottom = 8 }
        })
        frame:SetBackdropColor(1, 1, 1, 1)
    end
end

-------------------------------------------------
-- UTILITY & PARSING
-------------------------------------------------
local function GetCleanName(name)
    if not name then return "" end
    name = strsplit("-", name)
    return string.lower(strtrim(name))
end

-- SMARTER PARSING: Strip Negations
local function StripNegations(msg, kwString)
    if not kwString or kwString == "" then return msg end
    local keywords = {strsplit(",", kwString)}
    local negations = {"no", "without", "w/o", "w/out", "not", "dont have", "don't have", "0", "zero", "lack", "lacking"}
    local tempMsg = " " .. msg .. " "
    
    for _, kw in ipairs(keywords) do
        kw = string.lower(strtrim(kw))
        if kw ~= "" then
            local safeKw = string.gsub(kw, "[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")
            for _, neg in ipairs(negations) do
                local safeNeg = string.gsub(neg, "[%(%)%.%%%+%-%*%?%[%^%$]", "%%%1")
                local pattern = "%f[%w]" .. safeNeg .. "%f[%W][%s%p]*" .. safeKw .. "%f[%W]"
                tempMsg = string.gsub(tempMsg, pattern, " ")
            end
        end
    end
    return tempMsg
end

local function CheckKeywords(msg, kwString)
    local keywords = {strsplit(",", kwString)}
    for _, kw in ipairs(keywords) do
        kw = string.lower(strtrim(kw))
        if kw ~= "" and string.find(msg, kw, 1, true) then return true end
    end
    return false
end

local function CheckSmartKeywords(msg, kwString)
    local strippedMsg = StripNegations(msg, kwString)
    return CheckKeywords(strippedMsg, kwString)
end

local function ParseWhisper(msg)
    msg = string.lower(msg)
    local roles = {}
    local flags = {}

    if APM_DB.limits.D and APM_DB.limits.D > 0 then
        if CheckSmartKeywords(msg, APM_DB.keywords.D) then table.insert(roles, "D") end
    else
        if CheckSmartKeywords(msg, APM_DB.keywords.mD) then table.insert(roles, "mD") end
        if CheckSmartKeywords(msg, APM_DB.keywords.rD) then table.insert(roles, "rD") end
    end
    
    if CheckSmartKeywords(msg, APM_DB.keywords.T) then table.insert(roles, "T") end
    if CheckSmartKeywords(msg, APM_DB.keywords.H) then table.insert(roles, "H") end
    
    if CheckSmartKeywords(msg, APM_DB.keywords.F1) then flags.F1 = true; table.insert(flags, "F1") end
    if CheckSmartKeywords(msg, APM_DB.keywords.F2) then flags.F2 = true; table.insert(flags, "F2") end

    return roles, flags
end

function addon.GetCurrentRoleCounts()
    local counts = { T = 0, mD = 0, rD = 0, D = 0, H = 0, F1 = 0 }
    local now = GetTime()

    for _, data in pairs(addon.roster) do
        if counts[data.role] ~= nil then counts[data.role] = counts[data.role] + 1 end
        if data.F1 then counts.F1 = counts.F1 + 1 end
    end

    for cleanName, data in pairs(addon.pendingInvites) do
        if (now - data.time) < 45 then
            if counts[data.role] ~= nil then counts[data.role] = counts[data.role] + 1 end
            if data.F1 then counts.F1 = counts.F1 + 1 end
        else
            addon.pendingInvites[cleanName] = nil
        end
    end

    return counts
end

local function IsRaidFull()
    local c = addon.GetCurrentRoleCounts()
    local l = APM_DB.limits
    local full = true
    if l.T and l.T > 0 and c.T < l.T then full = false end
    if l.H and l.H > 0 and c.H < l.H then full = false end
    if l.D and l.D > 0 and c.D < l.D then full = false end
    if l.D and l.D == 0 and l.mD and l.mD > 0 and c.mD < l.mD then full = false end
    if l.D and l.D == 0 and l.rD and l.rD > 0 and c.rD < l.rD then full = false end
    return full
end

function addon.CheckLevel(level, condStr)
    if not level or level <= 0 then return false end
    if not condStr or condStr == "" then return false end
    
    local op, valStr = string.match(strtrim(condStr), "^([<>=]*)(%d+)$")
    local val = tonumber(valStr)
    if not val then return false end
    
    if op == ">" then return level > val end
    if op == "<" then return level < val end
    if op == ">=" then return level >= val end
    if op == "<=" then return level <= val end
    if op == "=" or op == "==" or op == "" then return level == val end
    return false
end

function addon.ResetMyRole()
    local pName = UnitName("player")
    if pName then
        local clean = GetCleanName(pName)
        addon.roster[clean] = nil
        addon.pendingInvites[clean] = nil
        if addon.isActive then
            addon.unassignedQueueMap[clean] = true
            table.insert(addon.unassignedQueueList, clean)
            if not addon.assignFrame:IsShown() then
                addon.ProcessUnassignedQueue()
            end
        end
        addon.UpdateTracker()
        print("|cff00ff00[APM] Your role has been reset. You will be prompted to reassign it.|r")
    end
end

function addon.RefreshRosterLevels()
    local updated = false
    local numRaid = GetNumRaidMembers()
    local numParty = GetNumPartyMembers()
    
    local function checkAndUpdate(unit)
        local n = UnitName(unit)
        if n then
            local clean = GetCleanName(n)
            local lvl = UnitLevel(unit)
            if lvl and lvl > 0 and addon.roster[clean] and addon.roster[clean].level ~= lvl then
                addon.roster[clean].level = lvl
                updated = true
            end
        end
    end

    if numRaid > 0 then
        for i = 1, numRaid do checkAndUpdate("raid"..i) end
    elseif numParty > 0 then
        for i = 1, numParty do checkAndUpdate("party"..i) end
        checkAndUpdate("player")
    else
        checkAndUpdate("player")
    end
    
    if updated then addon.UpdateTracker() end
end

-------------------------------------------------
-- FRAMES: TRACKER & POPUPS
-------------------------------------------------
addon.trackerFrame = CreateFrame("Frame", "APM_Tracker", UIParent)
local tracker = addon.trackerFrame
tracker:SetSize(250, 40)
tracker:SetPoint("TOP", 0, -50)
tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:RegisterForDrag("LeftButton")
tracker:SetScript("OnDragStart", tracker.StartMoving)
tracker:SetScript("OnDragStop", tracker.StopMovingOrSizing)
tracker.text = tracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tracker.text:SetPoint("CENTER", 0, 0)
tracker.text:SetJustifyH("CENTER")

function addon.UpdateTracker()
    if not APM_DB.tracker.show or not addon.isActive then tracker:Hide(); return end
    tracker:Show()
    addon.ApplyStyle(tracker)
    
    local c = addon.GetCurrentRoleCounts()
    local l = APM_DB.limits
    local statsStr = {}
    local lines = {}
    
    if l.T and l.T > 0 then table.insert(statsStr, string.format("T: %d/%d", c.T, l.T)) end
    if l.H and l.H > 0 then table.insert(statsStr, string.format("H: %d/%d", c.H, l.H)) end
    if l.D and l.D > 0 then
        table.insert(statsStr, string.format("DPS: %d/%d", c.D, l.D))
    else
        if l.mD and l.mD > 0 then table.insert(statsStr, string.format("mD: %d/%d", c.mD, l.mD)) end
        if l.rD and l.rD > 0 then table.insert(statsStr, string.format("rD: %d/%d", c.rD, l.rD)) end
    end
    if APM_DB.tracker.trackF1 then
        table.insert(statsStr, string.format("[%s]: %d/%d", APM_DB.tracker.f1Name or "Aura", c.F1, l.F1 or 0))
    end
    table.insert(lines, table.concat(statsStr, " - "))
    
    if APM_DB.tracker.showF1Names then
        local f1Names = {}
        for _, data in pairs(addon.roster) do
            if data.F1 then table.insert(f1Names, data.displayName or "Unknown") end
        end
        if #f1Names > 0 then
            table.insert(lines, "|cff00ff00" .. (APM_DB.tracker.f1Name or "Aura") .. "s:|r " .. table.concat(f1Names, ", "))
        end
    end
    
    if APM_DB.tracker.showLevelNames and APM_DB.tracker.levelCond and APM_DB.tracker.levelCond ~= "" then
        local lvlNames = {}
        for _, data in pairs(addon.roster) do
            if data.level and addon.CheckLevel(data.level, APM_DB.tracker.levelCond) then
                table.insert(lvlNames, (data.displayName or "Unknown") .. "(" .. data.level .. ")")
            end
        end
        if #lvlNames > 0 then
            table.insert(lines, "|cffffcc00Lvl " .. APM_DB.tracker.levelCond .. ":|r " .. table.concat(lvlNames, ", "))
        end
    end
    
    tracker.text:SetText(table.concat(lines, "\n"))
    tracker:SetHeight(math.max(tracker.text:GetStringHeight() + 15, 30))
    tracker:SetWidth(math.max(tracker.text:GetStringWidth() + 30, 50))
end

addon.assignFrame = CreateFrame("Frame", "APM_AssignPopup", UIParent)
local assignF = addon.assignFrame
assignF:SetSize(250, 160)
assignF:SetPoint("CENTER", 0, 100)
assignF:SetFrameStrata("DIALOG")
assignF:Hide()

assignF.title = assignF:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
assignF.title:SetPoint("TOP", 0, -15)

assignF.selectedRole = "D"
local roleBtns = {}
local roles = {"T", "H", "mD", "rD", "D"}
for i, r in ipairs(roles) do
    local btn = CreateFrame("Button", nil, assignF, "UIPanelButtonTemplate")
    btn:SetSize(40, 20)
    btn:SetPoint("TOPLEFT", 15 + ((i-1)*43), -45)
    btn:SetText(r)
    btn:SetScript("OnClick", function() assignF.selectedRole = r end)
    table.insert(roleBtns, btn)
end

assignF.cbF1 = CreateFrame("CheckButton", nil, assignF, "UICheckButtonTemplate")
assignF.cbF1:SetPoint("TOPLEFT", 20, -75)
assignF.cbF1.text = assignF.cbF1:CreateFontString(nil, "OVERLAY", "GameFontNormal")
assignF.cbF1.text:SetPoint("LEFT", assignF.cbF1, "RIGHT", 5, 0)

local saveBtn = CreateFrame("Button", nil, assignF, "UIPanelButtonTemplate")
saveBtn:SetSize(80, 25)
saveBtn:SetPoint("BOTTOM", 0, 15)
saveBtn:SetText("Save")
saveBtn:SetScript("OnClick", function()
    local name = assignF.currentPlayer
    if name then
        local clean = GetCleanName(name)
        local currentLvl = addon.roster[clean] and addon.roster[clean].level or 0
        addon.roster[clean] = { displayName = assignF.rawDisplayName or name, role = assignF.selectedRole, F1 = assignF.cbF1:GetChecked() and true or false, level = currentLvl }
        addon.unassignedQueueMap[clean] = nil
        table.remove(addon.unassignedQueueList, 1)
    end
    addon.UpdateTracker()
    addon.ProcessUnassignedQueue()
end)

function addon.ProcessUnassignedQueue()
    if not addon.isActive then
        assignF:Hide()
        return
    end

    if #addon.unassignedQueueList > 0 then
        local cleanName = addon.unassignedQueueList[1]
        local dispName = addon.unassignedQueueMap[cleanName] and addon.unassignedQueueMap[cleanName].displayName or cleanName
        assignF.currentPlayer = cleanName
        assignF.rawDisplayName = dispName
        assignF.title:SetText("Assign Role: " .. dispName)
        assignF.cbF1.text:SetText((APM_DB.tracker.f1Name or "Aura") .. " Active?")
        assignF.cbF1:SetChecked(false)
        addon.ApplyStyle(assignF)
        assignF:Show()
    else
        assignF:Hide()
        if addon.spamPaused and not IsRaidFull() and addon.isActive then
            addon.ApplyStyle(addon.resumeFrame)
            addon.resumeFrame:Show()
        end
    end
end

addon.resumeFrame = CreateFrame("Frame", "APM_ResumePopup", UIParent)
local resumeF = addon.resumeFrame
resumeF:SetSize(280, 100)
resumeF:SetPoint("CENTER", 0, 50)
resumeF:SetFrameStrata("DIALOG")
resumeF:Hide()

resumeF.text = resumeF:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
resumeF.text:SetPoint("TOP", 0, -20)
resumeF.text:SetText("Raid is no longer full.\nResume Auto-Spam?")

local yesBtn = CreateFrame("Button", nil, resumeF, "UIPanelButtonTemplate")
yesBtn:SetSize(60, 25)
yesBtn:SetPoint("BOTTOMLEFT", 40, 15)
yesBtn:SetText("Yes")
yesBtn:SetScript("OnClick", function()
    addon.spamPaused = false
    resumeF:Hide()
    print("|cff00ff00[APM] Auto-spam resumed.|r")
end)

local noBtn = CreateFrame("Button", nil, resumeF, "UIPanelButtonTemplate")
noBtn:SetSize(60, 25)
noBtn:SetPoint("BOTTOMRIGHT", -40, 15)
noBtn:SetText("No")
noBtn:SetScript("OnClick", function() resumeF:Hide() end)

-------------------------------------------------
-- OVERFLOW UI (Scrollable)
-------------------------------------------------
addon.overflowFrame = CreateFrame("Frame", "APM_OverflowFrame", UIParent)
local oframe = addon.overflowFrame
oframe:SetSize(270, 250)
oframe:SetPoint("CENTER")
oframe:SetMovable(true)
oframe:EnableMouse(true)
oframe:RegisterForDrag("LeftButton")
oframe:SetScript("OnDragStart", oframe.StartMoving)
oframe:SetScript("OnDragStop", oframe.StopMovingOrSizing)
oframe:Hide()

local oTitle = oframe:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
oTitle:SetPoint("TOP", 0, -15)
oTitle:SetText("Raid Overflow Queue")

local scrollFrame = CreateFrame("ScrollFrame", "APM_ScrollFrame", oframe, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -35)
scrollFrame:SetPoint("BOTTOMRIGHT", -35, 15)
local scrollChild = CreateFrame("Frame")
scrollChild:SetSize(220, 10)
scrollFrame:SetScrollChild(scrollChild)

oframe.rows = {}
local ROW_HEIGHT = 22

local function GetOrCreateRow(i)
    if not oframe.rows[i] then
        local row = CreateFrame("Frame", nil, scrollChild)
        row:SetSize(210, 20)
        row:SetPoint("TOPLEFT", 0, -((i-1) * ROW_HEIGHT))
        
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.text:SetPoint("LEFT", 5, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetWidth(140)
        row.text:SetWordWrap(false)
        
        row.btn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.btn:SetSize(60, 20)
        row.btn:SetPoint("RIGHT", 0, 0)
        row.btn:SetText("Invite")
        
        row.btn:SetScript("OnClick", function()
            if row.playerName then
                local clean = GetCleanName(row.playerName)
                SendChatMessage(APM_DB.invitePhrase, "WHISPER", nil, row.playerName)
                InviteUnit(row.playerName)
                
                addon.pendingInvites[clean] = {
                    displayName = row.playerName,
                    role = row.assignedRole,
                    F1 = row.hasF1,
                    time = GetTime()
                }
                
                for idx, entry in ipairs(addon.overflowQueue) do
                    if GetCleanName(entry.name) == clean then table.remove(addon.overflowQueue, idx); break end
                end
                addon.UpdateOverflow()
                addon.UpdateTracker()
            end
        end)
        oframe.rows[i] = row
    end
    return oframe.rows[i]
end

function addon.UpdateOverflow()
    addon.ApplyStyle(oframe)
    if not addon.isActive and #addon.overflowQueue == 0 then oframe:Hide(); return end
    if #addon.overflowQueue > 0 then oframe:Show() end
    
    for _, row in ipairs(oframe.rows) do row:Hide() end
    local totalHeight = 0
    
    for i, data in ipairs(addon.overflowQueue) do
        local row = GetOrCreateRow(i)
        local roleStr = table.concat(data.roles, "/")
        local flagDisplay = {}
        row.hasF1 = false
        for _, v in ipairs(data.flags) do
            if v == "F1" then table.insert(flagDisplay, "["..(APM_DB.tracker.f1Name or "Aura").."]"); row.hasF1 = true end
            if v == "F2" then table.insert(flagDisplay, "2nd") end
        end
        local flagStr = table.concat(flagDisplay, " ")
        
        row.text:SetText(string.format("[%s]: %s %s", data.name, roleStr, flagStr))
        row.playerName = data.name
        row.assignedRole = data.roles[1] or "D"
        row:Show()
        totalHeight = totalHeight + ROW_HEIGHT
    end
    scrollChild:SetHeight(math.max(totalHeight, 10))
end

-------------------------------------------------
-- EVENT LOGIC
-------------------------------------------------
coreFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            APM_DB = APM_DB or {}
            
            for k, v in pairs(defaultDB) do
                if type(v) == "table" then
                    APM_DB[k] = APM_DB[k] or {}
                    for subK, subV in pairs(v) do
                        if APM_DB[k][subK] == nil then APM_DB[k][subK] = subV end
                    end
                else
                    if APM_DB[k] == nil then APM_DB[k] = v end
                end
            end
            
            addon.UpdateMinimapButton()
            addon.UpdateTracker()
            print("|cff00ff00Auto PuG Manager loaded. Type /apm to open options.|r")
        end

    elseif event == "CHAT_MSG_WHISPER" then
        if not addon.isActive then return end
        local msg, sender = ...
        local rawSender = strsplit("-", sender)
        local cleanSender = GetCleanName(sender)
        
        if addon.roster[cleanSender] or addon.pendingInvites[cleanSender] then return end
        
        local roles, flags = ParseWhisper(msg)
        if #roles == 0 then return end
        
        local totalRaid = GetNumRaidMembers()
        local totalParty = GetNumPartyMembers()
        if totalRaid >= 40 then return end
        
        local counts = addon.GetCurrentRoleCounts()
        local invited = false
        local assignedRole = nil

        local flagsOK = true
        if APM_DB.requireF1 and not flags.F1 then flagsOK = false end
        if APM_DB.requireF2 and not flags.F2 then flagsOK = false end

        for _, role in ipairs(roles) do
            local limit = APM_DB.limits[role]
            if limit and limit > 0 and counts[role] < limit and flagsOK then
                assignedRole = role
                invited = true
                break
            end
        end

        if invited and not IsRaidFull() then
            InviteUnit(rawSender)
            addon.pendingInvites[cleanSender] = {
                displayName = rawSender,
                role = assignedRole,
                F1 = flags.F1 and true or false,
                time = GetTime()
            }
            addon.UpdateTracker()
            if totalParty > 0 and totalRaid == 0 then ConvertToRaid() end
        else
            local exists = false
            for _, entry in ipairs(addon.overflowQueue) do
                if GetCleanName(entry.name) == cleanSender then
                    entry.time = GetTime(); entry.roles = roles
                    local newFlags = {}
                    if flags.F1 then table.insert(newFlags, "F1") end
                    if flags.F2 then table.insert(newFlags, "F2") end
                    entry.flags = newFlags
                    exists = true; break
                end
            end
            
            if not exists then
                local newFlags = {}
                if flags.F1 then table.insert(newFlags, "F1") end
                if flags.F2 then table.insert(newFlags, "F2") end
                table.insert(addon.overflowQueue, { name = rawSender, time = GetTime(), roles = roles, flags = newFlags })
                if APM_DB.autoResponse and APM_DB.autoResponse ~= "" then
                    SendChatMessage(APM_DB.autoResponse, "WHISPER", nil, rawSender)
                end
            end
            addon.UpdateOverflow()
        end

    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        local currentMembers = {} 
        local numRaid = GetNumRaidMembers()
        local numParty = GetNumPartyMembers()
        
        if numRaid > 0 then
            for i = 1, numRaid do
                local n = UnitName("raid"..i)
                if n then
                    local clean = GetCleanName(n)
                    currentMembers[clean] = { displayName = strsplit("-", n), level = UnitLevel("raid"..i) or 0 }
                end
            end
        elseif numParty > 0 then
            for i = 1, numParty do
                local n = UnitName("party"..i)
                if n then
                    local clean = GetCleanName(n)
                    currentMembers[clean] = { displayName = strsplit("-", n), level = UnitLevel("party"..i) or 0 }
                end
            end
            local pName = UnitName("player")
            if pName then
                local clean = GetCleanName(pName)
                currentMembers[clean] = { displayName = strsplit("-", pName), level = UnitLevel("player") or 0 }
            end
        else
            local pName = UnitName("player")
            if pName then
                local clean = GetCleanName(pName)
                currentMembers[clean] = { displayName = strsplit("-", pName), level = UnitLevel("player") or 0 }
            end
        end
        
        for cleanName, data in pairs(addon.pendingInvites) do
            if currentMembers[cleanName] then
                addon.roster[cleanName] = {
                    displayName = data.displayName or currentMembers[cleanName].displayName,
                    role = data.role,
                    F1 = data.F1,
                    level = currentMembers[cleanName].level
                }
                addon.pendingInvites[cleanName] = nil
            end
        end
        
        for cleanName in pairs(addon.roster) do
            if not currentMembers[cleanName] then addon.roster[cleanName] = nil end
        end
        
        for cleanName, info in pairs(currentMembers) do
            if addon.roster[cleanName] then
                addon.roster[cleanName].level = info.level
            elseif addon.isActive and not addon.pendingInvites[cleanName] and not addon.unassignedQueueMap[cleanName] then
                table.insert(addon.unassignedQueueList, cleanName)
                addon.unassignedQueueMap[cleanName] = { displayName = info.displayName }
            end
        end
        
        if addon.isActive then
            if not addon.assignFrame:IsShown() then
                addon.ProcessUnassignedQueue()
            end
        else
            addon.unassignedQueueList = {}
            addon.unassignedQueueMap = {}
            if addon.assignFrame:IsShown() then addon.assignFrame:Hide() end
        end
        
        addon.UpdateTracker()
    end
end)

-------------------------------------------------
-- BACKGROUND TIMER & SPAM INJECTION
-------------------------------------------------
coreFrame:SetScript("OnUpdate", function(self, elapsed)
    if not addon.isActive then return end
    
    levelUpdateTimer = levelUpdateTimer + elapsed
    if levelUpdateTimer >= 5.0 then
        levelUpdateTimer = 0
        addon.RefreshRosterLevels()
    end
    
    timerAccumulator = timerAccumulator + elapsed
    if timerAccumulator >= 1.0 then
        timerAccumulator = 0
        local now = GetTime()
        
        if IsRaidFull() and not addon.spamPaused then
            addon.spamPaused = true
            print("|cff00ff00[APM] Limits reached! Auto-spam paused. Continuing to queue whispers.|r")
        end
        
        local expireSecs = APM_DB.overflowExpireMins * 60
        local cleaned = false
        for i = #addon.overflowQueue, 1, -1 do
            if (now - addon.overflowQueue[i].time) > expireSecs then
                table.remove(addon.overflowQueue, i); cleaned = true
            end
        end
        if cleaned then addon.UpdateOverflow() end

        local intervalSecs = APM_DB.spam.intervalSecs or 0
        if intervalSecs > 0 and (now - lastSpamTime) >= intervalSecs and not addon.spamPaused then
            lastSpamTime = now
            
            local spamMsg = APM_DB.spam.text
            if string.find(spamMsg, "%%STATS%%") then
                local c = addon.GetCurrentRoleCounts()
                local l = APM_DB.limits
                local statsStr = {}
                if l.T and l.T > 0 then table.insert(statsStr, string.format("Tanks: %d/%d", c.T, l.T)) end
                if l.H and l.H > 0 then table.insert(statsStr, string.format("Heal: %d/%d", c.H, l.H)) end
                if l.D and l.D > 0 then
                    table.insert(statsStr, string.format("DPS: %d/%d", c.D, l.D))
                else
                    if l.mD and l.mD > 0 then table.insert(statsStr, string.format("mDPS: %d/%d", c.mD, l.mD)) end
                    if l.rD and l.rD > 0 then table.insert(statsStr, string.format("rDPS: %d/%d", c.rD, l.rD)) end
                end
                if APM_DB.tracker.trackF1 then
                    table.insert(statsStr, string.format("%s: %d/%d", APM_DB.tracker.f1Name or "Aura", c.F1, l.F1 or 0))
                end
                
                spamMsg = string.gsub(spamMsg, "%%STATS%%", table.concat(statsStr, " - "))
            end
            
            local channelTarget = APM_DB.spam.channel
            local channelID = GetChannelName(channelTarget)
            if channelID > 0 then
                SendChatMessage(spamMsg, "CHANNEL", nil, channelID)
            else
                local numTarget = tonumber(channelTarget)
                if numTarget then
                    SendChatMessage(spamMsg, "CHANNEL", nil, numTarget)
                else
                    print("|cffff0000[APM] Error: Could not find chat channel: " .. tostring(channelTarget) .. "|r")
                end
            end
        end
    end
end)

-------------------------------------------------
-- SLASH COMMANDS
-------------------------------------------------
function addon.PrintRole(roleCode, roleName)
    local players = {}
    for cleanName, data in pairs(addon.roster) do
        if data.role == roleCode or (roleCode == "D" and (data.role == "mD" or data.role == "rD" or data.role == "D")) then
            table.insert(players, data.displayName or cleanName)
        end
    end
    if #players == 0 then
        print("|cff00ff00[APM]|r No " .. roleName .. " in roster.")
    else
        print("|cff00ff00[APM]|r " .. roleName .. " ("..#players.."): " .. table.concat(players, ", "))
    end
end

SLASH_APM1 = "/apm"
SlashCmdList["APM"] = function(msg)
    msg = string.lower(strtrim(msg))
    if msg == "" then
        if addon.MainUI then
            if addon.MainUI:IsShown() then
                addon.MainUI:Hide()
            else
                addon.ApplyStyle(addon.MainUI)
                addon.MainUI:Show()
            end
        end
    elseif msg == "button" then
        APM_DB.minimap.hide = not APM_DB.minimap.hide
        addon.UpdateMinimapButton()
        print("|cff00ff00[APM]|r Minimap button " .. (APM_DB.minimap.hide and "hidden." or "shown."))
    elseif msg == "t" or msg == "tank" or msg == "tanks" then
        addon.PrintRole("T", "Tanks")
    elseif msg == "h" or msg == "heal" or msg == "healer" or msg == "healers" then
        addon.PrintRole("H", "Healers")
    elseif msg == "md" or msg == "mdps" or msg == "melee" then
        addon.PrintRole("mD", "Melee DPS")
    elseif msg == "rd" or msg == "rdps" or msg == "ranged" then
        addon.PrintRole("rD", "Ranged DPS")
    elseif msg == "d" or msg == "dps" then
        addon.PrintRole("D", "Any DPS")
    else
        print("|cff00ff00[APM] Commands:|r")
        print("  /apm - Toggle Options UI")
        print("  /apm button - Toggle Minimap Button")
        print("  /apm <tank, heal, mdps, rdps, dps> - List roster by role")
    end
end
