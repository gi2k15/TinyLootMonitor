local fL = {}
local nLoot = 1

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background-Maw",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border-Maw",
	tile = true,
	tileEdge = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
};

local function GetLoot(...)
    local info = {...}
    local link = info[1]:match("(|c.+|r)")
    local guid = info[12]
    local player = select(6, GetPlayerInfoByGUID(guid))
    local class = select(2, GetPlayerInfoByGUID(guid))
    local classColor = C_ClassColor.GetClassColor(class)
    player = classColor:WrapTextInColorCode(player)
    local icon = select(10, GetItemInfo(link))
    local itemID = info[1]:match("item:(%d*)")
    local quality = select(3, GetItemInfo(link))
    return icon, player, link, itemID, quality
end

local function SortStack(fPool, fList, fAnchor)
    wipe(fList)
    local i = 1
    for widget in fPool:EnumerateActive() do
        fList[i] = widget
        i = i + 1
    end
    if fList[1] == nil then return fList end
    sort(fList, function(a,b) return a.sec < b.sec end)
    if #fList == 1 then
        fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
    else
        fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
        for i = 2, #fList do
            fList[i]:SetPoint("TOPLEFT", fList[i-1], "BOTTOMLEFT", 0, -5)
        end
    end
end

local function SetToastTooltip(frame, item)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
        GameTooltip:SetItemByID(item)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
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
anchor.text = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormalOutline")
anchor.text:SetText("Anchor")
anchor.text:SetPoint("CENTER")
anchor:Hide()

local function FrameCreation(fPool)
    local f = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    f:SetBackdrop(backdrop)
    f:SetPoint("CENTER")
    f:SetSize(200,50)
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            fPool:Release(f)
            SortStack(fPool, fL, anchor)
        end
    end)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(30,30)
    f.icon:SetPoint("LEFT", f, "LEFT", 10, 0)
    f.name = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallLeft")
    f.name:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 5, -3)
    f.item = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallLeft")
    f.item:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -2)
    return f
end

local function FrameResetter(fPool, frame)
    frame:Hide()
    --SortStack(fPool, fL, anchor)
end

local pool = CreateObjectPool(FrameCreation, FrameResetter)

--[[fL[1] = pool:Acquire()
SortStack(pool, fL, anchor)
fL[1]:Show()
fL[1].icon:SetTexture(132089)]]

local m = CreateFrame("Frame")
m:RegisterEvent("CHAT_MSG_LOOT")
m:SetScript("OnEvent", function(self, event, ...)
    local icon, player, link, itemID, quality = GetLoot(...)
    if quality >= 0 then
        fL[#fL+1] = pool:Acquire()
        fL[#fL].icon:SetTexture(icon)
        fL[#fL].name:SetText(player)
        fL[#fL].item:SetText(link)
        SetToastTooltip(fL[#fL], itemID)
        fL[#fL]:Show()
        fL[#fL].sec = nLoot
        nLoot = nLoot + 1
        SortStack(pool, fL, anchor)
    end
end)