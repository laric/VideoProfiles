-- VideoProfiles: the video CVars a profile stores.
-- restart = true marks CVars that only take effect after the graphics engine restarts.
local addonName, ns = ...

ns.CVAR_GROUPS = {
    {
        name = "Display",
        cvars = {
            { name = "gxApi", restart = true },
            { name = "gxMonitor", restart = true },
            { name = "gxMaximize", restart = true },
            { name = "gxWindowedResolution", restart = true },
            { name = "gxFullscreenResolution", restart = true },
            { name = "gxRefresh", restart = true },
            { name = "gxVSync", restart = true },
            { name = "vsync", restart = true }, -- newer clients' name for gxVSync
            { name = "gxTripleBuffer", restart = true },
            { name = "LowLatencyMode" },
            { name = "renderScale" },
            { name = "ResampleQuality" },
            { name = "ResampleSharpness" },
            { name = "Gamma" },
            { name = "Contrast" },
            { name = "Brightness" },
        },
    },
    {
        name = "Frame rate",
        cvars = {
            { name = "maxFPS" },
            { name = "useMaxFPS" },
            { name = "maxFPSBk" },
            { name = "useMaxFPSBk" },
            { name = "targetFPS" },
            { name = "useTargetFPS" },
        },
    },
    {
        name = "Anti-aliasing",
        cvars = {
            { name = "MSAAQuality", restart = true },
            { name = "MSAAAlphaTest" },
            { name = "ffxAntiAliasingMode" },
            { name = "textureFilteringMode" },
        },
    },
    {
        name = "Graphics quality",
        cvars = {
            { name = "graphicsQuality" },
            { name = "graphicsShadowQuality" },
            { name = "graphicsLiquidDetail" },
            { name = "graphicsParticleDensity" },
            { name = "graphicsSSAO" },
            { name = "graphicsDepthEffects" },
            { name = "graphicsComputeEffects" },
            { name = "graphicsOutlineMode" },
            { name = "graphicsTextureResolution" },
            { name = "graphicsSpellDensity" },
            { name = "graphicsProjectedTextures" },
            { name = "graphicsViewDistance" },
            { name = "graphicsEnvironmentDetail" },
            { name = "graphicsGroundClutter" },
        },
    },
    {
        name = "Raid graphics quality",
        cvars = {
            { name = "RAIDsettingsEnabled" },
            { name = "raidGraphicsQuality" },
            { name = "raidGraphicsShadowQuality" },
            { name = "raidGraphicsLiquidDetail" },
            { name = "raidGraphicsParticleDensity" },
            { name = "raidGraphicsSSAO" },
            { name = "raidGraphicsDepthEffects" },
            { name = "raidGraphicsComputeEffects" },
            { name = "raidGraphicsOutlineMode" },
            { name = "raidGraphicsTextureResolution" },
            { name = "raidGraphicsSpellDensity" },
            { name = "raidGraphicsProjectedTextures" },
            { name = "raidGraphicsViewDistance" },
            { name = "raidGraphicsEnvironmentDetail" },
            { name = "raidGraphicsGroundClutter" },
        },
    },
    {
        name = "Advanced",
        cvars = {
            { name = "farclip" },
            { name = "horizonStart" },
            { name = "particleDensity" },
            { name = "groundEffectDensity" },
            { name = "groundEffectDist" },
            { name = "environmentDetail" },
            { name = "shadowMode" },
            { name = "shadowTextureSize" },
            { name = "shadowRt" },
            { name = "ssao" },
            { name = "sunShafts" },
            { name = "waterDetail" },
            { name = "rippleDetail" },
            { name = "reflectionMode" },
            { name = "projectedTextures" },
            { name = "spellClutter" },
            { name = "weatherDensity" },
            { name = "physicsLevel" },
            { name = "ffxGlow" },
        },
    },
}

local GetCVar = C_CVar and C_CVar.GetCVar or GetCVar

-- CVars the running client knows about, in list order. Built on first use and
-- cached, so a CVar missing from Retail or WoW Forever is skipped quietly.
local supported, missing

local function Scan()
    supported, missing = {}, {}
    for _, group in ipairs(ns.CVAR_GROUPS) do
        for _, cvar in ipairs(group.cvars) do
            cvar.group = group.name
            if GetCVar(cvar.name) ~= nil then
                table.insert(supported, cvar)
            else
                table.insert(missing, cvar.name)
            end
        end
    end
end

function ns.GetSupportedCVars()
    if not supported then Scan() end
    return supported
end

function ns.GetMissingCVars()
    if not missing then Scan() end
    return missing
end

ns.AddCommand("cvars", "", "show which video CVars this client supports, ready to copy", function()
    local found, absent = ns.GetSupportedCVars(), ns.GetMissingCVars()
    local version, build, _, toc = GetBuildInfo()
    local lines = {
        "VideoProfiles CVar report",
        "Client: " .. tostring(version) .. " build " .. tostring(build) .. ", interface " .. tostring(toc),
        "",
        "Supported (" .. #found .. "):",
    }
    local group
    for _, cvar in ipairs(found) do
        if cvar.group ~= group then
            group = cvar.group
            table.insert(lines, "  [" .. group .. "]")
        end
        table.insert(lines, "    " .. cvar.name .. " = " .. tostring(GetCVar(cvar.name)))
    end
    table.insert(lines, "")
    table.insert(lines, "Missing (" .. #absent .. "):" .. (#absent == 0 and " none" or ""))
    for _, name in ipairs(absent) do
        table.insert(lines, "    " .. name)
    end
    ns.ShowCopyBox("Video CVars on this client", table.concat(lines, "\n"))
end)
