local GatherSage2 = GatherSage2

--[[-----------------------------------------------]]
--[[--------------- REGISTER EVENTS ---------------]]
--[[-----------------------------------------------]]
local events = {
    ["ADDON_LOADED"] = function(_, addon_name)
        if addon_name == GatherSage2.name then
            GatherSage2.DB = LibStub("AceDB-3.0"):New(GatherSage2.db_name, GatherSage2.db_defaults, true)

			local log_level = GatherSage2:DB_Read("profile", "general", "log_level")
			if log_level then GatherSage2:SetLogLevel(log_level) end
            
            GatherSage2:Options_EnableGUIOptions()
			GatherSage2:Session_Init()
			GatherSage2:Skill_Init()

            GatherSage2.enabled = GatherSage2:DB_Read("profile", "general", "enabled")
        end
    end,
    ["PLAYER_LOGIN"] = function()
        GatherSage2:Skill_Check()
        GatherSage2:Skill_InitSession()

        -- Sometimes the tooltip doesn't hide fast enough and mousing
        -- over a minimap node can cause issues.
        Minimap:HookScript("OnEnter", function() GameTooltip:Hide() end)

        for i=1, GetNumAddOns() do
            if IsAddOnLoaded(i) then
                local name = GetAddOnInfo(i)

                if name == "idTip" then
                    GatherSage2.id_addon_loaded = true

                elseif name == "RatingBuster" then
                    if RatingBuster and RatingBuster.ProcessTooltip and
                        (RatingBuster.db.profile.showItemLevel or RatingBuster.db.profile.showItemID)
                    then
                        GatherSage2.id_addon_loaded = true
                    end
                end
            end
        end
    end,
    ["SKILL_LINES_CHANGED"] = function()
        GatherSage2:Skill_Check()
    end,
    ["CHAT_MSG_SYSTEM"] = function(_, msg)
		if type(msg) ~= "string" then return end
        
		-- What skill is this for?
		local skill = msg:match(GatherSage2.ERR_SPELL_UNLEARNED_S)
		if not skill then return end

		-- Remove text such as (Apprentice)
		skill = skill:gsub(" %(.+%)", "")
        
		-- Remove skill from session
		GatherSage2:Skill_SetSessionSkill(skill, nil)
		GatherSage2:Skill_SetSessionSkillUp(skill, nil)
		
		-- Remove skill from database
		GatherSage2:Skill_SetSkillRank(skill, nil)
        GatherSage2:Skill_Check()
    end,
    ["CHAT_MSG_SKILL"] = function(_, msg)
		if type(msg) ~= "string" then return end
        
		-- Get skill and new rank
        local skill, rank = msg:match(GatherSage2.ERR_SKILL_UP_SI)
        
		-- Check if it's a skill we care about
		if skill then
			local module = GatherSage2:GetModule(skill)
			
			if module then
				if not module:IsEnabled() then return end
			else
				return
			end
		end
		
		if (not skill or not rank) then
			-- Look for skills here in case the player learned a new one
			GatherSage2:Skill_Check()
		
			-- Maybe the player learned a skill
			skill = msg:match(GatherSage2.ERR_SKILL_GAINED_S)
			if not skill then return end
			
			rank = GatherSage2:Skill_GetSkillRank(skill)
			if not rank then return end
			
			GatherSage2:Skill_SetSessionSkill(skill, rank)
			
			-- No need to figure out starting rank sd it's a new skill
			GatherSage2:Skill_SetSessionSkillUp(skill, 0)
		else
			-- Get rank the player was at on login
			local startRank = GatherSage2:Skill_GetSessionSkillRank(skill) or 0
			GatherSage2:Skill_SetSessionSkillUp(skill, tonumber(rank) - tonumber(startRank))
        end
    end,
    ["PLAYER_LOGOUT"] = function()
        GatherSage2:Session_Clear()
    end,
}

GatherSage2.frame:SetScript("OnEvent", function(frame, event, ...)
    local handler = events[event]

    if handler then
        handler(frame, ...)
    end
end)

for event in pairs(events) do
    GatherSage2.frame:RegisterEvent(event)
end

-- Gather player skills, save to database, and  load skill modules
function GatherSage2:Skill_Check()
    if GetNumSkillLines() <= 0 then return end

	self:DB_Delete("char", "skills")
	self:DB_InitKeys("char", "skills")
	
	-- Look for skills that show up in the character skill tab
	local name, rank, isHeader, _
	
	for idx=1, GetNumSkillLines() do
        name, isHeader, _, rank = GetSkillLineInfo(idx)

		if not isHeader and name and self:GetModule(name) then
			self:Skill_SetSkillRank(name, rank)
		end
	end
    
	for k, _ in self:IterateModules() do
		name, rank = self:Skill_PlayerHasSkill(k)
		
		if name and rank then
			self:Skill_SetSkillRank(name, rank)
		end
		
		if self:ShouldLoadModule(k) then
			self:EnableModule(k)
		else
			self:DisableModule(k)
		end
    end
end

--[[------------------------------------------------]]
--[[--------------------- MAIN ---------------------]]
--[[------------------------------------------------]]
local LibTooltip = GS2_TooltipLib
local L = GatherSage2.L

local WORLD = GatherSage2.WORLD_TYPE
local UNIT = GatherSage2.UNIT_TYPE
local ITEM = GatherSage2.ITEM_TYPE

local maxMobLevel = MAX_PLAYER_LEVEL + 3

-- Used to color items based on player's skill level
local red = "|cffB22222"
local colors = {red, "|cffFFA500", "|cffFFFF00", "|cff00BB00"}

local herbalism = L["Herbalism"]
local mining = L["Mining"]
local skinning = L["Skinning"]
local smelting = L["Smelting"]

local skillIdx = GatherSage2.PARENT_SKILL_IDX
local skillLabelIdx = GatherSage2.PARENT_LABEL_IDX
local childrenIdx = GatherSage2.CHILDREN_START_IDX

local childNameIdx = GatherSage2.CHILD_NAME_IDX
local childColorIdx = GatherSage2.CHILD_COLOR_IDX

local parentSkillKey = GatherSage2.PARENT_SKILL_KEY
local subSkillKey = GatherSage2.SUB_SKILL_KEY

-- Set module properties
for module_name, module in GatherSage2:IterateModules() do
	if module_name == mining then
		module:SetProperty(subSkillKey, smelting)
	elseif module_name == smelting then
		module:SetProperty(parentSkillKey, mining)
	end
end

local function TooltipHook(tooltip)
    if not GatherSage2.enabled then return end
    if not tooltip then return end
	
	local mouseFocus = GetMouseFocus()
	
	if mouseFocus then
		mouseFocus = mouseFocus:GetName()
		
		-- Ignore Gatherer tooltips
		if mouseFocus and mouseFocus:find("^GatherNote%d+$") then return end
	end
    
    -- Let item hook handle items
    if tooltip:GetItem() then return end

    local name = tooltip:GetUnit()
	local sType = UNIT
	
	if not name then
        -- Not a unit... grab name from tooltip
        local fs = _G[format("%sTextLeft1", tooltip:GetName())]
        
        if fs then
            -- Try to get the item by the tooltip text
            local text = fs:GetText()
            name = GetItemInfo(text or "")
            
            if not name then
                -- Just get raw text.
                name = text
            end
        else
            -- This should never happen
            GatherSage2:logerror("001 - cannot determine name")
            return
        end

        sType = WORLD
	end

	GatherSage2:ProcessTooltip(tooltip, name, sType)
end

local function TooltipHookItem(tooltip)
    if not GatherSage2.enabled then return end
    if not tooltip then return end

    local name = tooltip:GetItem()
    
    if not name then
        TooltipHook()
        return
    end

    GatherSage2:ProcessTooltip(tooltip, name, ITEM)
end


GameTooltip:HookScript("OnTooltipSetItem", TooltipHookItem)
ItemRefTooltip:HookScript("OnTooltipSetItem", TooltipHookItem)
GameTooltip:HookScript("OnShow", TooltipHook)

-- Returns a color based on a skill level
local function GetSkillLevelColor(itemRef, skillLevel)
	local color = "|cff808080"
	local level = tonumber(skillLevel) or 0
	
	-- For "varies", the skill level will be shown on each
	-- item line in the additional data section.
	if itemRef[skillIdx][1] == "v" then
		color = "|cffFFFFFF"
	else
		for i, n in ipairs(itemRef[skillIdx]) do
			if level < tonumber(n) then
				color = colors[i]
				break
			end
		end
	end
	
	return color
end

-- Returns information related to a given skill.
local function GetSkillLevelAndParent(skillName)
	if not skillName then return 0, "" end
	
	local skillLevel

	-- Get the parent skill to look for in the tooltip
	local parentSkill = GatherSage2:Skill_HasParent(skillName)

	if parentSkill then
		skillLevel = GatherSage2:Skill_GetSkillRank(parentSkill) or 0
	else
		parentSkill = skillName
		skillLevel = GatherSage2:Skill_GetSkillRank(skillName) or 0
	end
	
	return skillLevel, parentSkill
end

-- Returns left and right tooltip strings for skill information
local function GetSkillData(itemRef, skill)
	if not itemRef[skillIdx] then
		return " ", " "
	end

	local skillLevel, parentSkill = GetSkillLevelAndParent(skill)
	local color = GetSkillLevelColor(itemRef, skillLevel)
	local skillStr, skillStatsStr
	
	if skill == skinning and color ~= red then
		-- Use a color signifying we don't know if player will skill up
		color = "|cffEEE8AA"
	end
	
	local skillLevelRequired = tonumber(itemRef[skillIdx][1]) or 0
	
	-- Don't show skill level information if player doesn't have skill learned
	if skillLevel > 0 and skillLevelRequired > 0 then
		local skillDistance = tonumber(skillLevel) - skillLevelRequired
		
		if skillDistance >= 0 then
			skillDistance = format("+%d", skillDistance)
		else
			skillDistance = format("%s%d|r", red, skillDistance)
		end
	
		skillStatsStr = format(
			"|cff6495ED%s (+%s/%s)|r",
			skillLevel,
			GatherSage2:Skill_GetSessionSkillUp(parentSkill) or 0,
			skillDistance
		)
	else
		-- Clear text set previously
		skillStatsStr = " "
	end
	
	-- Now that we are not doing math on this, change it
	-- to what is should be for the tooltip
	if skillLevelRequired == 0 then
		skillLevelRequired = "varies"
	end
	
	skillStr = format("%s%s (%s)|r", color, skill, skillLevelRequired)
	
	return skillStr, skillStatsStr
end

--[[
	Main tooltip processing function.
	
	tooltip			-	The tooltip with which we are working on.
	name			-	The name of whatever the tooltip is showing. This could be
						an itemString or itemLink.
	sType			-	Indicates what the tooltip is showing (unit, item, world object)
--]]
function GatherSage2:ProcessTooltip(tooltip, name, sType)
	-- Check for modifier keys
	local modKeyIdx = self:DB_Read("profile", "general", "modKeys")

	if modKeyIdx then
		local modKey = self.modiferKeyNames[modKeyIdx]
		
		if modKey == "LEFT-SHIFT" and not IsLeftShiftKeyDown() then
			return
		elseif modKey == "LEFT-CTRL" and not IsLeftControlKeyDown() then
			return
		elseif modKey == "LEFT-ALT" and not IsLeftAltKeyDown() then
			return
		elseif modKey == "RIGHT-SHIFT" and not IsRightShiftKeyDown() then
			return
		elseif modKey == "RIGHT-CTRL" and not IsRightControlKeyDown() then
			return
		elseif modKey == "RIGHT-ALT" and not IsRightAltKeyDown() then
			return
		end
	end
		
	-- If unit tooltip, skip obvious false positives like Hunter pets
	if sType == UNIT and
		(
			(UnitExists("mouseover") and UnitPlayerControlled("mouseover")) or
			(UnitExists("playertarget") and UnitPlayerControlled("playertarget"))
		)
	then
		return
    end
    
    -- Support name being itemLink or itemString
	if name:find("item:%d+") then
		name = GetItemInfo(name:match("item:(%d+)"))
    end
    
	-- What skill(s) does this item require?
    local moduleData, moduleDataName
    local data
	
    for k, module in GatherSage2:IterateModules() do
        if module:IsEnabled() then
            -- Some creatures are named things like "Jade" so we
            -- need to ensure skinning only deals with units.
            --
            -- Disable item tooltips for all but smelting
            if (not (k == skinning and sType ~= UNIT)) and (not (k ~= smelting and sType == ITEM)) then
                moduleData = module:GetProperty("data")
                moduleDataName = moduleData[name]

                if moduleDataName ~= nil then
                    data = data or {}
                    data[k] = moduleDataName
                end
            end
        end
    end

    -- Not something we are interested in
    if data == nil then return end

    local _, scanStr, skillStr, skillStatsStr, scanNum
    local num = 0
    
	-- Set our "requires" lines in the tooltip. There may be more than one.
	-- These lines come first in the tooltip.
    for k, entry in pairs(data) do
		-- Fill in creature gathering levels
		if k == skinning or ((k == herbalism or k == mining) and sType == UNIT) then
			local levelRequired
			local mobLevel = maxMobLevel
			
			if UnitExists("mouseover") then
				mobLevel = UnitLevel("mouseover")
			elseif UnitExists("playertarget") then
				mobLevel = UnitLevel("playertarget")
			end

			-- This happens if mob level is too high for player to determine
			if mobLevel == -1 then
				-- Fake it
				mobLevel = UnitLevel("player") + 11
				
				if mobLevel > maxMobLevel then
					mobLevel = maxMobLevel
				end
			end
			
			if mobLevel < 21 then
				levelRequired = (mobLevel - 10) * 10
				if levelRequired < 1 then levelRequired = 1 end
			else
				levelRequired = mobLevel * 5
			end
			
			entry[skillIdx][1] = levelRequired
			entry[skillIdx][2] = levelRequired
			entry[skillIdx][3] = levelRequired
			entry[skillIdx][4] = levelRequired
        end

        skillStr, skillStatsStr = GetSkillData(entry, k)
		
		if k == herbalism then
			scanStr = UNIT_SKINNABLE_HERB
		elseif k == mining then
			scanStr = UNIT_SKINNABLE_ROCK
		elseif k == skinning then
			scanStr = UNIT_SKINNABLE_LEATHER
		elseif k == smelting then
			scanStr = ITEM_PROSPECTABLE
        else
			return
        end
        
		-- On first pass, look for default line entered by game. This
		-- text will depend on what we are looking at.
        if num == 0 then
			-- Look for a specific text in the tooltip
            _, scanNum = LibTooltip:ScanTooltip(tooltip, scanStr)
            
            -- If skill is known, the tooltip has "Requires SKILL".
            -- If unknown, the tooltip just has "SKILL".
            if scanNum == 0 then
                _, scanNum = LibTooltip:ScanTooltip(tooltip, scanStr:gsub(format("%s ", L["REQUIRES"]), ""))
            end

            if scanNum == 0 then
                local otherStr = name
				
				if sType == UNIT then otherStr = "Level %d+ " end
				
				if LibTooltip:ScanTooltip(tooltip, L["REQUIRES"] .. " Level %d") then
					otherStr = L["REQUIRES"] .. " Level %d"
				end
			
				-- Couldn't find it so look for the fallback text.
				_, scanNum = LibTooltip:ScanTooltip(tooltip, otherStr)
				
				if scanNum and scanNum > 0 then
					-- Found fallback text, add our text after it.
					scanNum = scanNum + 1
					LibTooltip:SpliceLine(tooltip, scanNum, skillStr, skillStatsStr)
                else
					-- Can't find the text on the tooltip; something is very wrong here.
					return
				end
			else
				-- Overwrite the line with our information.
				LibTooltip:ReplaceLine(tooltip, scanNum, skillStr, skillStatsStr)
			end
			
			num = scanNum
		else
			-- On subsequent passes, track where we are entering tooltip data so
			-- our formatting doesn't get messed up and we can order lines how
			-- we want them.
			num = num + 1
			
			-- If a node is showing more than one skill line, the order is not guaranteed and
			-- so the skill line may have shifted in the previous block and we need to look for
			-- it here and remove it.
			_, scanNum = LibTooltip:ScanTooltip(tooltip, scanStr, num)
			
			if scanNum > 0 then
				-- Delete line
				LibTooltip:ReplaceLine(tooltip, scanNum)
			else
				_, scanNum = LibTooltip:ScanTooltip(tooltip, UNIT_SKINNABLE_LEATHER, num)
				
				if scanNum == 0 then
					_, scanNum = LibTooltip:ScanTooltip(tooltip, ITEM_PROSPECTABLE, num)
				end
				
				if scanNum > 0 then
					LibTooltip:ReplaceLine(tooltip, scanNum)
				end
			end
			
			LibTooltip:SpliceLine(tooltip, num, skillStr, skillStatsStr)
        end
        
        -- Add in additional items that can be found for/in/on this item
        local color, item
		
        -- Add an empty line
        num = num + 1
        LibTooltip:SpliceLine(tooltip, num)
        
        -- Add the "chance of" line with the skill indicator.
        num = num + 1
        LibTooltip:SpliceLine(tooltip, num, format("|cffFFFFFF%s (%s):|r", entry[skillLabelIdx], k))

        -- Add the actual items there is a chance to obtain.
        for x = childrenIdx, #entry do
            item = entry[x]

            color = ITEM_QUALITY_COLORS[tonumber(item[childColorIdx])]
            num = num + 1
            
            LibTooltip:SpliceLine(
                tooltip,
                num,
                format(
                    "|cff%02x%02x%02x%s|r",
                    color.r*255,
                    color.g*255,
                    color.b*255,
                    item[childNameIdx]
                )
            )
        end
    end

    if sType == ITEM then
        if GatherSage2.id_addon_loaded == true then
            if not BetterVendorPrice then
                if not tooltip.shownMoneyFrames then
                    num = num + 1
                    LibTooltip:SpliceLine(tooltip, num)
                else
                    LibTooltip:AdjustMoneyFrame(tooltip)
                end
            end
        end

        -- This isn't a great solution since any addon that produces
        -- more than one money frame creates extra tooltip lines
        -- that cannot be removed.
        if BetterVendorPrice and BetterVendorPrice.ToolTipHook then
            GameTooltip_ClearMoney(tooltip)
            BetterVendorPrice.ToolTipHook(tooltip)
        end
    end
    
	-- Wrap all lines that match these texts.
	LibTooltip:WrapLongLines(
		tooltip,
		string.format("%s: ", USE),
		[["Commonly found .*%."]],
		[["Commonly obtained .*%."]],
		[["Rarely found .*%."]],
		[["Rarely obtained .*%."]]
	)
	
	LibTooltip:HideAllTextures(tooltip, true)
	tooltip:Show()
end
