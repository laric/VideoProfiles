-- VideoProfiles: turning a profile into text and back.
--
-- The profile is first written as ";"-separated pairs, the first being its name:
--   @=Base;gxApi=d3d11;gxMonitor=0;...
-- Every value carries its CVar name, so a string from another client or an
-- older version can never put a value on the wrong setting. On import, names
-- that aren't video CVars this addon knows are skipped.
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

function ns.ExportProfile(name)
    local values = ns.db.profiles[name].cvars
    -- ";" separates pairs, so it can't appear in the name or a value.
    local pairsList = { "@=" .. name:gsub(";", "") }
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

-- Returns name, { [cvar] = value }, skipped count, or nil and an error message.
function ns.DecodeProfile(text)
    text = strtrim(text or "")
    if text:sub(1, #PREFIX) ~= PREFIX then
        return nil, "That doesn't look like a VideoProfiles export string."
    end
    local compressed = LibDeflate:DecodeForPrint(text:sub(#PREFIX + 1))
    local decoded = compressed and LibDeflate:DecompressDeflateWithDict(compressed, DICTIONARY)
    if not decoded then return nil, "The export string is damaged or incomplete." end
    local known = KnownCVars()
    local name, values, count, skipped = nil, {}, 0, 0
    for pair in decoded:gmatch("[^;]+") do
        local key, value = pair:match("^([^=]+)=(.*)$")
        if key == "@" then
            name = strtrim(value)
        elseif key and known[key] then
            values[key] = value
            count = count + 1
        else
            skipped = skipped + 1
        end
    end
    if not name or name == "" then return nil, "The export string has no profile name." end
    if count == 0 then return nil, "The export string has no video settings this addon knows." end
    return name, values, skipped
end

-- Adds a decoded profile. A name that is taken gets " (2)", " (3)" and so on.
-- Returns the name it was saved under and how many entries were skipped,
-- or nil and an error message.
function ns.ImportProfile(text)
    local name, values, skipped = ns.DecodeProfile(text)
    if not name then return nil, values end
    name = name:gsub(">", "-")
    local base, n = name, 2
    while ns.FindProfile(name) do
        name = base .. " (" .. n .. ")"
        n = n + 1
    end
    ns.db.profiles[name] = { cvars = values, saved = time() }
    return name, skipped
end

function ns.ShowExport(name)
    ns.ShowCopyBox("Export '" .. name .. "'", ns.ExportProfile(name))
end

local function Import(text)
    local name, skipped = ns.ImportProfile(text)
    if name then
        ns.Print("Imported profile '" .. name .. "'." .. (skipped > 0 and (" Skipped " .. skipped .. " unknown settings.") or ""))
        if ns.UI and ns.UI:IsVisible() then
            ns.UI.selected = name
            ns.UI:Refresh()
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

ns.AddCommand("import", "[string]", "add a profile from an export string", function(text)
    if text == "" then
        ns.ShowImport()
    else
        Import(text)
    end
end)
