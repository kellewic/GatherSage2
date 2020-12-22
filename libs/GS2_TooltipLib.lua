local tooltipSides = {"TextLeft", "TextRight"}
local defaultFontString = GameTooltip:CreateFontString(nil, "OVERLAY", "GameTooltipText")

-- Clone a tooltip line to another
local function CloneLine(from, to)
	if not from or not to then return end
	
	if type(from) == "string" then
		defaultFontString:SetText(from)
		from = defaultFontString
	end
	
	to:SetFont(from:GetFont())
	to:SetJustifyH(from:GetJustifyH())
	to:SetJustifyV(from:GetJustifyV())
	to:SetShadowColor(from:GetShadowColor())
	to:SetShadowOffset(from:GetShadowOffset())
	to:SetSpacing(from:GetSpacing())
	to:SetTextColor(from:GetTextColor())
	to:SetText(from:GetText())
	
	return true
end

GS2_TooltipLib = { -- luacheck: ignore
	--[[
		Replace a line in the tooltip with new information. Can handle both
		left and right sides appropriately. Passing nil for either side will
		clear the data for that side.
		
		@param	tooltip			The tooltip for which to replace a line
		@param	num				The tooltip line number to replace
		@param	leftText		The new left text
		@param	rightText		The new right text
	--]]
    ["ReplaceLine"] = function(self, tooltip, num, leftText, rightText)
        local _ = self -- to appease luacheck
		local tooltipName = tooltip:GetName()
		local part
        local new = {leftText, rightText}
		
		for i, side in ipairs(tooltipSides) do
			part = _G[tooltipName .. side .. num]
			if not part then return end
			
			if new[i] then
				CloneLine(new[i], part)
				part:Show()
			else
				-- Clear the text in case this line is shifted and shown again
				part:SetText(" ")
				part:Hide()
			end
		end
		
		tooltip:Show()
	end,
	--[[
		Splice a new line into tooltip and adjust existing lines appropriately.
		
		@param	tooltip			The tooltip to splice into
		@param	num				The line number where we want to put new content
		@param	leftText		The new left content
		@param	rightText		The new right content
	--]]
    ["SpliceLine"] = function(self, tooltip, num, leftText, rightText)
        local _ = self -- to appease luacheck
		local tooltipName = tooltip:GetName()
		local src, dest
		
		-- Add a placeholder line at the end
		tooltip:AddDoubleLine(" ", " ")
		
		-- Start at the end of the tooltip and adjust lines
		-- down until we reach the point of insertion.
		for i=tooltip:NumLines(), num, -1 do
			for _, side in ipairs(tooltipSides) do
				src = _G[tooltipName .. side .. i-1]

				if src then
					dest = _G[tooltipName .. side .. i]
					
					if dest then
						CloneLine(src, dest)
						dest:Show()
					end
				end
			end
		end
		
		dest = _G[tooltipName .. "TextLeft" .. num]
		
		if dest then
			if leftText then
				CloneLine(leftText, dest)
				dest:Show()
			else
				-- Clear text in case this line is shifted and shown again
				dest:SetText(" ")
			end
		end
		
		dest = _G[tooltipName .. "TextRight" .. num]
		
		if dest then
			if rightText then
				CloneLine(rightText, dest)
				dest:Show()
			else
				-- Clear text in case this line is shifted and shown again
				dest:SetText(" ")
			end
		end
		
		-- Refresh tooltip
		tooltip:Show()
	end,
	--[[
		Scan the tooltip for given pattern and return matches
		
		@param	tooltip		The tooltip to scan
		@param	pattern		What to look for
		@param	num			What line to start scanning from
		@param	exactFlag	Match the 'pattern' exactly
		@return				The FontString object, line number, and text found
	--]]
    ["ScanTooltip"] = function(self, tooltip, pattern, num, exactFlag)
        local _ = self -- to appease luacheck
		if not pattern then return end
		
		local tooltipName = tooltip:GetName()
		local part, text
		local numType = type(num)
		
		-- Allow for psuedo-varargs
		if numType == "boolean" then
			exactFlag = num
		elseif numType == "string" then
			num = tonumber(num)
		end
		
		if numType ~= "number" or num < 1 then
			num = 1
		end
		
		if exactFlag then
			pattern = "^" .. pattern .. "$"
		end
		
		for i=num, tooltip:NumLines() do
			for _, side in ipairs(tooltipSides) do
				part = _G[tooltipName .. side .. i]
				
				if part then
					text = part:GetText()
					
					if text and text:match(pattern) then
						return part, i, text:match(pattern)
					end
				end
			end
		end
		
		return nil, 0, nil
	end,
	--[[
		Hide all textures in tooltip and potentially re-align left FontStrings.
		
		@param	tooltip	Tooltip for which to hide all textures
		@param	align	Whether to re-align left FontStrings. If {@code true}, re-align
						FontStrings. If {@code false}, do not re-align FontStrings.
	--]]
    ["HideAllTextures"] = function(self, tooltip, align)
        local _ = self -- to appease luacheck
		local tooltipName = tooltip:GetName()
		local texture, curFont, prevFont
		
		for i=1, 10 do
			texture = _G[tooltipName .. "Texture" .. i]
			if texture then texture:Hide() end
		end
		
		if align then
			for i=1, tooltip:NumLines() do
				curFont = _G[tooltipName .. "TextLeft" .. i]
				if not curFont then break end
				
				curFont:ClearAllPoints()
				
				-- Re-align all font strings on left side of tooltip since the
				-- texture is no longer there and the text will appear indented.
				if i == 1 then
					curFont:SetPoint("TOPLEFT", tooltip, 10, -10)
				else
					prevFont = _G[tooltipName .. "TextLeft" .. i-1]
					
					if prevFont then
						curFont:SetPoint("TOPLEFT", prevFont, "BOTTOMLEFT", 0, -2)
					end
				end
			end
		end
		
		tooltip:Show()
	end,
	--[[
        Code was moved from SpliceLine function so it is only called once, after all adjustments

		@param	tooltip	Tooltip for which to adjust money frame
	--]]
    ["AdjustMoneyFrame"] = function(self, tooltip)
        local _ = self -- to appease luacheck
		local tooltipName = tooltip:GetName()

		-- Adjust the money frame if it is being shown.
		if (tooltip.shownMoneyFrames) then
			local moneyFrame = _G[tooltipName.."MoneyFrame1"]
			local money = 0
			
			if (moneyFrame) then
				if (moneyFrame.info) then
					money = moneyFrame.info.UpdateFunc(moneyFrame)
				end
				
				-- Get money manunally from the frame
				if (not money) then
					local moneyFrameName = tooltipName .. "MoneyFrame1"
					local copper = _G[moneyFrameName.."CopperButtonText"]
					local silver = _G[moneyFrameName.."SilverButtonText"]
					local gold = _G[moneyFrameName.."GoldButtonText"]
					local t
					
					if (gold) then
						t = gold:GetText()
						
						if (t) then
							money = money + (t * 10000)
						end
					end
					
					if (silver) then
						t = silver:GetText()
						
						if (t) then
							money = money + (t * 100)
						end
					end
					
					if (copper) then
						t = copper:GetText()
						
						if (t) then
							money = money + t
						end
					end
				end
			end
			
			GameTooltip_ClearMoney(tooltip)
            SetTooltipMoney(tooltip, money)
		end
	end,
	--[[
		Fix really long lines that may have been shifted and ended up in
		non-wrapped positions.

		@param	tooltip	The tooltip for which to wrap lines
		@param	...		List of strings to look for and wrap
	--]]
	["WrapLongLines"] = function(self, tooltip, ...)
		-- Gets tooltip line of approximately 250 width
		local width = 32 -- character count
		local loopMax = 50
		local argText, left, num, text, loop

        -- Index of spaces
        local s
        -- Tracks position in current text segment
        local t
        -- Tracks position in entire text
        local x
        -- Holds entire replacement text (with newlines)
        local replace
        -- Holds working text segment
        local str

		-- Loop through all texts to look for as wrapping targets.
		for i=1, select("#", ...) do
			argText = select(i, ...)
			left, num = self:ScanTooltip(tooltip, argText)
		
			if num and left and num > 0 then
				text = left:GetText()
				
				if text:len() > width then
					-- Break up long text on first space after 'width' characters
					-- so we don't get breaks in the middle of words.
					loop = 1
					t = 0
					x = 0
					replace = ""
					str = text
				
					while true do
						s = str:find(" ")

						if s == nil then
							-- Reached end of possible breaks we can do
							-- Just tack the rest on the end.
							left:SetText(replace .. text:sub(x+1, t+x) .. str)
							break
						else
							-- Shift our current segment index
							t = t + s
							
							if t < width then
								-- Grab next text segment
								str = str:sub(s+1, str:len())
							else
								-- Break string with newline and trim spaces so we don't
								-- get a segment that starts with a space as it doesn't look
								-- right in the tooltip.
								replace = replace .. strtrim(text:sub(x+1, t+x)) .. "\n"
								
								-- Grab next text segment to work with
								str = text:sub(t+x+1, text:len())
								
								-- Adjust index that is tracking our position in the entire text
								x = x + t
								
								-- Reset index for the current text segment.
								t = 0
							end
						end
						
						-- Failsafe to prevent infinite recursion
						if loop > loopMax then break end
						loop = loop + 1
					end
				end
				
				-- Adjust text down one line
				self:SpliceLine(tooltip, num+1, left:GetText())
				left:SetText(" ")
			end
		end
	end,
}
