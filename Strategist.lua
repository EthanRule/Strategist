print("hello world")
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
    self:ScrollToEnd()             -- Scroll to the end of the text box
    self:ClearFocus()              -- Clear the focus after pressing Enter
end)

editBox:SetText("Enter text here")

frame.editBox = editBox -- Store the reference to the editBox in the frame for later use

frame:Show()

SLASH_STRATEGIST1 = "/strategist"

local function OpenStrategistWindow()
    print("In Open strategist window function")
    if not MyAddonFrame:IsShown() then
        print("show frame")
        MyAddonFrame:Show()
        LoadAddOn("Strategist")
    end
end

SlashCmdList["STRATEGIST"] = OpenStrategistWindow

local arenaFrame = CreateFrame("Frame")
arenaFrame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")

arenaFrame:SetScript("OnEvent", function(self, event, unitID, eventType)
    print("Entered")
    if event == "PLAYER_ENTERING_BATTLEGROUND" then
        print("Here")
        OpenStrategistWindow()
    end
end)

frame:SetScript("OnEvent", OnEvent)
frame:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
editBox:SetText("Enter text here")
frame.editBox = editBox -- Store the reference to the editBox in the frame for later use

frame:Show()
