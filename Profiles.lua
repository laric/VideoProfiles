-- VideoProfiles: capturing the current settings and managing named profiles.
local addonName, ns = ...

local GetCVar = C_CVar and C_CVar.GetCVar or GetCVar

-- Snapshot of every supported video CVar: { [cvar] = value }
function ns.CaptureCurrent()
    local values = {}
    for _, cvar in ipairs(ns.GetSupportedCVars()) do
        values[cvar.name] = GetCVar(cvar.name)
    end
    return values
end

-- Profile names are matched without regard to case, but stored as typed.
-- Names in slash commands may be wrapped in quotes: /vp apply "Raid low"
function ns.Unquote(name)
    return name:match('^"(.*)"$') or name
end

function ns.FindProfile(name)
    local wanted = ns.Unquote(name):lower()
    for key in pairs(ns.db.profiles) do
        if key:lower() == wanted then return key end
    end
end

function ns.SaveProfile(name)
    ns.db.profiles[name] = { cvars = ns.CaptureCurrent(), saved = time() }
end

ns.AddCommand("save", "<name>", "save your current video settings as a new profile", function(name)
    name = ns.Unquote(name)
    if name == "" then
        ns.Print("Usage: /vp save <name>")
        return
    end
    if name:find(">", 1, true) then
        ns.Print("Profile names can't contain '>'.")
        return
    end
    local existing = ns.FindProfile(name)
    if existing then
        ns.Print("A profile called '" .. existing .. "' already exists. Use /vp update " .. existing .. " to overwrite it.")
        return
    end
    ns.SaveProfile(name)
    ns.Print("Saved profile '" .. name .. "'.")
end)

function ns.GetProfileNames()
    local names = {}
    for name in pairs(ns.db.profiles) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b) return a:lower() < b:lower() end)
    return names
end

ns.AddCommand("list", "", "list your saved profiles", function()
    local names = ns.GetProfileNames()
    if #names == 0 then
        ns.Print("No profiles yet. Use /vp save <name> to make one.")
        return
    end
    ns.Print("Profiles:")
    for _, name in ipairs(names) do
        local saved = ns.db.profiles[name].saved
        local active = name == ns.db.active and " |cff00ff00(active)|r" or ""
        DEFAULT_CHAT_FRAME:AddMessage("  " .. name .. active .. (saved and (" (saved " .. date("%Y-%m-%d %H:%M", saved) .. ")") or ""))
    end
end)

ns.AddCommand("update", "<name>", "overwrite a profile with your current video settings", function(name)
    local existing = name ~= "" and ns.FindProfile(name)
    if not existing then
        ns.Print("No profile called '" .. name .. "'. Use /vp list to see your profiles.")
        return
    end
    ns.SaveProfile(existing)
    ns.Print("Updated profile '" .. existing .. "' with your current settings.")
end)

ns.AddCommand("delete", "<name>", "delete a profile", function(name)
    local existing = name ~= "" and ns.FindProfile(name)
    if not existing then
        ns.Print("No profile called '" .. name .. "'. Use /vp list to see your profiles.")
        return
    end
    ns.db.profiles[existing] = nil
    if ns.db.active == existing then ns.db.active = nil end
    ns.Print("Deleted profile '" .. existing .. "'.")
end)

-- Names may contain spaces, so old and new are separated by ">".
ns.AddCommand("rename", "<old> > <new>", "rename a profile", function(rest)
    local old, new = rest:match("^(.-)%s*>%s*(.-)$")
    new = new and ns.Unquote(new)
    if not old or old == "" or new == "" or new:find(">", 1, true) then
        ns.Print("Usage: /vp rename <old> > <new>")
        return
    end
    local existing = ns.FindProfile(old)
    if not existing then
        ns.Print("No profile called '" .. old .. "'. Use /vp list to see your profiles.")
        return
    end
    local clash = ns.FindProfile(new)
    if clash and clash ~= existing then
        ns.Print("A profile called '" .. clash .. "' already exists.")
        return
    end
    ns.db.profiles[new] = ns.db.profiles[existing]
    if new ~= existing then ns.db.profiles[existing] = nil end
    if ns.db.active == existing then ns.db.active = new end
    ns.Print("Renamed '" .. existing .. "' to '" .. new .. "'.")
end)
