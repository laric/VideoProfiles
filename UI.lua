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

-- Selects a profile by name, or a bundled preset. Only one is selected at a time.
function UI:Select(name, preset)
    if preset ~= self.preset then self.editing = false end
    self.selected = not preset and name or nil
    self.preset = preset
    self:Refresh()
end

-- The name of whatever is selected, profile or preset.
function UI:SelectedName()
    return self.selected or (self.preset and self.preset.name)
end

-- Profile list on the left, with the bundled presets below it. Clicking a row selects it.
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

-- Sits on the Presets heading in the list.
local newPresetButton = CreateFrame("Button", nil, listContent, "UIPanelButtonTemplate")
newPresetButton:SetSize(50, 18)
newPresetButton:SetText("New")
newPresetButton:SetFrameLevel(listContent:GetFrameLevel() + 5)
newPresetButton:SetScript("OnClick", function()
    StaticPopup_Show("VIDEOPROFILES_NEW_PRESET")
end)
UI.newPresetButton = newPresetButton

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
        UI:Select(self.name, self.preset)
    end)
    rows[i] = row
    return row
end

table.insert(UI.refreshers, function()
    local names = ns.GetProfileNames()
    if UI.selected and not ns.db.profiles[UI.selected] then UI.selected = nil end
    if UI.preset and not UI.preset.bundled and ns.db.presets[UI.preset.name] ~= UI.preset then UI.preset = nil end
    if not UI.selected and not UI.preset then UI.selected = ns.db.active or names[1] end
    local count = 0
    local function NextRow(name, preset, text)
        count = count + 1
        local row = GetRow(count)
        row.name, row.preset = name, preset
        row.text:SetText(text)
        row.selected:SetShown(name ~= nil and (preset and preset == UI.preset or not preset and name == UI.selected))
        -- Rows without a name are section headings.
        row:SetEnabled(name ~= nil)
        row:Show()
    end
    for _, name in ipairs(names) do
        NextRow(name, nil, name == ns.db.active and (name .. " |cff00ff00(active)|r") or name)
    end
    if #names > 0 then NextRow(nil, nil, "") end
    NextRow(nil, nil, "|cffffd100Presets|r")
    UI.newPresetButton:SetPoint("RIGHT", rows[count], "RIGHT", -2, 0)
    -- Your own presets first, then the bundled ones in blue.
    for _, preset in ipairs(ns.GetUserPresets()) do
        NextRow(preset.name, preset, preset.name)
    end
    for _, preset in ipairs(ns.presets) do
        NextRow(preset.name, preset, "|cff80c0ff" .. preset.name .. "|r")
    end
    for i = count + 1, #rows do rows[i]:Hide() end
    listContent:SetHeight(math.max(1, count * ROW_HEIGHT))
    UpdateScrollBar(list, count * ROW_HEIGHT)
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
        if ns.FindProfile(name) then
            UI:Select(ns.FindProfile(name))
        end
    end,
    EditBoxOnEnterPressed = AcceptOnEnter,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["VIDEOPROFILES_NEW_PRESET"] = {
    text = "New preset named:\n\nA preset sets only the settings you pick for it. Pick them on the right afterwards.",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    OnShow = function(self) PopupEditBox(self):SetFocus() end,
    OnAccept = function(self)
        local preset = ns.NewPreset(strtrim(PopupEditBox(self):GetText()))
        if preset then
            UI:Select(preset.name, preset)
            UI.editing = true
            UI:Refresh()
        end
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
    -- data is a profile name, or one of your presets.
    OnShow = function(self, data)
        local editBox = PopupEditBox(self)
        editBox:SetText(type(data) == "table" and data.name or data)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    OnAccept = function(self, data)
        local new = strtrim(PopupEditBox(self):GetText())
        if type(data) == "table" then
            ns.RenamePreset(data, new)
            UI:Select(data.name, data)
        else
            ns.commands.rename.run(data .. " > " .. new)
            UI.selected = ns.FindProfile(new) or UI.selected
            UI:Refresh()
        end
    end,
    EditBoxOnEnterPressed = AcceptOnEnter,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- "Name 2", "Name 3"... whichever is free as both a profile and a preset name.
local function FreeCopyName(base)
    local n = 2
    while ns.FindProfile(base .. " " .. n) or ns.FindPreset(base .. " " .. n) do n = n + 1 end
    return base .. " " .. n
end

-- data is { name =, isPreset = } for what is being copied.
StaticPopupDialogs["VIDEOPROFILES_COPY"] = {
    text = "Copy '%s' to a new profile or preset named:",
    button1 = "Profile",
    button3 = "Preset",
    button2 = CANCEL,
    hasEditBox = true,
    OnShow = function(self, data)
        local editBox = PopupEditBox(self)
        editBox:SetText(FreeCopyName(data.name))
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    OnAccept = function(self, data)
        local new = ns.CopyToProfile(data.name, strtrim(PopupEditBox(self):GetText()), data.isPreset)
        if new then UI:Select(new) end
    end,
    OnAlt = function(self, data)
        local preset = ns.CopyToPreset(data.name, strtrim(PopupEditBox(self):GetText()), not data.isPreset)
        if preset then UI:Select(preset.name, preset) end
    end,
    EditBoxOnEnterPressed = AcceptOnEnter,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["VIDEOPROFILES_DELETE"] = {
    text = "Delete '%s'?",
    button1 = DELETE,
    button2 = CANCEL,
    -- data is a profile name, or one of your presets.
    OnAccept = function(_, data)
        if type(data) == "table" then
            ns.commands.preset.run("delete " .. data.name)
        else
            ns.commands.delete.run(data)
        end
        UI:Refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local buttons = {}

-- needs: nil for always enabled, "editable" for a profile or one of your own
-- presets, "any" when a bundled preset will do too.
local function AddButton(label, needs, onClick)
    local button = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
    button:SetSize(74, 22)
    if #buttons == 0 then
        button:SetPoint("BOTTOMLEFT", 0, 0)
    else
        button:SetPoint("LEFT", buttons[#buttons], "RIGHT", 4, 0)
    end
    button:SetText(label)
    button.needs = needs
    button:SetScript("OnClick", onClick)
    table.insert(buttons, button)
end

AddButton("New", nil, function()
    StaticPopup_Show("VIDEOPROFILES_NEW")
end)
AddButton("Copy", "any", function()
    local name = UI:SelectedName()
    StaticPopup_Show("VIDEOPROFILES_COPY", name, nil, { name = name, isPreset = UI.preset ~= nil })
end)
AddButton("Apply", "any", function()
    if UI.preset then
        ns.UsePreset(UI.preset)
    else
        ns.commands.apply.run(UI.selected)
    end
    UI:Refresh()
end)
AddButton("Update", "editable", function()
    if UI.preset then
        ns.commands.preset.run("update " .. UI.preset.name)
    else
        ns.commands.update.run(UI.selected)
    end
    UI:Refresh()
end)
AddButton("Rename", "editable", function()
    StaticPopup_Show("VIDEOPROFILES_RENAME", UI:SelectedName(), nil, UI.preset or UI.selected)
end)
AddButton("Delete", "editable", function()
    StaticPopup_Show("VIDEOPROFILES_DELETE", UI:SelectedName(), nil, UI.preset or UI.selected)
end)
AddButton("Export", "any", function()
    if UI.preset then
        ns.ShowExportPreset(UI.preset)
    else
        ns.ShowExport(UI.selected)
    end
end)
AddButton("Import", nil, function()
    ns.ShowImport()
end)

table.insert(UI.refreshers, function()
    for _, button in ipairs(buttons) do
        local enabled = not button.needs
            or button.needs == "editable" and (UI.selected ~= nil or UI.preset ~= nil and not UI.preset.bundled)
            or button.needs == "any" and UI:SelectedName() ~= nil
        button:SetEnabled(enabled)
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

local function IsOwnPreset()
    return UI.preset ~= nil and not UI.preset.bundled
end

-- Switches between listing only the differences and every value in the profile.
-- For one of your presets it opens the settings picker instead.
local showAllButton = CreateFrame("Button", nil, UI, "UIPanelButtonTemplate")
showAllButton:SetSize(100, 22)
showAllButton:SetPoint("LEFT", compareButton, "RIGHT", 8, 0)
showAllButton:SetScript("OnClick", function()
    if IsOwnPreset() then
        UI.editing = not UI.editing
    else
        UI.showAll = not UI.showAll
    end
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

-- The settings picker for one of your presets: a check box per CVar.
local editor = CreateFrame("Frame", nil, diffContent)
editor:SetPoint("TOPLEFT")
editor:SetPoint("TOPRIGHT")
editor:Hide()

local editorIntro = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
editorIntro:SetPoint("TOPLEFT")
editorIntro:SetPoint("RIGHT")
editorIntro:SetJustifyH("LEFT")

-- data is { preset =, field = "notes" or "author" }.
StaticPopupDialogs["VIDEOPROFILES_PRESET_TEXT"] = {
    text = "%s for '%s':",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = true,
    OnShow = function(self, data)
        local editBox = PopupEditBox(self)
        editBox:SetText(data.preset[data.field] or "")
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    OnAccept = function(self, data)
        local text = strtrim(PopupEditBox(self):GetText())
        data.preset[data.field] = text ~= "" and text or nil
        UI:Refresh()
    end,
    EditBoxOnEnterPressed = AcceptOnEnter,
    EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function EditorButton(label, field, anchor)
    local button = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    button:SetSize(80, 20)
    button:SetText(label)
    if anchor then button:SetPoint("LEFT", anchor, "RIGHT", 4, 0) end
    button:SetScript("OnClick", function()
        StaticPopup_Show("VIDEOPROFILES_PRESET_TEXT", label, UI.preset.name, { preset = UI.preset, field = field })
    end)
    return button
end
local notesButton = EditorButton("Notes", "notes")
EditorButton("Author", "author", notesButton)

local editorChecks, editorHeaders = {}, {}

local function EditorCheck(i)
    if editorChecks[i] then return editorChecks[i] end
    local check = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
    check:SetSize(20, 20)
    check.label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    check.label:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check:SetScript("OnClick", function(self)
        ns.SetPresetCVar(UI.preset, self.cvar, self:GetChecked())
        UI:Refresh()
    end)
    editorChecks[i] = check
    return check
end

local function EditorHeader(i)
    if editorHeaders[i] then return editorHeaders[i] end
    editorHeaders[i] = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    return editorHeaders[i]
end

-- Lays out the picker and returns its height.
local function RefreshEditor()
    local preset, current = UI.preset, ns.CaptureCurrent()
    editorIntro:SetText("Tick the settings '" .. preset.name .. "' should set. Ticking one takes your current value, "
        .. "and Update sets them all to your current values. Everything else is left alone when the preset is applied.")
    local y = editorIntro:GetStringHeight() + 8
    notesButton:SetPoint("TOPLEFT", 0, -y)
    y = y + 24
    local checks, headers, group = 0, 0, nil
    for _, cvar in ipairs(ns.GetSupportedCVars()) do
        if cvar.group ~= group then
            group = cvar.group
            headers = headers + 1
            local header = EditorHeader(headers)
            header:SetPoint("TOPLEFT", 0, -(y + 6))
            header:SetText(group)
            header:Show()
            y = y + 22
        end
        checks = checks + 1
        local check = EditorCheck(checks)
        local value, now = preset.cvars[cvar.name], current[cvar.name]
        check.cvar = cvar.name
        check:SetPoint("TOPLEFT", 4, -y)
        check:SetChecked(value ~= nil)
        if value == nil then
            check.label:SetText("|cff808080" .. cvar.name .. ":  " .. tostring(now) .. "|r")
        elseif value ~= now then
            check.label:SetText("|cffff8040" .. cvar.name .. ":  " .. value .. "|r  (current: " .. tostring(now) .. ")")
        else
            check.label:SetText(cvar.name .. ":  " .. value)
        end
        check:Show()
        y = y + 20
    end
    for i = checks + 1, #editorChecks do editorChecks[i]:Hide() end
    for i = headers + 1, #editorHeaders do editorHeaders[i]:Hide() end
    editor:SetHeight(y)
    return y
end

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
    local selectedName = UI:SelectedName()
    compareButton:SetText(UI.compareWith or "Current settings")
    compareButton:SetEnabled(selectedName ~= nil)
    if IsOwnPreset() then
        showAllButton:SetText(UI.editing and "Done" or "Pick settings")
    else
        showAllButton:SetText(UI.showAll and "Show diffs" or "Show all")
    end
    showAllButton:SetEnabled(selectedName ~= nil)

    local editing = UI.editing and IsOwnPreset()
    editor:SetShown(editing)
    diffText:SetShown(not editing)
    if editing then
        local height = RefreshEditor()
        diffContent:SetHeight(height)
        UpdateScrollBar(diffScroll, height)
        return
    end

    local lines = {}
    if not selectedName then
        lines[1] = "Save a profile with New to get started."
    else
        local other = UI.compareWith and ns.db.profiles[UI.compareWith].cvars or ns.CaptureCurrent()
        local otherLabel = UI.compareWith or "current"
        local values = UI.preset and UI.preset.cvars or ns.db.profiles[UI.selected].cvars
        -- A preset is partial, so only the settings it sets are compared or listed.
        local only = UI.preset and values or nil
        local diffs = ns.DiffValues(values, other, only)
        if UI.preset then
            local by = UI.preset.author and ("Suggested by " .. UI.preset.author .. ". ") or ""
            table.insert(lines, "|cff80c0ff" .. by .. (UI.preset.notes or "") .. "|r")
            table.insert(lines, "|cff808080Applying it changes only the " .. ns.CountPresetCVars(UI.preset)
                .. " settings below and keeps the rest of yours. "
                .. (UI.preset.bundled and "Copy makes it a profile or preset you can change." or "Pick settings chooses which ones it sets.") .. "|r")
            table.insert(lines, "")
        end
        if UI.showAll then
            -- Every value in the profile; ones that differ are highlighted with the other value.
            table.insert(lines, "|cffffd100" .. selectedName .. "|r (" .. #diffs .. " differ from " .. otherLabel .. ")")
            local group
            for _, cvar in ipairs(ns.GetSupportedCVars()) do
                if not only or only[cvar.name] ~= nil then
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
            end
        elseif #diffs == 0 then
            table.insert(lines, "No differences. '" .. selectedName .. "' matches " .. (UI.compareWith and ("'" .. otherLabel .. "'") or "your current settings") .. ".")
        else
            table.insert(lines, "|cffffd100" .. #diffs .. " differences|r (" .. selectedName .. " -> " .. otherLabel .. ")")
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
