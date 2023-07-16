local StrategistAce = LibStub("AceAddon-3.0"):NewAddon("Strategist", "AceConsole-3.0")
local StrategistConsole = LibStub("AceConsole-3.0")


function StrategistAce:OnInitialize()
    StrategistAce:Print("Hello, world!")
    self.db = LibStub("AceDB-3.0"):New("StrategistDB")
end

function StrategistAce:OnEnable()
    -- Called when the addon is enabled
end

function StrategistAce:OnDisable()
    -- Called when the addon is disabled
end

