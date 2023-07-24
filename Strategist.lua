local Strategist = LibStub("AceAddon-3.0"):NewAddon("Strategist", "AceConsole-3.0", "AceEvent-3.0", "AceSerializer-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local frame
local editbox
local unitIDs = {}
local pendingInspections = {}
local playerComp = {}
local processedUnitIDs = {}
local enemyComp = {}
local specializationIcons = {}


local defaults = {
	profile = {
		message = "Welcome Home!",
		popUp = true,
		comps = {},
	},
}

local options = {
	name = "Strategist",
	handler = Strategist,
	type = "group",
	args = {
		popUp = {
			name = "Show Popup Window",
			desc = "Enables / disables the popup window",
			type = "toggle",
			set = "SetPopUp",
			get = "GetPopUp",
			order = 1,
		},
		import = {
			name = "Import",
			desc = "Import a profile",
			type = "execute",
			func = "InitiateImport",
		},
		export = {
			name = "Export",
			desc = "Export a profile",
			type = "execute",
			func = "ExportProfile",
		}
	},
}

function Strategist:SetPopUp(info)
	local pop = self.db.profile.popUp
	self.db.profile.popUp = not pop
end

function Strategist:GetPopUp(info)
	return self.db.profile.popUp
end

function Strategist:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:GetMainTable()
end

function Strategist:OnInitialize()
	-- Create Database & Fill specializationIcons Table
	self.db = LibStub("AceDB-3.0"):New("StrategistDB", defaults, true)
	local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	self:PopulateSpecializationIcons()

	-- Profiles
	self.db.RegisterCallback(self, "OnProfileChanged", "GetMainTable");
	self.db.RegisterCallback(self, "OnProfileReset", "GetMainTable");
	self.optionsFrame = ACD:AddToBlizOptions("Strategist_options", "Strategist")
	self.profilesFrame = ACD:AddToBlizOptions("Strategist_Profiles", "Profiles", "Strategist")
	AC:RegisterOptionsTable("Strategist_options", options)
	AC:RegisterOptionsTable("Strategist_Profiles", profiles)

	-- Slash Commands
	self:RegisterChatCommand("strat", "SlashCommand")
	self:RegisterChatCommand("strategist", "SlashCommand")
	self:RegisterChatCommand("teststrat", "StrategistWindowTest")
	self:RegisterChatCommand("teststrategist", "StrategistWindowTest")
end

-- Events --

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
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("INSPECT_READY")

	local class, spec = Strategist:GetClassAndSpec("player")
	if class and spec then
		table.insert(playerComp, class .. spec)
	else
		print("Error: Failed to get player class and spec")
	end

	local numOpps = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0

	if numOpps and numOpps > 0 then
		Strategist:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	end
end

function Strategist:LeftArena()
	self:UnregisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
	self:UnregisterEvent("GROUP_ROSTER_UPDATE") -- add someone to the queue with this event, check if they already exist too
	self:UnregisterEvent("INSPECT_READY")

	unitIDs = {}
	playerComp = {}
	enemyComp = {}
	processedUnitIDs = {}
end

function Strategist:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	local addedInfo = false
	for i = 1, GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or 0 do
		local unit = "arena" .. i
		local specID = GetArenaOpponentSpec and GetArenaOpponentSpec(i)

		if specID and specID > 0 then
			local iD, specName, description, icon, background, role, class = GetSpecializationInfoByID(specID)
			if class and specName and not Strategist:IsInTable(processedUnitIDs, unit) then
				addedInfo = true
				table.insert(processedUnitIDs, unit)
				table.insert(enemyComp, class .. specName)
			end
		end
	end

	if addedInfo then
		Strategist:CheckIfGUIReady()
	end
end

function Strategist:IsInTable(table, item)
	for _, Id in ipairs(table) do
		if item == Id then
			return true
		end
	end
	return false
end

function Strategist:CheckIfGUIReady()
	local numOpps = GetNumArenaOpponentSpecs()
	local numGroup = GetNumGroupMembers()

	if numOpps > 1 and numGroup > 1 and numOpps == numGroup and #enemyComp == #playerComp then
		table.sort(enemyComp, SortAlphabetically)
		table.sort(playerComp, SortAlphabetically)

		local concatPlayer = ConcatComp(playerComp)
		local concatEnemy = ConcatComp(enemyComp)

		Strategist:SetCurComp(concatPlayer, concatEnemy)
		Strategist:GUI(false, "", "")
	end
end

function SortAlphabetically(a, b)
	return a:lower() < b:lower()
end

function ConcatComp(comp)
	local temp = ""

	for i, classAndSpec in ipairs(comp) do
		if i ~= 1 then
			temp = temp .. "-" .. classAndSpec
		else
			temp = temp .. classAndSpec
		end
	end

	return temp
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

function Strategist:GROUP_ROSTER_UPDATE()
	if not Strategist:IsInTable(unitIDs, "player") then
		table.insert(unitIDs, "player")
	end

	local numGroupMembers = GetNumGroupMembers()
	if numGroupMembers > 0 then
		for i = 1, numGroupMembers do
			local unitId = "party" .. i
			if UnitExists(unitId) and not Strategist:IsInTable(unitIDs, unitId) then
				table.insert(unitIDs, unitId)

				local guid = UnitGUID(unitId)
				pendingInspections[guid] = unitId
			end
		end
	end
end

function Strategist:INSPECT_READY(event, guid)
	local addedInfo = false
	if pendingInspections[guid] then
		local playerUnitId = pendingInspections[guid]
		pendingInspections[guid] = nil
		local class, spec = Strategist:GetClassAndSpec(playerUnitId)
		if class and spec and not Strategist:IsInTable(processedUnitIDs, playerUnitId) then
			addedInfo = true
			table.insert(processedUnitIDs, playerUnitId)
			table.insert(playerComp, class .. spec)
		else
			print("Error: Failed to get class and spec")
		end
	end

	if addedInfo then
		Strategist:CheckIfGUIReady()
	end
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

-- Blizzard AddOns Interface UI --

function Strategist:PopulateSpecializationIcons()
	for classID = 1, GetNumClasses() do
		local class, className = GetClassInfo(classID)

		for specIndex = 1, GetNumSpecializationsForClassID(classID) do
			local _, specName, _, specIcon = GetSpecializationInfoForClassID(classID, specIndex)
			specializationIcons[class .. specName] = specIcon
		end
	end
end

function Strategist:GetMainTable()
	local tableOfComps = self.db.profile.comps

	if type(tableOfComps) ~= "table" then
		print("Error: Not a table")
		return
	end

	for comp, enemyTable in pairs(tableOfComps) do
		if comp then
			local curComp = {}
			local enemyComps = {}
			curComp["name"] = comp
			curComp["type"] = "group"

			if enemyTable and type(enemyTable) == "table" then
				for enemyComp, strat in pairs(enemyTable) do
					local curEnemyComp = {}
					curEnemyComp["name"] = enemyComp
					curEnemyComp["type"] = "input"
					curEnemyComp["multiline"] = true
					curEnemyComp["set"] = function(info, text)
						self.db.profile.comps[comp][enemyComp] = text
					end
					curEnemyComp["get"] = function()
						if not self.db.profile.comps[comp] then
							self.db.profile.comps[comp] = { [enemyComp] = strat }
						end

						return self.db.profile.comps[comp][enemyComp]
					end
					enemyComps[enemyComp] = curEnemyComp
				end

				curComp["args"] = enemyComps
				options.args[comp] = curComp
			end
		end
	end
end

-- Strategist Window --

function Strategist:GUI(test, testPlayerComp, testEnemyComp)
	if not self.db.profile.popUp then
		return
	end

	local concatPlayer
	local concatEnemy
	local compText

	-- Check if this is a "/teststrat" window
	if test == false then
		concatPlayer = ConcatComp(playerComp)
		concatEnemy = ConcatComp(enemyComp)
		compText = self.db.profile.comps[concatPlayer][concatEnemy]
	elseif test == true then
		concatPlayer = testPlayerComp
		concatEnemy = testEnemyComp
		compText = "Test window!"
	end


	if not frame then
		frame = AceGUI:Create("Frame")
		frame:SetTitle("Strategist")
		frame:SetCallback("OnClose", function(widget)
			frame:Release()
			frame = nil
			editbox = nil
		end)
		frame:SetLayout("Flow")
		frame:SetWidth(400)
		frame:SetHeight(300)

		Strategist:CreateEditBox(compText, concatPlayer, concatEnemy)
	else
		if frame:IsShown() then
			Strategist:CreateEditBox(compText, concatPlayer, concatEnemy)
		end
	end
end

function Strategist:CreateEditBox(compText, concatPlayer, concatEnemy)
	if editbox then
		editbox:Release()
		editbox = nil
	end
	Strategist:GetSpecIcons(concatPlayer, concatEnemy)
	editbox = AceGUI:Create("MultiLineEditBox")
	editbox:SetLabel("")
	editbox:SetText(compText)
	editbox:SetWidth(400)
	editbox:SetCallback("OnEnterPressed", function(widget, event, text)
		self.db.profile.comps[concatPlayer][concatEnemy] = text
	end)
	frame:AddChild(editbox)
end

function Strategist:GetSpecIcons(playerComp, enemyComp)
	local playerGroup = AceGUI:Create("SimpleGroup")
	playerGroup:SetLayout("Flow")
	playerGroup:SetWidth(100)

	local enemyGroup = AceGUI:Create("SimpleGroup")
	enemyGroup:SetLayout("Flow")
	enemyGroup:SetWidth(100)

	local spacer = AceGUI:Create("SimpleGroup")
	spacer:SetLayout("Flow")
	spacer:SetWidth(150)

	local playerTable = Split(playerComp)
	local enemyTable = Split(enemyComp)

	for _, classAndSpec in ipairs(playerTable) do
		self:SetSpecIcons(classAndSpec, playerGroup)
	end

	for _, classAndSpec in ipairs(enemyTable) do
		self:SetSpecIcons(classAndSpec, enemyGroup)
	end

	local compGroup = AceGUI:Create("SimpleGroup")
	compGroup:SetLayout("Flow")
	compGroup:SetWidth(400)

	compGroup:AddChild(playerGroup)
	compGroup:AddChild(spacer)
	compGroup:AddChild(enemyGroup)

	frame:AddChild(compGroup)
end

function Strategist:SetSpecIcons(classAndSpec, group)
	local composition = AceGUI:Create("Icon")
	composition:SetImageSize(30, 30)
	composition:SetImage(specializationIcons[classAndSpec])
	composition:SetRelativeWidth(0.33)
	group:AddChild(composition)
end

function Split(comp)
	local classes = {}
	for classAndSpec in string.gmatch(comp, "([^%-]+)") do
		table.insert(classes, classAndSpec)
	end
	return classes
end

-- Profiles --

function Strategist:ImportProfile(data)
	-- https://github.com/jordonwow/omnibar/blob/master/OmniBar.lua
	if not data then
		return
	end

	local realData = self:Decode(data)

	if not realData then
		return
	end

	if (realData.version ~= 1) then return end

	local profile = realData.name

	self.db.profiles[profile] = realData.profile
	self.db:SetProfile(profile)
	self:OnEnable()

	LibStub("AceConfigRegistry-3.0"):NotifyChange("Strategist")

	return true
end

function Strategist:Decode(encoded)
	-- https://github.com/jordonwow/omnibar/blob/master/OmniBar.lua
	local LibDeflate = LibStub:GetLibrary("LibDeflate")
	local decoded = LibDeflate:DecodeForPrint(encoded)
	if (not decoded) then return end
	local decompressed = LibDeflate:DecompressZlib(decoded)
	if (not decompressed) then return end
	local success, deserialized = self:Deserialize(decompressed)
	if (not success) then return end
	return deserialized
end

function Strategist:InitiateImport()
	self:CreateEditBoxForProfile(nil)
end

function Strategist:GetProfileData()
	-- https://github.com/jordonwow/omnibar/blob/master/OmniBar.lua
	local LibDeflate = LibStub:GetLibrary("LibDeflate")
	local data = {
		profile = self.db.profile,
		name = UnitName("player"),
		version = 1
	}
	local serialized = self:Serialize(data)
	if (not serialized) then return end
	local compressed = LibDeflate:CompressZlib(serialized)
	if (not compressed) then return end
	return LibDeflate:EncodeForPrint(compressed)
end

function Strategist:ExportProfile()
	local data = self:GetProfileData()
	self:CreateEditBoxForProfile(data)
end

function Strategist:CreateEditBoxForProfile(text)
	local profileFrame = AceGUI:Create("Frame")
	profileFrame:SetCallback("OnClose", function(widget)
		profileFrame:Release()
	end)
	profileFrame:SetLayout("Fill")
	profileFrame:SetWidth(600)
	profileFrame:SetHeight(600)

	if text then
		-- We are exporting
		profileFrame:SetTitle("Strategist Export")
		local exportEditBox = AceGUI:Create("MultiLineEditBox")
		exportEditBox:SetText(text)
		exportEditBox:HighlightText()
		exportEditBox:SetFocus()
		exportEditBox:SetWidth(400)
		exportEditBox:SetHeight(400)
		exportEditBox.editBox.autoComplete = false
		profileFrame:AddChild(exportEditBox)
	else
		-- We are importing
		profileFrame:SetTitle("Strategist Import")
		local importEditBox = AceGUI:Create("MultiLineEditBox")
		importEditBox:SetText("")
		importEditBox:SetFocus()
		importEditBox:SetWidth(400)
		importEditBox:SetHeight(400)
		importEditBox:SetCallback("OnEnterPressed", function(widget, event, data)
			self:ImportProfile(data)
			ACR:NotifyChange("Strategist_options")
		end)
		profileFrame:AddChild(importEditBox)
	end
end

-- Slash commands --

function Strategist:SlashCommand()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function Strategist:StrategistWindowTest()
	local testPlayerComp = "DruidBalance-MonkWindwalker-PaladinHoly"
	local testEnemyComp = "WarriorArms-MageFrost-DruidRestoration"
	Strategist:GUI(true, testPlayerComp, testEnemyComp)
end

-- Debug Functions --

function Strategist:PrintTable(table)
	print("Printing Table START:")

	for _, Id in ipairs(table) do
		print(Id)
	end

	print("Printing Table END")
end
