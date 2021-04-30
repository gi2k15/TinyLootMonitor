-- "Ding" sound made by Aiwha. 
-- https://freesound.org/people/Aiwha/sounds/196106/
-- CC BY 3.0 https://creativecommons.org/licenses/by/3.0/

TinyLootMonitor = LibStub("AceAddon-3.0"):NewAddon("TinyLootMonitor")
local a = TinyLootMonitor

local defaults = {
    profile = {
        rarity = 3,
        numMax = 5,
        delay = 5,
    },
}

local options = {
    type = "group",
    args = {
        rarity = {
            name = "Rarity",
            desc = "Sets the minimum rarity TinyLootMonitor will track.",
            type = "select",
            values = { 
                [0] = "Poor", 
                [1] = "Common", 
                [2] = "Uncommon", 
                [3] = "Rare", 
                [4] = "Epic",
                [5] = "Legendary",
                [6] = "Artifact" 
            },
            style = "dropdown",
            get = function(info) return a.db.rarity end,
            set = function(info, val) a.db.rarity = val end,
            order = 10,
        },
        numMax = {
            name = "Maximum",
            desc = "Sets the maximum number of toasts that will appear on screen.",
            type = "range",
            min = 1,
            max = 10,
            step = 1,
            softMin = 1,
            softMax = 10,
            get = function(info) return a.db.profile.numMax end,
            set = function(info, value) a.db.profile.numMax = value end,
            order = 20,
        },
        delay = {
            name = "Delay",
            desc = "Time (in seconds) the toast will stay on screen. Set it to 0 for sticky toasts.",
            type = "range",
            min = 0,
            max = 60,
            softMin = 0,
            softMax = 60,
            step = 1,
            get = function(info) return a.db.delay end,
            set = function(info,value) a.db.delay = value end,
            order = 30,
        },
        anchor = {
            name = "Show/Hide anchor",
            type = "execute",
            func = function()
                if TinyLootMonitorAnchor:IsShown() then
                    TinyLootMonitorAnchor:Hide()
                else
                    TinyLootMonitorAnchor:Show()
                end
            end,
            order = 40,            
        },
    },
}

local db
function a:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("TinyLootMonitorDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TinyLootMonitor", options)
    --profiles.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    local bliz = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TinyLootMonitor")
    --InterfaceOptionsFrame_OpenToCategory(bliz)
    db = a.db.profile
    DevTools_Dump(db)
end

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background-Maw",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border-Maw",
	tile = true,
	tileEdge = true,
	tileSize = 20,
	edgeSize = 20,
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
    local player = info[2]
    local class = select(2, GetPlayerInfoByGUID(guid))
    local classColor = C_ClassColor.GetClassColor(class)
    local cPlayer = classColor:WrapTextInColorCode(player)
    local icon = select(10, GetItemInfo(link))
    local rarity = select(3, GetItemInfo(link))
    local quantity = info[1]:match("x(%d*)\.$")
    return icon, player, cPlayer, link, rarity, quantity
end

local function SortStack(fPool, fList, fAnchor)
    wipe(fList)
    local i = 1
    for widget in fPool:EnumerateActive() do
        fList[i] = widget
        i = i + 1
    end
    if fList[1] == nil then return end
    sort(fList, function(a,b) return a.order < b.order end)
    fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
    if #fList > 1 then
        for i = 2, #fList do
            fList[i]:SetPoint("TOPLEFT", fList[i-1], "BOTTOMLEFT", 0, -5)
        end
    end
end

local function AnimateFrame(sChild, fPool, fList, fAnchor, delay)
    local group = fList[#fList]:CreateAnimationGroup()
    local fadeOut = group:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(1)
    fadeOut:SetSmoothing("OUT")
    fadeOut:SetStartDelay(delay)
    group:SetScript("OnFinished", function()
        sChild:SetHeight(sChild:GetHeight() - 55)
        fPool:Release(fList[#fList])
        SortStack(fPool, fList, fAnchor)
    end)
    return group
end

local anchor = CreateFrame("Frame", "TinyLootMonitorAnchor", UIParent)
anchor:SetSize(250,20)
anchor:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -224, -132)
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
    f:SetSize(250,60)
    f:SetFrameStrata("HIGH")
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(40,40)
    f.icon:SetPoint("LEFT", f, "LEFT", 10, 0)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.name = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLeft")
    f.name:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 5, 0, -2)
    f.name:SetWidth(185)
    f.name:SetHeight(16)
    f.item = f:CreateFontString(nil, "ARTWORK", "GameFontNormalLeft")
    f.item:SetPoint("BOTTOMLEFT", f.icon, "BOTTOMRIGHT", 5, 2)
    f.item:SetWidth(185)
    f.item:SetHeight(16)
    f.quantity = f:CreateFontString(nil, "ARTWORK", "GameFontNormalOutline")
    f.quantity:SetTextColor(1,1,0)
    f.quantity:SetJustifyH("RIGHT")
    f.quantity:SetPoint("BOTTOMRIGHT", f.icon, "BOTTOMRIGHT", -2, 2)
    return f
end

local function FrameResetter(fPool, frame)
    frame:Hide()
end

local pool = CreateObjectPool(FrameCreation, FrameResetter)

-- Monitor
local m = CreateFrame("ScrollFrame", "TinyLootMonitorScrollFrame", UIParent)
m:SetFrameStrata("HIGH")
m:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT")
m:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT")
m:Show()
local mf = CreateFrame("Frame", "TinyLootMonitorScrollChild")
m:SetScrollChild(mf)
mf:SetWidth(m:GetWidth())
m:RegisterEvent("CHAT_MSG_LOOT")
m:RegisterEvent("PLAYER_LOGIN")
m:RegisterEvent("PLAYER_LOGOUT")
m:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local icon, player, cPlayer, link, rarity, quantity = LootInfo(...)
        if rarity >= db.rarity then
            fL[#fL+1] = pool:Acquire()
            mf:SetHeight(mf:GetHeight() + fL[#fL]:GetHeight() + 5)
            fL[#fL]:SetParent(mf)
            fL[#fL].icon:SetTexture(icon)
            fL[#fL].name:SetText(cPlayer)
            fL[#fL].item:SetText(link)
            fL[#fL].quantity:SetText(quantity)
            fL[#fL].order = nLoot
            nLoot = nLoot + 1
            SortStack(pool, fL, anchor)
            local anim = AnimateFrame(mf, pool, fL, anchor, db.delay)
            if db.delay > 0 then anim:Play() end
            fL[#fL]:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_NONE")
                GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT")
                GameTooltip:SetHyperlink(link)
                GameTooltip:AddLine(" ")
                GameTooltip:AddDoubleLine("Right click", "Dismiss", 0,1,0)
                GameTooltip:AddDoubleLine("Shift+Right click", "Whisper player", 0,1,0)
                GameTooltip:AddDoubleLine("Ctrl+Left click", "Dress item", 0,1,0)
                GameTooltip:AddDoubleLine("Shift+Left click", "Link item", 0,1,0)
                GameTooltip:Show()
                anim:Stop()
            end)
            fL[#fL]:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                if db.delay > 0 then anim:Play() end
            end)
            fL[#fL]:SetScript("OnMouseUp", function(self, button)
                if button == "RightButton" and IsShiftKeyDown() then
                    SendChatMessage("Do you need " .. link .. "?", "WHISPER", nil, player)
                elseif button == "RightButton" then
                    mf:SetHeight(mf:GetHeight() - self:GetHeight() - 5)
                    pool:Release(self)
                    SortStack(pool, fL, anchor)
                elseif button == "LeftButton" and IsControlKeyDown() then
                    DressUpLink(link)
                elseif button == "LeftButton" and IsShiftKeyDown() then
                    ChatEdit_InsertLink(link)
                end
            end)
            PlaySoundFile("Interface\\AddOns\\TinyLootMonitor\\ding.ogg")
            DevTools_Dump(pool)
            fL[#fL]:Show()
        end
    end
end)

-- Slash commands
local function SlashHandler(text)
    local command, value = text:match("^(%S*)%s*(.-)$")
    if command == "rarity" then
        value = rarity[strlower(value)] or tonumber(value)
        if value then
            db.rarity = value
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
    elseif command == "max" then
        value = tonumber(value)
        if value then
            m:SetHeight((60 + 5) * value) -- Change '60' to toast's height.
            db.numMax = value
            print(format("%s %s items will appear.", addonName, value))
        else
            db.numMax = 4
            print(format("%s invalid argument. Setting to 4.", addonName))
        end
    elseif command == "delay" then
        value = tonumber(value)
        if value and value >= 0 then
            db.delay = value
            ReloadUI() -- change it later for a better solution
        else
            print(format("%s delay is currently set to %s", addonName, db.value))
        end
    else
        print(format("%s commands:", addonName))
        print(" |c0000FF00- rarity <0-6||rarity>:|r sets the minimum (and above) rarity TLM should monitor.")
        print(" |c0000FF00- max <number>:|r sets the maximum number of items to appear.")
        print(" |c0000FF00- delay <number>:|r sets the time (in seconds) the items will stay on screen. You interface will be reloaded.")
        print(" |c0000FF00- anchor:|r shows the anchor.")
    end
end
SLASH_TINYLOOTMONITOR1, SLASH_TINYLOOTMONITOR2 = "/tinylootmonitor", "/tlm"
SlashCmdList["TINYLOOTMONITOR"] = SlashHandler