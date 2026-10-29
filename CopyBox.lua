-- VideoProfiles: a popup with selectable text, for copying text out of the game
-- or pasting it in.
local addonName, ns = ...

local box

-- Built from plain textures and basic templates so it works on every client.
local function Create()
    box = CreateFrame("Frame", "VideoProfilesCopyBox", UIParent)
    box:SetSize(520, 380)
    box:SetPoint("CENTER")
    box:SetFrameStrata("DIALOG")
    box:SetMovable(true)
    box:EnableMouse(true)
    box:RegisterForDrag("LeftButton")
    box:SetScript("OnDragStart", box.StartMoving)
    box:SetScript("OnDragStop", box.StopMovingOrSizing)
    box:SetClampedToScreen(true)
    tinsert(UISpecialFrames, "VideoProfilesCopyBox") -- close with Escape

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.85)

    box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    box.title:SetPoint("TOPLEFT", 12, -10)

    local hint = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPRIGHT", -36, -12)
    hint:SetText("Ctrl+C to copy, Ctrl+V to paste")

    local close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local scroll = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -32)
    scroll:SetPoint("BOTTOMRIGHT", -32, 44)

    -- Only shown when the box takes input.
    box.accept = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    box.accept:SetSize(120, 22)
    box.accept:SetPoint("BOTTOMRIGHT", -12, 12)
    box.accept:SetScript("OnClick", function()
        box:Hide()
        box.onAccept(box.edit:GetText())
    end)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(470)
    edit:SetScript("OnEscapePressed", function() box:Hide() end)
    -- In read-only mode typing would change the text, so put it back after any edit.
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput and not box.onAccept then self:SetText(box.text) self:HighlightText() end
    end)
    scroll:SetScrollChild(edit)
    -- The edit box is only as tall as its text, so a click below it focuses it too.
    scroll:EnableMouse(true)
    scroll:SetScript("OnMouseDown", function() edit:SetFocus() end)
    box.edit = edit
end

function ns.ShowCopyBox(title, text)
    if not box then Create() end
    box.title:SetText(title)
    box.text = text
    box.onAccept = nil
    box.accept:Hide()
    box.edit:SetText(text)
    box:Show()
    box.edit:SetFocus()
    box.edit:HighlightText()
end

-- A box to type or paste into, empty or holding text. onAccept(text) runs
-- when the button is clicked.
function ns.ShowPasteBox(title, buttonText, onAccept, text)
    if not box then Create() end
    box.title:SetText(title)
    box.onAccept = onAccept
    box.accept:SetText(buttonText)
    box.accept:Show()
    box.edit:SetText(text or "")
    box:Show()
    box.edit:SetFocus()
end
