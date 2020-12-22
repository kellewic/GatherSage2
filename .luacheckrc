std = "lua51"

ignore = {
        "611"   -- A line consists of nothing but whitespace
}

globals = {
    -- Addon
    "GatherSage2",
    "GS2_TooltipLib",

    -- Libraries
    "LibStub",

    -- WoW API calls
    "CreateColor",
    "CreateFrame",
    "GameTooltip_ClearMoney",
    "GetAddOnInfo",
    "GetItemInfo",
    "GetLocale",
    "GetMouseFocus",
    "GetNumAddOns",
    "GetNumSkillLines",
    "GetSkillLineInfo",
    "GetSpellInfo",
    "IsAddOnLoaded",
    "IsLeftAltKeyDown",
    "IsLeftControlKeyDown",
    "IsLeftShiftKeyDown",
    "IsRightAltKeyDown",
    "IsRightControlKeyDown",
    "IsRightShiftKeyDown",
    "ItemRefTooltip",
    "SetTooltipMoney",
    "UnitExists",
    "UnitLevel",
    "UnitPlayerControlled",
    "format",
    "sort",
    "strlower",
    "strtrim",
    "tinsert",

    -- WoW Constants
    "BAG_ITEM_QUALITY_COLORS",
    "ERR_SKILL_GAINED_S",
    "ERR_SPELL_UNLEARNED_S",
    "ERR_SKILL_UP_SI",
    "ITEM_PROSPECTABLE",
    "ITEM_QUALITY_COLORS",
    "MAX_PLAYER_LEVEL",
    "REQUIRES_LABEL",
    "SELL_PRICE",
    "UNIT_SKINNABLE_HERB",
    "UNIT_SKINNABLE_LEATHER",
    "UNIT_SKINNABLE_ROCK",
    "USE",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_ID",

    -- WoW Objects
    "DEFAULT_CHAT_FRAME",
    "GameTooltip",
    "Minimap",
    "UIParent",

    -- Other globals
    "RatingBuster",
    "BetterVendorPrice",
}

exclude_files = {

}