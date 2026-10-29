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
-- or straight from an export string made in game with /vp preset export:
--   ns.AddPreset({ string = "VP2:..." })
-- The string's name, author and notes are used unless the table sets them.
local addonName, ns = ...

ns.presets = {}

function ns.AddPreset(preset)
    if preset.string then
        local name, values, _, meta = ns.DecodeProfile(preset.string)
        if not name then
            -- A broken string is the addon's fault, so say which preset it was.
            geterrorhandler()("VideoProfiles: bundled preset " .. tostring(preset.name or "?") .. ": " .. values)
            return
        end
        preset.name = preset.name or name
        preset.author = preset.author or meta.author
        preset.notes = preset.notes or meta.notes
        preset.cvars = values
        preset.string = nil
    end
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

-- Notes can have several lines; chat shows the first.
local function ListPresets()
    local user = ns.GetUserPresets()
    if #ns.presets == 0 and #user == 0 then
        ns.Print("No presets yet.")
        return
    end
    ns.Print("Presets (they change only the settings they list):")
    for _, preset in ipairs(user) do
        DEFAULT_CHAT_FRAME:AddMessage("  " .. preset.name .. " |cff00ff00(yours)|r (" .. ns.CountPresetCVars(preset) .. " settings)"
            .. (preset.notes and (": " .. preset.notes:match("[^\n]*")) or ""))
    end
    for _, preset in ipairs(ns.presets) do
        local by = preset.author and (" by " .. preset.author) or ""
        DEFAULT_CHAT_FRAME:AddMessage("  " .. preset.name .. by .. " (" .. ns.CountPresetCVars(preset) .. " settings)"
            .. (preset.notes and (": " .. preset.notes:match("[^\n]*")) or ""))
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

-- The player's own presets can be changed; bundled ones can't.
local function FindOwn(name)
    local preset = name ~= "" and ns.FindPreset(name)
    if not preset then return NoPreset(name) end
    if preset.bundled then
        ns.Print("'" .. preset.name .. "' comes with the addon and can't be changed. Use /vp preset copy " .. preset.name .. " to make your own.")
        return
    end
    return preset
end

-- "Name", or "Name 2", "Name 3"... if that is taken.
function ns.FreePresetName(base)
    local name, n = base, 1
    while ns.FindPreset(name) do
        n = n + 1
        name = base .. " " .. n
    end
    return name
end

-- Why a name can't be used for a new preset, or nil if it can.
local function NameProblem(name, except)
    if name == "" then return "A preset needs a name." end
    if name:find(">", 1, true) then return "Preset names can't contain '>'." end
    local clash = ns.FindPreset(name)
    if clash and clash ~= except then return "A preset called '" .. clash.name .. "' already exists." end
end

-- Makes a preset of the player's. Returns it, or nil after saying why not.
function ns.NewPreset(name, cvars)
    name = ns.Unquote(name)
    local problem = NameProblem(name)
    if problem then return ns.Print(problem) end
    local preset = { name = name, cvars = cvars or {}, saved = time() }
    ns.db.presets[name] = preset
    return preset
end

-- Matches CVar names typed in chat to the supported ones, ignoring case.
local function ParseCVarNames(text)
    local byLower = {}
    for _, cvar in ipairs(ns.GetSupportedCVars()) do byLower[cvar.name:lower()] = cvar.name end
    local names, unknown = {}, {}
    for word in text:gmatch("[^%s,]+") do
        local name = byLower[word:lower()]
        if name then table.insert(names, name) else table.insert(unknown, word) end
    end
    return names, unknown
end

AddSubcommand("new", "<name> [> <cvar> <cvar> ...]", "make a preset from your current values of the CVars you list (or pick them in the options)", function(rest)
    local name, list = rest:match("^(.-)%s*>%s*(.-)$")
    if not name then name, list = rest, "" end
    local names, unknown = ParseCVarNames(list)
    if #unknown > 0 then
        ns.Print("Unknown or unsupported CVars: " .. table.concat(unknown, ", ") .. ". /vp cvars lists them.")
        return
    end
    local current, cvars = ns.CaptureCurrent(), {}
    for _, cvar in ipairs(names) do cvars[cvar] = current[cvar] end
    local preset = ns.NewPreset(name, cvars)
    if preset then
        ns.Print("Made the preset '" .. preset.name .. "' with " .. #names .. " settings."
            .. (#names == 0 and " Pick its settings in /vp, or with /vp preset add." or ""))
    end
end)

-- Adds a CVar to a preset with its current value, or takes it out.
function ns.SetPresetCVar(preset, name, included)
    preset.cvars[name] = included and ns.CaptureCurrent()[name] or nil
    preset.saved = time()
end

-- Sets a value of the player's own choosing, which needn't match the current one.
function ns.SetPresetValue(preset, name, value)
    preset.cvars[name] = value
    preset.saved = time()
end

AddSubcommand("set", "<name> > <cvar> <value>", "set a value in a preset, adding the CVar if it isn't there", function(rest)
    local name, cvar, value = rest:match("^(.-)%s*>%s*(%S+)%s+(.-)%s*$")
    local preset = name and FindOwn(name)
    if not preset then return end
    local names = ParseCVarNames(cvar)
    if #names == 0 or value == "" then
        return ns.Print("Usage: /vp preset set <name> > <cvar> <value>. /vp cvars lists the CVars.")
    end
    ns.SetPresetValue(preset, names[1], value)
    ns.Print("Set " .. names[1] .. " to " .. value .. " in '" .. preset.name .. "'.")
end)

AddSubcommand("add", "<name> > <cvar> <cvar> ...", "add CVars to a preset with your current values", function(rest)
    local name, list = rest:match("^(.-)%s*>%s*(.-)$")
    local preset = name and FindOwn(name)
    if not preset then return end
    local names, unknown = ParseCVarNames(list)
    for _, cvar in ipairs(names) do ns.SetPresetCVar(preset, cvar, true) end
    ns.Print("Added " .. #names .. " settings to '" .. preset.name .. "'."
        .. (#unknown > 0 and (" Unknown: " .. table.concat(unknown, ", ") .. ".") or ""))
end)

AddSubcommand("remove", "<name> > <cvar> <cvar> ...", "take CVars out of a preset", function(rest)
    local name, list = rest:match("^(.-)%s*>%s*(.-)$")
    local preset = name and FindOwn(name)
    if not preset then return end
    local names = ParseCVarNames(list)
    for _, cvar in ipairs(names) do ns.SetPresetCVar(preset, cvar, false) end
    ns.Print("Removed " .. #names .. " settings from '" .. preset.name .. "'.")
end)

-- Takes your current value of every CVar the preset sets.
function ns.UpdatePreset(preset)
    local current = ns.CaptureCurrent()
    for name in pairs(preset.cvars) do
        if current[name] ~= nil then preset.cvars[name] = current[name] end
    end
    preset.saved = time()
end

AddSubcommand("update", "<name>", "set a preset's values to your current ones, keeping which settings it has", function(name)
    local preset = FindOwn(name)
    if not preset then return end
    ns.UpdatePreset(preset)
    ns.Print("Updated '" .. preset.name .. "' with your current values.")
end)

function ns.RenamePreset(preset, new)
    new = ns.Unquote(new)
    local problem = NameProblem(new, preset)
    if problem then return ns.Print(problem) end
    ns.db.presets[preset.name] = nil
    ns.Print("Renamed '" .. preset.name .. "' to '" .. new .. "'.")
    preset.name = new
    ns.db.presets[new] = preset
    return true
end

AddSubcommand("rename", "<old> > <new>", "rename one of your presets", function(rest)
    local old, new = rest:match("^(.-)%s*>%s*(.-)$")
    if not old then return ns.Print("Usage: /vp preset rename <old> > <new>") end
    local preset = FindOwn(old)
    if preset then ns.RenamePreset(preset, new) end
end)

AddSubcommand("delete", "<name>", "delete one of your presets", function(name)
    local preset = FindOwn(name)
    if not preset then return end
    ns.db.presets[preset.name] = nil
    ns.Print("Deleted the preset '" .. preset.name .. "'.")
end)

AddSubcommand("notes", "<name> > <text>", "set the notes shown with one of your presets", function(rest)
    local name, text = rest:match("^(.-)%s*>%s*(.-)$")
    local preset = name and FindOwn(name)
    if not preset then return end
    preset.notes = text ~= "" and text or nil
    ns.Print("Set the notes for '" .. preset.name .. "'.")
end)

AddSubcommand("author", "<name> > <text>", "set who the preset is by, shown when it is shared", function(rest)
    local name, text = rest:match("^(.-)%s*>%s*(.-)$")
    local preset = name and FindOwn(name)
    if not preset then return end
    preset.author = text ~= "" and text or nil
    ns.Print("Set the author of '" .. preset.name .. "'.")
end)

-- Copies a preset, or a whole profile, into a new preset of the player's.
-- Presets are looked up first, unless fromProfile is set.
function ns.CopyToPreset(source, new, fromProfile)
    local preset = not fromProfile and ns.FindPreset(source)
    local profile = not preset and ns.FindProfile(source)
    if not preset and not profile then
        return ns.Print("No preset or profile called '" .. source .. "'.")
    end
    local values = preset and preset.cvars or ns.db.profiles[profile].cvars
    local cvars = {}
    for k, v in pairs(values) do cvars[k] = v end
    new = (new and new ~= "") and new or ns.FreePresetName(preset and preset.name or profile)
    local copy = ns.NewPreset(new, cvars)
    if not copy then return end
    if preset then copy.notes, copy.author = preset.notes, preset.author end
    ns.Print("Copied '" .. (preset and preset.name or profile) .. "' to the new preset '" .. copy.name .. "'.")
    return copy
end

AddSubcommand("copy", "<name> [> <new>]", "copy a preset, or a whole profile, into a new preset you can change", function(rest)
    local source, new = rest:match("^(.-)%s*>%s*(.-)$")
    if not source then source = rest end
    if source == "" then return ns.Print("Usage: /vp preset copy <name> [> <new>]") end
    ns.CopyToPreset(source, new)
end)

AddSubcommand("export", "<name>", "show a preset as a string to share", function(name)
    local preset = name ~= "" and ns.FindPreset(name)
    if not preset then return NoPreset(name) end
    ns.ShowExportPreset(preset)
end)

AddSubcommand("import", "[string]", "add a preset from an export string (same as /vp import)", function(text)
    ns.commands.import.run(text)
end)
