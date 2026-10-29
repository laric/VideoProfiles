-- VideoProfiles: profile list, buttons and compare view on the options panel.
local addonName, ns = ...

local panel = ns.optionsPanel
local UI = CreateFrame("Frame", nil, panel)
ns.UI = UI
UI:SetPoint("TOPLEFT", panel.contentTop, "BOTTOMLEFT", 0, -12)
UI:SetPoint("BOTTOMRIGHT", -16, 48)

-- Each part of the profile UI adds a function here to redraw itself.
UI.refreshers = {}

function UI:Refresh()
    for _, refresh in ipairs(self.refreshers) do refresh() end
end

UI:SetScript("OnShow", function(self) self:Refresh() end)

-- Show a scroll bar only when its content is taller than the visible area.
local function UpdateScrollBar(scroll, contentHeight)
    -- The template re-shows the bar when the scroll range changes unless told not to.
    scroll.scrollBarHideable = true
    local bar = scroll.ScrollBar
    if not bar then return end
    local needed = contentHeight > scroll:GetHeight()
    bar:SetShown(needed)
    if not needed then scroll:SetVerticalScroll(0) end
end

ns.AddCommand("show", "", "open the profiles in Options > AddOns", function()
    if ns.OpenOptions then ns.OpenOptions() end
end)

-- Profile list on the left. Clicking a row selects it.
local ROW_HEIGHT = 20
local LIST_WIDTH = 190

local list = CreateFrame("ScrollFrame", nil, UI, "UIPanelScrollFrameTemplate")
list:SetPoint("TOPLEFT", 0, 0)
list:SetPoint("BOTTOMLEFT", 0, 32)
list:SetWidth(LIST_WIDTH - 24)
-- A dark backdrop marks out the list area.
local listBg = list:CreateTexture(nil, "BACKGROUND")
listBg:SetPoint("TOPLEFT", -2, 2)
listBg:SetPoint("BOTTOMRIGHT", 26, -2)
listBg:SetColorTexture(0, 0, 0, 0.3)

local listContent = CreateFrame("Frame", nil, list)
listContent:SetSize(LIST_WIDTH - 24, 1)
list:SetScrollChild(listContent)

local rows = {}

local function GetRow(i)
    if rows[i] then return rows[i] end
    local row = CreateFrame("Button", nil, listContent)
    row:SetSize(LIST_WIDTH - 24, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.selected = row:CreateTexture(nil, "BACKGROUND")
    row.selected:SetAllPoints()
    row.selected:SetColorTexture(0.2, 0.6, 1, 0.3)
    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.text:SetPoint("LEFT", 4, 0)
    row.text:SetPoint("RIGHT", -4, 0)
    row.text:SetJustifyH("LEFT")
    row:SetScript("OnClick", function(self)
        UI.selected = self.name
        UI:Refresh()
    end)
    rows[i] = row
    return row
end

table.insert(UI.refreshers, function()
    local names = ns.GetProfileNames()
    if UI.selected and not ns.db.profiles[UI.selected] then UI.selected = nil end
    if not UI.selected then UI.selected = ns.db.active or names[1] end
    for i, name in ipairs(names) do
        local row = GetRow(i)
        row.name = name
        row.text:SetText(name == ns.db.active and (name .. " |cff00ff00(active)|r") or name)
        row.selected:SetShown(name == UI.selected)
        row:Show()
    end
    for i = #names + 1, #rows do rows[i]:Hide() end
    listContent:SetHeight(math.max(1, #names * ROW_HEIGHT))
    UpdateScrollBar(list, #names * ROW_HEIGHT)
end)

-- Buttons along the bottom. They run the same code as the slash commands.
local function PopupEditBox(popup)
    return popup.editBox or popup.EditBox or (popup.GetEditBox and popup:GetEditBox())
end

local function AcceptOnEnter(editBox)
    local popup = editBox:GetParent()
    StaticPopupDialogs[popup.which].OnAccept(popup, popup.data)
    popup:Hide()
end

StaticPopupDialogs["VIDEOPROFILES_NEW"] = {
    text = "Save your current video settings as a new profile named:",
    button1 = SAVE,
    button2 = CANCEL,
    hasEditBox = true,
    OnShow = function(self) PopupEditBox(self):SetFocus() end,
    OnAccept = function(self)
        local name = strtrim(PopupEditBox(self):GetText())
        ns.commands.save.run(name)
        UI.selected = ns.FindProfile(name) or UI.selected
        UI:Refresh()
    end,
    EditBoxOnEnterPressed = AcceptOnEnter,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["VIDEOPROFILES_RENAME"] = {
    text = "Rename '%s' to:",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    OnShow = function(self, old)
        local editBox = PopupEditBox(self)
        editBox:SetText(old)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    OnAccept = function(self, old)
        local new = strtrim(PopupEditBox(self):GetText())
        ns.commands.rename.run(old .. " > " .. new)
        UI.selected = ns.FindProfile(new) or UI.selected
        UI:Refresh()
    end,
    EditBoxOnEnterPressed = AcceptOnEnter,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["VIDEOPROFILES_DELETE"] = {
    text = "Delete the profile '%s'?",
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(_, name)
        ns.commands.delete.run(name)
        UI:Refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local buttons = {}

local function AddButton(label, needsSelection, onClick)
    local button = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
    button:SetSize(84, 22)
    if #buttons == 0 then
        button:SetPoint("BOTTOMLEFT", 0, 0)
    else
        button:SetPoint("LEFT", buttons[#buttons], "RIGHT", 4, 0)
    end
    button:SetText(label)
    button.needsSelection = needsSelection
    button:SetScript("OnClick", onClick)
    table.insert(buttons, button)
end

AddButton("New", false, function()
    StaticPopup_Show("VIDEOPROFILES_NEW")
end)
AddButton("Apply", true, function()
    ns.commands.apply.run(UI.selected)
    UI:Refresh()
end)
AddButton("Update", true, function()
    ns.commands.update.run(UI.selected)
    UI:Refresh()
end)
AddButton("Rename", true, function()
    StaticPopup_Show("VIDEOPROFILES_RENAME", UI.selected, nil, UI.selected)
end)
AddButton("Delete", true, function()
    StaticPopup_Show("VIDEOPROFILES_DELETE", UI.selected, nil, UI.selected)
end)
AddButton("Export", true, function()
    ns.ShowExport(UI.selected)
end)
AddButton("Import", false, function()
    ns.ShowImport()
end)

table.insert(UI.refreshers, function()
    for _, button in ipairs(buttons) do
        button:SetEnabled(not button.needsSelection or UI.selected ~= nil)
    end
end)

-- Compare panel on the right: the selected profile against the current
-- settings, or against another profile. The button cycles through the choices.
local compareLabel = UI:CreateFontString(nil, "OVERLAY", "GameFontNormal")
compareLabel:SetPoint("TOPLEFT", LIST_WIDTH + 16, -6)
compareLabel:SetText("Compare with:")

local compareButton = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
compareButton:SetSize(200, 22)
compareButton:SetPoint("LEFT", compareLabel, "RIGHT", 8, 0)

-- Switches between listing only the differences and every value in the profile.
local showAllButton = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
showAllButton:SetSize(100, 22)
showAllButton:SetPoint("LEFT", compareButton, "RIGHT", 8, 0)
showAllButton:SetScript("OnClick", function()
    UI.showAll = not UI.showAll
    UI:Refresh()
end)

local diffScroll = CreateFrame("ScrollFrame", nil, UI, "UIPanelScrollFrameTemplate")
diffScroll:SetPoint("TOPLEFT", LIST_WIDTH + 16, -32)
diffScroll:SetPoint("BOTTOMRIGHT", -24, 32)
local diffContent = CreateFrame("Frame", nil, diffScroll)
diffContent:SetSize(1, 1)
diffScroll:SetScrollChild(diffContent)
local diffText = diffContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
diffText:SetPoint("TOPLEFT")
diffText:SetJustifyH("LEFT")
diffText:SetJustifyV("TOP")

-- false stands for the current settings and comes first.
local function CompareChoices()
    local choices = { false }
    for _, name in ipairs(ns.GetProfileNames()) do
        if name ~= UI.selected then table.insert(choices, name) end
    end
    return choices
end

local function ChoiceText(choice)
    return choice or "Current settings"
end

local function SetCompareWith(choice)
    UI.compareWith = choice or nil
    UI:Refresh()
end

-- Clicking opens a list to pick from. Retail uses the Menu API, older clients
-- UIDropDownMenu, and a client with neither steps to the next choice.
local fallbackMenu
compareButton:SetScript("OnClick", function(self)
    local choices = CompareChoices()
    local current = UI.compareWith or false
    if MenuUtil and MenuUtil.CreateContextMenu then
        MenuUtil.CreateContextMenu(self, function(_, root)
            root:CreateTitle("Compare with")
            if root.SetScrollMode then root:SetScrollMode(400) end
            for _, choice in ipairs(choices) do
                root:CreateRadio(ChoiceText(choice), function() return choice == current end, function() SetCompareWith(choice) end)
            end
        end)
    elseif UIDropDownMenu_Initialize and ToggleDropDownMenu then
        fallbackMenu = fallbackMenu or CreateFrame("Frame", "VideoProfilesCompareMenu", UI, "UIDropDownMenuTemplate")
        UIDropDownMenu_Initialize(fallbackMenu, function()
            for _, choice in ipairs(choices) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = ChoiceText(choice)
                info.checked = choice == current
                info.func = function() SetCompareWith(choice) end
                UIDropDownMenu_AddButton(info)
            end
        end, "MENU")
        ToggleDropDownMenu(1, nil, fallbackMenu, self, 0, 0)
    else
        local nextIndex = 1
        for i, choice in ipairs(choices) do
            if choice == current then nextIndex = i % #choices + 1 end
        end
        SetCompareWith(choices[nextIndex])
    end
end)

local function ShowValue(value)
    return value == nil and "|cff808080not saved|r" or value
end

table.insert(UI.refreshers, function()
    diffContent:SetWidth(diffScroll:GetWidth())
    diffText:SetWidth(diffScroll:GetWidth())
    if UI.compareWith and (UI.compareWith == UI.selected or not ns.db.profiles[UI.compareWith]) then
        UI.compareWith = nil
    end
    compareButton:SetText(UI.compareWith or "Current settings")
    compareButton:SetEnabled(UI.selected ~= nil)
    showAllButton:SetText(UI.showAll and "Show diffs" or "Show all")
    showAllButton:SetEnabled(UI.selected ~= nil)

    local lines = {}
    if not UI.selected then
        lines[1] = "Save a profile with New to get started."
    else
        local other = UI.compareWith and ns.db.profiles[UI.compareWith].cvars or ns.CaptureCurrent()
        local otherLabel = UI.compareWith or "current"
        local values = ns.db.profiles[UI.selected].cvars
        local diffs = ns.DiffValues(values, other)
        if UI.showAll then
            -- Every value in the profile; ones that differ are highlighted with the other value.
            lines[1] = "|cffffd100" .. UI.selected .. "|r (" .. #diffs .. " differ from " .. otherLabel .. ")"
            local group
            for _, cvar in ipairs(ns.GetSupportedCVars()) do
                if cvar.group ~= group then
                    group = cvar.group
                    table.insert(lines, "")
                    table.insert(lines, "|cffffd100" .. group .. "|r")
                end
                local value, otherValue = values[cvar.name], other[cvar.name]
                if value ~= otherValue then
                    table.insert(lines, "  |cffff8040" .. cvar.name .. ":  " .. ShowValue(value) .. "|r  (" .. otherLabel .. ": " .. ShowValue(otherValue) .. ")")
                else
                    table.insert(lines, "  " .. cvar.name .. ":  " .. ShowValue(value))
                end
            end
        elseif #diffs == 0 then
            lines[1] = "No differences. '" .. UI.selected .. "' matches " .. (UI.compareWith and ("'" .. otherLabel .. "'") or "your current settings") .. "."
        else
            lines[1] = "|cffffd100" .. #diffs .. " differences|r (" .. UI.selected .. " -> " .. otherLabel .. ")"
            local group
            for _, d in ipairs(diffs) do
                if d.group ~= group then
                    group = d.group
                    table.insert(lines, "")
                    table.insert(lines, "|cffffd100" .. group .. "|r")
                end
                table.insert(lines, "  " .. d.name .. ":  " .. ShowValue(d.a) .. "  ->  " .. ShowValue(d.b))
            end
        end
    end
    diffText:SetText(table.concat(lines, "\n"))
    diffContent:SetHeight(math.max(1, diffText:GetStringHeight()))
    UpdateScrollBar(diffScroll, diffText:GetStringHeight())
end)
