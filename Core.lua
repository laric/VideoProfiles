-- VideoProfiles: saved variables, events and slash commands.
local addonName, ns = ...

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffVideoProfiles:|r " .. msg)
end
ns.Print = Print

-- Profiles are account-wide: VideoProfilesDB.profiles[name] = { cvars = { [cvar] = value }, saved = time() }
local DEFAULTS = {
    profiles = {},
    askReload = true, -- offer a UI reload after applying a profile
}

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        VideoProfilesDB = VideoProfilesDB or {}
        local db = VideoProfilesDB
        for k, v in pairs(DEFAULTS) do
            if db[k] == nil then
                if type(v) == "table" then v = {} end
                db[k] = v
            end
        end
        ns.db = db
        events:UnregisterEvent("ADDON_LOADED")
    end
end)

-- Slash commands register themselves here: ns.commands[name] = { args = "", help = "", run = function(rest) end }
ns.commands = {}
local commandOrder = {}

function ns.AddCommand(name, args, help, run)
    ns.commands[name] = { args = args, help = help, run = run }
    table.insert(commandOrder, name)
end

local function PrintHelp()
    Print("commands:")
    for _, name in ipairs(commandOrder) do
        local cmd = ns.commands[name]
        local usage = cmd.args ~= "" and (name .. " " .. cmd.args) or name
        DEFAULT_CHAT_FRAME:AddMessage("  /vp " .. usage .. " - " .. cmd.help)
    end
end

ns.AddCommand("help", "", "show this list", PrintHelp)

SLASH_VIDEOPROFILES1 = "/vp"
SLASH_VIDEOPROFILES2 = "/videoprofiles"
SlashCmdList.VIDEOPROFILES = function(msg)
    local name, rest = strtrim(msg or ""):match("^(%S*)%s*(.-)$")
    if name == "" and ns.commands.show then name = "show" end
    local cmd = ns.commands[name:lower()]
    if cmd then
        cmd.run(rest)
        -- Keep the window in step with changes made from chat.
        if ns.UI and ns.UI:IsVisible() then ns.UI:Refresh() end
    else
        PrintHelp()
    end
end
