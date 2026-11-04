local addonName, ns = ...

ns.AddPreset({
    name = "BellularGaming",
    author = "Bellular",
    notes = "Good shadows, high SSAO and compute effects, essential spell density, render scale at 90%. From the video https://youtu.be/7EgafKMO8Lg?si=mJ720msU3PF47EEw",
    cvars = {
        terrainLodDist = 650,
        graphicsPBRLiquidDetail = 2,
        horizonStart = 4000,
        pbrLiquidDetail = 2,
        SSAO = 3,
        farclip = 10000,
        graphicsShadowQuality = 2,
        renderScale = 0.9,
        graphicsSpellDensity = 0,
        shadowMode = 2,
        graphicsComputeEffects = 3,
        volumeFogLevel = 3,
        spellClutter = 1,
        spellVisualDensityFilterSetting = 1,
        horizonClip = 10000,
        graphicsViewDistance = 9,
        graphicsSSAO = 3,
    },
})
