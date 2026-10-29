-- VideoProfiles: presets, bundled with the addon or made by the player.
--
-- A preset is usually partial: it sets only the CVars it lists and leaves
-- every other setting as the player has it. Bundled presets are read-only;
-- the player's own live in VideoProfilesDB.presets. Preset files in Presets/
-- register bundled ones with ns.AddPreset:
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
    preset.bundled = true
    table.insert(ns.presets, preset)
end

-- The player's presets, sorted by name.
function ns.GetUserPresets()
    local list = {}
    for _, preset in pairs(ns.db.presets) do table.insert(list, preset) end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)
    return list
end

-- Matched without regard to case, like profile names. The player's own
-- presets are looked up before the bundled ones.
function ns.FindPreset(name)
    local wanted = ns.Unquote(name):lower()
    for key, preset in pairs(ns.db.presets) do
        if key:lower() == wanted then return preset end
    end
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

local function ListPresets()
    local user = ns.GetUserPresets()
    if #ns.presets == 0 and #user == 0 then
        ns.Print("No presets yet.")
        return
    end
    ns.Print("Presets (they change only the settings they list):")
    for _, preset in ipairs(user) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. preset.name .. " |cff00ff00(yours)|r (" .. ns.CountPresetCVars(preset) .. " settings)"
            .. (preset.notes and (": " .. preset.notes) or ""))
    end
    for _, preset in ipairs(ns.presets) do
        local by = preset.author and (" by " .. preset.author) or ""
        DEFAULT_CHAT_FRAME:AddMessage("  " .. preset.name .. by .. " (" .. ns.CountPresetCVars(preset) .. " settings)"
            .. (preset.notes and (": " .. preset.notes) or ""))
    end
end

-- Only the preset's own CVars are written. The settings then no longer match
-- the active profile, so that is cleared.
function ns.ApplyPreset(preset)
    local changed = ns.ApplyValues(preset.cvars)
    if changed and changed > 0 then ns.db.active = nil end
    return changed
end

-- Applies a preset and reports the result, offering a reload.
function ns.UsePreset(preset)
    local changed = ns.ApplyPreset(preset)
    if not changed then return end
    if changed == 0 then
        ns.Print("Your settings already match the preset '" .. preset.name .. "'.")
    else
        ns.Print("Applied the preset '" .. preset.name .. "' (" .. changed .. " settings changed).")
        if ns.db.askReload then StaticPopup_Show("VIDEOPROFILES_RELOAD", preset.name) end
    end
end

local function NoPreset(name)
    ns.Print("No preset called '" .. name .. "'. Use /vp preset list to see them.")
end

-- /vp preset <command> [args]. Presets get their own commands, so a preset
-- and a profile may share a name.
local subcommands, subcommandOrder = {}, {}

local function AddSubcommand(name, args, help, run)
    subcommands[name] = { args = args, help = help, run = run }
    table.insert(subcommandOrder, name)
end

local function PrintSubcommands()
    ns.Print("preset commands:")
    for _, name in ipairs(subcommandOrder) do
        local cmd = subcommands[name]
        local usage = cmd.args ~= "" and (name .. " " .. cmd.args) or name
        DEFAULT_CHAT_FRAME:AddMessage("  /vp preset " .. usage .. " - " .. cmd.help)
    end
end

ns.AddCommand("preset", "<command> [name]", "list, apply, make and share presets; /vp preset help for more", function(rest)
    local name, args = rest:match("^(%S*)%s*(.-)$")
    local cmd = subcommands[name:lower()]
    if cmd then
        cmd.run(args)
    else
        PrintSubcommands()
    end
end)

ns.AddCommand("presets", "", "list the presets", ListPresets)

AddSubcommand("list", "", "list the presets", ListPresets)

AddSubcommand("apply", "<name>", "apply a preset's settings, keeping the rest of yours", function(name)
    local preset = name ~= "" and ns.FindPreset(name)
    if not preset then return NoPreset(name) end
    ns.UsePreset(preset)
end)
