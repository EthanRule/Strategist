local Strategist = LibStub("AceAddon-3.0"):NewAddon("Strategist", "AceConsole-3.0", "AceEvent-3.0")
local AC = LibStub("AceConfig-3.0")
local ACD = LibStub("AceConfigDialog-3.0")

local defaults = {
	profile = {
		message = "Welcome Home!",
		comps = { ["rmp"] = "test" },
		showOnScreen = true,
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
			get = "GetMessage",
			set = "SetMessage",
		},
		showOnScreen = {
			type = "toggle",
			name = "Show on Screen",
			desc = "Toggles the display of the message on the screen.",
			get = "IsShowOnScreen",
			set = "ToggleShowOnScreen"
		},
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
	self:RegisterEvent("ZONE_CHANGED")
end

function Strategist:ZONE_CHANGED()
	if GetBindLocation() == GetSubZoneText() then
		if self.db.profile.showOnScreen then
			UIErrorsFrame:AddMessage(self.db.profile.message, 1, 1, 1)
		else
			self:Print(self.db.profile.message)
		end
	end
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

function Strategist:IsShowOnScreen(info)
	return self.db.profile.showOnScreen
end

function Strategist:ToggleShowOnScreen(info, value)
	self.db.profile.showOnScreen = value
end

function Strategist:GetCurComp(info)
end

function Strategist:SetCurComp(curComp)
	self.db.profile.comps[curComp] = {}
end

function Strategist:GetAllMyComps(curComp)
end

function Strategist:GetAllMyCompsHaveFaced(curComp)
	return self.db.profile.comps[curComp]
end

Strategist:SetMessage("BalanceDruid")
