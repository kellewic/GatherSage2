-- THIS FILE IS AUTO_GENERATED. DO NOT EDIT. ALL CHANGES WILL BE LOST.
-- LAST UPDATE FROM https://classic.wowhead.com AT 2019-10-03 17:33:19.056971 UTC

local L = GatherSage2.L
local module = GatherSage2:NewModule(L["Smelting"])

local data = {
    [L["Copper Ore"]] = {
        {"1", "25", "47", "70"},
        L["Produces"],
        {L["Copper Bar"], "1"},
    },
    [L["Tin Ore"]] = {
        {"65", "65", "70", "75"},
        L["Produces"],
        {L["Tin Bar"], "1"},
    },
    [L["Silver Ore"]] = {
        {"75", "115", "122", "130"},
        L["Produces"],
        {L["Silver Bar"], "2"},
    },
    [L["Iron Ore"]] = {
        {"125", "130", "145", "160"},
        L["Produces"],
        {L["Iron Bar"], "1"},
    },
    [L["Gold Ore"]] = {
        {"155", "170", "177", "185"},
        L["Produces"],
        {L["Gold Bar"], "2"},
    },
    [L["Mithril Ore"]] = {
        {"175", "175", "202", "230"},
        L["Produces"],
        {L["Mithril Bar"], "1"},
    },
    [L["Truesilver Ore"]] = {
        {"230", "250", "270", "290"},
        L["Produces"],
        {L["Truesilver Bar"], "2"},
    },
    [L["Dark Iron Ore"]] = {
        {"230", "300", "305", "310"},
        L["Produces"],
        {L["Dark Iron Bar"], "1"},
    },
    [L["Thorium Ore"]] = {
        {"230", "250", "270", "290"},
        L["Produces"],
        {L["Thorium Bar"], "1"},
    },
    [L["Elementium Ore"]] = {
        {"230", "250", "270", "290"},
        L["Produces"],
        {L["Elementium Bar"], "5"},
    },
}

module:SetProperty("data", data)
