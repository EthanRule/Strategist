local Strategist = LibStub("AceAddon-3.0"):NewAddon("Strategist", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local frame 
local editbox
local button
local partyMembers = {}

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
		-- msg = {
		-- 	type = "input",
		-- 	name = "Message",
		-- 	desc = "The message to be displayed when you get home.",
		-- 	usage = "<Your message>",
		-- 	get = "GetCurComp",
		-- 	set = "SetCurComp",
		-- },
		nestedDict = {         -- Adding a nested dictionary
			name = "Nested Dictionary", -- Add a valid string value for the name
			type = "group",
			args = {
				subKey1 = {
					type = "input",
					name = "Sub Key 1",
					desc = "Description for Sub Key 1",
					usage = "<Value for Sub Key 1>", -- Example usage field
					get = function(info) end, -- Example get function
					set = function(info, value) end, -- Example set function
				},
				subKey2 = {
					type = "toggle",
					name = "Sub Key 2",
					desc = "Description for Sub Key 2",
					get = function(info) end, -- Example get function
					set = function(info, value) end, -- Example set function
				},
				-- Additional key-value pairs within the nested dictionary
			}
		},
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
	-- self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Strategist:PLAYER_ENTERING_WORLD()
	print("Hello")
	local _, instanceType, _, _, _, _, _, _ = GetInstanceInfo()
	print(instanceType)

	if instanceType == "arena" then
		print("Entered arena.")

		local timer = C_Timer.NewTicker(5, RefreshPartyMembers)
		C_Timer.After(30, function() Strategist:OnTimerClose(timer) end)
	end
end

function Strategist:OnTimerClose(timer)
	print("Closing timer...")
	timer:Cancel() 

	-- Retrieve and display class and spec for each party member
	local temp = ""
	for _, playerName in ipairs(partyMembers) do
		local class, spec = GetClassAndSpec(playerName)
		print("Class: " .. class .. " spec: " .. spec)
		temp = temp .. class .. spec
	end

	print("comp: " .. temp)

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
	self.db.profile.comps[curComp] = {}
	print(curComp)
	self.db:SaveData()
end

function Strategist:GetAllMyCompsHaveFaced(curComp)
	return self.db.profile.comps[curComp]
end

function GetClassAndSpec(playerName)
	local _, class, _, _, _, _ = GetPlayerInfoByGUID(UnitGUID(playerName))
	local specIndex = GetSpecialization(playerName)
	local _, spec = GetSpecializationInfo(specIndex)
	
	return class, spec
end

function IsPartyMemberInTable(playerName)
	for _, name in ipairs(partyMembers) do
		if playerName == name then
			return true
		end
	end

	return false
end
  
function RefreshPartyMembers()
	print("Refreshing...")
	-- Get the names of arena party members dynamically
	local numOfPartyMembers = GetNumGroupMembers()

	for i = 1, numOfPartyMembers do
	  	local unitId = "party" .. i

	  	if UnitExists(unitId) then
			local playerName = UnitName(unitId)

			if not IsPartyMemberInTable(playerName) then
				table.insert(partyMembers, playerName)
			end
	  	end
	end

	if not IsPartyMemberInTable(UnitName("player")) then
		-- Add the player
		table.insert(partyMembers, UnitName("player"))
	end
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
