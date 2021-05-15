-- "Ding" sound made by Aiwha. 
-- https://freesound.org/people/Aiwha/sounds/196106/
-- CC BY 3.0 https://creativecommons.org/licenses/by/3.0/

TinyLootMonitor = LibStub("AceAddon-3.0"):NewAddon("TinyLootMonitor", "AceConsole-3.0")
local a = TinyLootMonitor
local L = LibStub("AceLocale-3.0"):GetLocale("TinyLootMonitor")

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("sound", "Ding", "Interface\\AddOns\\TinyLootMonitor\\ding.ogg")

local itemColors = ITEM_QUALITY_COLORS
local toastHeight = 60
local fL = {}
local nLoot = 1
local addonName = "|c002FC5D0TLM:|r"

local defaults = {
    profile = {
        rarity = 3,
        numMax = 5,
        delay = 5,
        sound = "Ding",
        equipable = false,
        banlist = {},
    },
}

local options = {
    type = "group",
    args = {
        description = {
            type = "description",
            name = L["A loot monitor that tracks yours and group's loot."],
            fontSize = "medium",
            order = 5,
        },
        rarity = {
            name = L["Rarity"],
            desc = L["Sets the minimum rarity TinyLootMonitor will track."],
            type = "select",
            values = { 
                [0] = itemColors[0].hex .. ITEM_QUALITY0_DESC, 
                [1] = itemColors[1].hex .. ITEM_QUALITY1_DESC, 
                [2] = itemColors[2].hex .. ITEM_QUALITY2_DESC, 
                [3] = itemColors[3].hex .. ITEM_QUALITY3_DESC, 
                [4] = itemColors[4].hex .. ITEM_QUALITY4_DESC,
                [5] = itemColors[5].hex .. ITEM_QUALITY5_DESC,
                [6] = itemColors[6].hex .. ITEM_QUALITY6_DESC, 
            },
            style = "dropdown",
            get = function(info) return a.db.profile.rarity end,
            set = function(info, val) a.db.profile.rarity = val end,
            order = 10,
        },
        numMax = {
            name = L["Maximum"],
            desc = L["Sets the maximum number of toasts that will appear on screen."],
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
            name = L["Delay"],
            desc = L["Time (in seconds) the toast will stay on screen. Set it to 0 for sticky toasts."],
            type = "range",
            min = 0,
            max = toastHeight,
            softMin = 0,
            softMax = toastHeight,
            step = 1,
            get = function(info) return a.db.profile.delay end,
            set = function(info,value) a.db.profile.delay = value end,
            order = 30,
        },
        anchor = {
            name = L["Show/Hide anchor"],
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
        sound = {
            name = L["Sound"],
            desc = L["The sound that plays when the toast appears."],
            type = "select",
            dialogControl = "LSM30_Sound",
            values = LSM:HashTable("sound"),
            get = function(info) return a.db.profile.sound end,
            set = function(info,value) a.db.profile.sound = value end,
            order = 35,
        },
        equipable = {
            name = L["Equipable only"],
            desc = L["Display only equipable items."],
            type = "toggle",
            get = function(info) return a.db.profile.equipable end,
            set = function(info, value) a.db.profile.equipable = value end,
            order = 50,
        },
        banGroup = {
            type = "group",
            name = L["Ban list"],
            guiInline = true,
            order = 1000,
            args = {
                banList = {
                    name = L["Items"],
                    type = "multiselect",
                    values = function()
                        items = {}
                        for k in pairs(a.db.profile.banlist) do
                            local name = GetItemInfo(k)
                            items[k] = name
                        end
                        return items
                    end,
                    get = function(info, key) return a.db.profile.banlist[key] end,
                    set = function(info, key, value) a.db.profile.banlist[key] = value end,
                    order = 1010,
                },
                clear = {
                    name = L["Clear unmarked"],
                    desc = L["Will remove from banlist every unmarked item."],
                    type = "execute",
                    order = 1020,
                    func = function()
                        for k,v in pairs(a.db.profile.banlist) do
                            if v == false then
                                a.db.profile.banlist[k] = nil
                            end
                        end
                    end,
                },
            },
        },
    },
}

local db
function a:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("TinyLootMonitorDB", defaults)
    db = self.db.profile
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TinyLootMonitor", options)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TinyLootMonitor/Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TinyLootMonitor")
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TinyLootMonitor/Profiles", L["Profiles"], "TinyLootMonitor")
    TinyLootMonitorScrollFrame:SetHeight((toastHeight + 5) * db.numMax)
    self:RegisterChatCommand("tlm", function() LibStub("AceConfigDialog-3.0"):Open("TinyLootMonitor") end)
end

local function GetKey(tab, value)
    for k,v in pairs(tab) do
        if v == value then
            return k
        end
    end
end

local function LootInfo(...)
    local info        = {...}
    local link        = info[1]:match("(|c.+|r)")
    local guid        = info[12]
    local player      = info[2]
    local class       = select(2, GetPlayerInfoByGUID(guid))
    local classColor  = C_ClassColor.GetClassColor(class)
    local classPlayer = classColor:WrapTextInColorCode(player)
    local icon        = select(10, GetItemInfo(link))
    local rarity      = select(3, GetItemInfo(link))
    local quantity    = info[1]:match("x(%d*)\.$")
    local itemID      = info[1]:match("item:(%d*):")
    return icon, player, classPlayer, link, rarity, quantity, itemID
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
anchor.text = anchor:CreateFontString(nil, "ARTWORK", "GameFontNormal")
anchor.text:SetText(L["TinyLootMonitor Anchor"])
anchor.text:SetPoint("CENTER")
anchor:Hide()

local function FrameCreation(fPool)
    local f = CreateFrame("Frame", nil, nil, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background-Maw",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border-Maw",
        tile = true,
        tileEdge = true,
        tileSize = 20,
        edgeSize = 20,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetSize(250,toastHeight)
    f:SetFrameStrata("HIGH")
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(38,38)
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
m:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local icon, player, classPlayer, link, rarity, quantity, itemID = LootInfo(...)
        if db.equipable and not IsEquippableItem(link) then return else
            if itemID and rarity and rarity >= db.rarity and not db.banlist[itemID] then
                fL[#fL+1] = pool:Acquire()
                mf:SetHeight(mf:GetHeight() + fL[#fL]:GetHeight() + 5)
                fL[#fL]:SetParent(mf)
                fL[#fL].icon:SetTexture(icon)
                fL[#fL].name:SetText(classPlayer)
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
                    GameTooltip:AddDoubleLine(L["Left click"], L["Equip item"], 0,1,0)
                    GameTooltip:AddDoubleLine(L["Right click"], L["Dismiss"], 0,1,0)
                    GameTooltip:AddDoubleLine(L["Shift+Right click"], L["Whisper player"], 0,1,0)
                    GameTooltip:AddDoubleLine(L["Ctrl+Left click"], L["Dress item"], 0,1,0)
                    GameTooltip:AddDoubleLine(L["Shift+Left click"], L["Link item"], 0,1,0)
                    GameTooltip:AddDoubleLine(L["Middle click"], L["Add to the ban list"], 0,1,0)
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
                    elseif button == "LeftButton" and IsEquippableItem(link) and not InCombatLockdown() then
                        EquipItemByName(link)
                    elseif button == "LeftButton" and IsControlKeyDown() then
                        DressUpLink(link)
                    elseif button == "LeftButton" and IsShiftKeyDown() then
                        ChatEdit_InsertLink(link)
                    elseif button == "MiddleButton" then
                        db.banlist[itemID] = true
                        mf:SetHeight(mf:GetHeight() - self:GetHeight() - 5)
                        pool:Release(self)
                        SortStack(pool, fL, anchor)
                        print(format("%s %s", addonName, L["item added to the ban list."]))
                    end
                end)
                PlaySoundFile(LSM:Fetch("sound", db.sound))
                fL[#fL]:Show()
            end
        end
    end
end)