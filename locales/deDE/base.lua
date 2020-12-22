if GetLocale() ~= "deDE" then return end

-- These always load as enUS is the default. Other translations override these.
local L = GatherSage2.L

-- Adjust the English version of these strings.
GatherSage2.ERR_SKILL_UP_SI = ERR_SKILL_UP_SI:gsub("%%%d+%$s", "(.+)"):gsub("%%%d+%$d", "(%%d+)")

-- Chat message when gaining new skill
GatherSage2.ERR_SKILL_GAINED_S = ERR_SKILL_GAINED_S:gsub("%%%d+%$s", "(.+)")

-- System message when unlearning ability
GatherSage2.ERR_SPELL_UNLEARNED_S = ERR_SPELL_UNLEARNED_S:gsub("%%%d+%$s", "(.+)")


L["Chance of"] = "Chance auf"
L["Produces"] = "Produziert"

-- Skills
L["Herbalism"] = "Kr\195\164uterkunde"
L["Mining"] = "Bergbau"
L["Skinning"] = "K\195\188rschnerei"
L["Smelting"] = "Verh\195\188ttung"

-- Options
L["General"] = "Produziert"
L["Enabled"] = "Aktiviert"
L["Disabled"] = "Deaktiviert"

L["Addon Enabled"] = GatherSage2.name .. " Aktiviert"
L["DESC1"] = "Aktivieren oder Deaktivieren %s"
L["Load all modules"] = "Lade alle Module"

L["Unload all modules"] = "Unload alle Module"
L["DESC2"] = "Aktivieren oder Deaktivieren von Modulen"

L["Modifier Key"] = true
L["DESC3"] = "Zeige Tooltip Informationen, wenn der Modifikator-Taste gedr\195\188ckt wird"

L["Clear"] = true
L["DESC4"] = "Deaktivieren Sie die Einstellung Zusatztaste"

L["Log Level"] = true
L["DESC5"] = "Setzt den Log-Level mehr oder weniger Leistung zeigen"
