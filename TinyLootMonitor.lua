local frameList = {}

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background-Maw",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border-Maw",
	tile = true,
	tileEdge = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
};

local function SortStack(fPool, fList, fAnchor)
    wipe(fList)
    local i = 1
    for widget in fPool:EnumerateActive() do
        fList[i] = widget
        i = i + 1
    end
    sort(fList, function(a,b) return a.sec < b.sec end)
    if #fList == 1 then
        fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
    else
        fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
        for i = 2, #fList do
            fList[i]:SetPoint("TOPLEFT", fList[i-1], "BOTTOMLEFT", 0, -5)
        end
    end
    return fList
end

local anchor = CreateFrame("Frame", "TinyLootMonitorAnchor")
anchor:SetPoint("CENTER")
anchor:SetSize(150,20)
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

local function FrameCreation(fPool)
    local f = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    f:SetBackdrop(backdrop)
    f:SetPoint("CENTER")
    f:SetSize(150,40)
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            fPool:Release(f)
            frameList = SortStack(fPool, frameList, anchor)
        end
    end)
    f.text = f:CreateFontString(nil, "ARTWORK", "GameFontNormalSmallLeft")
    f.text:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -5)
    f.sec = GetTimePreciseSec()
    return f
end

local function FrameResetter(fPool, frame)
    frame:Hide()
end

local pool = CreateObjectPool(FrameCreation, FrameResetter)

for i = 1, 5 do
    frameList[i] = pool:Acquire()
    frameList[i].text:SetText(i)
end

frameList = SortStack(pool, frameList, anchor)

for k,v in pairs(frameList) do v:Show() end