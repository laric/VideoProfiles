# VideoProfiles

A World of Warcraft addon for Retail and WoW Forever that saves your video
settings as named profiles and lets you swap between them.

A profile stores the video CVars listed in `CVars.lua`: display mode and
resolution, frame rate limits, anti-aliasing, the graphics quality presets
(including raid quality) and the advanced settings. CVars the running client
doesn't have are skipped. Profiles are shared by every character on the
account.

## Usage

Type `/vp` or open **Options > AddOns > VideoProfiles**. Select a profile on
the left; the right side shows what differs from your current settings, or
from another profile picked from the **Compare with** list. **Show all**
lists every value in the profile instead, highlighting the ones that
differ. The buttons below the list save, copy, apply, update, rename, delete,
export and import profiles.

## Presets

A preset usually sets only a few settings, such as a creator's recommended
raid effects. Applying one changes just those and keeps everything else as
you have it. The list shows your own presets under **Presets**, followed by
the suggested ones that come with the addon (in blue). Selecting one shows its
notes and how its values compare with your settings.

To make one, set the game up the way you want, click **New** on the Presets
heading, then tick the settings it should set under **Pick settings**. Ticking
a setting takes your current value, which you can change in the box next to
it; **Update** later sets them all to your current values. **Notes** and **Author** are shown with the preset and carried
in its export string, so you can share it like a profile.

Bundled presets can't be changed, but **Copy** turns any preset or profile into
a new profile (your current settings with the preset's values on top) or a new
preset you can edit.

To ship a preset with the addon, add a file to `Presets/` (see
`Presets/Examples.lua`) and list it in `VideoProfiles.toc`. It can call
`ns.AddPreset` with a name, author, notes and CVars, or simply
`ns.AddPreset({ string = "VP2:..." })` with a string made in game with
**Export**.

## Export and import

**Export** gives a compressed string (about 330 characters for a profile) you
can copy to another computer and paste into **Import** there. Import adds
profiles as profiles and presets as presets. Every setting is stored with
its CVar name, and unknown names are skipped on import.

| Command | What it does |
| --- | --- |
| `/vp` or `/vp show` | open the profiles in Options > AddOns |
| `/vp save <name>` | save your current video settings as a new profile |
| `/vp update <name>` | overwrite a profile with your current settings |
| `/vp apply <name>` | switch to a profile |
| `/vp applyreload <name>` | switch to a profile and reload the UI at once, handy in macros |
| `/vp diff <name> [> <other>]` | list differences from current settings or another profile; presets are compared on the settings they set |
| `/vp copy <name> [> <new>]` | copy a profile, or make a preset into a profile of your own |
| `/vp preset list` | list the presets (also `/vp presets`) |
| `/vp preset apply <name>` | apply a preset's settings, keeping the rest of yours |
| `/vp preset new <name> [> <cvar> ...]` | make a preset from your current values of the listed CVars |
| `/vp preset add` / `remove <name> > <cvar> ...` | add or take out CVars |
| `/vp preset set <name> > <cvar> <value>` | set a value in a preset |
| `/vp preset update`, `rename`, `delete`, `copy`, `export` | as for profiles, for your own presets |
| `/vp preset notes` / `author <name> > <text>` | set the text shown and shared with a preset |
| `/vp rename <old> > <new>` | rename a profile |
| `/vp delete <name>` | delete a profile |
| `/vp export <name>` | show a profile as a string to copy to another computer |
| `/vp import [string]` | add a profile or preset from an export string, or open a box to paste it into |
| `/vp list` | list your profiles |
| `/vp cvars` | show which video CVars this client supports, with values, in a copy box |
| `/vp help` | list the commands |

Applying a profile is refused in combat. When display CVars such as resolution
or MSAA change, the graphics engine restarts. Afterwards a popup offers to
reload the UI (it can be turned off on the options page), since changing CVars from an addon can taint the default UI.

## License

MIT, see [LICENSE](LICENSE). The bundled LibStub is public domain and LibDeflate is
under the zlib license.
