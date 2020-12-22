if GetLocale() ~= "ruRU" then return end

-- These always load as enUS is the default. Other translations override these.
local L = GatherSage2.L

-- Adjust the English version of these strings.
GatherSage2.ERR_SKILL_UP_SI = ERR_SKILL_UP_SI:gsub("%%%d+%$s", "(.+)"):gsub("%%%d+%$d", "(%%d+)")

-- Chat message when gaining new skill
GatherSage2.ERR_SKILL_GAINED_S = ERR_SKILL_GAINED_S:gsub("%%%d+%$s", "(.+)")

-- System message when unlearning ability
GatherSage2.ERR_SPELL_UNLEARNED_S = ERR_SPELL_UNLEARNED_S:gsub("%%%d+%$s", "(.+)")



L["Chance of"] = "Шанс"
L["Produces"] = "Производит"

-- Skills
L["Herbalism"] = "Травничество"
L["Mining"] = "Горное дело"
L["Skinning"] = "Снятие шкур"
L["Smelting"] = "Выплавка металлов"

-- Options
L["General"] = "Основной"
L["Enabled"] = "Активно"
L["Disabled"] = "Неактивно"

L["Addon Enabled"] = GatherSage2.name .. " Включено"
L["DESC1"] = "Включить или отключить %s"
L["Load all modules"] = "Включить все модули"

L["Unload all modules"] = "Выключить все модули"
L["DESC2"] = "Выключить все модули"

L["Modifier Key"] = true
L["DESC3"] = "Показывать информацию всплывающей подсказки при нажатии клавиши-модификатора"

L["Clear"] = true
L["DESC4"] = "Очистить настройки клавиши-модификатора"

L["Log Level"] = true
L["DESC5"] = "Установить уровень журнала для показа большего или меньшего количества информации"
