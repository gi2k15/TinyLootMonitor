-- "Ding" sound made by Aiwha. 
-- https://freesound.org/people/Aiwha/sounds/196106/
-- CC BY 3.0 https://creativecommons.org/licenses/by/3.0/

local wipe, sort, select, pcall, print, format, pairs = wipe, sort, select, pcall, print, format, pairs

TinyLootMonitor = LibStub("AceAddon-3.0"):NewAddon("TinyLootMonitor", "AceConsole-3.0")
local a = TinyLootMonitor
local L = LibStub("AceLocale-3.0"):GetLocale("TinyLootMonitor")

local LSM = LibStub("LibSharedMedia-3.0")
LSM:Register("sound", "Ding", "Interface\\AddOns\\TinyLootMonitor\\ding.ogg")

local itemColors = ITEM_QUALITY_COLORS
local tooltipColor = "#D4F1F4"
local toastHeight = 60
local fL = {}
local nLoot = 1
local addonName = "|c002FC5D0TLM:|r"

-- Icons and keys
local leftClick = CreateAtlasMarkup("newplayertutorial-icon-mouse-leftbutton", 14, 14)
local middleClick = CreateAtlasMarkup("newplayertutorial-icon-mouse-middlebutton", 14, 14)
local rightClick = CreateAtlasMarkup("newplayertutorial-icon-mouse-rightbutton", 14, 14)
local ctrl = CTRL_KEY_TEXT
local shift = SHIFT_KEY_TEXT

local gearOptions = {
    [2] = {                         -- Weapons
        [0]  = L["1H axe"],
        [1]  = L["2H axe"],
        [2]  = L["Bow"],
        [18] = L["Crossbow"],
        [15] = L["Dagger"],
        [20] = L["Fishing pole"],
        [13] = L["Fist weapon"],
        [3]  = L["Gun"],
        [4]  = L["1H mace"],
        [5]  = L["2H mace"],
        [6]  = L["Polearm"],
        [10] = L["Stave"],
        [7]  = L["1H sword"],
        [8]  = L["2H sword"],
        [16] = L["Thrown weapon"],
        [19] = L["Wand"],
        [9]  = L["Warglaive"],
        [17] = L["Spear"],
    },
    [4] = {                         -- Armor
        [1]  = L["Cloth"],
        [2]  = L["Leather"],
        [3]  = L["Mail"],
        [4]  = L["Plate"],
        [5]  = L["Cosmetic"],
        [6]  = L["Shield"],
        [11] = L["Relic"],
    },
    others = L["Others"],
}

local defaults = {
    profile = {
        rarity = 3,
        numMax = 5,
        delay = 5,
        sound = "Ding",
        equipable = false,
        hideloot = true,
        grow = "below",
        banlist = {},
        gearOptions = {
            ['**'] = {
                ['**'] = true,
            },
            others = true,
        },
    },
}

local options = {
    type = "group",
    childGroups = "tab",
    args = {
        description = {
            type = "description",
            name = L["A loot monitor that tracks yours and group's loot."],
            fontSize = "medium",
            order = 5,
        },
        general = {
            type = "group",
            name = L["General"],
            order = 1,
            args = {
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
                    set = function(info, value) a.db.profile.numMax = value; a:ChangeHeight() end,
                    order = 30,
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
                    set = function(info, value) 
                        a.db.profile.delay = value
                        wipe(a.pool)  
                        a.pool = CreateObjectPool(a.FrameCreation, a.FrameResetter) end,
                    order = 40,
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
                    order = 50,            
                },
                sound = {
                    name = L["Sound"],
                    desc = L["The sound that plays when the toast appears."],
                    type = "select",
                    dialogControl = "LSM30_Sound",
                    values = LSM:HashTable("sound"),
                    get = function(info) return a.db.profile.sound end,
                    set = function(info,value) a.db.profile.sound = value end,
                    order = 20,
                },
                grow = {
                    name = L["Display direction"],
                    desc = L["Sets if the toasts will display above or below the anchor."],
                    type = "select",
                    values = {
                        above = L["Above"],
                        below = L["Below"],
                    },
                    get = function(info) return a.db.profile.grow end,
                    set = function(info,value) a.db.profile.grow = value; a:ChangeAnchor(value) end,
                    order = 25,
                },
                hideloot = {
                    name = L["Hide Blizzard's loot window"],
                    type = "toggle",
                    get = function(info) return a.db.profile.hideloot end,
                    set = function(info, value) a.db.profile.hideloot = value end,
                    width = "double",
                    order = 60,
                    hidden = true,
                },
            },
        },
        gear = {
            type = "group",
            name = L["Gear"] .. " - BETA",
            order = 2,
            args = {
                armor = {
                    name = _G["ARMOR"],
                    type = "multiselect",
                    values = gearOptions[4],
                    get = function(info, key) return a.db.profile.gearOptions[4][key] end,
                    set = function(info, key, value) a.db.profile.gearOptions[4][key] = value end,
                    order = 10,
                },
                weapon = {
                    name = _G["WEAPON"],
                    type = "multiselect",
                    values = gearOptions[2],
                    get = function(info, key) return a.db.profile.gearOptions[2][key] end,
                    set = function(info, key, value) a.db.profile.gearOptions[2][key] = value end,
                    order = 20,
                },
                others = {
                    name = L["Others"],
                    desc = L["Shows everything that's not a weapon or armor."],
                    type = "toggle",
                    get = function(info) return a.db.profile.gearOptions.others end,
                    set = function(info, value) a.db.profile.gearOptions.others = value end,
                    order = 30,
                },
                equipable = {
                    name = L["Equipable only"],
                    desc = L["Display only equipable items."],
                    type = "toggle",
                    get = function(info) return a.db.profile.equipable end,
                    set = function(info, value) a.db.profile.equipable = value end,
                    width = "double",
                    order = 35,
                },
                enableAll = {
                    name = L["Enable all"],
                    type = "execute",
                    order = 40,
                    func = function()
                        for k,v in pairs(a.db.profile.gearOptions[2]) do
                            a.db.profile.gearOptions[2][k] = true
                        end
                        for k,v in pairs(a.db.profile.gearOptions[4]) do
                            a.db.profile.gearOptions[4][k] = true
                        end
                        a.db.profile.gearOptions.others = true
                    end
                },
                disableAll = {
                    name = L["Disable all"],
                    type = "execute",
                    order = 50,
                    func = function()
                        for k,v in pairs(a.db.profile.gearOptions[2]) do
                            a.db.profile.gearOptions[2][k] = false
                        end
                        for k,v in pairs(a.db.profile.gearOptions[4]) do
                            a.db.profile.gearOptions[4][k] = false
                        end
                        a.db.profile.gearOptions.others = false
                    end
                },
            },
        },
        banGroup = {
            type = "group",
            name = L["Ban list"],
            order = 3,
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
                    order = 10,
                },
                clear = {
                    name = L["Clear unmarked"],
                    desc = L["Will remove from banlist every unmarked item."],
                    type = "execute",
                    order = 20,
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
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TinyLootMonitor", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("TinyLootMonitor")

    -- Have to redefine db everytime the profile changes.
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    self:RegisterChatCommand("tlm", function() LibStub("AceConfigDialog-3.0"):Open("TinyLootMonitor") end)

    -- Setup the ScrollFrame
    self:ChangeHeight()
    self:ChangeAnchor(db.grow)
end

function a:RefreshConfig()
    db = self.db.profile
    self:ChangeHeight()
    self:ChangeAnchor(db.grow)
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

local function SortStack(fPool, fList, fAnchor, direction)
    if fPool.numActiveObjects == 0 then return end
    wipe(fList)
    local i = 1
    for widget in fPool:EnumerateActive() do
        fList[i] = widget
        fList[i]:ClearAllPoints()
        i = i + 1
    end
    sort(fList, function(a,b) return a.order < b.order end)
    if direction == "below" then
        fList[1]:SetPoint("TOPLEFT", fAnchor, "BOTTOMLEFT", 0, -5)
        if #fList > 1 then
            for i = 2, #fList do
                fList[i]:SetPoint("TOPLEFT", fList[i-1], "BOTTOMLEFT", 0, -5)
            end
        end
    else
        fList[1]:SetPoint("BOTTOMLEFT", fAnchor, "TOPLEFT", 0, 5)
        if #fList > 1 then
            for i = 2, #fList do
                fList[i]:SetPoint("BOTTOMLEFT", fList[i-1], "TOPLEFT", 0, 5)
            end
        end
    end
end

local function IsGearChecked(link)
    -- [4][0] = Includes Spellstones, Firestones, Trinkets, Rings and Necks
    local classID, subclassID = select(6, GetItemInfoInstant(link))
    local noError, item = pcall(function() return db.gearOptions[classID][subclassID] end)
    if noError and item then 
        return true
    elseif db.gearOptions.others and classID == 4 and subclassID == 0 then
        return true
    elseif db.gearOptions.others and classID ~= 2 and classID ~= 4 then 
        return true
    else 
        return false 
    end
end

local function UncheckGearType(link)
    local classID, subclassID = select(6, GetItemInfoInstant(link))
    if classID == 2 or classID == 4 then
        db.gearOptions[classID][subclassID] = false
        print(format("%s %s", addonName, L["Gear type unchecked."]))
    end
end

local function HexToRGB(hex)
    hex = string.gsub(hex, "^#", "", 1)
    local R = string.sub(hex, 1, 2)
    local G = string.sub(hex, 3, 4)
    local B = string.sub(hex, 5, 6)
    R, G, B = tonumber(R, 16) / 255, tonumber(G, 16) / 255, tonumber(B, 16) / 255
    return R, G, B
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

function a.FrameCreation(fPool)
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
    f.group = f:CreateAnimationGroup()
    local fadeOut = f.group:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(.5)
    fadeOut:SetSmoothing("OUT")
    fadeOut:SetStartDelay(db.delay)
    fadeOut:SetScript("OnFinished", function()
        fPool:Release(f)
    end)
    return f
end

function a.FrameResetter(fPool, frame)
    frame.group:Stop()
    frame:ClearAllPoints()
    frame:Hide()
end

a.pool = CreateObjectPool(a.FrameCreation, a.FrameResetter)

-- Monitor
function a:ChangeAnchor(grow)
    -- You have to clear points every time you set new ones.
    TinyLootMonitorScrollFrame:ClearAllPoints()
    if grow == "below" then
        TinyLootMonitorScrollFrame:SetPoint("TOPLEFT", TinyLootMonitorAnchor, "BOTTOMLEFT")
        TinyLootMonitorScrollFrame:SetPoint("TOPRIGHT", TinyLootMonitorAnchor, "BOTTOMRIGHT")
    else
        TinyLootMonitorScrollFrame:SetPoint("BOTTOMLEFT", TinyLootMonitorAnchor, "TOPLEFT")
        TinyLootMonitorScrollFrame:SetPoint("BOTTOMRIGHT", TinyLootMonitorAnchor, "TOPRIGHT")
    end
    SortStack(a.pool, fL, anchor, grow)
end

function a:ChangeHeight()
    TinyLootMonitorScrollFrame:SetHeight((toastHeight + 5) * db.numMax)
end

local m = CreateFrame("ScrollFrame", "TinyLootMonitorScrollFrame", UIParent)
m:SetFrameStrata("HIGH")
local mf = CreateFrame("Frame", "TinyLootMonitorScrollChild", m)
m:SetScrollChild(mf)
mf:SetAllPoints()
m:RegisterEvent("CHAT_MSG_LOOT")
m:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_LOOT" then
        local icon, player, classPlayer, link, rarity, quantity, itemID = LootInfo(...)
        if db.equipable and not IsEquippableItem(link) then return else
            if itemID and rarity and rarity >= db.rarity and not db.banlist[itemID] and IsGearChecked(link) then
                fL[#fL+1] = a.pool:Acquire()
                local f = fL[#fL]
                f:SetParent(mf)
                f.icon:SetTexture(icon)
                f.name:SetText(classPlayer)
                f.item:SetText(link)
                f.quantity:SetText(quantity)
                f.order = nLoot
                nLoot = nLoot + 1
                if db.delay > 0 then f.group:Play() end
                f:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_NONE")
                    GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT")
                    GameTooltip:SetHyperlink(link)
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddDoubleLine(leftClick, L["Equip item"])
                    GameTooltip:AddDoubleLine(format("%s+%s", leftClick, ctrl), L["Dress item"], HexToRGB(tooltipColor))
                    GameTooltip:AddDoubleLine(format("%s+%s", leftClick, shift), L["Link item"], HexToRGB(tooltipColor))
                    GameTooltip:AddDoubleLine(rightClick, L["Dismiss"])
                    GameTooltip:AddDoubleLine(format("%s+%s", rightClick, ctrl), L["Whisper player"], HexToRGB(tooltipColor))
                    GameTooltip:AddDoubleLine(middleClick, L["Add to the ban list"])
                    GameTooltip:AddDoubleLine(format("%s+%s", middleClick, ctrl), L["Uncheck gear type"], HexToRGB(tooltipColor))
                    GameTooltip:Show()
                    self.group:Stop()
                end)
                f:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                    if db.delay > 0 then self.group:Play() end
                end)
                f:SetScript("OnMouseUp", function(self, button)
                    if button == "RightButton" and IsControlKeyDown() then
                        SendChatMessage("Do you need " .. link .. "?", "WHISPER", nil, player)
                    elseif button == "RightButton" then
                        a.pool:Release(self)
                        SortStack(a.pool, fL, anchor, db.grow)                      
                    elseif button == "LeftButton" and IsControlKeyDown() then
                        DressUpLink(link)
                    elseif button == "LeftButton" and IsShiftKeyDown() then
                        ChatEdit_InsertLink(link)
                    elseif button == "LeftButton" and IsEquippableItem(link) and not InCombatLockdown() then
                        a.pool:Release(self)
                        EquipItemByName(link)
                    elseif button == "MiddleButton" and IsControlKeyDown() then
                        UncheckGearType(link)
                        a.pool:Release(self)
                        SortStack(a.pool, fL, anchor, db.grow)
                    elseif button == "MiddleButton" then
                        db.banlist[itemID] = true
                        a.pool:Release(self)
                        SortStack(a.pool, fL, anchor, db.grow)
                        print(format("%s %s", addonName, L["item added to the ban list."]))
                    end
                end)
                PlaySoundFile(LSM:Fetch("sound", db.sound))
                SortStack(a.pool, fL, anchor, db.grow)
                f:Show()
            end
        end
    end
end)