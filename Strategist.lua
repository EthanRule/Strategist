local Strategist = LibStub("AceAddon-3.0"):NewAddon("Strategist", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local frame
local editbox
local button
local unitIDs = {}


local defaults = {
	profile = {
		message = "Welcome Home!",
		comps = {},
	},
}

local options = {
	name = "Strategist",
	handler = Strategist,
	type = "group",
	args = {
		msg = {
			type = "input",
			name = "Message",
			desc = "The message to be displayed when you get home.",
			usage = "<Your message>",
			get = "GetCurComp",
			set = "SetCurComp",
		},
		-- nestedDict = {         -- Adding a nested dictionary
		-- 	name = "Nested Dictionary", -- Add a valid string value for the name
		-- 	type = "group",
		-- 	args = {
		-- 		subKey1 = {
		-- 			type = "input",
		-- 			name = "Sub Key 1",
		-- 			desc = "Description for Sub Key 1",
		-- 			usage = "<Value for Sub Key 1>", -- Example usage field
		-- 			get = function(info) end, -- Example get function
		-- 			set = function(info, value) end, -- Example set function
		-- 		},
		-- 		subKey2 = {
		-- 			type = "toggle",
		-- 			name = "Sub Key 2",
		-- 			desc = "Description for Sub Key 2",
		-- 			get = function(info) end, -- Example get function
		-- 			set = function(info, value) end, -- Example set function
		-- 		},
		-- 		-- Additional key-value pairs within the nested dictionary
		-- 	}
		-- },
	},
}

function Strategist:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("StrategistDB", defaults, true)
	AC:RegisterOptionsTable("Strategist_options", options)
	self.optionsFrame = ACD:AddToBlizOptions("Strategist_options", "Strategist")

	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	AC:RegisterOptionsTable("Strategist_Profiles", profiles)
	ACD:AddToBlizOptions("Strategist_Profiles", "Profiles", "Strategist")

	self:RegisterChatCommand("strat", "SlashCommand")
	self:RegisterChatCommand("strategist", "SlashCommand")
end

function Strategist:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	-- self:RegisterEvent("GROUP_ROSTER_UPDATE") -- add someone to the queue with this event, check if they already exist too
end

function Strategist:PLAYER_ENTERING_WORLD()
	local _, instanceType, _, _, _, _, _, _ = GetInstanceInfo()

	if instanceType == "arena" then
		Strategist:EnteredArena()
	elseif instanceType ~= "arena" and self.instanceType == "arena" then
		Strategist:LeftArena()
	end

	self.instanceType = instanceType
end

function Strategist:EnteredArena()
	print("Entered arena.")
	self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	self:RegisterEvent("ARENA_OPPONENT_UPDATE")

	-- Get Party Information
	local timer = C_Timer.NewTicker(5, RefreshPartyMembers)
	C_Timer.After(30, function() Strategist:OnTimerClose(timer) end)

	local numOpps = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0

	if numOpps and numOpps > 0 then
		Strategist:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	end
end

-- function Strategist:GROUP_ROSTER_UPDATE()
-- 	local numGroupMembers = GetNumGroupMembers()
-- 	if numGroupMembers > 0 then
-- 		for i = 1, numGroupMembers do
-- 			local unitId = "party" .. i
-- 			if UnitExists(unitId) and not Strategist:IsUnitIdInTable(unitId) then
-- 				local class, spec = Strategist:GetClassAndSpec(unitId)
-- 				print(class)
-- 				print(spec)
-- 				if class and spec then
-- 					table.insert(unitIDs, unitId)
-- 					print(class .. " - " .. spec)
-- 				end
-- 			end
-- 		end
-- 	else
-- 		print("You are not in a group.")
-- 	end
-- end

function Strategist:GetAllMyCompsHaveFaced(curComp)
	return self.db.profile.comps[curComp]
end

-- need events to trigger queue pops

function Strategist:GetClassAndSpec(unitId)
	local iD = nil
	print("GetClassAndSpec unitId" .. unitId)

	if unitId then
		if unitId == "player" then
			iD = GetSpecialization()
			iD = select(1, GetSpecializationInfo(iD))
			print("the next line is player iD")
			print(iD)
			-- elseif Strategist:IsValidUnit(unitId) then                              //OPONENTS
			-- 	print("Arena person")
			-- 	iD = GetArenaOpponentSpec and GetArenaOpponentSpec(tonumber(unitId))

			-- 	if iD then
			-- 		print("Arena id: " .. iD)
			-- 	end
		elseif strmatch(unitId, "party(%d+)") then
			iD = GetInspectSpecialization(unitId)
		end

		print(iD)
		if iD then
			local specID, specName, description, icon, background, role, class = GetSpecializationInfoByID(iD)

			return class, specName
		end
	end

	return nil, nil
end

function Strategist:PrintUnitIdTable()
	print("Printing IDs")

	for _, Id in ipairs(unitIDs) do
		print(Id)
	end

	print("Printing IDs END")
end

function Strategist:IsUnitIdInTable(unitId)
	for _, Id in ipairs(unitIDs) do
		if unitId == Id then
			return true
		end
	end

	return false
end

function Strategist:ARENA_OPPONENT_UPDATE(event, unit, type)
	if not Strategist:IsValidUnit(unit) then
		return
	end
	print("Opponent updated")

	local id = string.match(unit, "arena(%d)")
	local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(tonumber(id))

	if specID and specID > 0 and not Strategist:IsUnitIdInTable(unit) then
		table.insert(unitIDs, unit)
	end
end

function Strategist:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	print("Prepping opponent information")
	for i = 1, GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0 do
		local unit = "arena" .. i
		local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)

		if specID and specID > 0 and not Strategist:IsUnitIdInTable(unit) then
			table.insert(unitIDs, unit)
		end
	end
end

function RefreshPartyMembers()
	print("Refreshing...")
	local _, _, _, _, maxPlayers, _, _, instanceMapID = GetInstanceInfo()

	local numOfPartyMembers = GetNumGroupMembers()
	print(numOfPartyMembers)
	print("Max number of players allowed " .. maxPlayers)

	for i = 1, numOfPartyMembers do
		local unitId = "party" .. i

		if UnitExists(unitId) then
			if not Strategist:IsUnitIdInTable(unitId) then
				table.insert(unitIDs, unitId)
				print(unitId)
			end
		end
	end

	if not Strategist:IsUnitIdInTable("player") then
		table.insert(unitIDs, "player")
	end
end

function Strategist:IsValidUnit(unit)
	if not unit then
		return
	end

	local unitID = strmatch(unit, "arena(%d+)")
	return unitID and tonumber(unitID) <= 5
end

function Strategist:LeftArena()
	print("Left arena.")
	self:UnregisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
	Strategist:PrintUnitIdTable()

	if frame then
		frame:Hide()
	end

	unitIDs = {}
end

function Strategist:OnTimerClose(timer)
	print("Closing timer...")
	timer:Cancel()

	-- Retrieve and display class and spec for each party member
	local temp = ""
	local enemyTemp = ""
	for _, unitId in ipairs(unitIDs) do
		local class, spec = Strategist:GetClassAndSpec(unitId)

		if class and spec and not strmatch(unitId, "party(%d+)") then
			if unitId == "player" or strmatch(unitId, "party(%d+)") then
				print("Class: " .. class .. " spec: " .. spec)
				temp = temp .. class .. spec
			else
				enemyTemp = enemyTemp .. class .. spec
			end
		end
	end

	print("my comp: " .. temp)
	print("enemy comp: " .. enemyTemp)

	Strategist:SetCurComp(temp)

	Strategist:GUI()
end

function Strategist:SlashCommand(msg)
	if not msg or msg:trim() == "" then
		-- https://github.com/Stanzilla/WoWUIBugs/issues/89
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	else
		self:Print("hello there!")
	end
end

function Strategist:GetMessage(info)
	return self.db.profile.message
end

function Strategist:SetMessage(info, value)
	self.db.profile.message = value
end

function Strategist:GetCurComp(info)
	return self.db.profile.comps
end

function Strategist:SetCurComp(curComp)
	if curComp == nil then
		return
	end

	self.db.profile.comps[curComp] = {}
	print(curComp)
end

function Strategist:GUI()
	print("Entered new zone!")

	if frame ~= nil and frame:IsShown() then
		print("Frame is already visible!")
	else
		print("Frame is not visible!")

		if frame == nil then
			print("Creating frame!")
			frame = AceGUI:Create("Frame")
			frame:SetTitle("Strategist")
			frame:SetCallback("OnClose", function(widget)
				-- AceGUI:Release(widget)
				widget:Hide() -- Hide the frame instead of releasing it
			end)
			frame:SetLayout("Fill")
			frame:SetWidth(400)
			frame:SetHeight(200)

			editbox = AceGUI:Create("MultiLineEditBox")
			editbox:SetLabel("Insert text:")
			editbox:SetWidth(400)
			frame:AddChild(editbox)

			button = AceGUI:Create("Button")
			button:SetText("Save")
			button:SetWidth(100)
			frame:AddChild(button)
		else
			print("Showing frame!")
			frame:Show()
		end
	end
end
