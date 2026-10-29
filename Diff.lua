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

-- Resolves a name to a values table. An empty name means the current settings.
local function Resolve(name)
    if name == "" or name:lower() == "current" then
        return "current settings", ns.CaptureCurrent()
    end
    local existing = ns.FindProfile(name)
    if existing then
        return "'" .. existing .. "'", ns.db.profiles[existing].cvars
    end
end

ns.AddCommand("diff", "<name> [> <other>]", "show what differs from your current settings, or from another profile", function(rest)
    local left, right = rest:match("^(.-)%s*>%s*(.-)$")
    if not left then left, right = rest, "" end
    if left == "" then
        ns.Print("Usage: /vp diff <name> [> <other>]")
        return
    end
    local labelA, a = Resolve(left)
    local labelB, b = Resolve(right)
    if not a or not b then
        ns.Print("No profile called '" .. (a and right or left) .. "'. Use /vp list to see your profiles.")
        return
    end
    local diffs = ns.DiffValues(a, b)
    if #diffs == 0 then
        ns.Print(labelA .. " and " .. labelB .. " are the same.")
        return
    end
    ns.Print(#diffs .. " differences, " .. labelA .. " vs " .. labelB .. ":")
    for _, d in ipairs(diffs) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. d.name .. ": " .. tostring(d.a or "-") .. " |cffffd100vs|r " .. tostring(d.b or "-"))
    end
end)
