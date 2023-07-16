print("Hello World!")
SLASH_TEST1 = "/strategist"
SlashCmdList["TEST"] = function(msg)
   print("Hello World!")
end 

-- (1)
local f = CreateFrame("Frame", "Strategist", UIParent)
f:SetSize(400, 400)
f:SetPoint("CENTER")

-- (2)
f:SetBackdrop({
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeSize = 1,
})
f:SetBackdropColor(0, 0, 0, .5)
f:SetBackdropBorderColor(0, 0, 0)

-- (3)
f:EnableMouse(true)
f:SetMovable(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)
f:SetScript("OnHide", f.StopMovingOrSizing)

-- (4)
local close = CreateFrame("Button", "YourCloseButtonName", f, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", f, "TOPRIGHT")
close:SetScript("OnClick", function()
	f:Hide()
end)

-- (5)
local text = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
text:SetPoint("CENTER")
text:SetText("Hello World!")