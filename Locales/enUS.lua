--@debug@
local noError = true
--@end-debug@

local L = LibStub("AceLocale-3.0"):NewLocale("TinyLootMonitor", "enUS", true, noError)

if L then
--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true)@
--@do-not-package@
    L["Profiles"]                                                                        = true
    L["A loot monitor that tracks yours and group's loot."]                              = true
    L["Rarity"]                                                                          = true
    L["Sets the minimum rarity TinyLootMonitor will track."]                             = true
    L["Maximum"]                                                                         = true
    L["Sets the maximum number of toasts that will appear on screen."]                   = true
    L["Delay"]                                                                           = true
    L["Time (in seconds) the toast will stay on screen. Set it to 0 for sticky toasts."] = true
    L["Show/Hide anchor"]                                                                = true
    L["Sound"]                                                                           = true
    L["The sound that plays when the toast appears."]                                    = true
    L["Display direction"]                                                               = true
    L["Sets if the toasts will display above or below the anchor."]                      = true
    L["Above"]                                                                           = true
    L["Below"]                                                                           = true
    L["Equipable only"]                                                                  = true
    L["Display only equipable items."]                                                   = true
    L["Hide Blizzard's loot window"]                                                     = true
    L["Ban list"]                                                                        = true
    L["Items"]                                                                           = true
    L["Clear unmarked"]                                                                  = true
    L["Will remove from banlist every unmarked item."]                                   = true
    L["TinyLootMonitor Anchor"]                                                          = true
    L["Left click"]                                                                      = true
    L["Equip item"]                                                                      = true 
    L["Middle click"]                                                                    = true
    L["Add to the ban list"]                                                             = true
    L["Right click"]                                                                     = true
    L["Dismiss"]                                                                         = true
    L["Shift+Right click"]                                                               = true
    L["Whisper player"]                                                                  = true
    L["Ctrl+Left click"]                                                                 = true
    L["Dress item"]                                                                      = true
    L["Shift+Left click"]                                                                = true
    L["Link item"]                                                                       = true
    L["item added to the ban list."]                                                     = true
    L["A simple yet efficient loot monitor."]                                            = true
--@end-do-not-package@
end