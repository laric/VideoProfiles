-- VideoProfiles: finding which values differ between two sets of settings.
local addonName, ns = ...

-- Compares two { [cvar] = value } tables over the supported CVars, in list order.
-- Returns { { name =, group =, a =, b = }, ... } for each CVar whose values differ.
-- A value missing from one side (saved on another client) shows as nil.
-- With only given, CVars missing from that table are left out, so a partial
-- preset is compared on just the settings it sets.
function ns.DiffValues(a, b, only)
    local diffs = {}
    for _, cvar in ipairs(ns.GetSupportedCVars()) do
        local va, vb = a[cvar.name], b[cvar.name]
        if va ~= vb and (not only or only[cvar.name] ~= nil) then
            table.insert(diffs, { name = cvar.name, group = cvar.group, a = va, b = vb })
        end
    end
    return diffs
end

-- Resolves a name to a values table, and whether it is a partial preset.
-- An empty name means the current settings. Profiles win over presets.
local function Resolve(name)
    if name == "" or name:lower() == "current" then
        return "current settings", ns.CaptureCurrent()
    end
    local existing = ns.FindProfile(name)
    if existing then
        return "'" .. existing .. "'", ns.db.profiles[existing].cvars
    end
    local preset = ns.FindPreset(name)
    if preset then
        return "preset '" .. preset.name .. "'", preset.cvars, true
    end
end

ns.AddCommand("diff", "<name> [> <other>]", "show what a profile or preset changes from your current settings, or from another profile", function(rest)
    local left, right = rest:match("^(.-)%s*>%s*(.-)$")
    if not left then left, right = rest, "" end
    if left == "" then
        ns.Print("Usage: /vp diff <name> [> <other>]")
        return
    end
    local labelA, a, partialA = Resolve(left)
    local labelB, b, partialB = Resolve(right)
    if not a or not b then
        ns.Print("No profile or preset called '" .. (a and right or left) .. "'. Use /vp list or /vp presets to see them.")
        return
    end
    -- A preset is only compared on the settings it sets.
    local diffs = ns.DiffValues(a, b, partialA and a or partialB and b or nil)
    if #diffs == 0 then
        ns.Print(labelA .. " and " .. labelB .. " are the same.")
        return
    end
    ns.Print(#diffs .. " differences, " .. labelA .. " vs " .. labelB .. ":")
    for _, d in ipairs(diffs) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. d.name .. ": " .. tostring(d.a or "-") .. " |cffffd100vs|r " .. tostring(d.b or "-"))
    end
end)
