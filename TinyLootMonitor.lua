-- "Ding" sound made by Aiwha. 
-- https://freesound.org/people/Aiwha/sounds/196106/
-- CC BY 3.0 https://creativecommons.org/licenses/by/3.0/

local defaults = {
    __index = {
        rarity = 2,
    }
}

local rarity = {
    poor = 0,
    common = 1,
    uncommon = 2,
    rare = 3,
    epic = 4,
    legendary = 5,
    artifact = 6,
}

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background-Maw",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border-Maw",
	tile = true,
	tileEdge = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local fL = {}
local nLoot = 1
local addonName = "|c002FC5D0TLM:|r"

local function GetKey(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
end

local function LootInfo(...)
    local info = {...}
    local link = info[1]:match("(|c.+|r)")
    local guid = info[12]
    local player = select(6, GetPlayerInfoByGUID(guid))
    local class = select(2, GetPlayerInfoByGUID(guid))
    local classColor = C_ClassColor.GetClassColor(class)
    local cPlayer = classColor:WrapTextInColorCode(player)
    local icon = select(10, GetItemInfo(link))
    local itemID = info[1]:match("item:(%d*)")
    local quality = select(3, GetItemInfo(link))
    return icon, player, cPlayer, link, itemID, quality
end

local function SortStack(fPool, fList, fAnchor)
    wipe(fList)
    local i = 1
    for widget in fPool:EnumerateActive() do
        fList[i] = widget
        i = i + 1
    end
    if fList[1] == nil then return end
    sort(fList, function(a,b) return a.sec < b.sec end)
    fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
    if #fList > 1 then
        for i = 2, #fList do
            fList[i]:SetPoint("TOPLEFT", fList[i-1], "BOTTOMLEFT", 0, -5)
        end
    end
end

local function SlashHandler(text)
    local command, value = text:match("^(%S*)%s*(.-)$")
    if command == "rarity" then
        value = rarity[strlower(value)] or tonumber(value)
        if value then
            TinyLootMonitorDB.rarity = value
            print(format("%s rarity set to %s.", addonName, GetKey(rarity, value)))
        else
            print(format("%s invalid rarity.", addonName))
        end
    elseif command == "anchor" then
        if TinyLootMonitorAnchor:IsShown() then
            TinyLootMonitorAnchor:Hide()
        else
            TinyLootMonitorAnchor:Show()
        end
    else
        print(format("%s commands:", addonName))
        print(format(" |c0000FF00- rarity:|r sets the minimum (and above) rarity TLM should monitor."))
    end
end

--[[local function AnimateFrame(frame, outOnly)
    local groupFI = frame:CreateAnimationGroup()
    local fadeIn = groupFI:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.3)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(1.5)
    fadeIn:SetSmoothing("IN")
    local groupFO = frame:CreateAnimationGroup()
    local fadeOut = groupFO:CreateAnimation("Alpha")
    fadeOut:SetStartDelay(3)
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(1)
    fadeOut:SetSmoothing("OUT")
    groupFO:SetToFinalAlpha()
    if not outOnly then
        groupFI:Play()
        groupFO:Play()
    else
        groupFI:Stop()
        groupFO:Play()
    end
    return group
end]]

local anchor = CreateFrame("Frame", "TinyLootMonitorAnchor")
anchor:SetPoint("CENTER")
anchor:SetSize(200,20)
anchor:EnableMouse(true)
anchor:SetMovable(true)
anchor:SetScript("OnMouseDown", function(self) self:StartMoving() end)
anchor:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
anchor.bg = anchor:CreateTexture(nil, "BACKGROUND")
anchor.bg:SetAllPoints()
anchor.bg:SetColorTexture(0,1,0,0.2)
anchor.text = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
anchor.text:SetText("TinyLootMonitor Anchor")
anchor.text:SetPoint("CENTER")
anchor:Hide()

local function FrameCreation(fPool)
    local f = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    f:SetBackdrop(backdrop)
    f:SetPoint("CENTER")
    f:SetSize(200,50)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(30,30)
    f.icon:SetPoint("LEFT", f, "LEFT", 10, 0)
    f.name = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallLeft")
    f.name:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 5, 0)
    f.name:SetWidth(148)
    f.name:SetHeight(16)
    f.name:SetNonSpaceWrap(false)
    f.item = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallLeft")
    f.item:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, 2)
    f.item:SetWidth(148)
    f.item:SetHeight(16)
    f.sec = nLoot
    nLoot = nLoot + 1
    return f
end

local function FrameResetter(fPool, frame)
    frame:Hide()
end

local pool = CreateObjectPool(FrameCreation, FrameResetter)

-- Monitor
local m = CreateFrame("ScrollFrame")
m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
m:SetHeight(50 * 2 + 10)
m:Show()
local mf = CreateFrame("Frame")
m:SetScrollChild(mf)
mf:SetWidth(m:GetWidth())
m:RegisterEvent("CHAT_MSG_LOOT")
m:RegisterEvent("ADDON_LOADED")
m:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local icon, player, cPlayer, link, itemID, quality = LootInfo(...)
        if quality >= TinyLootMonitorDB.rarity then
            fL[#fL+1] = pool:Acquire()
            mf:SetHeight(mf:GetHeight() + 55)
            fL[#fL]:SetParent(mf)
            fL[#fL].icon:SetTexture(icon)
            fL[#fL].name:SetText(cPlayer)
            fL[#fL].item:SetText(link)
            SortStack(pool, fL, anchor)
            fL[#fL]:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT")
                GameTooltip:SetHyperlink(link)
                GameTooltip:Show()
            end)
            fL[#fL]:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            fL[#fL]:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" and IsShiftKeyDown() then
                    SendChatMessage("Do you need " .. link .. "?", "WHISPER", nil, player)
                elseif button == "LeftButton" and IsControlKeyDown() then
                    SendChatMessage("Roll for " .. link, "INSTANCE_CHAT")
                elseif button == "RightButton" then
                    mf:SetHeight(mf:GetHeight() - 55)
                    pool:Release(self)
                    SortStack(pool, fL, anchor)
                end
            end)
            PlaySoundFile("Interface\\AddOns\\TinyLootMonitor\\ding.ogg")
            fL[#fL]:Show()
        end
    elseif event == "ADDON_LOADED" then
        TinyLootMonitorDB = TinyLootMonitorDB or {}
        setmetatable(TinyLootMonitorDB, defaults)
    end
end)

-- Slash commands
SLASH_TINYLOOTMONITOR1, SLASH_TINYLOOTMONITOR2 = "/tinylootmonitor", "/tlm"
SlashCmdList["TINYLOOTMONITOR"] = SlashHandler