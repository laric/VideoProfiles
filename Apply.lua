-- VideoProfiles: writing a profile's values back to the client.
local addonName, ns = ...

local GetCVar = C_CVar and C_CVar.GetCVar or GetCVar
local SetCVar = C_CVar and C_CVar.SetCVar or SetCVar

-- Values are written in CVar list order, so a preset such as graphicsQuality
-- is set before the individual settings it would otherwise reset.
-- Returns the number of CVars changed, or nil if applying was refused.
function ns.ApplyProfile(name)
    if InCombatLockdown() then
        ns.Print("Can't change video settings in combat. Try again afterwards.")
        return
    end
    local values = ns.db.profiles[name].cvars
    local changed, needsRestart = 0, false
    for _, cvar in ipairs(ns.GetSupportedCVars()) do
        local value = values[cvar.name]
        if value ~= nil and value ~= GetCVar(cvar.name) then
            SetCVar(cvar.name, value)
            changed = changed + 1
            if cvar.restart then needsRestart = true end
        end
    end
    ns.db.active = name
    -- Display, resolution and MSAA changes only take effect after a graphics restart.
    if needsRestart and RestartGx then
        RestartGx()
    end
    return changed
end

-- Changing CVars from an addon can taint parts of the default UI, so offer a reload.
StaticPopupDialogs["VIDEOPROFILES_RELOAD"] = {
    text = "VideoProfiles applied '%s'.\n\nReload the UI now? This avoids taint from changing video settings.",
    button1 = "Reload UI",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

ns.AddCommand("apply", "<name>", "switch to a saved profile", function(name)
    local existing = name ~= "" and ns.FindProfile(name)
    if not existing then
        ns.Print("No profile called '" .. name .. "'. Use /vp list to see your profiles.")
        return
    end
    local changed = ns.ApplyProfile(existing)
    if not changed then return end
    if changed == 0 then
        ns.Print("Your settings already match '" .. existing .. "'.")
    else
        ns.Print("Applied '" .. existing .. "' (" .. changed .. " settings changed).")
        if ns.db.askReload then StaticPopup_Show("VIDEOPROFILES_RELOAD", existing) end
    end
end)

ns.AddCommand("applyreload", "<name>", "switch to a saved profile and reload the UI straight away", function(name)
    local existing = name ~= "" and ns.FindProfile(name)
    if not existing then
        ns.Print("No profile called '" .. name .. "'. Use /vp list to see your profiles.")
        return
    end
    local changed = ns.ApplyProfile(existing)
    if not changed then return end
    if changed == 0 then
        ns.Print("Your settings already match '" .. existing .. "'. No reload needed.")
    else
        ReloadUI()
    end
end)
