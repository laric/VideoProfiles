-- VideoProfiles: turning a profile into text and back.
--
-- The profile is first written as ";"-separated pairs, the first being its name:
--   @=Base;gxApi=d3d11;gxMonitor=0;...
-- Every value carries its CVar name, so a string from another client or an
-- older version can never put a value on the wrong setting. On import, names
-- that aren't video CVars this addon knows are skipped.
--
-- A preset adds "#=preset" after the name, and "#a=" and "#n=" for its author
-- and notes if it has them. Older versions skip these and import it as a profile.
--
-- The pairs are then compressed with LibDeflate and made printable:
--   "VP2:" .. EncodeForPrint(CompressDeflateWithDict(pairs))
-- The dictionary below holds the CVar names, so they cost almost nothing.
local addonName, ns = ...

local LibDeflate = LibStub("LibDeflate")

local PREFIX = "VP2:"

-- Never change this string: old exports can only be read with the same dictionary.
-- New CVars don't need adding here; they still export, just less compressed.
-- The fixed length and checksum make LibDeflate raise an error if it is edited.
local DICTIONARY = LibDeflate:CreateDictionary((function(text)
    return text, 1333, 744292699
end)("@=;gxApi=;gxMonitor=;gxMaximize=;gxWindowedResolution=;gxFullscreenResolution=;"
    .. "gxRefresh=;gxVSync=;vsync=;gxTripleBuffer=;LowLatencyMode=;renderScale=;"
    .. "ResampleQuality=;ResampleSharpness=;Gamma=;Contrast=;Brightness=;maxFPS=;useMaxFPS=;"
    .. "maxFPSBk=;useMaxFPSBk=;targetFPS=;useTargetFPS=;MSAAQuality=;MSAAAlphaTest=;"
    .. "ffxAntiAliasingMode=;textureFilteringMode=;graphicsQuality=;graphicsShadowQuality=;"
    .. "graphicsLiquidDetail=;graphicsParticleDensity=;graphicsSSAO=;graphicsDepthEffects=;"
    .. "graphicsComputeEffects=;graphicsOutlineMode=;graphicsTextureResolution=;"
    .. "graphicsSpellDensity=;graphicsProjectedTextures=;graphicsViewDistance=;"
    .. "graphicsEnvironmentDetail=;graphicsGroundClutter=;RAIDsettingsEnabled=;"
    .. "raidGraphicsQuality=;raidGraphicsShadowQuality=;raidGraphicsLiquidDetail=;"
    .. "raidGraphicsParticleDensity=;raidGraphicsSSAO=;raidGraphicsDepthEffects=;"
    .. "raidGraphicsComputeEffects=;raidGraphicsOutlineMode=;raidGraphicsTextureResolution=;"
    .. "raidGraphicsSpellDensity=;raidGraphicsProjectedTextures=;raidGraphicsViewDistance=;"
    .. "raidGraphicsEnvironmentDetail=;raidGraphicsGroundClutter=;farclip=;horizonStart=;"
    .. "particleDensity=;groundEffectDensity=;groundEffectDist=;environmentDetail=;"
    .. "shadowMode=;shadowTextureSize=;shadowRt=;ssao=;sunShafts=;waterDetail=;rippleDetail=;"
    .. "reflectionMode=;projectedTextures=;spellClutter=;weatherDensity=;physicsLevel=;ffxGlow="))

-- Every CVar name in the list, supported on this client or not.
local function KnownCVars()
    local known = {}
    for _, group in ipairs(ns.CVAR_GROUPS) do
        for _, cvar in ipairs(group.cvars) do known[cvar.name] = true end
    end
    return known
end

-- ";" separates pairs, so it can't appear in a name, a value or the notes.
local function Clean(text)
    return (text:gsub(";", ","))
end

-- meta is { preset = true, author =, notes = } for a preset, or nil.
local function Encode(name, values, meta)
    local pairsList = { "@=" .. Clean(name) }
    if meta and meta.preset then
        table.insert(pairsList, "#=preset")
        if meta.author then table.insert(pairsList, "#a=" .. Clean(meta.author)) end
        if meta.notes then table.insert(pairsList, "#n=" .. Clean(meta.notes)) end
    end
    for _, group in ipairs(ns.CVAR_GROUPS) do
        for _, cvar in ipairs(group.cvars) do
            local value = values[cvar.name]
            if value and not value:find(";", 1, true) then
                table.insert(pairsList, cvar.name .. "=" .. value)
            end
        end
    end
    local compressed = LibDeflate:CompressDeflateWithDict(table.concat(pairsList, ";"), DICTIONARY, { level = 9 })
    return PREFIX .. LibDeflate:EncodeForPrint(compressed)
end

function ns.ExportProfile(name)
    return Encode(name, ns.db.profiles[name].cvars)
end

function ns.ExportPreset(preset)
    return Encode(preset.name, preset.cvars, { preset = true, author = preset.author, notes = preset.notes })
end

-- Returns name, { [cvar] = value }, skipped count and meta (see Encode),
-- or nil and an error message.
function ns.DecodeProfile(text)
    text = strtrim(text or "")
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "That doesn't look like a VideoProfiles export string."
    end
    local compressed = LibDeflate:DecodeForPrint(text:sub(#PREFIX + 1))
    local decoded = compressed and LibDeflate:DecompressDeflateWithDict(compressed, DICTIONARY)
    if not decoded then return nil, "The export string is damaged or incomplete." end
    local known = KnownCVars()
    local name, values, count, skipped, meta = nil, {}, 0, 0, {}
    for pair in decoded:gmatch("[^;]+") do
        local key, value = pair:match("^([^=]+)=(.*)$")
        if key == "@" then
            name = strtrim(value)
        elseif key == "#" then
            meta.preset = value == "preset"
        elseif key == "#a" then
            meta.author = value
        elseif key == "#n" then
            meta.notes = value
        elseif key and known[key] then
            values[key] = value
            count = count + 1
        else
            skipped = skipped + 1
        end
    end
    if not name or name == "" then return nil, "The export string has no profile name." end
    if count == 0 then return nil, "The export string has no video settings this addon knows." end
    return name, values, skipped, meta
end

-- Adds a decoded profile, or preset if the string holds one. A name that is
-- taken gets " (2)", " (3)" and so on. Returns the name it was saved under,
-- how many entries were skipped and whether it is a preset, or nil and an
-- error message.
function ns.ImportProfile(text)
    local name, values, skipped, meta = ns.DecodeProfile(text)
    if not name then return nil, values end
    name = name:gsub(">", "-")
    local Find = meta.preset and ns.FindPreset or ns.FindProfile
    local base, n = name, 2
    while Find(name) do
        name = base .. " (" .. n .. ")"
        n = n + 1
    end
    if meta.preset then
        ns.db.presets[name] = { name = name, cvars = values, author = meta.author, notes = meta.notes, saved = time() }
    else
        ns.db.profiles[name] = { cvars = values, saved = time() }
    end
    return name, skipped, meta.preset
end

function ns.ShowExport(name)
    ns.ShowCopyBox("Export '" .. name .. "'", ns.ExportProfile(name))
end

function ns.ShowExportPreset(preset)
    ns.ShowCopyBox("Export the preset '" .. preset.name .. "'", ns.ExportPreset(preset))
end

local function Import(text)
    local name, skipped, isPreset = ns.ImportProfile(text)
    if name then
        ns.Print("Imported " .. (isPreset and "preset" or "profile") .. " '" .. name .. "'."
            .. (skipped > 0 and (" Skipped " .. skipped .. " unknown settings.") or ""))
        if ns.UI and ns.UI:IsVisible() then
            ns.UI:Select(name, isPreset and ns.db.presets[name])
        end
    else
        ns.Print(skipped)
    end
end

function ns.ShowImport()
    ns.ShowPasteBox("Paste a VideoProfiles export string", "Import", Import)
end

ns.AddCommand("export", "<name>", "show a profile as a string you can copy to another computer", function(name)
    local existing = name ~= "" and ns.FindProfile(name)
    if not existing then
        ns.Print("No profile called '" .. name .. "'. Use /vp list to see your profiles.")
        return
    end
    ns.ShowExport(existing)
end)

ns.AddCommand("import", "[string]", "add a profile or preset from an export string", function(text)
    if text == "" then
        ns.ShowImport()
    else
        Import(text)
    end
end)
