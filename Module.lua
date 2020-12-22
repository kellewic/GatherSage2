local function noop() end

local function clone(c_obj)
	local lookup_table = {}
	
	local function _copy(obj)
		if type(obj) ~= "table" then
			return obj
		elseif lookup_table[obj] then
			return lookup_table[obj]
		end
		
		local new_table = {}
		lookup_table[obj] = new_table
		
		for idx, val in pairs(obj) do
			new_table[_copy(idx)] = _copy(val)
		end
		
		return setmetatable(new_table, _copy(getmetatable(obj)))
	end
	
	return _copy(c_obj)
end

local Module = {
    GetName = function (self) return self.name end,
    IsEnabled = function (self) return self.enabled end,
	SetProperty = function (self, p, v) self.__properties[p] = v end,
    GetProperty = function (self, p) return self.__properties[p] end,
	OnInit = noop,
	OnEnable = noop,
	OnDisable = noop,

	Enable = function (self)
        if self.enabled then return end
        self:OnEnable()
        
        local subModule = self:GetProperty("SubSkill")
        if subModule and GatherSage2:ShouldLoadModule(subModule) then
            GatherSage2:GetModule(subModule):Enable()
        end
    
        self.enabled = true
        GatherSage2:logdebug("%s loaded", self:GetName())
    end,

	Disable = function (self)
        if not self.enabled then return end
        self:OnDisable()
        
        local subModule = self:GetProperty("SubSkill")
        if subModule then
            GatherSage2:GetModule(subModule):Disable()
        end
        
        self.enabled = false
        GatherSage2:logdebug("%s unloaded", self:GetName())
    end,

	Init = function (self)
        if self.initialized then return end
        self:OnInit()
        self.initialized = true
    end,
	
	enabled = false,
	initialized = false,
	name = "",
    __properties = {},
}

function GatherSage2:NewModule(name)
	if self.__modules[name] then
		return self.__modules[name]
	end
	
	local module = clone(Module)
	module.name = name

	module:Init()
	
	self.__modules[name] = module
	return module
end

function GatherSage2:GetModule(name)
	return self.__modules[name]
end

function GatherSage2:IterateModules() return pairs(self.__modules) end

function GatherSage2:EnableModule(moduleName)
	local module = self:GetModule(moduleName)
	if module then module:Enable() end
end

function GatherSage2:DisableModule(moduleName)
	local module = self:GetModule(moduleName)
	if module then module:Disable() end
end

-- Determine if module should be loaded
function GatherSage2:ShouldLoadModule(module_name)
	local ret
	local profileEnabled = self:DB_Read("profile", "general", module_name)
	
	-- Profile settings override all if player set explicitly
	if profileEnabled then
		ret = true
	elseif profileEnabled == false then
		ret = false
	else
		-- Does the player have this skill, or a parent skill?
		local tSkill, rank = self:Skill_PlayerHasSkill(module_name)
		
		if tSkill and rank then
			ret = true
		else
			local subSkillName = self:GetModule(module_name):GetProperty(self.SUB_SKILL_KEY)
			
			if subSkillName then
				ret = self:ShouldLoadModule(subSkillName)
			end
		end
	end
	
	return ret
end
