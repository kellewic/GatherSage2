-- These always load as enUS is the default. Other translations override these.
local L = GatherSage2.L

-- Adjust the English version of these strings.
GatherSage2.ERR_SKILL_UP_SI = ERR_SKILL_UP_SI:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

-- Chat message when gaining new skill
GatherSage2.ERR_SKILL_GAINED_S = ERR_SKILL_GAINED_S:gsub("%%s", "(.+)")

-- System message when unlearning ability
GatherSage2.ERR_SPELL_UNLEARNED_S = ERR_SPELL_UNLEARNED_S:gsub("%%s", "(.+)")


L["REQUIRES"] = REQUIRES_LABEL:gsub(":", "")
L["Chance of"] = true
L["Produces"] = true

-- Skills
L["Herbalism"] = true
L["Mining"] = true
L["Skinning"] = true
L["Smelting"] = true

-- Options
L["General"] = true
L["Enabled"] = true
L["Disabled"] = true

L["Addon Enabled"] = GatherSage2.name .. " Enabled"
L["DESC1"] = "Enable or disable %s"
L["Load all modules"] = true

L["Unload all modules"] = true
L["DESC2"] = "Enable or disable modules"

L["Modifier Key"] = true
L["DESC3"] = "Show tooltip information when modifier key is pressed"

L["Clear"] = true
L["DESC4"] = "Clear the modifier key setting"

L["Log Level"] = true
L["DESC5"] = "Sets the log level to show more or less output"
