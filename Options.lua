-- VideoProfiles: the panel under Options > AddOns.
local addonName, ns = ...

local panel = CreateFrame("Frame")
panel.name = "VideoProfiles"
ns.optionsPanel = panel

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("VideoProfiles")

local GetMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local version = GetMetadata(addonName, "Version")
if not version or version:find("@", 1, true) then version = "dev" end
local versionText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
versionText:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 1)
versionText:SetText(version)

local notes = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
notes:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
notes:SetPoint("RIGHT", -16, 0)
notes:SetJustifyH("LEFT")
notes:SetText("Save your video settings as named profiles and swap between them. Profiles are shared by every character on your account.")

local profilesHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
profilesHeader:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, -16)
profilesHeader:SetText("Profiles")

-- UI.lua places the profile list below this.
panel.contentTop = profilesHeader

local askReload = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
askReload:SetPoint("BOTTOMLEFT", 12, 12)
askReload.label = askReload:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
askReload.label:SetPoint("LEFT", askReload, "RIGHT", 2, 0)
askReload.label:SetText("Offer to reload the UI after applying a profile")
askReload:SetScript("OnClick", function(self)
    ns.db.askReload = self:GetChecked() and true or false
end)
-- Saved variables aren't loaded when this file runs, so sync on show.
panel:SetScript("OnShow", function()
    askReload:SetChecked(ns.db.askReload)
end)

-- Retail and newer clients use the Settings API; older ones the Interface Options.
if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    ns.OpenOptions = function() Settings.OpenToCategory(category:GetID()) end
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    ns.OpenOptions = function()
        -- Called twice: the first call can land on the wrong page the first time.
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

ns.AddCommand("options", "", "open the VideoProfiles options panel", function()
    if ns.OpenOptions then ns.OpenOptions() end
end)
