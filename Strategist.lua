local addonName = "Strategist"

-- Register for the ADDON_LOADED event to load and save the data
local frame = CreateFrame("Frame")   -- Need a frame to respond to events
frame:RegisterEvent("ADDON_LOADED")  -- Fired when saved variables are loaded
frame:RegisterEvent("PLAYER_LOGOUT") -- Fired when about to log out

frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon == addonName then
        print("Strategist loaded")

        -- Access the SavedVariables for the account
        if not _G[addonName .. "Data"] then
            _G[addonName .. "Data"] = {} -- Create an empty table if it doesn't exist
        end

        -- Print the stored data
        print("Stored Data:")
        for i, text in ipairs(_G[addonName .. "Data"]) do
            print(i .. ": " .. text)
        end
    end
end)

-- Function to save text to the SavedVariables
local function SaveTextToSavedVariables(text)
    if not _G[addonName .. "Data"] then
        _G[addonName .. "Data"] = {} -- Create an empty table if it doesn't exist
    end
    table.insert(_G[addonName .. "Data"], text)
end

local frame = CreateFrame("Frame", "MyAddonFrame", UIParent, "BasicFrameTemplate")
frame:SetSize(400, 200)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("TOP", frame, "TOP", 0, -8)
title:SetText("Strategist")

local editBox = CreateFrame("EditBox", nil, frame)
editBox:SetSize(200, 80) -- Adjust the width and height as needed
editBox:SetPoint("TOPLEFT", 16, -40)
editBox:SetFontObject(GameFontNormal)
editBox:SetAutoFocus(false)
editBox:SetMultiLine(true)         -- Set it to allow multiple lines
editBox:SetMaxLetters(0)           -- Remove any character limit
editBox:SetScript("OnEnterPressed", function(self)
    self:Insert("\n")              -- Insert a new line when Enter is pressed
    self:SetTextInsets(0, 0, 0, 0) -- Reset the text insets to prevent unnecessary scrolling
    self:SetCursorPosition(0)      -- Set the cursor position to the end of the text
    self:ClearFocus()              -- Clear the focus after pressing Enter

    local text = self:GetText()    -- Get the entered text
    SaveTextToSavedVariables(text) -- Save the text to Saved Variables
end)

editBox:SetText("Enter text here")

frame.editBox = editBox -- Store the reference to the editBox in the frame for later use

frame:Show()

SLASH_STRATEGIST1 = "/strategist"

local function OpenStrategistWindow()
    print("In Open strategist window function")
    if not MyAddonFrame:IsShown() then
        MyAddonFrame:Show()
    end
end

SlashCmdList["STRATEGIST"] = OpenStrategistWindow

-- local arenaFrame = CreateFrame("Frame")
-- arenaFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- arenaFrame:RegisterEvent("ARENA_OPPONENT_UPDATE")

-- -- Table to store opponent information
-- local opponents = {}

-- -- Function to retrieve class and specialization information
-- local function GetOpponentInfo(index)
--     local name, _, _, _, _, className, _, classID, specID = GetArenaOpponentInfo(index)
--     local classColor = RAID_CLASS_COLORS[className]

--     return {
--         name = name,
--         className = className,
--         classColor = classColor,
--         specID = specID,
--     }
-- end

-- -- Event handler function
-- local function OnEvent(self, event)
--     if event == "PLAYER_ENTERING_WORLD" then
--         local inArena = select(2, IsInInstance()) == "arena"
--         -- Reset opponents table when entering a new arena
--         if inArena then
--             print("Entered arena")
--             OpenStrategistWindow()
--             wipe(opponents)
--         end
--     elseif event == "ARENA_OPPONENT_UPDATE" then
--         print("More opponent information")
--         -- Get the current number of opponents
--         local numOpponents = GetNumArenaOpponents()
--         print("num of opp" .. numOpponents)

--         -- Check for new opponents
--         for i = 1, numOpponents do
--             if not opponents[i] then
--                 -- Retrieve information for new opponent
--                 opponents[i] = GetOpponentInfo(i)
--                 print(opponents[i])
--             end
--         end
--     end
-- end

-- Register event handler function
arenaFrame:SetScript("OnEvent", OnEvent)

frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
editBox:SetText("Enter text here")
frame.editBox = editBox -- Store the reference to the editBox in the frame for later use
