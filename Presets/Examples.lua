-- VideoProfiles: example presets. Copy this file to add more; each file in
-- Presets/ also needs a line in VideoProfiles.toc. Values are CVar values as
-- /vp cvars shows them. CVars a client doesn't have are skipped when applying.
local addonName, ns = ...

ns.AddPreset({
    name = "Background power saver",
    author = "VideoProfiles",
    notes = "Caps the frame rate at 30 while the game is in the background.",
    cvars = {
        useMaxFPSBk = 1,
        maxFPSBk = 30,
    },
})

ns.AddPreset({
    name = "Clear raid combat",
    author = "VideoProfiles",
    notes = "Cuts spell and particle effects in raids so mechanics are easier to see.",
    cvars = {
        RAIDsettingsEnabled = 1,
        raidGraphicsSpellDensity = 0,
        raidGraphicsParticleDensity = 1,
        raidGraphicsOutlineMode = 2,
    },
})
