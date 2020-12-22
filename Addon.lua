--[[-------------------------------------------------]]
--[[--------------------- ADDON ---------------------]]
--[[-------------------------------------------------]]
local addonName, addon = ...
GatherSage2 = addon

GatherSage2.name = addonName
GatherSage2.db_name = "GatherSage2DB"
GatherSage2.enabled = false
GatherSage2.modifier_key_names = {"LEFT-SHIFT", "LEFT-CTRL", "LEFT-ALT", "RIGHT-SHIFT", "RIGHT-CTRL", "RIGHT-ALT"}
GatherSage2.id_addon_loaded = false

GatherSage2.frame = CreateFrame("Frame", "", UIParent)

GatherSage2.log_levels = {NONE = 0, ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4}
GatherSage2.log_level_names = {"NONE", "ERROR", "WARN", "INFO", "DEBUG"}
GatherSage2.log_level = GatherSage2.log_levels.INFO

GatherSage2.db_defaults = {
    profile = {
        general = {
            enabled = true,
            log_level = GatherSage2.log_levels.INFO
        }
    }
}
GatherSage2.DB = nil

GatherSage2.WORLD_TYPE = 1
GatherSage2.UNIT_TYPE = 2
GatherSage2.ITEM_TYPE = 3

GatherSage2.L = setmetatable(
    {__store = {}},
    {
        __index = function(t, k)
            return rawget(t.__store, k)
        end,
        
        __newindex = function(t, k, v)
            rawset(t.__store, k, v == true and k or v)
        end,
    }
)

GatherSage2.__modules = {}

-- Module properties
GatherSage2.SUB_SKILL_KEY = "s_skill"
GatherSage2.PARENT_SKILL_KEY = "p_skill"

-- Index values to retrieve skill module data
GatherSage2.PARENT_SKILL_IDX = 1
GatherSage2.PARENT_LABEL_IDX = 2
-- Children are items that can be gathered from the parent (i.e. Copper Ore from Copper Vein)
-- They are in the parent table starting here and going to N index
GatherSage2.CHILDREN_START_IDX = 3
-- Within each child table, these index values retrive data
GatherSage2.CHILD_NAME_IDX = 1
GatherSage2.CHILD_COLOR_IDX = 2

--[[------------------------------------------------]]
--[[-------------------- LOGGING -------------------]]
--[[------------------------------------------------]]
function GatherSage2:SetLogLevel(level)
    self.log_level = tonumber(level) or self.log_levels.INFO
end

function GatherSage2:GetLogLevel()
    return self.log_level
end

function GatherSage2:log(level, tag, ...)
	if level <= self.log_level and (...) then
		DEFAULT_CHAT_FRAME:AddMessage(format("[%s] %s%s", self.name, tag, format(...)))
	end
end

function GatherSage2:logerror(...)
    self:log(self.log_levels.ERROR, "|cffff0000ERROR:|r ", ...)
end

function GatherSage2:logwarn(...)
    self:log(self.log_levels.WARN, "|cffffff00WARN:|r ", ...)
end

function GatherSage2:loginfo(...)
    self:log(self.log_levels.INFO, "", ...)
end

function GatherSage2:logdebug(...)
    self:log(self.log_levels.DEBUG, "|cffd9d919DEBUG:|r ", ...)
end

--[[------------------------------------------------]]
--[[------------------- DATABASE -------------------]]
--[[------------------------------------------------]]
function GatherSage2:DB_InitKeysIfNotExist(dbKey, ...)
	if not self:DB_Read(dbKey, ...) then
		return self:DB_InitKeys(dbKey, ...)
	end
end

function GatherSage2:DB_InitKeys(dbKey, ...)
	local tbl = self.DB[dbKey]
	local tArgs = select("#", ...)
	
	-- Must have at least one key
	if tArgs < 1 then return end

	local key, subTable
	
	for i=1, tArgs do
		key = select(i, ...)
		subTable = tbl[key]
		
		if not subTable then
			tbl[key] = {}
		end
		
		tbl = tbl[key]
	end

	return tbl
end

function GatherSage2:DB_Read(dbKey, ...)
	local tbl = self.DB[dbKey]
	local tArgs = select("#", ...)
	
	-- Request for entire base sub-table
	if tArgs == 0 then return tbl end
	
	for i=1, tArgs do
		tbl = tbl[select(i, ...)]
		if tbl == nil then break end
	end
	
	return tbl
end

--[[
	DB_Save({"char", "a", "b"}, "TEST") results in:
	
	char = {
		a = {
			b = "TEST"
		}
	}
--]]
function GatherSage2:DB_Save(keys, value)
	local tbl = self.DB[keys[1]]
	local key, subTable
	
	for i=2, #keys-1 do
		key = keys[i]
        subTable = tbl[key]
        
		if not subTable then
			tbl[key] = {}
		end
		
		tbl = tbl[key]
	end
	
	tbl[keys[#keys]] = value
	
	return true
end

function GatherSage2:DB_Delete(dbKey, mainKey)
	if self:DB_Read(dbKey, mainKey) ~= nil then
		self.DB[dbKey][mainKey] = nil
		return true
	else
		return false
	end
end

--[[------------------------------------------------]]
--[[------------------ DB SESSION ------------------]]
--[[------------------------------------------------]]
function GatherSage2:Session_Init()
	self:DB_InitKeysIfNotExist("char", "session")
end

function GatherSage2:Session_Save(keys, value)
	return self:DB_Save({"char", "session", unpack(keys)}, value)
end

function GatherSage2:Session_Read(...)
	return self:DB_Read("char", "session", ...)
end

function GatherSage2:Session_Clear()
	return self:DB_Delete("char", "session")
end

--[[------------------------------------------------]]
--[[------------------ DB SKILLS -------------------]]
--[[------------------------------------------------]]
function GatherSage2:Skill_Init()
	self:DB_InitKeysIfNotExist("char", "skills")
end

-- Copy current skill levels to session
function GatherSage2:Skill_InitSession()
	for k, v in pairs(self:DB_Read("char", "skills")) do
		if not self:Session_Read("skills", k) then
			self:Session_Save({"skills", k}, v)
		end
	end
end

-- Get session's start rank for skill
function GatherSage2:Skill_GetSessionSkillRank(skill)
	return self:Session_Read("skills", skill)
end

function GatherSage2:Skill_SetSkillRank(skill, rank)
	self:DB_Save({"char", "skills", skill}, rank)
end

-- Get rank for skill from database
function GatherSage2:Skill_GetSkillRank(skill)
	return self:DB_Read("char", "skills", skill)
end

-- Set ranks for session when player learns skill
function GatherSage2:Skill_SetSessionSkill(skill, rank)
	self:Session_Save({"skills", skill}, rank)
end

-- Save skill up value to session
function GatherSage2:Skill_SetSessionSkillUp(skill, gain)
	self:Session_Save({"skillUps", skill}, gain)
end

-- Get skill up value from session
function GatherSage2:Skill_GetSessionSkillUp(skill)
	return self:Session_Read("skillUps", skill)
end

-- Retrieves if skill has parent skill
function GatherSage2:Skill_HasParent(skill)
    local parentSkillKey = self.PARENT_SKILL_KEY
	for module_name, module in self:IterateModules() do
		if skill == module_name then
			return module:GetProperty(parentSkillKey)
		end
	end
end

function GatherSage2:Skill_PlayerHasSkill(skill)
	local rank = 0
	
	if skill then
		rank = self:Skill_GetSkillRank(skill)
	
		if not rank then
			-- Look for skills that show up in the player spell book
			skill, rank = GetSpellInfo(skill)
			
			if skill then
				if (not rank or rank == "") then
					-- This skill probably has a parent skill so we fake
					-- it by using the rank of the parent skill
					rank = self:Skill_GetSkillRank(self:Skill_HasParent(skill)) or 1
				end
			end
		end
	end
	
	return skill, rank
end

--[[----------------------------------------------]]
--[[------------------ OPTIONS -------------------]]
--[[----------------------------------------------]]
-- Build keys based on option that generated the call.
local function GetKeys(info)
	local keys = {"profile"}

	-- arg keys are stored in info[1] .. info[n]
	-- Ignore index [0] as it's the addon name
	for k, v in pairs(info) do
		if type(k) == "number" and k > 0 then
			tinsert(keys, v)
		end
	end
	
	return keys
end

-- Retrieve setting from database
local function DefaultGet(info)
	return GatherSage2:DB_Read(unpack(GetKeys(info)))
end

-- Save setting to database
local function DefaultSet(info, value)
	return GatherSage2:DB_Save(GetKeys(info), value)
end

function GatherSage2:Options_EnableGUIOptions()
    local L = self.L
    local options

	options = {
		name = self.name,
		type = "group",
		handler = self,
		childGroups = "tab",
		get = DefaultGet,
		set = DefaultSet,
		args = {
			general = {
				order = 1,
				name = L["General"],
				type = "group",
				args = {
					-- Addon options
					enabled = {
						order = 1,
						name = L["Addon Enabled"],
						desc = format(L["DESC1"], self.name),
						type = "toggle",
						get = function() return self.enabled end,
						set = function(info, value)
							-- This must be first or the toggle doesn't work
							DefaultSet(info, value)
							
                            if value then
								self:Skill_Check()
								
								for k, _ in self:IterateModules() do
									if self:Skill_GetSkillRank(L[k]) then
										-- Forge the info so it looks like the module is asking to be enabled
										info[2] = k
									
										-- Call the module's set function
										options.args.general.args[k].set(info, true)
									end
                                end
                                
                                self.enabled = true
                                self:loginfo(strlower(L["Enabled"]))
                            else
								-- Uncheck all the module checkboxes
								for k, _ in self:IterateModules() do
									-- Forge the info so it looks like the module is asking to be disabled
									info[2] = k
									
									-- Call the module's set function
									options.args.general.args[k].set(info, false)
								end

								self.enabled = false
								self:loginfo(strlower(L["Disabled"]))
							end
						end,
					},
                    
					-- Module options
					modsHeader_desc = {
						order = 102,
						type = "header",
						name = L["DESC2"],
                    },
                    
                    -- 103 is dynamically inserted in code below
                    -- List of modules with checkboxes

                    moduleSpacer1 = {
                        order = 201,
                        type = "description",
                        name = "",
                    },
					loadAllModulesSession = {
						order = 202,
						name = L["Load all modules"],
						type = "execute",
						func = function()
							for k, _ in self:IterateModules() do
								self:GetModule(k):Enable()
							end
						end,
					},
					unloadAllModulesSession = {
						order = 203,
						name = L["Unload all modules"],
						type = "execute",
						func = function()
							for k, _ in self:IterateModules() do
								self:GetModule(k):Disable()
							end
						end,
                    },
                    modsFooter_desc = {
						order = 204,
						type = "header",
						name = "",
                    },

					-- Key modifier options
					modKeySpacer1 = {
						order = 400,
						type = "description",
						name = "",
					},
					mod_keys = {
						name = L["Modifier Key"],
						desc = L["DESC3"],
						order = 405,
						type = "select",
						values = self.modifier_key_names,
                    },
					modKeysClear = {
						order = 410,
						name = L["Clear"],
						desc = L["DESC4"],
						type = "execute",
						func = function(info)
							-- This must be first or the toggle doesn't work
							DefaultSet(info, nil)
							self:DB_Save({"profile", "general", "mod_keys"}, nil)
						end,
					},
                    
                    logLevelSpacer = {
						order = 500,
						type = "description",
						name = "",
					},
					-- Debug options
					log_level = {
						name = L["Log Level"],
						desc = L["DESC5"],
						order = 505,
						type = "select",
						values = self.log_level_names,
						get = function()
							return tonumber(self:GetLogLevel()) + 1
						end,
						
						set = function(info, value)
							local logLevel = tonumber(value) - 1
							
                            DefaultSet(info, logLevel)
							self:SetLogLevel(logLevel)
						end,
                    },
				},
			},
		},
	}
    
	local mods = {}
    local modOrder = 103
    local subSkillKey = self.SUB_SKILL_KEY
	
	for module_name, _ in self:IterateModules() do
		tinsert(mods, module_name)
	end
	
	sort(mods)
	
	for _, module_name in ipairs(mods) do
		local module = self:GetModule(module_name)
		local sub = module:GetProperty(subSkillKey)
		
		options.args.general.args[module_name] = {
			order = modOrder,
			name = module_name,
			desc =  format(L["DESC1"], module:GetName()),
			type = "toggle",
            get = function(info)
				-- This sets and returns the data. Since we don't know which modules
                -- will be activated until the player logs in, we can't create profile
                -- defaults, so we do it here. This is needed so the controls will
                -- enable/disable themselves properly without player intervention.
				if module:IsEnabled() then
					DefaultSet(info, true)
					return true
				else
					DefaultSet(info, false)
					return false
				end
			end,
            set = function(info, value)
				-- This must be first or the toggle doesn't work
                DefaultSet(info, value)
				
				if value then
					module:Enable()
				else
					module:Disable()
				end
				
				if sub then
					info[2] = sub
					options.args.general.args[sub].set(info, value)
				end
			end,
		}
		
		modOrder = modOrder + 1
    end
	
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.DB)
	options.args.profiles.order = 2
	
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(self.name, options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.name)
end
