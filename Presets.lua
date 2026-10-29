-- VideoProfiles: suggested settings bundled with the addon.
--
-- A preset is read-only and usually partial: it sets only the CVars it lists
-- and leaves every other setting as the player has it. Preset files in
-- Presets/ register themselves with ns.AddPreset:
--   ns.AddPreset({
--       name = "Clear raids",
--       author = "Someone",            -- who suggested the settings
--       notes = "One line on what it is for.",
--       cvars = { raidGraphicsSpellDensity = 0, ... },
--   })
local addonName, ns = ...

ns.presets = {}

function ns.AddPreset(preset)
    local cvars = {}
    -- GetCVar returns strings, so store values the same way.
    for name, value in pairs(preset.cvars) do
        cvars[name] = tostring(value)
    end
    preset.cvars = cvars
    table.insert(ns.presets, preset)
end

-- Matched without regard to case, like profile names.
function ns.FindPreset(name)
    local wanted = ns.Unquote(name):lower()
    for _, preset in ipairs(ns.presets) do
        if preset.name:lower() == wanted then return preset end
    end
end

-- How many of a preset's CVars the running client supports.
function ns.CountPresetCVars(preset)
    local count = 0
    for _, cvar in ipairs(ns.GetSupportedCVars()) do
        if preset.cvars[cvar.name] ~= nil then count = count + 1 end
    end
    return count
end

ns.AddCommand("presets", "", "list the suggested settings that come with the addon", function()
    if #ns.presets == 0 then
        ns.Print("No presets are bundled with this version.")
        return
    end
    ns.Print("Presets (they change only the settings they list):")
    for _, preset in ipairs(ns.presets) do
        local by = preset.author and (" by " .. preset.author) or ""
        DEFAULT_CHAT_FRAME:AddMessage("  " .. preset.name .. by .. " (" .. ns.CountPresetCVars(preset) .. " settings)"
            .. (preset.notes and (": " .. preset.notes) or ""))
    end
end)
