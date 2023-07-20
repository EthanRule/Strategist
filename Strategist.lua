local Strategist = LibStub("AceAddon-3.0"):NewAddon("Strategist", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local frame
local editbox
local button
local unitIDs = {}
local pendingInspections = {}
local playerComp = {}
local enemyUnitIDs = {}
local enemyComp = {}
local guiBeingShown = false

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
end

function Strategist:EnqueuePlayers()
	-- Enter Self into table
	if not Strategist:IsInTable(unitIDs, "player") then
		table.insert(unitIDs, "player")
	end

	-- Enter Teamates into table
	local numGroupMembers = GetNumGroupMembers()
	if numGroupMembers > 0 then
		for i = 1, numGroupMembers do
			local unitId = "party" .. i
			if UnitExists(unitId) and not Strategist:IsInTable(unitIDs, unitId) then
				table.insert(unitIDs, unitId)

				-- Add the player to the pendingInspections table with their GUID
				local guid = UnitGUID(unitId)
				pendingInspections[guid] = unitId
			end
		end
	else
		print("You are not in a group.")
	end
end

function Strategist:INSPECT_READY(event, guid)
	-- Check if the inspected GUID is in the pendingInspections table
	if pendingInspections[guid] then
		local playerUnitId = pendingInspections[guid]

		-- Remove the player from the pendingInspections table
		pendingInspections[guid] = nil

		local class, spec = Strategist:GetClassAndSpec(playerUnitId)
		if class and spec and not Strategist:IsInTable(playerComp, class .. spec) then
			-- Do something with the class and spec information (e.g., store it, print it, etc.)
			print(playerUnitId .. ": " .. class .. " " .. spec)
			table.insert(playerComp, class .. spec)
		else
			print("Error: Failed to get class and spec")
		end
	end
	
	Strategist:CheckIfGUIReady()
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
	self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "EnqueuePlayers")
	self:RegisterEvent("INSPECT_READY")

	print("Entered Arena")

	local class, spec = Strategist:GetClassAndSpec("player")
	if class and spec then
		-- Do something with the class and spec information (e.g., store it, print it, etc.)
		print("player" .. ": " .. class .. " " .. spec)
		table.insert(playerComp, class .. spec)
	else
		print("Error: Failed to get player class and spec")
	end

	local numOpps = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0

	if numOpps and numOpps > 0 then
		Strategist:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	end
end

function Strategist:GetAllMyCompsHaveFaced(curComp)
	return self.db.profile.comps[curComp]
end

function Strategist:GetClassAndSpec(unitId)
	local iD = nil

	if unitId then
		if unitId == "player" then
			iD = GetSpecialization()
			iD = select(1, GetSpecializationInfo(iD))
		elseif strmatch(unitId, "party(%d+)") then
			iD = GetInspectSpecialization(unitId)
		end

		if iD then
			local specID, specName, description, icon, background, role, class = GetSpecializationInfoByID(iD)

			return class, specName
		end
	end

	return nil, nil
end

function Strategist:PrintTable(table)
	print("Printing Table START:")

	for _, Id in ipairs(table) do
		print(Id)
	end

	print("Printing Table END")
end

function Strategist:IsInTable(table, item)
	for _, Id in ipairs(table) do
		if item == Id then
			return true
		end
	end

	return false
end

function Strategist:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	print("Prepping opponent information")
	for i = 1, GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0 do
		local unit = "arena" .. i
		local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)

		if specID and specID > 0 then
			print("here")
			local iD, specName, description, icon, background, role, class = GetSpecializationInfoByID(specID)
			if class and specName and not Strategist:IsInTable(enemyComp, class .. specName) then
				print(class .. specName)
				table.insert(enemyComp, class .. specName)
			end
		end
	end

	Strategist:CheckIfGUIReady()
end

function Strategist:CheckIfGUIReady()
	local numOpps = GetNumArenaOpponentSpecs()
	local numGroup = GetNumGroupMembers()
	print("numopps " .. numOpps)
	print("numgroup " .. numGroup)
	print(#enemyComp)
	print(#playerComp)

	if not guiBeingShown and numOpps == numGroup and #enemyComp == #playerComp then
		guiBeingShown = true
		table.sort(enemyComp, SortAlphabetically)
		table.sort(playerComp, SortAlphabetically)

		local concatPlayer = ConcatComp(playerComp)
		local concatEnemy = ConcatComp(enemyComp)

		Strategist:SetCurComp(concatPlayer, concatEnemy)

		Strategist:GUI()
	end
end

function SortAlphabetically(a, b)
	return a:lower() < b:lower()
end

function ConcatComp(comp) 
	local temp = ""

	for _, classAndSpec in ipairs(comp) do
		temp = temp .. classAndSpec
	end

	return temp
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
	self:UnregisterEvent("GROUP_ROSTER_UPDATE", "EnqueuePlayers") -- add someone to the queue with this event, check if they already exist too
	self:UnregisterEvent("INSPECT_READY")

	if frame then
		frame:Hide()
	end

	print("playerComp")
	Strategist:PrintTable(playerComp)
	print("enemyComp")
	Strategist:PrintTable(enemyComp)

	guiBeingShown = false
	unitIDs = {}
	playerComp = {}
	enemyComp = {}
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

function Strategist:SetCurComp(playerComp, enemyComp)
	if not playerComp or not enemyComp then
		return
	end

	if not self.db.profile.comps[playerComp] then
		self.db.profile.comps[playerComp] = {}
	end

	if not self.db.profile.comps[playerComp][enemyComp] then
		self.db.profile.comps[playerComp][enemyComp] = ""
	end
end

function Strategist:GUI()
	print("Entered new zone!")

	if frame and frame:IsShown() then
		print("Frame is already visible!")
	else
		print("Frame is not visible!")

		if not frame then
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
			local compText = self.db.profile.comps[ConcatComp(playerComp)][ConcatComp(enemyComp)]
			editbox:SetText(compText)
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
